import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // 📤 SEND MESSAGE TO BACKEND
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required bool ghostMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final res = await http.post(
      Uri.parse("$baseUrl/chat/message"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "message": message,
        "ghost_mode": ghostMode,
      }),
    );
    return jsonDecode(res.body);
  }

  // 💾 GET CHAT HISTORY
  static Future<List<dynamic>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final res = await http.get(
      Uri.parse("$baseUrl/chat/history"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    
    final data = jsonDecode(res.body);
    return data["messages"] ?? [];
  }

  // 🗑️ CLEAR CHAT HISTORY
  static Future<Map<String, dynamic>> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final res = await http.delete(
      Uri.parse("$baseUrl/chat/history"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(res.body);
  }

  // 📊 GET STRESS TRENDS
  static Future<List<dynamic>> getStressTrends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final res = await http.get(
      Uri.parse("$baseUrl/chat/stress-trends"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    
    final data = jsonDecode(res.body);
    return data["trends"] ?? [];
  }
}