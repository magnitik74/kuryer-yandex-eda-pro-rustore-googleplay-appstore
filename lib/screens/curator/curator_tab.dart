import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/curator_ai_service.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';

class CuratorTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  const CuratorTab({super.key, this.onOpenProfile});

  @override
  State<CuratorTab> createState() => _CuratorTabState();
}

class _CuratorTabState extends State<CuratorTab> {
  final LocaleService _locale = LocaleService();
  final CuratorAiService _ai = CuratorAiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<CuratorMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _initChat();
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _initChat() {
    _messages.add(
      CuratorMessage(
        text: _locale.tr('curatorGreeting'),
        isUser: false,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    HapticFeedback.lightImpact();
    _textController.clear();

    setState(() {
      _messages.add(CuratorMessage(text: query, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    // Задержка 400мс для естественного эффекта набора текста
    await Future.delayed(const Duration(milliseconds: 400));

    final response = await _ai.ask(
      query,
      lang: _locale.currentLang,
      country: _locale.workCountry,
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(
        CuratorMessage(
          text: response.text,
          isUser: false,
          isActionCard: response.showActionCard,
          actionType: response.actionType,
        ),
      );
    });

    _scrollToBottom();
  }

  void _handleChipSelected(String chipText) {
    if (chipText == _locale.tr('chipFastReg')) {
      HapticFeedback.mediumImpact();
      RegistrationHelper.startRegistration(context);
      return;
    }
    _handleUserMessage(chipText);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F4F2);
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryYellow.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIcons.robot, color: textDark, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locale.tr('curator'),
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF28C76F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'онлайн 24/7',
                      style: TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 11,
                        color: Color(0xFF6B6560),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.onOpenProfile != null)
            IconButton(
              icon: const Icon(PhosphorIcons.userCircle, color: textDark, size: 26),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenProfile!();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // Быстрые чипсы-кнопки
          _buildQuickChips(),

          // Поле ввода сообщения
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(CuratorMessage msg) {
    if (msg.isActionCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBubble(msg.text, isUser: false),
          const SizedBox(height: 8),
          _buildRichActionCard(),
          const SizedBox(height: 12),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildBubble(msg.text, isUser: msg.isUser),
    );
  }

  Widget _buildBubble(String text, {required bool isUser}) {
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? primaryYellow : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isUser ? 0.02 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'MontFamily',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textDark,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildRichActionCard() {
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryYellow.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🟡', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Яндекс Еда',
                    style: TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Официально',
                  style: TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B873F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCardPerk(PhosphorIcons.creditCard, _locale.tr('regCardPerk1')),
          const SizedBox(height: 6),
          _buildCardPerk(PhosphorIcons.tShirt, _locale.tr('regCardPerk2')),
          const SizedBox(height: 6),
          _buildCardPerk(PhosphorIcons.clock, _locale.tr('regCardPerk3')),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                RegistrationHelper.startRegistration(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _locale.tr('regCardBtn'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPerk(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B6560)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
            ),
            SizedBox(width: 8),
            Text(
              'Печатает ответ...',
              style: TextStyle(
                fontFamily: 'MontFamily',
                fontSize: 12,
                color: Color(0xFF6B6560),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final chips = [
      _locale.tr('chipFastReg'),
      _locale.tr('chipWalk'),
      _locale.tr('chipBike'),
      _locale.tr('chipCar'),
      _locale.tr('chipError'),
      _locale.tr('chipDocs'),
      _locale.tr('chipAge'),
      _locale.tr('chipFines'),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isHighlight = index == 0; // Сразу к регистрации выделена
          return GestureDetector(
            onTap: () => _handleChipSelected(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlight ? const Color(0xFFFCE000) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                chip,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 12,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    const textDark = Color(0xFF1A1A1A);
    const primaryYellow = Color(0xFFFCE000);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4F2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 14,
                  color: textDark,
                ),
                decoration: InputDecoration(
                  hintText: _locale.tr('inputHint'),
                  hintStyle: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 13,
                    color: Color(0xFF9E9B97),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: _handleUserMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleUserMessage(_textController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: primaryYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIcons.paperPlaneRight, color: textDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
