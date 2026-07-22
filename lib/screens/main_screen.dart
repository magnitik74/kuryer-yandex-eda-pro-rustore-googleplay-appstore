import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: const Color(0xFFF5F5F7), // Premium iOS grey
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, "Главная", Icons.home_outlined, Icons.home),
            _buildNavItem(1, "FAQ", Icons.help_outline, Icons.help),
            _buildNavItem(2, "Доход", Icons.monetization_on_outlined, Icons.monetization_on),
            _buildNavItem(3, "Чат", Icons.chat_bubble_outline, Icons.chat_bubble),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData iconOutline, IconData iconFilled) {
    final isActive = _selectedTab == index;
    final color = isActive ? const Color(0xFF211B15) : const Color(0xFFAAAAAA);

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
              transform: Matrix4.identity()..scale(isActive ? 1.15 : 1.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle active indicator bubble
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isActive ? 1.0 : 0.0,
                    child: Container(
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE000).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Icon(
                    isActive ? iconFilled : iconOutline,
                    color: color,
                    size: 26,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isActive ? 18 : 0,
              curve: Curves.easeOut,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
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
          // Compact Banner
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.asset(
              'assets/main_banner.png',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Станьте курьером-партнёром",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF211B15),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Доставляйте заказы и получайте стабильный доход. Выбирайте свой транспорт и график.",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF8A8A8E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFCE000),
                      foregroundColor: const Color(0xFF211B15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "ПОДКЛЮЧИТЬСЯ",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _TransportCard(title: "Пеший курьер", icon: Icons.directions_walk, onClick: onAction),
                const SizedBox(height: 12),
                _TransportCard(title: "Велокурьер", icon: Icons.directions_bike, onClick: onAction),
                const SizedBox(height: 12),
                _TransportCard(title: "Автокурьер", icon: Icons.directions_car, onClick: onAction),
                const SizedBox(height: 12),
                _TransportCard(title: "На самокате", icon: Icons.electric_scooter, onClick: onAction),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: const Color(0xFF211B15)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF211B15),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
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
      ("Можно ли стать курьером-партнёром, если мне ещё нет 18 лет?", "Да, в некоторых городах можно выполнять заказы с 16 лет. Точную информацию вы узнаете при регистрации."),
      ("Можно доставлять заказы на велосипеде, самокате или только пешком?", "Вы можете доставлять заказы любым удобным способом: пешком, на велосипеде, самокате или на личном автомобиле. Чем быстрее транспорт — тем больше доход."),
      ("Какие документы нужны для оформления?", "Потребуется только паспорт. Для автокурьеров также нужны права и СТС."),
      ("Можно ли выполнять заказы по выходным?", "Да, график полностью свободный. Вы сами решаете, в какие дни и часы выходить на доставки."),
      ("Из каких ресторанов будет доставка?", "Доставка осуществляется из популярных ресторанов, кафе и магазинов в вашем городе, сотрудничающих с сервисом."),
      ("Сколько заказов выполняет курьер за час?", "В среднем от 1 до 3 заказов в час, в зависимости от загруженности и вашего способа передвижения."),
      ("Выдают ли одежду с логотипом?", "Да, партнёры предоставляют термокороб и фирменную одежду бесплатно (может зависеть от курьерской службы)."),
      ("Оплачивается ли курьерам проезд на общественном транспорте?", "Проезд не оплачивается, поэтому рекомендуется выбирать удобные локации или использовать велосипед/самокат."),
      ("У меня есть основная работа, могу ли я выполнять заказы в свободное время?", "Конечно! Вы можете совмещать доставки с основной работой или учёбой, выходя на линию всего на несколько часов."),
      ("Можно ли получать оплату ежедневно?", "Да, при оформлении статуса самозанятого выплаты могут поступать ежедневно на вашу банковскую карту."),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF5F5F7),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: const Text(
            "Частые вопросы",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF211B15)),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _FaqItem(
                question: questions[index].$1,
                answer: questions[index].$2,
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

  const _FaqItem({required this.question, required this.answer});

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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF211B15),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF8A8A8E),
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
