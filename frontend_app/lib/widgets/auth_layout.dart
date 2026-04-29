import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget formContent;
  final String title;

  const AuthLayout({
    super.key,
    required this.formContent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF00796B), // Teal 700
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildCopy(isDesktop: true),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFFF5F7FA), // Light grey
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: formContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF00796B),
                padding: const EdgeInsets.all(32),
                child: _buildCopy(isDesktop: false),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: formContent,
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFF00796B),
                padding: const EdgeInsets.all(32),
                child: _buildFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopy({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 48),
        const SizedBox(height: 24),
        const Text(
          "Healing is a quiet revolution.",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "We believe that healthcare should feel like a deep breath. Our approach combines clinical precision with the warmth of human connection to nurture your mind, body, and spirit.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(height: 48),
          _buildFeature("The Pulse of Care", "We don’t just treat symptoms; we listen to stories. Your journey is unique, and your treatment should be too."),
          const SizedBox(height: 24),
          _buildFeature("A Modern Sanctuary", "Our space is designed for clarity, safety, and recovery. We’ve removed the clinical coldness and replaced it with an environment where you can truly feel at ease."),
          const SizedBox(height: 24),
          _buildFeature("Expertise in Motion", "Leading-edge technology meets intuitive, patient-first practitioners. We stay at the forefront of medicine so you can stay at the center of your life."),
          const SizedBox(height: 48),
          _buildFooter(),
        ]
      ],
    );
  }

  Widget _buildFeature(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        const Text(
          "Your health, held in good hands.",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "Trust is the foundation of every treatment plan. We are dedicated to providing accessible, honest, and compassionate care for every stage of your life.",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),
        _buildBulletPoint("Radical Empathy: We see the person behind the patient."),
        const SizedBox(height: 8),
        _buildBulletPoint("Transparent Paths: No jargon—just clear steps toward wellness."),
        const SizedBox(height: 8),
        _buildBulletPoint("Proactive Defense: Modern diagnostics that stay two steps ahead."),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
