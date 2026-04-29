import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants/app_colors.dart';
import '../services/chat_service.dart';
import 'trends_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _ghostMode = false;
  
  // Voice input
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print("Speech error: $error"),
      onStatus: (status) => print("Speech status: $status"),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.accent,
      ),
    );
  }

  // 📤 SEND MESSAGE
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({"role": "user", "content": text});
      _msgCtrl.clear();
    });

    _scrollToBottom();
    setState(() => _loading = true);

    try {
      final res = await ChatService.sendMessage(
        message: text,
        ghostMode: _ghostMode,
      );

      setState(() => _loading = false);

      if (res["error"] != null) {
        _showSnack(res["error"]);
      } else {
        // Add AI response
        setState(() {
          _messages.add({
            "role": "assistant", 
            "content": res["response"] ?? "I'm here for you 💙",
            "intent": res["intent"],
            "high_stress_alert": res["high_stress_alert"],
          });
        });
        
        if (res["high_stress_alert"] == true) {
          _showTrustedContactDialog();
        }
        
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Connection error");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTrustedContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Checking in 💙"),
        content: const Text("It sounds like you're going through a lot right now. Would you like to reach out to a trusted friend or family member?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No thanks", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack("Redirecting to contacts...", isError: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Yes, please"),
          ),
        ],
      )
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      width: MediaQuery.of(context).size.width * 0.65,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
            onPressed: () => _showSnack("Starting $title action...", isError: false),
          )
        ],
      ),
    );
  }

  // 🎤 VOICE INPUT
  Future<void> _voiceInput() async {
    if (!_speechEnabled) {
      _showSnack("Voice input not available");
      return;
    }
    
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    
    setState(() => _listening = true);
    
    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_US",
      onResult: (result) {
        setState(() {
          _listening = false;
          if (result.recognizedWords.isNotEmpty) {
            _msgCtrl.text = result.recognizedWords;
            _showSnack("Voice captured", isError: false);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: const Text(
          "StressCare 💙",
          style: TextStyle(color: AppColors.textDark),
        ),
        actions: [
          // 📊 Trends Button
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrendsScreen()),
            ),
          ),
          // 🔒 Ghost Mode Toggle
          Row(
            children: [
              const Text("👻", style: TextStyle(fontSize: 16)),
              Switch(
                value: _ghostMode,
                onChanged: (val) => setState(() => _ghostMode = val),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: Column(
        children: [
          // 💬 CHAT MESSAGES
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("💙", style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(
                          "I'm here to listen",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Share what's on your mind",
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isUser = msg["role"] == "user";
                      
                      return Align(
                        alignment: isUser 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isUser 
                                    ? AppColors.primary 
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg["content"],
                                style: TextStyle(
                                  color: isUser ? Colors.white : AppColors.textDark,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!isUser && msg["intent"] == "buy_medicine")
                              _buildActionCard(Icons.medical_services, "Order Medicine", "We can help you find pharmacies nearby."),
                            if (!isUser && msg["intent"] == "set_alarm")
                              _buildActionCard(Icons.alarm, "Set Alarm", "Do you want to set a reminder?"),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // ⏳ LOADING
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          
          // 📝 MESSAGE INPUT
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 🎤 MIC BUTTON
                  IconButton(
                    onPressed: _voiceInput,
                    icon: const Icon(Icons.mic, color: AppColors.primary),
                    tooltip: "Voice input",
                  ),
                  
                  // 📝 TEXT FIELD
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: AppColors.textGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 📤 SEND BUTTON
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}