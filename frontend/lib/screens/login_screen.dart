import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.accent,
    ));
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final res = await AuthService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Welcome back!", isError: false);
        // TODO: Navigate to Home
      } else {
        _showSnack(res["detail"] ?? "Login failed");
      }
    } catch (_) {
      _showSnack("Connection error. Check your server.");
    }
    setState(() => _loading = false);
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    final idToken = await GoogleAuthService.getIdToken();
    if (idToken == null) { setState(() => _loading = false); return; }
    try {
      final res = await AuthService.googleAuth(idToken);
      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Signed in with Google!", isError: false);
        // TODO: Navigate to Home
      } else {
        _showSnack("Google sign-in failed");
      }
    } catch (_) {
      _showSnack("Connection error.");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── Logo / Brand ──────────────────────────
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.self_improvement, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text("StressCare",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
              ),
              const Center(
                child: Text("Your mental wellness companion",
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
              ),

              const SizedBox(height: 48),

              // ── Form Label ────────────────────────────
              const Text("Sign In", style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text("Welcome back! Please enter your details.",
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),

              const SizedBox(height: 28),

              // ── Email ─────────────────────────────────
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email address",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // ── Forgot Password ───────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot password?",
                    style: TextStyle(color: AppColors.primary)),
                ),
              ),

              const SizedBox(height: 8),

              // ── Login Button ──────────────────────────
              _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Sign In", style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  ),

              const SizedBox(height: 20),

              // ── Divider ───────────────────────────────
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("OR", style: TextStyle(color: AppColors.textGrey,
                    fontSize: 12)),
                ),
                const Expanded(child: Divider()),
              ]),

              const SizedBox(height: 20),

              // ── Google Button ─────────────────────────
              OutlinedButton.icon(
                onPressed: _googleLogin,
                icon: Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                label: const Text("Continue with Google",
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 32),

              // ── Signup Link ───────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ",
                  style: TextStyle(color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text("Sign Up",
                    style: TextStyle(color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}