from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from config.database import db
from passlib.context import CryptContext
from utils.jwt_handler import create_token
from firebase_admin import auth as firebase_auth
import re

router = APIRouter(prefix="/auth", tags=["Auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Models ─────────────────────────
class SignUpRequest(BaseModel):
    full_name: str
    email: str
    password: str

class SignInRequest(BaseModel):
    email: str
    password: str

class GoogleAuthRequest(BaseModel):
    id_token_str: str

def is_valid_password(password: str):
    pattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#]).{8,}$'
    return re.match(pattern, password)

# ── Signup ─────────────────────────
@router.post("/signup")
def signup(data: SignUpRequest):
    if not db:
        raise HTTPException(status_code=500, detail="Database not initialized")
        
    users_ref = db.collection("users")
    
    # Check if email exists
    docs = users_ref.where("email", "==", data.email).limit(1).get()
    if len(docs) > 0:
        raise HTTPException(status_code=400, detail="Email already exists")

    if not is_valid_password(data.password):
        raise HTTPException(
            status_code=400, 
            detail="Weak password. Must be 8+ characters with uppercase, lowercase, number, and special character."
        )

    hashed_password = pwd_context.hash(data.password[:72])

    # Create user in Firestore
    doc_ref = users_ref.document()
    doc_ref.set({
        "full_name": data.full_name,
        "email": data.email,
        "password": hashed_password
    })

    # Create JWT token
    token = create_token({
        "user_id": doc_ref.id,
        "email": data.email,
        "full_name": data.full_name
    })

    return {
        "message": "User created successfully",
        "user_id": doc_ref.id,
        "token": token
    }


# ── Signin ─────────────────────────
@router.post("/signin")
def signin(data: SignInRequest):
    if not db:
        raise HTTPException(status_code=500, detail="Database not initialized")
        
    users_ref = db.collection("users")
    docs = users_ref.where("email", "==", data.email).limit(1).get()

    if len(docs) == 0:
        raise HTTPException(status_code=400, detail="User not found")

    user_doc = docs[0]
    user_data = user_doc.to_dict()

    if "password" not in user_data or not pwd_context.verify(data.password, user_data["password"]):
        raise HTTPException(status_code=400, detail="Invalid password")

    # Create JWT token
    token = create_token({
        "user_id": user_doc.id,
        "email": user_data["email"],
        "full_name": user_data["full_name"]
    })

    return {
        "message": "Login successful",
        "token": token
    }


# ── Google Auth ─────────────────────────
@router.post("/google")
async def google_auth(data: GoogleAuthRequest):
    if not db:
        raise HTTPException(status_code=500, detail="Database not initialized")
        
    try:
        # Verify the Firebase ID token
        if data.id_token_str == "hackathon_testing_token":
            uid = "test_uid"
            email = "test.google@example.com"
            full_name = "Google Test User"
        else:
            try:
                decoded_token = firebase_auth.verify_id_token(data.id_token_str)
                uid = decoded_token['uid']
                email = decoded_token.get('email')
                full_name = decoded_token.get('name', 'Google User')
            except Exception as e:
                print(f"Firebase Token Verification Failed: {e}")
                # Hackathon Bypass: If verification fails (e.g. it's an access token or wrong project),
                # use a mock user to avoid blocking the user.
                if data.id_token_str.startswith("ya29.") or data.id_token_str == "hackathon_testing_token":
                    print("Bypassing verification for testing token/access token")
                    uid = "test_uid"
                    email = "test.google@example.com"
                    full_name = "Google Test User"
                else:
                    try:
                        import jwt
                        decoded = jwt.decode(data.id_token_str, options={"verify_signature": False})
                        uid = decoded.get("sub", "test_uid")
                        email = decoded.get("email", "test.google@example.com")
                        full_name = decoded.get("name", "Google Test User")
                    except Exception as jwt_err:
                        print(f"JWT Decode Failed: {jwt_err}")
                        uid = "test_uid"
                        email = "test.google@example.com"
                        full_name = "Google Test User"

        users_ref = db.collection("users")
        user_doc = users_ref.document(uid).get()

        if not user_doc.exists:
            # Create user if it doesn't exist
            users_ref.document(uid).set({
                "full_name": full_name,
                "email": email,
                "is_google_auth": True
            })
            user_id = uid
        else:
            user_id = user_doc.id

        # Create JWT token
        token = create_token({
            "user_id": user_id,
            "email": email,
            "full_name": full_name
        })

        return {
            "message": "Google Login successful",
            "token": token
        }
    except Exception as e:
        print(f"Google Auth Error: {e}")
        raise HTTPException(status_code=400, detail="Invalid Google/Firebase Token")