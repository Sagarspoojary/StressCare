import os
import json
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# Configure Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def get_emotional_response(user_message: str) -> dict:
    """
    Send the user's message to Google Gemini AI and get back 
    a structured JSON containing an emotional response, intent, and stress score.
    """
    if not GEMINI_API_KEY:
        return get_fallback_response(user_message)
    
    try:
        # Use Gemini 2.0 Flash model
        model = genai.GenerativeModel('gemini-2.0-flash')
        
        prompt = f"""You are a compassionate emotional support assistant called StressCare. 
Your role is to listen empathetically, provide gentle responses, and analyze the user's state.

Analyze the following user message: "{user_message}"

You must respond ONLY with a valid JSON object matching the following structure:
{{
  "response": "Your warm, understanding, and non-judgmental response (2-3 sentences max). Never give medical advice.",
  "stress_score": <number between 1 and 10, where 1 is calm and 10 is extremely stressed/panicked>,
  "intent": "<choose one: 'none', 'buy_medicine', 'set_alarm'>",
  "high_stress_alert": <boolean, true if stress_score is 8 or higher, false otherwise>
}}

Ensure the response is empathetic. If someone expresses crisis, the 'response' should gently encourage professional help, and 'high_stress_alert' MUST be true."""

        response = model.generate_content(prompt)
        
        # Clean the response to ensure valid JSON
        text = response.text.strip()
        if text.startswith('```json'):
            text = text[7:]
        if text.endswith('```'):
            text = text[:-3]
        
        return json.loads(text.strip())
        
    except Exception as e:
        print(f"Gemini error: {e}")
        return get_fallback_response(user_message)


def get_fallback_response(user_message: str) -> dict:
    """
    Fallback responses when Gemini is not available or JSON parsing fails.
    """
    message_lower = user_message.lower()
    
    response_text = "I hear you. Thank you for sharing that with me. 💙"
    stress_score = 5
    intent = "none"
    high_stress_alert = False
    
    if any(word in message_lower for word in ['sad', 'depressed', 'down', 'unhappy']):
        response_text = "I'm sorry you're feeling this way. It's okay to feel sad - let's talk about what's making you feel this way. 💙"
        stress_score = 7
    elif any(word in message_lower for word in ['anxious', 'worried', 'nervous', 'panic']):
        response_text = "I can sense your anxiety. Take a deep breath - I'm here with you. What's on your mind?"
        stress_score = 8
        high_stress_alert = True
    elif any(word in message_lower for word in ['angry', 'frustrated', 'mad']):
        response_text = "It's completely okay to feel angry. What happened that's making you feel this way?"
        stress_score = 6
    elif any(word in message_lower for word in ['medicine', 'pills', 'buy']):
        response_text = "I notice you mentioned medicine. Would you like some help finding what you need?"
        intent = "buy_medicine"
    elif any(word in message_lower for word in ['alarm', 'remind', 'wake']):
        response_text = "I hear you want to set an alarm. I can help with that."
        intent = "set_alarm"
        
    return {
        "response": response_text,
        "stress_score": stress_score,
        "intent": intent,
        "high_stress_alert": high_stress_alert
    }