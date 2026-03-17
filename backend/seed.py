import asyncio
import uuid
import bcrypt
from datetime import datetime, timedelta, timezone
from db.appwrite_client import tablesDB, DATABASE_ID
from appwrite.id import ID
from utils.logger import logger

USERS_COLLECTION = "users"
PATIENTS_COLLECTION = "patients"
VITALS_COLLECTION = "vitals"
ALERTS_COLLECTION = "alerts"

async def seed_database():
    logger.info("Starting database seeding...")

    # 1. Create a mock user with bcrypt-hashed password
    test_email = "test.patient@example.com"
    test_password = "SecurePassword123!"

    user_id = None
    try:
        logger.info(f"Creating test user: {test_email}")
        hashed_password = bcrypt.hashpw(test_password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        result = tablesDB.create_row(
            database_id=DATABASE_ID,
            table_id=USERS_COLLECTION,
            row_id=ID.unique(),
            data={
                "username": "testpatient",
                "email": test_email,
                "password": hashed_password,
                "firstName": "Test",
                "lastName": "Patient",
                "role": "user",
                "isActive": True
            }
        )
        user_id = result["$id"]
        logger.info(f"Created user with ID: {user_id}")
    except Exception as e:
        logger.warning(f"User creation failed (may already exist). Error: {e}")
        user_id = str(uuid.uuid4())
        logger.info(f"Using mock UUID for user: {user_id}")

    doctor_id = str(uuid.uuid4())
    patient_id = str(uuid.uuid4())

    # 2. Seed Patients
    logger.info("Seeding patients collection...")
    try:
        tablesDB.create_row(
            database_id=DATABASE_ID,
            table_id=PATIENTS_COLLECTION,
            row_id=patient_id,
            data={
                "name": "Jacob Jones",
                "age": 45,
                "doctorId": doctor_id,
                "familyUserId": user_id,
                "medicalCondition": "Hypertension",
                "admissionDate": "2025-01-15T00:00:00+00:00"
            }
        )
        logger.info("Inserted patient: Jacob Jones")
    except Exception as e:
        logger.error(f"Failed to insert patient: {e}")

    # 3. Seed Vitals
    logger.info("Seeding vitals collection...")
    base_time = datetime.now(timezone.utc) - timedelta(hours=4)
    pulses = [72, 75, 78, 85, 92, 95, 88, 76, 70, 68]

    for i, pulse in enumerate(pulses):
        status = "normal"
        if pulse > 90:
            status = "warning"

        try:
            tablesDB.create_row(
                database_id=DATABASE_ID,
                table_id=VITALS_COLLECTION,
                row_id=ID.unique(),
                data={
                    "patientId": patient_id,
                    "pulseRate": pulse,
                    "status": status,
                    "recordedAt": (base_time + timedelta(minutes=30 * i)).isoformat()
                }
            )
        except Exception as e:
            logger.error(f"Failed to insert vital record: {e}")

    logger.info(f"Inserted {len(pulses)} vital records")

    # 4. Seed Alerts
    logger.info("Seeding alerts collection...")
    alerts_data = [
        {
            "patientId": patient_id,
            "message": "Elevated heart rate detected (95 bpm)",
            "severity": "warning",
            "pulseRate": 95,
            "isRead": False
        },
        {
            "patientId": patient_id,
            "message": "Heart rate returning to normal",
            "severity": "info",
            "isRead": True
        }
    ]

    for alert in alerts_data:
        try:
            tablesDB.create_row(
                database_id=DATABASE_ID,
                table_id=ALERTS_COLLECTION,
                row_id=ID.unique(),
                data=alert
            )
        except Exception as e:
            logger.error(f"Failed to insert alert: {e}")

    logger.info(f"Inserted {len(alerts_data)} alert records")
    logger.info("Seeding complete!")

if __name__ == "__main__":
    asyncio.run(seed_database())
