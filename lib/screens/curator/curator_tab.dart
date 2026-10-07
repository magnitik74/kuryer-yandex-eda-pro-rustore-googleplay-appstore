import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/curator_ai_service.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';
import '../../services/rating_service.dart';
import '../../services/local_push_service.dart';
import '../../theme/app_theme.dart';

class CuratorTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final String? initialCourierFormat;

  const CuratorTab({
    super.key,
    this.onOpenProfile,
    this.initialCourierFormat,
  });

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
    if (widget.initialCourierFormat != null) {
      _initFormatGreeting(widget.initialCourierFormat!);
    } else {
      _messages.add(
        CuratorMessage(
          text: _locale.tr('assistantGreeting'),
          isUser: false,
          isActionCard: true,
          actionType: 'register',
        ),
      );
    }
  }

  void _initFormatGreeting(String format) {
    final userName = _locale.userName.isNotEmpty ? _locale.userName : 'друг';
    String introMessage = '';
    switch (format) {
      case 'auto':
        introMessage = 'Привет, $userName! 👋 Рад помочь с оформлением на авто.\n\nЭто самый доходный вариант доставки. Подскажи, у тебя свой автомобиль или нужна аренда со скидкой партнёра?';
        break;
      case 'moto':
        introMessage = 'Привет, $userName! 👋 Отличный выбор. На мото или мопеде нет пробок, а заказы доставляются быстрее.\n\nЕсть ли у тебя водительские права категории М или А?';
        break;
      case 'bike':
        introMessage = 'Привет, $userName! 👋 Велокурьер — это спорт и быстрый доход в 2 раза выше пешего.\n\nУ тебя свой велосипед или интересует аренда электровелосипеда?';
        break;
      default:
        introMessage = 'Привет, $userName! 👋 Пеший формат — самый простой и быстрый старт без расходов на транспорт.\n\nВ каком районе города тебе удобнее доставлять заказы?';
        break;
    }

    _messages.add(
      CuratorMessage(
        text: introMessage,
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

    await Future.delayed(const Duration(milliseconds: 350));

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    final response = await _ai.ask(
      query,
      history: history,
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

  Future<void> _handleChipSelected(String chipText) async {
    if (chipText == _locale.tr('chipFastReg')) {
      HapticFeedback.mediumImpact();
      RegistrationHelper.startRegistration(context);
      return;
    }

    if (chipText == _locale.tr('chipThanksHelper')) {
      HapticFeedback.lightImpact();
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(
          text: 'Всегда рад помочь! 👍 Если появятся любые вопросы по заказам, слотам или приложению Яндекс Про — пиши сюда в любое время, я на связи 24/7. Удачных смен!',
          isUser: false,
        ));
      });
      _scrollToBottom();
      RatingService().checkAndPromptRating(context, triggerSource: 'curator_thanks');
      return;
    }

    if (chipText == _locale.tr('chipStage1Done')) {
      HapticFeedback.mediumImpact();
      await _locale.setCuratorStage(2);
      await LocalPushService().scheduleStagePushes(2);
      final isCIS = _locale.workCountry != 'ru';
      final stage1Text = isCIS
          ? (_locale.currentLang == 'uz'
              ? 'Ajoyib! 🎉 Hamkorlik anketasi yuborildi. Operator ma’lumotlarni tekshirish uchun tez orada qo‘ng‘iroq qiladi.\n\nKeyingi qadam — qo‘ng‘iroqni kutish va ma’lumotlarni tasdiqlash. «📞 Operator qo‘ng‘irog‘i» tugmasini bosib qo‘llanmani ko‘rishingiz mumkin!'
              : 'Отлично! 🎉 Анкета партнёра отправлена. Оператор контакт-центра позвонит для подтверждения данных.\n\nСледующий шаг — ответить на звонок оператора. После подтверждения вы сможете получить термокороб и форму!')
          : 'Отлично! 🎉 Анкета партнёра отправлена. Оператор перезвонит в течение 15 минут для подтверждения.\n\nСледующий шаг — связка со статусом самозанятого в приложении «Мой налог». Нажми на кнопку «📲 Связка с Мой налог» ниже для быстрой шпаргалки!';
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(
          text: stage1Text,
          isUser: false,
        ));
      });
      _scrollToBottom();
      RatingService().checkAndPromptRating(context, triggerSource: 'curator_stage1');
      return;
    }

    if (chipText == _locale.tr('chipStage2Done') || chipText == _locale.tr('cisChipStage2Done')) {
      HapticFeedback.mediumImpact();
      await _locale.setCuratorStage(3);
      await LocalPushService().scheduleStagePushes(3);
      final isCIS = _locale.workCountry != 'ru';
      final stage2Text = isCIS
          ? (_locale.currentLang == 'uz'
              ? 'Ajoyib! Ma’lumotlar tasdiqlandi ✅\n\nEndi bepul termosumka va formani olish qoldi! Garov puli olinmaydi. Manzillarni «Yo‘lim» bo‘limida ko‘rishingiz mumkin.'
              : 'Супер! Данные успешно подтверждены ✅\n\nТеперь осталось забрать фирменный термокороб и форму. Это бесплатно и без залога! Адрес курьерского центра указан в разделе «Мой путь».')
          : 'Супер! Статус самозанятого подтверждён ✅\n\nТеперь осталось забрать фирменный термокороб и форму. Это бесплатно и без залога! Адреса центров выдачи указаны в разделе «Мой путь», либо нажми кнопку «🎒 Где забрать короб (ЦД)?» ниже.';
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(
          text: stage2Text,
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    if (chipText == _locale.tr('chipOperatorCall')) {
      HapticFeedback.selectionClick();
      final isUz = _locale.currentLang == 'uz';
      final answer = isUz
          ? '📞 Operator qo‘ng‘irog‘i haqida:\n\n1. Aloqa markazi operatori bir necha soat ichida qo‘ng‘iroq qiladi.\n2. Telefoningiz yoqilgan bo‘lishiga ishonch hosil qiling.\n3. Operator ma’lumotlaringizni tekshiradi va termosumka olish uchun kuryerlik markazi manzilini aytadi.\n\nAgar qo‘ng‘iroqqa javob bergan bo‘lsangiz, «Qo‘ng‘iroqqa javob berdim ✅» tugmasini bosing!'
          : '📞 О звонке оператора:\n\n1. Оператор контакт-центра позвонит в течение нескольких часов после отправки анкеты.\n2. Держите телефон под рукой и включённым.\n3. Оператор проверит город, формат доставки и назовёт адрес для получения термокороба без залога.\n\nЕсли вам уже позвонили, нажмите «На звонок ответил ✅»!';
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(text: answer, isUser: false));
      });
      _scrollToBottom();
      return;
    }

    if (chipText == _locale.tr('chipStage3Done')) {
      HapticFeedback.mediumImpact();
      await _locale.setCuratorStage(4);
      await LocalPushService().scheduleStagePushes(4);
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(
          text: 'Поздравляю с получением экипировки! 🎒\n\nТы полностью готов к первому выходу на линию. Обязательно проверь наш чек-лист перед сменой в разделе «Мой путь» и выходи на первый короткий слот возле дома!',
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    if (chipText == _locale.tr('chipStage4Done')) {
      HapticFeedback.mediumImpact();
      await _locale.setCuratorStage(5);
      await LocalPushService().scheduleStagePushes(5);
      setState(() {
        _messages.add(CuratorMessage(text: chipText, isUser: true));
        _messages.add(CuratorMessage(
          text: 'Ура, первый слот успешно завершён! 🔥\n\nВыполни 5 доставок, чтобы закрепить статус партнёра и забрать максимальный приветственный бонус новичка!',
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    _handleUserMessage(chipText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
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
                color: AppColors.brandPrimary.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIcons.chatTeardropDots,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locale.tr('assistant'),
                  style: AppTypography.headingS,
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.feedbackSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'онлайн 24/7',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
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
              icon: const Icon(
                PhosphorIcons.userCircle,
                color: AppColors.textPrimary,
                size: 26,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenProfile!();
              },
            ),
        ],
      ),
      body: Column(
        children: [
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
          _buildQuickChips(),
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brandPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: AppShadows.xs,
        ),
        child: Text(
          text,
          style: AppTypography.bodyL.copyWith(
            color: isUser ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRichActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.r20,
        boxShadow: AppShadows.s,
        border: Border.all(color: AppColors.brandPrimary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadius.r8,
                ),
                child: const Icon(PhosphorIcons.rocketLaunch, size: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _locale.tr('regCardTitle'),
                  style: AppTypography.headingS,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPerkRow(_locale.tr('regCardPerk1')),
          const SizedBox(height: 6),
          _buildPerkRow(_locale.tr('regCardPerk2')),
          const SizedBox(height: 6),
          _buildPerkRow(_locale.tr('regCardPerk3')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                RegistrationHelper.startRegistration(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rPill,
                ),
              ),
              child: Text(
                _locale.tr('regCardBtn'),
                style: AppTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: AppColors.feedbackSuccess),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyS.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChips() {
    final stage = _locale.curatorStage;
    final List<String> chips = [];

    // 1. Стадийный чип самоотчёта (на первом месте)
    if (stage == 1) {
      chips.add(_locale.tr('chipStage1Done'));
    } else if (stage == 2) {
      chips.add(_locale.tr('chipStage2Done'));
    } else if (stage == 3) {
      chips.add(_locale.tr('chipStage3Done'));
    } else if (stage == 4) {
      chips.add(_locale.tr('chipStage4Done'));
    }

    // 2. Чип восторга и оценки (доступен после 2 сообщений или при решении вопроса)
    if (_messages.length >= 2) {
      chips.add(_locale.tr('chipThanksHelper'));
    }

    // 3. Быстрые чипы воронки доведения до ЦД
    if (_locale.workCountry == 'ru') {
      chips.add(_locale.tr('chipMoyNalog'));
    } else {
      chips.add(_locale.tr('chipOperatorCall'));
    }
    chips.add(_locale.tr('chipWhereIsCD'));
    chips.add(_locale.tr('chipFirstOrderGuide'));

    // 4. Регистрация на ранних этапах
    if (stage <= 1) {
      chips.add(_locale.tr('chipFastReg'));
    }

    // 5. Базовые темы
    chips.add(_locale.tr('chipDocs'));
    chips.add(_locale.tr('chipError'));
    chips.add(_locale.tr('chipAge'));
    chips.add(_locale.tr('chipFines'));

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isFastReg = chip == _locale.tr('chipFastReg');
          final isStageDone = chip.contains('✅');
          final isThanks = chip == _locale.tr('chipThanksHelper');

          final Color bgColor = isFastReg || isStageDone
              ? AppColors.brandPrimary
              : isThanks
                  ? const Color(0xFFE8F5E9)
                  : Colors.white;

          final Color borderColor = isFastReg || isStageDone
              ? AppColors.brandPrimary
              : isThanks
                  ? const Color(0xFF81C784)
                  : AppColors.borderDefault;

          final FontWeight weight = isFastReg || isStageDone || isThanks
              ? FontWeight.w700
              : FontWeight.w500;

          return GestureDetector(
            onTap: () => _handleChipSelected(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.rPill,
                boxShadow: AppShadows.xs,
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: Text(
                chip,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: weight,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.top,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: AppRadius.rPill,
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleUserMessage,
                style: AppTypography.bodyL,
                decoration: InputDecoration(
                  hintText: _locale.tr('inputHint'),
                  hintStyle: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.brandPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                PhosphorIcons.paperPlaneTilt,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => _handleUserMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.brandPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
