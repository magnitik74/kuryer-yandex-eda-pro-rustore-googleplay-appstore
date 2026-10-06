import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/services.dart';

class ChatTabContent extends StatefulWidget {
  const ChatTabContent({super.key});

  @override
  State<ChatTabContent> createState() => _ChatTabContentState();
}

class _ChatTabContentState extends State<ChatTabContent> {
  String _nickname = "";
  bool _isRegistered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNickname();
  }

  Future<void> _checkNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('nickname') ?? "";
    if (mounted) {
      setState(() {
        _nickname = name;
        _isRegistered = name.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  void _saveNickname(String name) async {
    if (name.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', name.trim());
      setState(() {
        _nickname = name.trim();
        _isRegistered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFCE000)));
    }
    if (!_isRegistered) {
      return _NicknameScreen(onSave: _saveNickname);
    } else {
      return _ChatContent(nickname: _nickname);
    }
  }
}

class _NicknameScreen extends StatefulWidget {
  final ValueChanged<String> onSave;

  const _NicknameScreen({required this.onSave});

  @override
  State<_NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<_NicknameScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F4F2),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(PhosphorIconsLight.chatCircle, size: 40, color: const Color(0xFF211B15)),
              ),
              const SizedBox(height: 24),
              Text(
                "Добро пожаловать\nв Чат курьеров!",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: const Color(0xFF1A1A1A),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Представьтесь, чтобы общаться\nс другими курьерами",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: const Color(0xFF6B6560),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: const Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    labelText: "Ваше имя или никнейм",
                    labelStyle: GoogleFonts.manrope(
                      color: const Color(0xFF6B6560), 
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFFCE000), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF211B15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "ВОЙТИ В ЧАТ",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatContent extends StatefulWidget {
  final String nickname;

  const _ChatContent({required this.nickname});

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _errorMessage;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    final docRef = _db.collection('chat').doc();
    docRef.set({
      'id': docRef.id,
      'text': text,
      'senderName': widget.nickname,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Чат временно недоступен";
        });
      }
    });

    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIconsLight.users, size: 24, color: const Color(0xFF211B15)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Чат курьеров",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600, 
                      fontSize: 18, 
                      letterSpacing: -0.5,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    "общение и вопросы",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w500, 
                      fontSize: 14, 
                      color: const Color(0xFF6B6560),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFF3E0),
            alignment: Alignment.center,
            child: Text(
              _errorMessage!,
              style: GoogleFonts.manrope(
                color: const Color(0xFF211B15), 
                fontSize: 13, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Messages List
        Expanded(
          child: Container(
            color: const Color(0xFFF5F4F2),
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chat')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Чат временно недоступен",
                      style: GoogleFonts.manrope(color: const Color(0xFF6B6560), fontSize: 14),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFCE000)));
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final text = data['text'] as String? ?? "";
                    final senderName = data['senderName'] as String? ?? "";
                    final ts = data['timestamp'];
                    
                    final isMe = senderName == widget.nickname;

                    String timeString = "";
                    if (ts != null && ts is int) {
                      timeString = DateFormat('dd.MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ts));
                    } else if (ts != null && ts is Timestamp) {
                      timeString = DateFormat('dd.MM HH:mm').format(ts.toDate());
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MessageBubble(
                        text: text,
                        senderName: senderName,
                        timeString: timeString,
                        isMe: isMe,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Input Area
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F4F2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 1,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF1A1A1A), 
                        fontSize: 14, 
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: "Сообщение...",
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFF6B6560), 
                          fontSize: 14, 
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE000),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorIconsLight.paperPlaneTilt, color: const Color(0xFF211B15), size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String timeString;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.timeString,
    required this.isMe,
  });

  Color _getAvatarColor(String name) {
    final List<Color> pastelColors = [
      const Color(0xFFE8F5E9), // Green
      const Color(0xFFF3E5F5), // Purple
      const Color(0xFFE3F2FD), // Blue
      const Color(0xFFFFF3E0), // Orange
    ];
    int hash = name.hashCode;
    return pastelColors[hash.abs() % pastelColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: _getAvatarColor(senderName),
            child: Text(
              senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
              style: GoogleFonts.manrope(
                color: const Color(0xFF1A1A1A), 
                fontSize: 14, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFCE000) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w500, 
                        fontSize: 13, 
                        color: const Color(0xFF6B6560),
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: GoogleFonts.manrope(
                    fontSize: 14, 
                    color: const Color(0xFF1A1A1A), 
                    height: 1.5, 
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.manrope(
                        fontSize: 11, 
                        color: const Color(0xFF6B6560), 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(PhosphorIconsLight.checks, size: 14, color: const Color(0xFF211B15)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


