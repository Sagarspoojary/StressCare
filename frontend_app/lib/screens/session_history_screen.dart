import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatSession {
  final String sessionId;
  final List<Map<String, dynamic>> messages;
  final String firstMessagePreview;
  final DateTime latestTimestamp;
  final String latestEmotion;
  final int latestStressScore;
  final String latestStressLevel;

  ChatSession({
    required this.sessionId,
    required this.messages,
    required this.firstMessagePreview,
    required this.latestTimestamp,
    required this.latestEmotion,
    required this.latestStressScore,
    required this.latestStressLevel,
  });
}

class SessionHistoryScreen extends StatefulWidget {
  final Function(String sessionId, List<Map<String, dynamic>> messages) onSessionSelected;
  final bool isGhostMode;

  const SessionHistoryScreen({
    Key? key,
    required this.onSessionSelected,
    required this.isGhostMode,
  }) : super(key: key);

  @override
  _SessionHistoryScreenState createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  bool _loading = true;
  List<ChatSession> _sessions = [];
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchAndGroupHistory();
  }

  Future<void> _fetchAndGroupHistory() async {
    try {
      final rawMessages = await ChatService.getChatHistory();
      
      // Group by session_id
      Map<String, List<Map<String, dynamic>>> groups = {};
      for (var m in rawMessages) {
        if (m is! Map<String, dynamic>) continue;
        
        final String sessId = m["session_id"]?.toString() ?? "default";
        
        // Extract raw fields
        final String content = (m["user_message"] != null) 
            ? m["user_message"].toString()
            : (m["ai_response"] ?? "").toString();
            
        final String role = (m["user_message"] != null) ? "user" : "assistant";
        
        DateTime parsedTime;
        try {
          parsedTime = DateTime.parse(m["timestamp"] ?? m["created_at"] ?? DateTime.now().toIso8601String());
        } catch (_) {
          parsedTime = DateTime.now();
        }

        final msg = {
          "chat_id": m["chat_id"] ?? "",
          "role": role,
          "content": content,
          "stress_level": m["stress_level"] ?? "low",
          "emotion": m["emotion"] ?? "neutral",
          "stress_score": m["score"] ?? m["stress_score"] ?? 0,
          "timestamp": parsedTime.toIso8601String(),
          "analysis": m["analysis"] ?? "",
          "is_private": m["is_private"] ?? false,
          "emergency": m["emergency"] == true,
        };
        
        groups.putIfAbsent(sessId, () => []).add(msg);
      }

      List<ChatSession> sessionsList = [];
      
      groups.forEach((sessId, msgs) {
        // Sort chronologically ascending
        msgs.sort((a, b) {
          DateTime timeA = DateTime.parse(a["timestamp"]);
          DateTime timeB = DateTime.parse(b["timestamp"]);
          return timeA.compareTo(timeB);
        });

        // First user message for preview
        String preview = "Voice/Emotion Session";
        for (var msg in msgs) {
          if (msg["role"] == "user" && msg["content"].toString().isNotEmpty) {
            preview = msg["content"];
            break;
          }
        }
        
        if (preview.length > 60) {
          preview = "${preview.substring(0, 60)}...";
        }

        DateTime latestTime = DateTime.now();
        String latestEmotion = "neutral";
        int latestScore = 0;
        String latestLevel = "low";
        if (msgs.isNotEmpty) {
          final lastMsg = msgs.last;
          latestTime = DateTime.parse(lastMsg["timestamp"]);
          latestEmotion = lastMsg["emotion"];
          latestScore = lastMsg["stress_score"];
          latestLevel = lastMsg["stress_level"];
        }

        sessionsList.add(ChatSession(
          sessionId: sessId,
          messages: msgs,
          firstMessagePreview: preview,
          latestTimestamp: latestTime,
          latestEmotion: latestEmotion,
          latestStressScore: latestScore,
          latestStressLevel: latestLevel,
        ));
      });

      // Sort sessions: Newest first
      sessionsList.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));

      if (mounted) {
        setState(() {
          _sessions = sessionsList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load history";
          _loading = false;
        });
      }
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isGhostMode;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FC);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1D26);
    final Color subTextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final Color primaryColor = isDark ? Colors.tealAccent.shade400 : const Color(0xFF3F51B5);

    // Grouping
    final List<ChatSession> todaySessions = _sessions.where((s) => _isToday(s.latestTimestamp)).toList();
    final List<ChatSession> yesterdaySessions = _sessions.where((s) => _isYesterday(s.latestTimestamp)).toList();
    final List<ChatSession> olderSessions = _sessions.where((s) => !_isToday(s.latestTimestamp) && !_isYesterday(s.latestTimestamp)).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Session History", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20)
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isGhostMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  "👻 Ghost Mode ON", 
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: textColor)))
              : _sessions.isEmpty
                  ? _buildEmptyState(textColor, subTextColor, primaryColor)
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        if (todaySessions.isNotEmpty) ...[
                          _buildSectionHeader("Today", primaryColor),
                          ...todaySessions.map((s) => _buildSessionCard(s, cardColor, textColor, subTextColor, primaryColor)),
                          const SizedBox(height: 16),
                        ],
                        if (yesterdaySessions.isNotEmpty) ...[
                          _buildSectionHeader("Yesterday", primaryColor),
                          ...yesterdaySessions.map((s) => _buildSessionCard(s, cardColor, textColor, subTextColor, primaryColor)),
                          const SizedBox(height: 16),
                        ],
                        if (olderSessions.isNotEmpty) ...[
                          _buildSectionHeader("Older Conversations", primaryColor),
                          ...olderSessions.map((s) => _buildSessionCard(s, cardColor, textColor, subTextColor, primaryColor)),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    ChatSession session,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
  ) {
    final timeStr = DateFormat('jm').format(session.latestTimestamp);
    final dateStr = DateFormat('MMM d').format(session.latestTimestamp);
    final bool hasStress = session.latestStressScore > 0;
    
    Color badgeColor = Colors.grey.shade500;
    if (session.latestStressLevel.toLowerCase() == "high") {
      badgeColor = Colors.red.shade400;
    } else if (session.latestStressLevel.toLowerCase() == "medium") {
      badgeColor = Colors.orange.shade400;
    } else if (session.latestStressLevel.toLowerCase() == "low") {
      badgeColor = Colors.green.shade400;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isGhostMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onSessionSelected(session.sessionId, session.messages);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.firstMessagePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isToday(session.latestTimestamp) ? timeStr : dateStr,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Emotion Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getEmotionEmoji(session.latestEmotion),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                session.latestEmotion.toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasStress)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "STRESS: ${session.latestStressScore}%",
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: subTextColor.withOpacity(0.5),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case "happy":
      case "happiness":
        return "😊";
      case "sad":
      case "sadness":
        return "😢";
      case "angry":
      case "anger":
        return "😠";
      case "anxious":
      case "fear":
        return "😰";
      case "surprise":
      case "excited":
        return "😲";
      case "fatigue":
      case "tired":
        return "😴";
      default:
        return "😐";
    }
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 64,
              color: primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Session History",
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Your completed conversations will appear here. Start a chat to begin!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
