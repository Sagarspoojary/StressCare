from pydantic import BaseModel, EmailStr
from typing import Optional

class UserModel(BaseModel):
    full_name: str
    email: EmailStr
    password: Optional[str] = None   # Optional for Google users
    auth_provider: str = "local"     # "local" or "google"
    profile_picture: Optional[str] = None