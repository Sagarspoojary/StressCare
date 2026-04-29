import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
static const String baseUrl = "http://127.0.0.1:8000/auth";

  static Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      return {"error": body["detail"] ?? body["error"] ?? "An error occurred"};
    }
    return body;
  }

  // ── Sign Up ────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"full_name": fullName, "email": email, "password": password}),
    );
    return _handleResponse(res);
  }

  // ── Sign In ────────────────────────────────────────────
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/signin"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return _handleResponse(res);
  }

  // ── Google Auth ────────────────────────────────────────
  static Future<Map<String, dynamic>> googleAuth(String idToken) async {
    final res = await http.post(
      Uri.parse("$baseUrl/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_token_str": idToken}),
    );
    return _handleResponse(res);
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