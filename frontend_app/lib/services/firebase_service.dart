import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCsPlaPISsVVVGffA0Pzc5Ks7DACuOru50",
            authDomain: "stresscare-c1cfb.firebaseapp.com",
            projectId: "stresscare-c1cfb",
            storageBucket: "stresscare-c1cfb.firebasestorage.app",
            messagingSenderId: "279179097492",
            appId: "ADD_YOUR_WEB_APP_ID_HERE", // 👈 Get this from Firebase Console
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      print("Firebase initialized successfully");
    } catch (e) {
      print("Firebase initialization warning: $e");
      print("Please ensure you have added google-services.json / GoogleService-Info.plist or configured Firebase Options.");
    }
  }
}
