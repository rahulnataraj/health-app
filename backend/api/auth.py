from fastapi import APIRouter, HTTPException, Security
from fastapi.security import APIKeyHeader
from models.auth_model import UserSignup, UserLogin
from services.auth_service import signup_user, login_user
from db.appwrite_client import tablesDB, DATABASE_ID
from appwrite.query import Query
from config import settings
from utils.logger import logger
import jwt

router = APIRouter(prefix="/auth", tags=["Authentication"])

auth_header = APIKeyHeader(name="Authorization", auto_error=False)

@router.post("/signup")
def signup(user: UserSignup):
    """
    Register a new user with email and password.
    Password is hashed with bcrypt and stored in the database.
    """
    response = signup_user(user)
    return response

@router.post("/login")
def login(user: UserLogin):
    """
    Login an existing user and get a JWT session token.
    """
    response = login_user(user)
    return response

@router.get("/me")
def get_current_user(authorization: str = Security(auth_header)):
    """
    Returns the current user profile + linked patient_id.
    Requires Authorization: Bearer <jwt_token>
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")

    prefix = "Bearer "
    if not authorization.startswith(prefix):
        raise HTTPException(status_code=401, detail="Invalid Authorization format")

    token = authorization[len(prefix):]

    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    # Look up linked patient by familyUserId
    patient_id = None
    try:
        result = tablesDB.list_rows(
            database_id=DATABASE_ID,
            table_id="patients",
            queries=[Query.equal("familyUserId", user_id)]
        )
        if result["total"] > 0:
            patient_id = result["rows"][0]["$id"]
    except Exception as e:
        logger.warning(f"Failed to look up patient for user {user_id}: {e}")

    return {
        "user_id": user_id,
        "email": payload.get("email"),
        "username": payload.get("username"),
        "role": payload.get("role"),
        "patient_id": patient_id
    }
