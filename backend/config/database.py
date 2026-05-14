import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os
from dotenv import load_dotenv

load_dotenv()

db = None

try:
    # Support for JSON string in environment variable (for production like Render)
    service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    
    if service_account_json:
        import json
        service_account_info = json.loads(service_account_json)
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin initialized from JSON string")
    elif service_account_path and os.path.exists(service_account_path):
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin initialized from service account file")
    else:
        # Fallback to default credentials or env var GOOGLE_APPLICATION_CREDENTIALS
        firebase_admin.initialize_app()
        print("Firebase Admin initialized with default credentials")
    
    db = firestore.client()
    print("Firestore initialized successfully")
except Exception as e:
    print(f"Firebase Admin initialization warning: {e}")
    print("Please ensure you have set GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_SERVICE_ACCOUNT_PATH, or FIREBASE_SERVICE_ACCOUNT_JSON in .env")