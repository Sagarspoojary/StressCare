from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
import json
import datetime

from config.database import db
from utils.pii_masking import mask_pii
from utils.gemini_ai import get_emotional_response
from utils.jwt_handler import decode_token

router = APIRouter(prefix="/chat", tags=["Chat"])

# ── Models ─────────────────────────
class ChatMessage(BaseModel):
    message: str
    ghost_mode: bool = False


# ── HELPER: Get user from token ─────────────────────────
def get_user_from_token(authorization: str):
    if not authorization or authorization.endswith("null"):
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    token = authorization.replace("Bearer ", "")
    
    try:
        payload = decode_token(token)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {e}")
    
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    return payload


# ── SEND MESSAGE ─────────────────────────
@router.post("/message")
def send_message(
    data: ChatMessage,
    authorization: Optional[str] = Header(None)
):
    user = get_user_from_token(authorization)
    user_id = user.get("user_id")
    
    # Step 1: Mask PII (privacy)
    masked_message = mask_pii(data.message)
    
    # Step 2: Get AI response
    ai_response_dict = get_emotional_response(masked_message)
    response_text = ai_response_dict.get("response", "I'm here for you 💙")
    stress_score = ai_response_dict.get("stress_score", 5)
    
    # Step 3: Save to database only if Ghost Mode is OFF
    if not data.ghost_mode:
        chats = db["chats"]
        chats.insert_one({
            "user_id": user_id,
            "user_message": data.message,  # Save original for context
            "ai_response": response_text,
            "stress_score": stress_score,
            "created_at": datetime.datetime.utcnow()
        })
        
        stress_logs = db["stress_logs"]
        stress_logs.insert_one({
            "user_id": user_id,
            "stress_score": stress_score,
            "timestamp": datetime.datetime.utcnow().isoformat()
        })
    
    return {
        "response": response_text,
        "ghost_mode": data.ghost_mode,
        "stress_score": stress_score,
        "intent": ai_response_dict.get("intent", "none"),
        "high_stress_alert": ai_response_dict.get("high_stress_alert", False),
    }


# ── GET CHAT HISTORY ─────────────────────────
@router.get("/history")
def get_chat_history(authorization: Optional[str] = Header(None)):
    user = get_user_from_token(authorization)
    user_id = user.get("user_id")
    
    chats = db["chats"]
    user_chats = list(chats.find(
        {"user_id": user_id},
        {"_id": 0, "user_id": 0}
    ).sort("created_at", -1).limit(50))
    
    return {"messages": user_chats}


# ── CLEAR CHAT HISTORY ─────────────────────────
@router.delete("/history")
def clear_chat_history(authorization: Optional[str] = Header(None)):
    user = get_user_from_token(authorization)
    user_id = user.get("user_id")
    
    chats = db["chats"]
    result = chats.delete_many({"user_id": user_id})
    
    return {
        "message": "Chat history cleared",
        "deleted_count": result.deleted_count
    }


# ── GET STRESS TRENDS ─────────────────────────
@router.get("/stress-trends")
def get_stress_trends(authorization: Optional[str] = Header(None)):
    user = get_user_from_token(authorization)
    user_id = user.get("user_id")
    
    stress_logs = db["stress_logs"]
    # Get the last 7 logs
    logs = list(stress_logs.find(
        {"user_id": user_id},
        {"_id": 0, "user_id": 0}
    ).sort("timestamp", -1).limit(7))
    
    # Reverse to make it chronological
    logs.reverse()
    
    return {"trends": logs}