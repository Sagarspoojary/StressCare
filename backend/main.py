from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes.auth_routes import router as auth_router
from routes.chat_routes import router as chat_router
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

@app.get("/")
def root():
    return {"message": "StressCare API is running ✅"}

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