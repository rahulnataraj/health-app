import bcrypt
import jwt
from datetime import datetime, timedelta, timezone
from db.appwrite_client import tablesDB, DATABASE_ID
from appwrite.id import ID
from appwrite.query import Query
from models.auth_model import UserSignup, UserLogin
from config import settings
from utils.logger import logger
from fastapi import HTTPException

USERS_COLLECTION = "users"

def signup_user(user: UserSignup):
    try:
        # Check if user already exists by email
        existing = tablesDB.list_rows(
            database_id=DATABASE_ID,
            table_id=USERS_COLLECTION,
            queries=[Query.equal("email", user.email)]
        )
        if existing["total"] > 0:
            raise HTTPException(status_code=400, detail="User with this email already exists")

        # Hash the password
        hashed_password = bcrypt.hashpw(user.password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

        # Build user document matching Appwrite users collection
        user_data = {
            "username": user.username,
            "email": user.email,
            "password": hashed_password,
            "isActive": True
        }

        # Add optional fields if provided
        if user.first_name:
            user_data["firstName"] = user.first_name
        if user.last_name:
            user_data["lastName"] = user.last_name
        if user.role:
            user_data["role"] = user.role
        if user.birthdate:
            user_data["birthdate"] = user.birthdate.isoformat()

        # Store user document
        result = tablesDB.create_row(
            database_id=DATABASE_ID,
            table_id=USERS_COLLECTION,
            row_id=ID.unique(),
            data=user_data
        )
        logger.info(f"User registered: {user.email}")
        return {
            "message": "User registered successfully",
            "user_id": result["$id"],
            "username": result["username"],
            "email": result["email"]
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during signup: {e}")
        raise HTTPException(status_code=400, detail=str(e))

def login_user(user: UserLogin):
    try:
        # Find user by email
        result = tablesDB.list_rows(
            database_id=DATABASE_ID,
            table_id=USERS_COLLECTION,
            queries=[Query.equal("email", user.email)]
        )

        if result["total"] == 0:
            raise HTTPException(status_code=401, detail="Invalid email or password")

        user_doc = result["rows"][0]

        # Check if user is active
        if not user_doc.get("isActive", True):
            raise HTTPException(status_code=403, detail="Account is deactivated")

        # Verify password
        if not bcrypt.checkpw(user.password.encode("utf-8"), user_doc["password"].encode("utf-8")):
            raise HTTPException(status_code=401, detail="Invalid email or password")

        # Generate JWT token
        payload = {
            "user_id": user_doc["$id"],
            "email": user_doc["email"],
            "username": user_doc["username"],
            "role": user_doc.get("role"),
            "exp": datetime.now(timezone.utc) + timedelta(hours=24)
        }
        token = jwt.encode(payload, settings.jwt_secret, algorithm="HS256")

        logger.info(f"User logged in: {user.email}")
        return {
            "access_token": token,
            "token_type": "bearer",
            "user_id": user_doc["$id"],
            "username": user_doc["username"],
            "email": user_doc["email"],
            "role": user_doc.get("role")
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise HTTPException(status_code=401, detail=str(e))
