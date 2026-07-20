import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: Color(0xFFF57F17)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Добро пожаловать\nв Чат курьеров!",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: Color(0xFF211B15),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Представьтесь, чтобы общаться\nс другими курьерами",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF8A8A8E),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "Ваше имя или никнейм",
              labelStyle: const TextStyle(color: Color(0xFF8A8A8E), fontWeight: FontWeight.w500),
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFCE000), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF211B15),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "ВОЙТИ В ЧАТ",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    )));
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, size: 20, color: Color(0xFF211B15)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Чат курьеров",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF211B15)),
                  ),
                  Text(
                    "общение и вопросы",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF8A8A8E)),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFFFFF3E0),
            alignment: Alignment.center,
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFF57F17), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

        // Messages List
        Expanded(
          child: Container(
            color: const Color(0xFFEFEBE4),
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chat')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Чат временно недоступен",
                      style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      padding: const EdgeInsets.only(bottom: 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: "Сообщение...",
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, fontWeight: FontWeight.w500),
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Color(0xFF211B15), size: 20),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFBDBDBD),
            child: Text(
              senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      senderName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1976D2)),
                    ),
                  ),
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF211B15), height: 1.35, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      timeString,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8E), fontWeight: FontWeight.w500),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF4FC3F7)),
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
