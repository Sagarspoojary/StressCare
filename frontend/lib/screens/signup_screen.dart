import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.accent,
    ));
  }

  Future<void> _signup() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showSnack("Passwords do not match"); return;
    }
    setState(() => _loading = true);
    try {
      final res = await AuthService.signUp(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Account created!", isError: false);
        Navigator.pop(context); // Go back to login
      } else {
        _showSnack(res["detail"] ?? "Signup failed");
      }
    } catch (_) {
      _showSnack("Connection error.");
    }
    setState(() => _loading = false);
  }

  Future<void> _googleSignup() async {
    setState(() => _loading = true);
    final idToken = await GoogleAuthService.getIdToken();
    if (idToken == null) { setState(() => _loading = false); return; }
    try {
      final res = await AuthService.googleAuth(idToken);
      if (res["token"] != null) {
        await AuthService.saveToken(res["token"]);
        _showSnack("Registered with Google!", isError: false);
        Navigator.pop(context);
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        )),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text("Start your wellness journey today.",
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 32),

              // ── Full Name ─────────────────────────────
              TextField(controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────
              TextField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email address",
                  prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────
              TextField(controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ))),
              const SizedBox(height: 16),

              // ── Confirm Password ──────────────────────
              TextField(controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock_outline))),

              const SizedBox(height: 28),

              // ── Signup Button ─────────────────────────
              _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _signup,
                    child: const Text("Create Account", style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
                  ),

              const SizedBox(height: 20),

              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("OR", style: TextStyle(
                    color: AppColors.textGrey, fontSize: 12)),
                ),
                const Expanded(child: Divider()),
              ]),

              const SizedBox(height: 20),

              // ── Google Button ─────────────────────────
              OutlinedButton.icon(
                onPressed: _googleSignup,
                icon: Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                label: const Text("Sign up with Google",
                  style: TextStyle(color: AppColors.textDark,
                    fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),

              const SizedBox(height: 32),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Already have an account? ",
                  style: TextStyle(color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text("Sign In", style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}