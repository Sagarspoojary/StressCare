import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 👤 Save user data
  static Future<void> saveUserData(User user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("User data saved to Firestore");
    } catch (e) {
      print("Error saving user data to Firestore: $e");
    }
  }

  // 💬 Save chat history
  static Future<void> saveChatHistory(String userId, String message, bool isUser) async {
    try {
      await _db.collection('chat_history').add({
        'userId': userId,
        'message': message,
        'isUser': isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving chat history to Firestore: $e");
    }
  }

  // 📊 Save stress reports
  static Future<void> saveStressReport(String userId, Map<String, dynamic> reportData) async {
    try {
      await _db.collection('stress_reports').add({
        'userId': userId,
        ...reportData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving stress report to Firestore: $e");
    }
  }
}
