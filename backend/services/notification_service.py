import firebase_admin
from firebase_admin import credentials, messaging
from db.appwrite_client import tablesDB, DATABASE_ID
from appwrite.query import Query
from config import settings
from utils.logger import logger

DEVICES_COLLECTION = "devices"

# ── Firebase Initialization ──────────────────────────────────────────────────

_firebase_initialized = False

def init_firebase():
    """Initialize Firebase Admin SDK with service account credentials."""
    global _firebase_initialized
    if _firebase_initialized:
        return True

    try:
        if not firebase_admin._apps:
            creds_path = settings.get_firebase_credentials_path()
            if creds_path:
                cred = credentials.Certificate(creds_path)
                firebase_admin.initialize_app(cred)
                _firebase_initialized = True
                logger.info("Firebase Admin SDK initialized successfully.")
                return True
            else:
                logger.warning(
                    "Firebase credentials not found. "
                    "Set FIREBASE_CREDENTIALS_PATH (local) or FIREBASE_CREDENTIALS_JSON (Render). "
                    "Push notifications will be logged but not delivered."
                )
                return False
        else:
            _firebase_initialized = True
            return True
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        return False

# Initialize on module load
_firebase_ready = init_firebase()


# ── Device Token Management ──────────────────────────────────────────────────

def get_device_tokens_for_patient(patient_id: str) -> list[str]:
    """
    Look up all FCM device tokens associated with a patient.
    Flow: patient → familyUserId → devices collection → fcmToken(s)
    """
    try:
        # 1. Get the patient to find their familyUserId
        patient = tablesDB.get_row(
            database_id=DATABASE_ID,
            table_id="patients",
            row_id=patient_id
        )
        family_user_id = patient.get("familyUserId")
        if not family_user_id:
            logger.warning(f"Patient {patient_id} has no familyUserId, cannot send push.")
            return []

        # 2. Find all registered devices for this user
        result = tablesDB.list_rows(
            database_id=DATABASE_ID,
            table_id=DEVICES_COLLECTION,
            queries=[
                Query.equal("userId", family_user_id),
                Query.equal("isActive", True)
            ]
        )
        tokens = [doc["fcmToken"] for doc in result["rows"] if doc.get("fcmToken")]
        logger.info(f"Found {len(tokens)} device(s) for patient {patient_id} (user {family_user_id})")
        return tokens

    except Exception as e:
        logger.error(f"Failed to look up device tokens for patient {patient_id}: {e}")
        return []


# ── Push Notification Sending ────────────────────────────────────────────────

async def send_push_notification(patient_id: str, title: str, body: str):
    """
    Send FCM push notification to all devices registered for this patient's family user.
    Called as a FastAPI BackgroundTask so it never blocks the API response.
    """
    logger.info(f"Preparing push notification for patient {patient_id}: {title}")

    if not _firebase_ready:
        logger.warning(
            f"Firebase not initialized — logging alert instead. "
            f"Patient: {patient_id} | {title}: {body}"
        )
        return

    # Get all device tokens for this patient
    tokens = get_device_tokens_for_patient(patient_id)
    if not tokens:
        logger.warning(f"No device tokens found for patient {patient_id}. Push not sent.")
        return

    # Build the FCM message with data payload (for background handling in Flutter)
    notification = messaging.Notification(
        title=title,
        body=body
    )

    # Send to each device token
    success_count = 0
    failure_count = 0

    for token in tokens:
        try:
            message = messaging.Message(
                notification=notification,
                data={
                    "patient_id": patient_id,
                    "alert_type": "critical" if "CRITICAL" in title.upper() else "warning",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK"
                },
                token=token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        sound="default",
                        channel_id="health_alerts",
                        priority="max"
                    )
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound="default",
                            badge=1,
                            content_available=True
                        )
                    )
                )
            )
            response = messaging.send(message)
            logger.info(f"FCM sent successfully to token ...{token[-8:]}: {response}")
            success_count += 1

        except messaging.UnregisteredError:
            logger.warning(f"Token ...{token[-8:]} is unregistered. Deactivating device.")
            _deactivate_device_token(token)
            failure_count += 1

        except messaging.SenderIdMismatchError:
            logger.error(f"Sender ID mismatch for token ...{token[-8:]}. Deactivating.")
            _deactivate_device_token(token)
            failure_count += 1

        except Exception as e:
            logger.error(f"Failed to send FCM to token ...{token[-8:]}: {e}")
            failure_count += 1

    logger.info(
        f"Push notification results for patient {patient_id}: "
        f"{success_count} sent, {failure_count} failed"
    )


def _deactivate_device_token(token: str):
    """Mark a device token as inactive when it becomes invalid."""
    try:
        result = tablesDB.list_rows(
            database_id=DATABASE_ID,
            table_id=DEVICES_COLLECTION,
            queries=[Query.equal("fcmToken", token)]
        )
        for doc in result["rows"]:
            tablesDB.update_row(
                database_id=DATABASE_ID,
                table_id=DEVICES_COLLECTION,
                row_id=doc["$id"],
                data={"isActive": False}
            )
        logger.info(f"Deactivated device with token ...{token[-8:]}")
    except Exception as e:
        logger.error(f"Failed to deactivate device token: {e}")
