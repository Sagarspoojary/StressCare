import os
import json
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# Configure Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def get_emotional_response(
    user_message: str, 
    history_summary: str = "", 
    recent_stress_levels: list = [], 
    input_type: str = "text",
    behavior_summary: dict = None,
    pattern_summary: dict = None
) -> dict:
    """
    Send the user's masked message and context to Google Gemini AI.
    Returns the exact JSON structure required by StressCare.
    """
    if not GEMINI_API_KEY or True:  # Force fallback for testing masking as requested by user
        return get_fallback_response(user_message)
    
    try:
        model_name = 'models/gemini-2.5-flash'
        model = genai.GenerativeModel(model_name)
        print("USING MODEL:", model_name)
        
        # Safe System Prompt version
        system_instruction = (
            "You are StressCare, an emotionally intelligent and observant caregiver assistant.\n\n"
            "You MUST analyze:\n"
            "1. User message\n"
            "2. behavior_summary\n"
            "3. pattern_summary\n\n"
            "IMPORTANT RULES:\n"
            "If pattern_summary.repeated_pattern == true:\n"
            "You MUST acknowledge that the user has been feeling this way for a while.\n\n"
            "If pattern_summary.increasing_stress == true:\n"
            "You MUST mention that stress seems to be increasing.\n\n"
            "If pattern_summary.high_risk == true:\n"
            "You MUST warn about possible burnout.\n\n"
            "If pattern_summary.fatigue_cycle == true:\n"
            "You MUST mention consistent tiredness.\n\n"
            "If multiple conditions are true:\n"
            "Combine them naturally in a human way.\n\n"
            "CRITICAL SAFETY RULE:\n"
            "If user message contains phrases like:\n"
            "I can't do this anymore, I give up, I feel mentally drained, I am exhausted\n"
            "You MUST respond with high concern and support.\n"
            "NEVER classify as neutral.\n\n"
            "Tone rules:\n"
            "Be human, supportive, and calm.\n"
            "Be more serious when risk is high.\n"
            "Do not ignore patterns.\n\n"
            "Return ONLY valid JSON.\n"
            "Do NOT include markdown.\n"
            "Do NOT include extra text.\n"
            "Return EXACTLY this structure:\n"
            "{\n"
            "  \"message\": \"<empathetic response>\",\n"
            "  \"stress_level\": \"low | medium | high\",\n"
            "  \"burnout_score\": <integer 0-100>,\n"
            "  \"emotion\": \"stress | fatigue | neutral | happiness | sadness | anger | fear | surprise | disgust | anxiety | frustration | calmness | engagement\",\n"
            "  \"suggestion\": \"<short helpful suggestion>\",\n"
            "  \"actions\": [],\n"
            "  \"intent\": \"normal\"\n"
            "}"
        )

        print("BEHAVIOR CONTEXT SENT:", behavior_summary)
        input_data = {
            "message": user_message,
            "history_summary": history_summary,
            "recent_stress_levels": recent_stress_levels,
            "behavior_summary": behavior_summary,
            "pattern_summary": pattern_summary,
            "input_type": input_type
        }

        prompt = f"System Instruction: {system_instruction}\n\nInput Context: {json.dumps(input_data)}"
        
        print(f"--- GEMINI REQUEST (Model: {model_name}) ---\nPrompt: {prompt}\n-----------------------")
        
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        print(f"--- GEMINI RESPONSE ---\nText: {text}\n------------------------")
        
        raw_response = response.text.strip()
        print(f"RAW GEMINI RESPONSE: {raw_response}")
        
        # Clean the response to ensure valid JSON (remove markdown code blocks manually)
        json_text = raw_response
        json_text = json_text.replace("```json", "").replace("```", "").strip()
            
        try:
            ai_result = json.loads(json_text)
            print(f"PARSED JSON: {ai_result}")
        except Exception as json_err:
            print(f"JSON PARSE ERROR: {json_err}")
            print(f"RAW GEMINI RESPONSE FOR DEBUG: {raw_response}")
            return get_fallback_response(user_message)
        
        # Validate and normalize fields
        valid_emotions = ["stress", "fatigue", "neutral", "happiness", "sadness", "anger", "fear", "surprise", "disgust", "anxiety", "frustration", "calmness", "engagement"]
        ai_result["emotion"] = ai_result.get("emotion", "neutral").lower()
        if ai_result["emotion"] not in valid_emotions:
            ai_result["emotion"] = "neutral"
            
        ai_result["message"] = ai_result.get("message") or ai_result.get("response") or "I'm here for you. 💙"
        ai_result["stress_level"] = ai_result.get("stress_level", "low").lower()
        ai_result["burnout_score"] = ai_result.get("burnout_score", 30)
        ai_result["intent"] = ai_result.get("intent", "normal")
        
        print(f"DETECTED EMOTION: {ai_result['emotion']}")
            
        return ai_result
        
    except Exception as e:
        error_msg = str(e)
        if "429" in error_msg:
            print(f"!!! GEMINI QUOTA EXHAUSTED !!!: {error_msg}")
        else:
            print(f"!!! GEMINI ERROR !!!: {error_msg}")
        # Return a structured error response that routes to fallback
        return get_fallback_response(user_message)


def _classify_emotion_with_ai(text: str) -> dict | None:
    """
    Lightweight Gemini call dedicated to emotion classification only.
    Used as PRIMARY detector inside the fallback pipeline.
    Returns a minimal dict or None if AI is unavailable.
    """
    if not GEMINI_API_KEY:
        return None

    try:
        model = genai.GenerativeModel('models/gemini-2.5-flash')
        prompt = (
            f'Analyze this message and return ONLY valid JSON with no markdown:\n\n'
            f'Message: "{text}"\n\n'
            f'Rules:\n'
            f'- Understand full sentence meaning, NOT just keywords\n'
            f'- Handle negation: "not stressed" = LOW stress\n'
            f'- Handle improvement: "feeling better" = LOW stress\n'
            f'- Handle typos: "stressd" should be treated as "stressed"\n'
            f'- "not at all stressed", "not really tired" = LOW stress\n\n'
            f'Return EXACTLY:\n'
            f'{{\n'
            f'  "emotion": "stress | fatigue | anxiety | sadness | anger | happiness | calmness | neutral",\n'
            f'  "stress_level": "low | medium | high",\n'
            f'  "burnout_score": <integer 0-100>\n'
            f'}}'
        )
        response = model.generate_content(prompt)
        raw = response.text.strip().replace("```json", "").replace("```", "").strip()
        result = json.loads(raw)
        print(f"AI EMOTION CLASSIFIER RESULT: {result}")
        return result
    except Exception as e:
        print(f"AI EMOTION CLASSIFIER FAILED (using keyword fallback): {e}")
        return None


def _keyword_emotion_detect(msg_lower: str) -> str:
    """
    Window-based keyword emotion detection.
    True last resort when AI is unavailable.
    """
    NEGATIONS = ["not", "no", "never", "dont", "don't"]
    IMPROVEMENT_WORDS = ["better", "fine", "okay", "good", "improving", "good now"]
    STRESS_EMOTION_WORDS = ["stress", "stressed", "anxious", "tired", "exhausted"]

    words = msg_lower.split()

    # STEP 1: Improvement check (highest priority)
    if any(word in msg_lower for word in IMPROVEMENT_WORDS):
        return "neutral_positive"  # Signals improvement, treat as neutral/low

    # STEP 2: Window-based negation (checks 3 words BEFORE any stress keyword)
    for i, word in enumerate(words):
        if word in STRESS_EMOTION_WORDS:
            window = words[max(0, i - 3):i]
            if any(neg in window for neg in NEGATIONS):
                return "neutral_negated"  # Signals negation, treat as neutral/low

    # STEP 3: Standard keyword matching
    if any(w in msg_lower for w in ["sleep", "tired", "exhausted", "sleepy"]):
        return "fatigue"
    if any(w in msg_lower for w in ["stress", "pressure", "overwhelmed", "anxious", "tension"]):
        return "stress"
    if any(w in msg_lower for w in ["happy", "good", "excited", "joy"]):
        return "happiness"
    if any(w in msg_lower for w in ["sad", "upset", "unhappy", "cry"]):
        return "sadness"
    if any(w in msg_lower for w in ["angry", "annoyed", "irritated", "hate"]):
        return "anger"
    if any(w in msg_lower for w in ["worried", "nervous", "anxiety", "fear"]):
        return "anxiety"
    if any(w in msg_lower for w in ["calm", "relaxed", "peaceful"]):
        return "calmness"

    return "neutral"


def get_fallback_response(user_message: str) -> dict:
    """
    Upgraded fallback system for StressCare.
    Priority order:
      1. Lightweight AI classifier (full sentence understanding)
      2. Window-based keyword detection (negation-aware)
    Ensures a valid response even if the main Gemini call is unavailable.
    """
    msg_lower = user_message.lower()

    # ── STEP 1: TRY LIGHTWEIGHT AI CLASSIFICATION (PRIMARY) ──
    ai_result = _classify_emotion_with_ai(user_message)
    if ai_result:
        emotion = ai_result.get("emotion", "neutral")
        stress_level = ai_result.get("stress_level", "low")
        burnout_score = ai_result.get("burnout_score", 20)
        print(f"AI CLASSIFIER USED: emotion={emotion}, stress={stress_level}")

        # Build a complete response from the AI classification result
        if stress_level == "high" or emotion == "stress":
            return {
                "emotion": emotion,
                "message": "It sounds like you're carrying a heavy load right now. I'm right here with you 💙",
                "stress_level": stress_level,
                "burnout_score": burnout_score,
                "suggestion": "Try taking a short break. Even 5 minutes of calm breathing can make a big difference.",
                "actions": [],
                "intent": "normal"
            }
        elif stress_level == "medium":
            return {
                "emotion": emotion,
                "message": "I can sense you have a lot on your plate. It's okay to slow down a little.",
                "stress_level": stress_level,
                "burnout_score": burnout_score,
                "suggestion": "Break your tasks into smaller steps and take one thing at a time.",
                "actions": [],
                "intent": "normal"
            }
        else:
            return {
                "emotion": emotion,
                "message": "I'm glad you're doing well. I'm here whenever you need to talk 💙",
                "stress_level": "low",
                "burnout_score": burnout_score,
                "suggestion": "Keep taking care of yourself. Small daily habits make a big difference.",
                "actions": [],
                "intent": "normal"
            }

    # ── STEP 2: KEYWORD + WINDOW FALLBACK (SECONDARY) ──
    emotion = _keyword_emotion_detect(msg_lower)
    print(f"KEYWORD FALLBACK EMOTION USED: {emotion}")

    # ── Handle neutral states from window-based detection ──
    if emotion in ("neutral_positive", "neutral_negated"):
        return {
            "emotion": "neutral",
            "message": "I'm really glad to hear that things are feeling a bit lighter for you. That's a positive step forward 💙",
            "stress_level": "low",
            "burnout_score": 25,
            "suggestion": "Take a moment to enjoy this feeling of peace. Keep taking care of yourself!",
            "actions": [],
            "intent": "normal"
        }

    # ── Keyword detection responses ──
    if any(w in msg_lower for w in ["overwhelmed", "can't handle", "panic", "suicide", "hurt"]):
        return {
            "emotion": "stress",
            "message": "I'm so sorry you're feeling this way. Please know that you're not alone, and it's okay to ask for help when things feel like too much.",
            "stress_level": "high",
            "burnout_score": 85,
            "suggestion": "Take a moment to sit down and focus on your breath. If you're feeling unsafe, please reach out to someone you trust immediately.",
            "actions": [{"label": "Emergency Contacts", "type": "task"}],
            "intent": "crisis"
        }

    if emotion == "stress":
        return {
            "emotion": "stress",
            "message": "It sounds like you have a lot on your plate right now. It's completely natural to feel a bit stretched during busy times.",
            "stress_level": "medium",
            "burnout_score": 60,
            "suggestion": "Try breaking your tasks into smaller, manageable steps. Taking a 5-minute walk might also help clear your mind.",
            "actions": [{"label": "Plan my day", "type": "task"}],
            "intent": "normal"
        }

    if emotion == "fatigue":
        return {
            "emotion": "fatigue",
            "message": "I hear you. It sounds like you might be feeling a bit tired today. Sleep is so important for our well-being.",
            "stress_level": "low",
            "burnout_score": 35,
            "suggestion": "Try to take a short rest or drink some water. Even a small 15-minute break can make a big difference.",
            "actions": [],
            "intent": "normal"
        }

    if emotion == "happiness":
        return {
            "emotion": "happiness",
            "message": "I'm so glad to hear that you're having a good day! Positive energy is wonderful.",
            "stress_level": "low",
            "burnout_score": 15,
            "suggestion": "Take a moment to truly savor this feeling. You deserve this happiness!",
            "actions": [],
            "intent": "normal"
        }
    
    if emotion == "sadness":
        return {
            "emotion": "sadness",
            "message": "I'm here for you. It's okay to feel down sometimes, and I'm listening if you want to share more.",
            "stress_level": "low",
            "burnout_score": 40,
            "suggestion": "Be gentle with yourself today. Maybe listen to some comforting music or have a warm drink.",
            "actions": [],
            "intent": "normal"
        }

    if emotion == "anger":
        return {
            "emotion": "anger",
            "message": "It sounds like you're feeling quite frustrated or angry. It's important to acknowledge those feelings.",
            "stress_level": "medium",
            "burnout_score": 50,
            "suggestion": "Try taking a few deep breaths or stepping away from the situation for a moment to cool down.",
            "actions": [],
            "intent": "normal"
        }

    if emotion == "anxiety":
        return {
            "emotion": "anxiety",
            "message": "I can tell you're feeling a bit anxious or worried. Let's take things one step at a time.",
            "stress_level": "medium",
            "burnout_score": 55,
            "suggestion": "Try the 5-4-3-2-1 grounding technique: notice 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you can taste.",
            "actions": [],
            "intent": "normal"
        }

    if emotion == "calmness":
        return {
            "emotion": "calmness",
            "message": "It's wonderful that you're feeling calm and peaceful right now. That's a great state to be in.",
            "stress_level": "low",
            "burnout_score": 10,
            "suggestion": "Enjoy this tranquility. It's a perfect time for some light reading or meditation.",
            "actions": [],
            "intent": "normal"
        }

    # Default fallback
    return {
        "emotion": "neutral",
        "message": "Thank you for sharing that with me. I'm here to listen and support you in any way I can. 💙",
        "stress_level": "low",
        "burnout_score": 20,
        "suggestion": "Maybe take a few deep breaths and tell me more about what's on your mind?",
        "actions": [],
        "intent": "normal"
    }