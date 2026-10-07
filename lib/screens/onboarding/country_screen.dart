import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_flags/country_flags.dart';

import 'quiz_screen.dart';
import 'stat_webview_screen.dart';
import '../../services/rating_service.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  bool _isLoading = false;

  final List<Map<String, dynamic>> _countries = [
    {'id': 'ru', 'name': 'Россия', 'abbr': 'RU', 'refCode': 'refRU'},
    {'id': 'kz', 'name': 'Казахстан', 'abbr': 'KZ', 'refCode': 'refKZ'},
    {'id': 'uz', 'name': 'Узбекистан', 'abbr': 'UZ', 'refCode': 'refUZ'},
    {'id': 'by', 'name': 'Беларусь', 'abbr': 'BY', 'refCode': 'refBY'},
    {'id': 'kg', 'name': 'Кыргызстан', 'abbr': 'KG', 'refCode': 'refKG'},
  ];

  Future<void> _handleCountrySelection(Map<String, dynamic> country) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('countryRef', country['refCode']);
      await prefs.setString('countryId', country['id']);

      final db = FirebaseFirestore.instance;
      // Проверяем как стандартный путь (testAdmin/showTest), так и кириллический (тестАдминистратор теста/показатьТест)
      DocumentSnapshot<Map<String, dynamic>> doc = await db.collection('testAdmin').doc('showTest').get();
      if (!doc.exists) {
        doc = await db.collection('тестАдминистратор теста').doc('показатьТест').get();
      }

      if (!mounted) return;

      int testValue = 0;
      String url = "";
      if (doc.exists) {
        final data = doc.data()!;
        
        // Рубильники модерации для Android:
        // Google Play → test_googleplay, RuStore → test
        const String store = String.fromEnvironment('STORE', defaultValue: 'rustore');
        final String testField = (store == 'googleplay') ? 'test_googleplay' : 'test';
        final rawTest = data[testField] ?? data['test'];
        testValue = (rawTest as num?)?.toInt() ?? 0;
        
        url = (data[country['refCode']] as String?) ?? "";
      }

      if (testValue == 1) {
        // Go to Quiz
        _goToQuiz();
      } else {
        // Показываем оценку через централизованный RatingService
        // (1-3 звезды → Firebase, 4-5 звёзд → нативный стор)
        if (mounted) {
          await RatingService().showRating(context);
        }
        if (url.isNotEmpty) {
          _goToWebView(url);
        } else {
          _goToQuiz();
        }
      }
    } catch (e) {
      if (mounted) {
        _goToQuiz(); // Fallback
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToQuiz() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  void _goToWebView(String url) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => StatWebViewScreen(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Где вы планируете работать?",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: Color(0xFF211B15),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Выберите регион для заработка.",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _countries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _handleCountrySelection(country),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: CountryFlag.fromCountryCode(
                                      country['abbr'],
                                      height: 36,
                                      width: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    country['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF211B15),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Color(0xFFFCE000)),
            ),
        ],
      ),
    );
  }
}
