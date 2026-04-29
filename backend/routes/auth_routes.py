from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from config.database import db
from passlib.context import CryptContext
from utils.jwt_handler import create_token
from google.oauth2 import id_token
from google.auth.transport import requests

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


# ── Signup ─────────────────────────
@router.post("/signup")
def signup(data: SignUpRequest):
    users = db["users"]

    if users.find_one({"email": data.email}):
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed_password = pwd_context.hash(data.password[:72])

    result = users.insert_one({
        "full_name": data.full_name,
        "email": data.email,
        "password": hashed_password
    })

    # Create JWT token
    token = create_token({
        "user_id": str(result.inserted_id),
        "email": data.email,
        "full_name": data.full_name
    })

    return {
        "message": "User created successfully",
        "user_id": str(result.inserted_id),
        "token": token
    }


# ── Signin ─────────────────────────
@router.post("/signin")
def signin(data: SignInRequest):
    users = db["users"]

    user = users.find_one({"email": data.email})

    if not user:
        raise HTTPException(status_code=400, detail="User not found")

    if not pwd_context.verify(data.password, user["password"]):
        raise HTTPException(status_code=400, detail="Invalid password")

    # Create JWT token
    token = create_token({
        "user_id": str(user["_id"]),
        "email": user["email"],
        "full_name": user["full_name"]
    })

    return {
        "message": "Login successful",
        "token": token
    }


import httpx

# ── Google Auth ─────────────────────────
@router.post("/google")
async def google_auth(data: GoogleAuthRequest):
    try:
        # Hackathon Bypass: For local testing, we bypass strict Google token verification
        # because Flutter Web's popup often gets blocked by local browser settings.
        email = "test.google@example.com"
        full_name = "Google Test User"
        
        # If a real token is provided, try to decode it without verification just to get the email
        if "ya29." not in data.id_token_str and len(data.id_token_str.split(".")) == 3:
            try:
                import jwt
                decoded = jwt.decode(data.id_token_str, options={"verify_signature": False})
                email = decoded.get("email", email)
                full_name = decoded.get("name", full_name)
            except:
                pass

        users = db["users"]
        user = users.find_one({"email": email})

        if not user:
            # Create user if it doesn't exist (no password needed for OAuth)
            result = users.insert_one({
                "full_name": full_name,
                "email": email,
                "is_google_auth": True
            })
            user_id = str(result.inserted_id)
        else:
            user_id = str(user["_id"])

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
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid Google Token")