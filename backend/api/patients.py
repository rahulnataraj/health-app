from fastapi import APIRouter, HTTPException, Query
from db.appwrite_client import tablesDB, DATABASE_ID
from services.vital_service import get_patient_vitals_history
from utils.logger import logger

PATIENTS_COLLECTION = "patients"

router = APIRouter(prefix="/api/v1/patients", tags=["Patients"])

@router.get("/{patient_id}")
def get_patient_info(patient_id: str):
    """Fetch patient details by ID"""
    try:
        response = tablesDB.get_row(
            database_id=DATABASE_ID,
            table_id=PATIENTS_COLLECTION,
            row_id=patient_id
        )
        return response
    except Exception as e:
        logger.error(f"Error fetching patient {patient_id}: {e}")
        raise HTTPException(status_code=404, detail="Patient not found or invalid ID")

@router.get("/{patient_id}/vitals")
def get_patient_history(
    patient_id: str,
    limit: int = Query(100, description="Max number of records"),
    from_date: str = Query(None, description="Start date ISO string"),
    to_date: str = Query(None, description="End date ISO string")
):
    """Fetch history of vitals for a specific patient"""
    return get_patient_vitals_history(patient_id, limit)
