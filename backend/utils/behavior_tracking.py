import datetime
from config.database import db
from firebase_admin import firestore

STRESS_KEYWORDS = ["stress", "tired", "exhausted", "pressure", "overwhelmed"]

def analyze_user_behavior(user_id: str, current_message: str) -> dict:
    """
    Analyze user interaction patterns to detect hidden stress signals.
    Returns flags and a combined behavior score.
    """
    now = datetime.datetime.utcnow()
    
    # 1. Late Night Activity (12:00 AM - 5:00 AM)
    current_hour = now.hour
    late_night_activity = 0 <= current_hour <= 5
    
    if not db:
        print("Database not initialized in behavior_tracking")
        return {
            "late_night_activity": late_night_activity,
            "repeated_stress": False,
            "low_activity": False,
            "behavior_score": 0
        }
        
    chats_ref = db.collection("chats")
    behavior_logs_ref = db.collection("behavior_logs")
    
    # Fetch recent history (last 10 messages) without order_by to avoid index requirement
    docs = chats_ref.where("user_id", "==", user_id).get()
    recent_history = [doc.to_dict() for doc in docs]
    recent_history.sort(key=lambda x: x.get("created_at") or datetime.datetime(1970, 1, 1), reverse=True)
    recent_history = recent_history[:10]
    
    # 2. Repeated Stress Signals
    stress_count = 0
    msg_lower = current_message.lower()
    if any(k in msg_lower for k in STRESS_KEYWORDS):
        stress_count += 1
        
    for chat in recent_history:
        prev_msg = chat.get("user_message", "").lower()
        if any(k in prev_msg for k in STRESS_KEYWORDS):
            stress_count += 1
            
    repeated_stress = stress_count >= 3 # Threshold: 3 occurrences in last 11 messages
    
    # 3. Reduced Activity
    # Check if there was a long gap between last message and this one
    low_activity = False
    if recent_history:
        last_chat_time = recent_history[0].get("created_at")
        if last_chat_time:
            # Make offset-naive to avoid subtraction error
            if hasattr(last_chat_time, 'tzinfo') and last_chat_time.tzinfo is not None:
                last_chat_time = last_chat_time.replace(tzinfo=None)
            time_gap = (now - last_chat_time).days
            if time_gap >= 3: # Gap of 3+ days
                low_activity = True
                
    # Behavior Score Logic
    behavior_score = 0
    if late_night_activity: behavior_score += 30
    if repeated_stress: behavior_score += 40
    if low_activity: behavior_score += 30
    
    result = {
        "late_night_activity": late_night_activity,
        "repeated_stress": repeated_stress,
        "low_activity": low_activity,
        "behavior_score": behavior_score
    }
    
    # 4. Store Behavior Log
    try:
        behavior_logs_ref.add({
            "user_id": user_id,
            "timestamp": now,
            "behavior_score": behavior_score,
            "flags": {
                "late_night_activity": late_night_activity,
                "repeated_stress": repeated_stress,
                "low_activity": low_activity
            }
        })
    except Exception as e:
        print(f"Error storing behavior log: {e}")
        
    print(f"BEHAVIOR ANALYSIS: {result}")
    print(f"BEHAVIOR SCORE: {behavior_score}")
    
    return result

