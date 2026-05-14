from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.auth_routes import router as auth_router
from routes.chat_routes import router as chat_router
from routes.audio_routes import router as audio_router
from config.database import db

app = FastAPI(title="StressCare API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(chat_router)
app.include_router(audio_router)

@app.get("/")
def root():
    return {"message": "StressCare API is running ✅"}

import os
import google.generativeai as genai

# ... existing code ...

@app.get("/test-gemini")
def test_gemini():
    print("\n--- GEMINI API TEST ---")
    api_key = os.getenv("GEMINI_API_KEY")
    print(f"API KEY LOADED: {'YES' if api_key else 'NO'}")
    
    if not api_key:
        return {"status": "error", "error": "API Key not found in environment variables"}

    try:
        genai.configure(api_key=api_key)
        
        print("Listing available models...")
        models = genai.list_models()
        model_names = [m.name for m in models]
        print(f"Available models: {model_names[:10]}")
        
        # Try to find a suitable model
        target_model = 'models/gemini-1.5-flash'
        if target_model not in model_names:
             # Fallback to the first available model that supports generateContent
             for m in genai.list_models():
                 if 'generateContent' in m.supported_generation_methods:
                     target_model = m.name
                     break
        
        print(f"Request sent to Gemini ({target_model}): 'Hello, this is a test message'")
        model = genai.GenerativeModel(target_model)
        response = model.generate_content("Hello, this is a test message")
        
        print(f"Raw response from Gemini: {response.text}")
        
        return {
            "status": "success",
            "model_used": target_model,
            "available_models": model_names,
            "message": response.text
        }
    except Exception as e:
        error_msg = str(e)
        print(f"!!! GEMINI TEST ERROR !!!: {error_msg}")
        return {
            "status": "error",
            "error": error_msg
        }

# ✅ TEST DATABASE
@app.get("/test-db")
def test_db():
    try:
        collections = db.list_collection_names()
        return {
            "status": "connected",
            "collections": collections
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }