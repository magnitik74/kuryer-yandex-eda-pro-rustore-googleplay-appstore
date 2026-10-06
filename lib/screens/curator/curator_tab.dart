import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/curator_ai_service.dart';
import '../../services/curator_dialogue_engine.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';
import '../../theme/app_theme.dart';

class CuratorTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final String? initialCourierFormat;
  final bool isFreshLead;

  const CuratorTab({
    super.key,
    this.onOpenProfile,
    this.initialCourierFormat,
    this.isFreshLead = false,
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
      final locale = _locale;
      final ctx = CuratorContext.fromLocale(locale, isFreshLead: widget.isFreshLead);

      if (widget.isFreshLead) {
        // Fresh lead from onboarding - welcome with context + ActionCard immediately
        final userName = _locale.userName.isNotEmpty ? _locale.userName : 'друг';
        final format = widget.initialCourierFormat ?? _locale.courierType;
        final formatLabel = _getFormatLabel(format);

        _messages.add(CuratorMessage(
          text: 'Привет, $userName! 👋 Я твой личный куратор. Ты выбрал **$formatLabel** — отличный старт.\n\nДавай оформим тебя официально за 3 минуты. Нажми кнопку **«Регистрация»** прямо здесь 👇 — откроется анкета партнёра. Я буду на связи, если что-то непонятно.',
          isUser: false,
          isActionCard: true,
          actionType: 'register',
        ));

        // Track chat opened for fresh lead
        _locale.trackEvent('chat_opened', params: {
          'stage': ctx.stage.name,
          'format': format,
          'country': _locale.workCountry,
        });
      } else if (widget.initialCourierFormat != null) {
        _initFormatGreeting(widget.initialCourierFormat!);
      } else {
        // Returning user - use context-aware greeting
        final greetingText = _getContextualGreeting(ctx);
        _messages.add(CuratorMessage(
          text: greetingText,
          isUser: false,
          isActionCard: ctx.stage == CuratorStage.preRegistration,
          actionType: ctx.stage == CuratorStage.preRegistration ? 'register' : null,
        ));

        _locale.trackEvent('chat_opened', params: {
          'stage': ctx.stage.name,
          'format': _locale.courierType,
          'country': _locale.workCountry,
        });
      }
    }

    String _getContextualGreeting(CuratorContext ctx) {
      final userName = ctx.userName;
      final formatLabel = _getFormatLabel(ctx.format);
    
      switch (ctx.stage) {
        case CuratorStage.greeting:
          return 'Привет, $userName! 👋 Я твой личный куратор. Ты выбрал **$formatLabel** — отличный старт.\n\nДавай оформим тебя официально за 3 минуты. Нажми кнопку **«Регистрация»** прямо здесь 👇 — откроется анкета партнёра. Я буду на связи, если что-то непонятно.';
      
        case CuratorStage.preRegistration:
          return _locale.tr('assistantGreeting');
      
        case CuratorStage.registrationSent:
          return 'С возвращением, $userName! 👋 Твоя анкета отправлена, оператор перезвонит в течение 15 минут.\n\nПока ждёшь — могу ответить на любые вопросы: про VPN, «Мой налог», документы, сумку. Что интересует?';
      
        case CuratorStage.postRegistration:
          if (!ctx.bagReceived) {
            return 'Привет, $userName! 👋 Ты в системе! Осталось получить термосумку в Курьерском центре и выйти на первый слот.\n\nНужна помощь с адресом ЦО или инструкцией по «Мой налог»?';
          }
          return 'Привет, $userName! 👋 Сумка получена — можно выходить на заказы. Совет: начни с 2-3 часов вечером, заказов больше.\n\nКак заказы вчера? Есть вопросы по тарифам?';
      
        case CuratorStage.activeCourier:
          return 'Привет, $userName! 👋 На связи. Как заказы вчера? Есть вопросы по тарифам или зонам?';
      
        case CuratorStage.churnedRisk:
          return 'Давно не виделись, $userName. Всё ок?\n\nЧто мешает выйти на линию? Могу помочь с документами, зоной или ответом на вопросы.';
      }
    }

  String _getFormatLabel(String format) {
    switch (format) {
      case 'auto': return 'Авто 🚗';
      case 'moto': return 'Мото 🛵';
      case 'bike': return 'Вело 🚲';
      default: return 'Пеший 🚶';
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

    _messages.add(CuratorMessage(text: introMessage, isUser: false));
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

    /// Self-report handlers
    Future<void> _handleBagReceived() async {
      HapticFeedback.mediumImpact();
      await _locale.setBagReceived(true);
      // Sync stage with CuratorDialogueEngine
      await _locale.syncCuratorStage(CuratorStage.postRegistration);
      // Add confirmation message to chat
      if (!mounted) return;
      setState(() {
        _messages.add(CuratorMessage(
          text: _locale.tr('selfReportBagReceived'),
          isUser: false,
        ));
      });
      _scrollToBottom();
    }

    Future<void> _handleFirstOrderDone() async {
      HapticFeedback.mediumImpact();
      await _locale.setActiveCourier(true);
      // Sync stage with CuratorDialogueEngine
      await _locale.syncCuratorStage(CuratorStage.activeCourier);
      if (!mounted) return;
      setState(() {
        _messages.add(CuratorMessage(
          text: _locale.tr('selfReportFirstOrderDone'),
          isUser: false,
        ));
      });
      _scrollToBottom();
    }

    Future<void> _handleMoyNalogLinked() async {
      HapticFeedback.mediumImpact();
      await _locale.setMoyNalogLinked(true);
      if (!mounted) return;
      setState(() {
        _messages.add(CuratorMessage(
          text: _locale.tr('selfReportMoyNalogLinked'),
          isUser: false,
        ));
      });
      _scrollToBottom();
    }

    /// Build self-report inline buttons based on current stage
    Widget? _buildSelfReportButtons(CuratorContext ctx) {
      final List<Widget> buttons = [];
    
      // Show "Bag received" button if registered but not received bag
      if (ctx.hasRegistered && !ctx.bagReceived && ctx.stage != CuratorStage.preRegistration && ctx.stage != CuratorStage.greeting) {
        buttons.add(_SelfReportButton(
          label: _locale.tr('btnBagReceived'),
          icon: PhosphorIconsRegular.package,
          onTap: _handleBagReceived,
        ));
      }
    
      // Show "First order done" button if bag received but not active courier
      if (ctx.bagReceived && !_locale.isActiveCourier && ctx.stage != CuratorStage.greeting) {
        buttons.add(_SelfReportButton(
          label: _locale.tr('btnFirstOrderDone'),
          icon: PhosphorIconsRegular.checkCircle,
          onTap: _handleFirstOrderDone,
        ));
      }
    
      // Show "Moy Nalog linked" button if not linked yet
      if (!_locale.moyNalogLinked && ctx.hasRegistered && ctx.stage != CuratorStage.greeting && ctx.stage != CuratorStage.preRegistration) {
        buttons.add(_SelfReportButton(
          label: _locale.tr('btnMoyNalogLinked'),
          icon: PhosphorIconsRegular.linkSimple,
          onTap: _handleMoyNalogLinked,
        ));
      }
    
      if (buttons.isEmpty) return null;
    
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttons,
        ),
      );
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
          .map((m) => <String, String>{
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      // Build context from current locale state
      final ctx = CuratorContext.fromLocale(_locale);

      final response = await _ai.askWithContext(
        query,
        history: history,
        ctx: ctx,
      );

      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _messages.add(CuratorMessage(
          text: response.text,
          isUser: false,
          isActionCard: response.showActionCard,
          actionType: response.actionType,
        ));
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
      // Build context for self-report buttons
      final ctx = CuratorContext.fromLocale(_locale);
      final selfReportWidget = _buildSelfReportButtons(ctx);
    
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
            if (selfReportWidget != null) selfReportWidget,
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
    List<String> chips;

    if (widget.initialCourierFormat == 'auto') {
      chips = [
        _locale.tr('chipFastReg'),
        'Своё авто 🚗',
        'Нужна аренда 🔑',
        'Сколько платят?',
        _locale.tr('chipDocs'),
        _locale.tr('chipError'),
      ];
    } else if (widget.initialCourierFormat == 'bike') {
      chips = [
        _locale.tr('chipFastReg'),
        'Свой велосипед 🚲',
        'Аренда электровелосипеда ⚡',
        'Сколько платят?',
        _locale.tr('chipDocs'),
      ];
    } else if (widget.initialCourierFormat == 'moto') {
      chips = [
        _locale.tr('chipFastReg'),
        'Права есть (кат. М/А)',
        'Свой мопед 🛵',
        'Сколько платят?',
        _locale.tr('chipDocs'),
      ];
    } else if (widget.initialCourierFormat == 'walk') {
      chips = [
        _locale.tr('chipFastReg'),
        'Доставка возле дома 🚶',
        'Сколько платят?',
        _locale.tr('chipDocs'),
        _locale.tr('chipAge'),
      ];
    } else {
      chips = [
        _locale.tr('chipFastReg'),
        _locale.tr('chipCar'),
        _locale.tr('chipWalk'),
        _locale.tr('chipMoto'),
        _locale.tr('chipBike'),
        _locale.tr('chipError'),
        _locale.tr('chipDocs'),
        _locale.tr('chipAge'),
        _locale.tr('chipFines'),
      ];
    }

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

          return GestureDetector(
            onTap: () => _handleChipSelected(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isFastReg ? AppColors.brandPrimary : Colors.white,
                borderRadius: AppRadius.rPill,
                boxShadow: AppShadows.xs,
                border: Border.all(
                  color: isFastReg ? AppColors.brandPrimary : AppColors.borderDefault,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                chip,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: isFastReg ? FontWeight.w700 : FontWeight.w500,
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

        /// Inline self-report button widget
        class _SelfReportButton extends StatelessWidget {
          final String label;
          final IconData icon;
          final VoidCallback onTap;

          const _SelfReportButton({
            required this.label,
            required this.icon,
            required this.onTap,
          });

          @override
          Widget build(BuildContext context) {
            return GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
