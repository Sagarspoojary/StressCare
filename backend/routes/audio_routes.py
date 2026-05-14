from fastapi import APIRouter, UploadFile, File
import shutil
import os
import uuid

from utils.audio_emotion import extract_features, detect_emotion_from_audio

router = APIRouter(tags=["Audio"])

# Create temp directory for audio processing
UPLOAD_DIR = "temp_audio"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/audio/analyze")
async def analyze_audio(file: UploadFile = File(...)):
    """
    Analyzes raw audio waveform for emotional markers.
    NO speech-to-text is performed to ensure privacy and focus on vocal tone.
    """
    file_path = ""
    try:
        # Generate unique filename to avoid collisions
        ext = os.path.splitext(file.filename)[1] or ".wav"
        unique_filename = f"{uuid.uuid4()}{ext}"
        file_path = os.path.join(UPLOAD_DIR, unique_filename)

        # Save uploaded file temporarily
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # 1. Extract Waveform Features
        features = extract_features(file_path)
        
        # 2. Detect Emotion
        result = detect_emotion_from_audio(features)

        # Cleanup
        if os.path.exists(file_path):
            os.remove(file_path)

        return {
            "message": "Audio processed successfully",
            "emotion": result.get("emotion", "neutral"),
            "stress_level": result.get("stress_level", "low"),
            "burnout_score": result.get("burnout_score", 20),
            "emergency": result.get("stress_level") == "high"
        }

    except Exception as e:
        print("AUDIO ROUTE ERROR:", e)
        
        # Cleanup on error
        if file_path and os.path.exists(file_path):
            os.remove(file_path)

        return {
            "message": "Audio processing failed",
            "emotion": "neutral",
            "stress_level": "low",
            "burnout_score": 20,
            "emergency": False
        }
