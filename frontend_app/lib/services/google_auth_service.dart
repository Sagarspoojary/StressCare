import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "658312207862-1atk3gothavrp390c09o3sk96h0q8ott.apps.googleusercontent.com",
    scopes: ['email', 'profile', 'openid'],
  );

  static Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) return "hackathon_testing_token";

      final auth = await user.authentication;

      return auth.idToken ?? auth.accessToken ?? "hackathon_testing_token";
    } catch (e) {
      print("Google Error: $e");
      // Hackathon bypass: if the popup fails due to browser security, allow test login
      return "hackathon_testing_token";
    }
  }
}