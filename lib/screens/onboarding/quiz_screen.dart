import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentStep = 0;
  bool _finished = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Укажите ваш возраст',
      'options': [
        {'text': '16-17 лет', 'icon': Icons.child_care},
        {'text': '18-21 год', 'icon': Icons.school},
        {'text': '22-35 лет', 'icon': Icons.work},
        {'text': 'Старше 35 лет', 'icon': Icons.person},
      ],
    },
    {
      'title': 'На чем планируете доставлять?',
      'options': [
        {'text': 'Пешком', 'icon': Icons.directions_walk},
        {'text': 'Велосипед / Самокат', 'icon': Icons.directions_bike},
        {'text': 'Личный автомобиль', 'icon': Icons.directions_car},
      ],
    },
    {
      'title': 'Был ли у вас опыт работы курьером?',
      'options': [
        {'text': 'Да, работал ранее', 'icon': Icons.check_circle_outline},
        {'text': 'Нет, это мой первый опыт', 'icon': Icons.cancel_outlined},
      ],
    },
    {
      'title': 'Какой график вам больше подходит?',
      'options': [
        {'text': 'Полный день (5/2, 2/2)', 'icon': Icons.calendar_today},
        {'text': 'Подработка (по вечерам)', 'icon': Icons.nightlight_round},
        {'text': 'Свободный график', 'icon': Icons.access_time},
      ],
    },
  ];

  void _answerQuestion(int selectedIndex) {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      setState(() {
        _finished = true;
      });
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '88005553535',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Анкета кандидата", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: _finished ? _buildFinishedScreen() : _buildQuizScreen(),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final step = _steps[_currentStep];
    final options = step['options'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey[300],
            color: const Color(0xFFFCE000),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Text(
            step['title'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF211B15)),
          ),
          const SizedBox(height: 32),
          ...List.generate(
            options.length,
            (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _answerQuestion(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(options[index]['icon'], color: const Color(0xFF211B15), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[index]['text'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF211B15)),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 80),
          const SizedBox(height: 16),
          const Text(
            "Поздравляем!\nВы нам подходите! 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF211B15), height: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            "Остался всего один шаг до первых заказов.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildInstructionCard(
            "1. Позвоните нам",
            "Позвоните по номеру 8 (800) 555-35-35 для подтверждения заявки.",
            Icons.phone_in_talk,
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            "2. Получите экипировку",
            "Запишитесь на выдачу термосумки и формы у оператора.",
            Icons.backpack,
          ),
          const SizedBox(height: 16),
          _buildInstructionCard(
            "3. Приезжайте в офис",
            "Наш центр оформления: Садовническая ул., 82, стр. 2, Москва",
            Icons.location_on,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _makePhoneCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCE000),
              foregroundColor: const Color(0xFF211B15),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.phone, size: 24),
            label: const Text(
              "ПОЗВОНИТЬ СЕЙЧАС",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Вернуться на главную", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildInstructionCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF57F17), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF211B15)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
