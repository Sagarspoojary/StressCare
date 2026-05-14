import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class GoogleAuthService {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "658312207862-83709rj0n66n5b0oaqge32dsppqm929r.apps.googleusercontent.com",
    scopes: ['email', 'profile', 'openid'],
  );

  static Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) return "hackathon_testing_token";

      final auth = await user.authentication;

      // 🔥 Firebase Auth Integration
      try {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        
        // Save user data to Firestore
        if (userCredential.user != null) {
          await FirestoreService.saveUserData(userCredential.user!);
        }
      } catch (e) {
        print("Firebase Auth Error: $e");
        // We catch the error and don't rethrow to ensure the app still runs 
        // without Firebase if it's not yet configured.
      }

      return auth.idToken ?? auth.accessToken ?? "hackathon_testing_token";
    } catch (e) {
      print("Google Error: $e");
      // Hackathon bypass: if the popup fails due to browser security, allow test login
      return "hackathon_testing_token";
    }
  }
}