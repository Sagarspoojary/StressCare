import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Sign Up ────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Create user document in Firestore
        await _db.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "full_name": fullName,
          "email": email,
          "photoURL": "",
          "createdAt": FieldValue.serverTimestamp(),
          "is_google_auth": false,
        });

        // Get token for backward compatibility
        final token = await user.getIdToken() ?? "hackathon_token";
        return {"token": token, "user_id": user.uid};
      }
      return {"error": "User creation failed"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ── Sign In ────────────────────────────────────────────
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final token = await user.getIdToken() ?? "hackathon_token";
        return {"token": token, "user_id": user.uid};
      }
      return {"error": "Login failed"};
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ── Google Auth ────────────────────────────────────────
  static Future<Map<String, dynamic>> googleAuth(String idToken) async {
    // For Google Auth, the user is already signed in on the frontend or using fallback.
    // We just return success with the token to proceed to chat.
    return {"token": idToken, "user_id": "test_uid"};
  }

  // ── Sign Out ───────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }

  // ── Save / Get Token ───────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }
}