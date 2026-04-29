import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ✅ USE YOUR SYSTEM IP (VERY IMPORTANT)
  static const String baseUrl = "http://10.237.133.74:8000/auth";

  // ── Sign Up ─────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      print("🔵 SIGNUP REQUEST STARTED");

      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
          "password": password,
        }),
      );

      print("🟢 STATUS: ${response.statusCode}");
      print("🟢 BODY: ${response.body}");

      final data = jsonDecode(response.body);

      // ✅ Handle backend errors
      if (response.statusCode != 200) {
        return {"error": data["detail"] ?? "Signup failed"};
      }

      return data;
    } catch (e) {
      print("🔴 SIGNUP ERROR: $e");
      return {"error": "Connection failed"};
    }
  }

  // ── Sign In ─────────────────────────
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print("🔵 SIGNIN REQUEST STARTED");

      final response = await http.post(
        Uri.parse("$baseUrl/signin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("🟢 STATUS: ${response.statusCode}");
      print("🟢 BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {"error": data["detail"] ?? "Login failed"};
      }

      return data;
    } catch (e) {
      print("🔴 SIGNIN ERROR: $e");
      return {"error": "Connection failed"};
    }
  }

  // ── Google Auth ─────────────────────
  static Future<Map<String, dynamic>> googleAuth(String idToken) async {
    try {
      print("🔵 GOOGLE AUTH REQUEST");

      final response = await http.post(
        Uri.parse("$baseUrl/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token_str": idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return {"error": data["detail"] ?? "Google auth failed"};
      }

      return data;
    } catch (e) {
      print("🔴 GOOGLE ERROR: $e");
      return {"error": "Connection failed"};
    }
  }

  // ── Token Storage ───────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("auth_token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }
}