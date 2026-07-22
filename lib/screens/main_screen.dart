import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'onboarding/prelanding_screen.dart';

import 'calculator_tab.dart';
import 'chat/chat_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;

  void _startOnboarding() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PrelandingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F2), // Warm off-white
      bottomNavigationBar: isKeyboardOpen ? null : _buildPremiumBottomBar(),
      body: SafeArea(
        child: Stack(
          children: [
            _buildFadeTab(0, MainTabContent(onAction: _startOnboarding)),
            _buildFadeTab(1, const FaqTabContent()),
            _buildFadeTab(2, const IncomeCalculatorTab()),
            _buildFadeTab(3, const ChatTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBottomBar() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, "Главная", Icons.home_rounded),
            _buildNavItem(1, "FAQ", Icons.help_outline_rounded),
            _buildNavItem(2, "Доход", Icons.calculate_rounded),
            _buildNavItem(3, "Чат", Icons.chat_bubble_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isActive = _selectedTab == index;
    final color = isActive ? const Color(0xFF211B15) : const Color(0xFF6B6560);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isActive) {
          HapticFeedback.lightImpact();
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          setState(() {
            _selectedTab = index;
          });
        }
      },
      child: SizedBox(
        width: 70, // Symmetrical spacing
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Active indicator pill
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.0,
                    child: Container(
                      width: 48,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE000),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFadeTab(int index, Widget child) {
    final isActive = _selectedTab == index;
    return ExcludeFocus(
      excluding: !isActive,
      child: IgnorePointer(
        ignoring: !isActive,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          opacity: isActive ? 1.0 : 0.0,
          child: TickerMode(
            enabled: isActive,
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- TAB 1: Main ---
class MainTabContent extends StatelessWidget {
  final VoidCallback onAction;

  const MainTabContent({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/main_banner.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Text(
                      "Более 50 000 курьеров уже зарабатывают",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Станьте курьером-партнёром",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Доставляйте заказы и получайте стабильный доход. Выбирайте свой транспорт и график.",
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: const Color(0xFF6B6560),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCE000),
                      foregroundColor: const Color(0xFF1A1A1A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "ПОДКЛЮЧИТЬСЯ",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _TransportCard(title: "Пеший курьер", icon: Icons.directions_walk_rounded, onClick: onAction),
                const SizedBox(height: 16),
                _TransportCard(title: "Велокурьер", icon: Icons.directions_bike_rounded, onClick: onAction),
                const SizedBox(height: 16),
                _TransportCard(title: "Автокурьер", icon: Icons.directions_car_rounded, onClick: onAction),
                const SizedBox(height: 16),
                _TransportCard(title: "На самокате", icon: Icons.moped_rounded, onClick: onAction),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClick;

  const _TransportCard({required this.title, required this.icon, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: const Color(0xFF1A1A1A)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 24, color: const Color(0xFF6B6560)),
          ],
        ),
      ),
    );
  }
}

// --- TAB 2: FAQ ---
class FaqTabContent extends StatelessWidget {
  const FaqTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = [
      ("Можно ли стать курьером-партнёром, если мне ещё нет 18 лет?", "Да, в некоторых городах можно выполнять заказы с 16 лет. Точную информацию вы узнаете при регистрации.", Icons.child_care_rounded),
      ("Можно доставлять заказы на велосипеде, самокате или только пешком?", "Вы можете доставлять заказы любым удобным способом: пешком, на велосипеде, самокате или на личном автомобиле. Чем быстрее транспорт — тем больше доход.", Icons.directions_bike_rounded),
      ("Какие документы нужны для оформления?", "Потребуется только паспорт. Для автокурьеров также нужны права и СТС.", Icons.description_rounded),
      ("Можно ли выполнять заказы по выходным?", "Да, график полностью свободный. Вы сами решаете, в какие дни и часы выходить на доставки.", Icons.calendar_month_rounded),
      ("Из каких ресторанов будет доставка?", "Доставка осуществляется из популярных ресторанов, кафе и магазинов в вашем городе, сотрудничающих с сервисом.", Icons.fastfood_rounded),
      ("Сколько заказов выполняет курьер за час?", "В среднем от 1 до 3 заказов в час, в зависимости от загруженности и вашего способа передвижения.", Icons.timer_rounded),
      ("Выдают ли одежду с логотипом?", "Да, партнёры предоставляют термокороб и фирменную одежду бесплатно (может зависеть от курьерской службы).", Icons.checkroom_rounded),
      ("Оплачивается ли курьерам проезд на общественном транспорте?", "Проезд не оплачивается, поэтому рекомендуется выбирать удобные локации или использовать велосипед/самокат.", Icons.directions_bus_rounded),
      ("У меня есть основная работа, могу ли я выполнять заказы в свободное время?", "Конечно! Вы можете совмещать доставки с основной работой или учёбой, выходя на линию всего на несколько часов.", Icons.work_rounded),
      ("Можно ли получать оплату ежедневно?", "Да, при оформлении статуса самозанятого выплаты могут поступать ежедневно на вашу банковскую карту.", Icons.credit_card_rounded),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF5F4F2),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Text(
            "Частые вопросы",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600, 
              fontSize: 24, 
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _FaqItem(
                question: questions[index].$1,
                answer: questions[index].$2,
                icon: questions[index].$3,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final IconData icon;

  const _FaqItem({required this.question, required this.answer, required this.icon});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _expanded = !_expanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE000).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF6B6560), size: 24),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 32),
                  child: Text(
                    widget.answer,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xFF6B6560),
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




