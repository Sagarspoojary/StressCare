import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _email = "";
  String _createdAt = "N/A";
  bool _loading = false;
  
  bool _notifEnabled = true;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _email = user.email ?? "";
        
        // Check if PIN is enabled
        final pin = await _storage.read(key: "app_pin");
        setState(() {
          _pinEnabled = pin != null;
        });
        
        final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _nameCtrl.text = data["full_name"] ?? "";
          _phoneCtrl.text = data["phone_number"] ?? "";
          
          if (data["createdAt"] != null) {
            final ts = data["createdAt"] as Timestamp;
            final date = ts.toDate();
            _createdAt = "${date.day}/${date.month}/${date.year}";
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveUserData() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
          "full_name": _nameCtrl.text.trim(),
          "phone_number": _phoneCtrl.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $launchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4A80F0);
    final bgColor = const Color(0xFFF8FAFF);
    final surfaceColor = Colors.white;
    final textColor = const Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: surfaceColor.withOpacity(0.7),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Your Profile",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Header
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage("https://ui-avatars.com/api/?name=Sagar&background=4A80F0&color=fff&size=256"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading 
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          Text(
                            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : "Sagar",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 40),
                  
                  // Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Sessions", "24", Icons.chat_bubble_outline_rounded, Colors.blue),
                      _buildStatItem("Streak", "5 Days", Icons.local_fire_department_rounded, Colors.orange),
                      _buildStatItem("Mood", "Calm", Icons.sentiment_satisfied_alt_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Menu items
                  _buildMenuItem(Icons.person_outline_rounded, "Account Settings", textColor, onTap: () => _showAccountSettings()),
                  _buildMenuItem(Icons.notifications_none_rounded, "Notifications", textColor, onTap: () => _showNotificationsSettings()),
                  _buildMenuItem(Icons.privacy_tip_outlined, "Privacy & Security", textColor, onTap: () => _showPrivacySettings()),
                  _buildMenuItem(Icons.help_outline_rounded, "Help & Support", textColor, onTap: () => _showHelpSupport()),
                  const SizedBox(height: 20),
                  
                  _buildMenuItem(
                    Icons.logout_rounded, 
                    "Sign Out", 
                    Colors.red.shade400,
                    onTap: () async {
                      await AuthService.signOut();
                      Navigator.pushNamedAndRemoveUntil(context, "/signin", (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
          ],
        ),
      ),
    );
  }

  // 📝 MODAL BOTTOM SHEETS FOR SETTINGS
  
  void _showAccountSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Account Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _email),
              decoration: const InputDecoration(labelText: "Email (Read-Only)", border: OutlineInputBorder()),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Text("Joined Date: $_createdAt", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveUserData();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A80F0), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Enable Notifications"),
                subtitle: const Text("Receive daily stress relief tips"),
                value: _notifEnabled,
                onChanged: (val) {
                  setModalState(() => _notifEnabled = val);
                  setState(() => _notifEnabled = val);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 🔑 PIN SETUP MODAL
  void _showPinSetup(BuildContext ctx, StateSetter setModalState) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isConfirm = false;
    String firstPin = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bCtx) => StatefulBuilder(
        builder: (context, setPinState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(bCtx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isConfirm ? "Confirm PIN" : "Setup PIN", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: isConfirm ? confirmCtrl : pinCtrl,
                decoration: InputDecoration(
                  labelText: isConfirm ? "Confirm 4-digit PIN" : "Enter 4-digit PIN",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final pin = isConfirm ? confirmCtrl.text.trim() : pinCtrl.text.trim();
                    if (pin.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN must be 4 digits")));
                      return;
                    }

                    if (!isConfirm) {
                      setPinState(() {
                        isConfirm = true;
                        firstPin = pin;
                      });
                    } else {
                      if (pin == firstPin) {
                        await _storage.write(key: "app_pin", value: pin);
                        setModalState(() => _pinEnabled = true);
                        setState(() => _pinEnabled = true);
                        Navigator.pop(bCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PIN Lock Enabled!"), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match!")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A80F0), padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(isConfirm ? "Save PIN" : "Continue", style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Privacy & Security", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Biometric Unlock"),
                subtitle: const Text("Use fingerprint or face unlock"),
                value: _biometricEnabled,
                onChanged: (val) async {
                  if (val) {
                    try {
                      final bool authenticated = await _localAuth.authenticate(
                        localizedReason: 'Please authenticate to enable biometric unlock',
                        options: const AuthenticationOptions(biometricOnly: true),
                      );
                      if (authenticated) {
                        setModalState(() => _biometricEnabled = true);
                        setState(() => _biometricEnabled = true);
                      } else {
                        setModalState(() => _biometricEnabled = false);
                        setState(() => _biometricEnabled = false);
                      }
                    } catch (e) {
                      print("Biometric error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Biometrics not supported on this device/browser"), backgroundColor: Colors.orange),
                      );
                      setModalState(() => _biometricEnabled = false);
                      setState(() => _biometricEnabled = false);
                    }
                  } else {
                    setModalState(() => _biometricEnabled = false);
                    setState(() => _biometricEnabled = false);
                  }
                },
              ),
              SwitchListTile(
                title: const Text("PIN Lock"),
                subtitle: const Text("Require a 4-digit PIN to open app"),
                value: _pinEnabled,
                onChanged: (val) async {
                  if (val) {
                    _showPinSetup(ctx, setModalState);
                  } else {
                    await _storage.delete(key: "app_pin");
                    setModalState(() => _pinEnabled = false);
                    setState(() => _pinEnabled = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PIN Lock Disabled"), backgroundColor: Colors.orange),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Help & Support", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("We are here for you 24/7.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF4A80F0)),
              title: const Text("+1 234 567 890"),
              onTap: () => _makePhoneCall("+1234567890"),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF4A80F0)),
              title: const Text("support@stresscare.com"),
              onTap: () => _sendEmail("support@stresscare.com"),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
