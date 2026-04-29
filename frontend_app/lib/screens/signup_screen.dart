import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../widgets/auth_layout.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  // Healthcare Theme Colors
  final Color _primaryColor = const Color(0xFF00796B); // Teal 700
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF5F7FA); // Soft cool grey
  final Color _textColor = const Color(0xFF263238); // BlueGrey 900

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ✅ SIGNUP
  Future<void> _signup() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await AuthService.signUp(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      setState(() => _loading = false);

      if (res["error"] != null) {
        _showSnack(res["error"]);
      } else {
        _showSnack("Account created! Please sign in.", isError: false);
        if (mounted) Navigator.pushReplacementNamed(context, "/signin");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Connection error");
    }
  }

  // ✅ GOOGLE SIGNUP
  Future<void> _googleSignup() async {
    setState(() => _loading = true);

    try {
      final idToken = await GoogleAuthService.getIdToken();

      if (idToken == null) {
        setState(() => _loading = false);
        _showSnack("Google cancelled");
        return;
      }

      final res = await AuthService.googleAuth(idToken);
      setState(() => _loading = false);

      if (res["error"] != null) {
        _showSnack(res["error"]);
      } else {
        if (res["token"] != null) {
          await AuthService.saveToken(res["token"]);
        }
        _showSnack("Google login success", isError: false);
        if (mounted) Navigator.pushReplacementNamed(context, "/chat");
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Google failed");
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
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: _primaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: _surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: "Create Account",
      formContent: Container(
        width: 400,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌟 Header
              Icon(Icons.health_and_safety_rounded, size: 56, color: _primaryColor),
              const SizedBox(height: 24),
              Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join our healthcare platform",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // 📧 Inputs
              _buildTextField(
                controller: _nameCtrl,
                hint: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailCtrl,
                hint: "Email Address",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordCtrl,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmCtrl,
                hint: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 32),

              // 🔘 Signup Button
              _loading
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
              const SizedBox(height: 24),

              // 〰️ Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 24),

              // 🔵 Google Button
              OutlinedButton.icon(
                onPressed: _loading ? null : _googleSignup,
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.blue, size: 32),
                ),
                label: const Text(
                  "Sign up with Google",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 🔁 Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () {
                      if (mounted) Navigator.pushReplacementNamed(context, "/signin");
                    },
                    child: Text(
                      "Sign In",
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