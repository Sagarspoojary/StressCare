def user_serial(user) -> dict:
    return {
        "id": str(user["_id"]),
        "full_name": user["full_name"],
        "email": user["email"],
        "auth_provider": user.get("auth_provider", "local"),
        "profile_picture": user.get("profile_picture", ""),
    }   