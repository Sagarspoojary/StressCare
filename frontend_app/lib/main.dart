import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/helpline_screen.dart';
import 'screens/usage_patterns_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final user = FirebaseAuth.instance.currentUser;
  final initialRoute = user != null ? '/chat' : '/signup';
  
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,

      routes: {
        '/signup': (context) => const SignupScreen(),
        '/signin': (context) => const LoginScreen(),
        '/chat': (context) => const ChatScreen(),
        '/helpline': (context) => const HelplineScreen(),
        '/usage_patterns': (context) => const UsagePatternsScreen(),
        '/profile': (context) => const ProfileScreen(),



      },
    );
  }
}