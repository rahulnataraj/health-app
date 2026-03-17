from appwrite.client import Client
from appwrite.services.tables_db import TablesDB
from config import settings
from utils.logger import logger

try:
    client = Client()
    client.set_endpoint(settings.appwrite_endpoint)
    client.set_project(settings.appwrite_project_id)
    client.set_key(settings.appwrite_api_key)

    tablesDB = TablesDB(client)
    DATABASE_ID = settings.appwrite_database_id

    logger.info("Appwrite client initialized successfully.")
except Exception as e:
    logger.error(f"Failed to initialize Appwrite client: {e}")
    raise e
