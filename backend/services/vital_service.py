from db.appwrite_client import databases, DATABASE_ID
from appwrite.id import ID
from appwrite.query import Query
from models.vital_model import VitalCreate
from models.alert_model import AlertCreate
from services.threshold_service import evaluate_pulse
from services.alert_service import create_alert
from services.notification_service import send_push_notification
from fastapi import BackgroundTasks
from utils.logger import logger

VITALS_COLLECTION = "vitals"

class VitalPipeline:
    def __init__(self, background_tasks: BackgroundTasks):
        self.background_tasks = background_tasks

    def process_vital(self, vital: VitalCreate):
        """
        The main processing pipeline for an incoming vital record.
        """
        logger.info(f"Processing vital from device {vital.device_id} for patient {vital.patient_id}")
        
        # 1. Evaluate pulse state
        state = evaluate_pulse(vital.pulse_rate)
        
        # 2. Store vital in Appwrite (camelCase keys)
        vital_record = {
            "patientId": str(vital.patient_id),
            "pulseRate": vital.pulse_rate,
            "status": state
        }
        if vital.timestamp:
            vital_record["recordedAt"] = vital.timestamp.isoformat()
            
        try:
            databases.create_document(
                database_id=DATABASE_ID,
                collection_id=VITALS_COLLECTION,
                document_id=ID.unique(),
                data=vital_record
            )
            logger.info("Vital stored successfully.")
        except Exception as e:
            logger.error(f"Failed to store vital: {e}")
            raise e

        # 3. If abnormal, trigger alert
        if state in ["warning", "critical"]:
            logger.warning(f"Abnormal vital detected: {state} state for pulse {vital.pulse_rate}")
            alert_msg = f"Abnormal pulse detected: {vital.pulse_rate} bpm"
            alert_data = AlertCreate(
                patient_id=vital.patient_id,
                pulse_rate=vital.pulse_rate,
                severity=state,
                message=alert_msg
            )
            create_alert(alert_data)

            # 4. Trigger background notification
            title = "CRITICAL ALERT" if state == "critical" else "WARNING ALERT"
            self.background_tasks.add_task(
                send_push_notification,
                patient_id=str(vital.patient_id),
                title=title,
                body=alert_msg
            )

        return {"status": "stored", "pulse_state": state}

def get_patient_vitals_history(patient_id: str, limit: int = 100):
    try:
        response = databases.list_documents(
            database_id=DATABASE_ID,
            collection_id=VITALS_COLLECTION,
            queries=[
                Query.equal("patientId", patient_id),
                Query.order_desc("recordedAt"),
                Query.limit(limit)
            ]
        )
        return response["documents"]
    except Exception as e:
        logger.error(f"Failed to fetch vital history for {patient_id}: {e}")
        return []
