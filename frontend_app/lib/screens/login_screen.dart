import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/auth_layout.dart';
import '../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  // Healthcare Theme Colors (Using AppColors)
  Color get _primaryColor => AppColors.primary;
  Color get _surfaceColor => AppColors.surface;
  Color get _backgroundColor => AppColors.background;
  Color get _textColor => AppColors.textDark;

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.highStress : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 🔐 LOGIN
  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final res = await AuthService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      setState(() => _loading = false);

      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Welcome back!", isError: false);
        if (mounted) Navigator.pushReplacementNamed(context, "/chat");
      } else {
        _showSnack(res["error"] ?? "Login failed");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Connection error");
    }
  }

  // 🔵 GOOGLE LOGIN
  Future<void> _googleLogin() async {
    setState(() => _loading = true);

    try {
      final idToken = await GoogleAuthService.getIdToken();

      if (idToken == null) {
        setState(() => _loading = false);
        _showSnack("Google login cancelled");
        return;
      }

      final res = await AuthService.googleAuth(idToken);
      setState(() => _loading = false);

      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Google login success", isError: false);
        if (mounted) Navigator.pushReplacementNamed(context, "/chat");
      } else {
        _showSnack("Google login failed");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Google error");
    }
  }

  // 🔑 FORGOT PASSWORD
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack("Please enter your email address first");
      return;
    }

    setState(() => _loading = true);
    try {
      // Check if email exists in Firestore first
      final usersRef = FirebaseFirestore.instance.collection("users");
      final snapshot = await usersRef.where("email", isEqualTo: email).limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        setState(() => _loading = false);
        _showSnack("This email is not registered. Please sign up first!");
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() => _loading = false);
      _showSnack("Reset link sent to your email!", isError: false);
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Error: ${e.toString()}");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscure : false,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: _primaryColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textGrey,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: _backgroundColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: "Sign In",
      formContent: Container(
        width: 450,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌟 Header
              const Text(
                "STRESSCARE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue your wellness journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 32),

              // 📧 Inputs
              _buildTextField(
                controller: _emailCtrl,
                hint: "Email Address",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordCtrl,
                hint: "Password",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              
              // 🔑 Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔘 Login Button
              _loading
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "SIGN IN",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
              const SizedBox(height: 32),

              // 〰️ Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 32),

              // 🔵 Google Button
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleLogin,
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 20,
                ),
                label: Text(
                  "Continue with Google",
                  style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.border),
                  backgroundColor: _surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🔁 Signup link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () {
                      if (mounted) Navigator.pushReplacementNamed(context, "/signup");
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}