import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/onboarding/quiz_screen.dart';
import '../screens/onboarding/stat_webview_screen.dart';
import 'local_push_service.dart';
import 'locale_service.dart';

class RegistrationHelper {
  /// Открывает официальную регистрацию с сохранением рубильников модерации и ГЕО
  static Future<void> startRegistration(BuildContext context, {String? targetCountry}) async {
    final country = targetCountry ?? LocaleService().workCountry;
    final countryRefCode = _getRefCode(country);

    // 1. Запускаем умные PUSH-напоминания (30 мин, 3ч, 24ч)
    try {
      await LocalPushService().scheduleCuratorFollowUps();
    } catch (_) {}

    // 2. Получаем ссылку и флаг модерации из Firebase
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('countryRef', countryRefCode);
      await prefs.setString('countryId', country);

      final db = FirebaseFirestore.instance;
      DocumentSnapshot<Map<String, dynamic>> doc =
          await db.collection('testAdmin').doc('showTest').get();
      if (!doc.exists) {
        doc = await db.collection('тестАдминистратор теста').doc('показатьТест').get();
      }

      int testValue = 0;
      String url = '';

      if (doc.exists) {
        final data = doc.data()!;
        const String store = String.fromEnvironment('STORE', defaultValue: 'rustore');
        
        // Для Google Play -> test_googleplay, для RuStore -> test, для App Store -> test_ios (или 0)
        final String testField = (store == 'googleplay') 
            ? 'test_googleplay' 
            : (store == 'appstore') ? 'test_ios' : 'test';
            
        final rawTest = data[testField] ?? data['test'];
        testValue = (rawTest as num?)?.toInt() ?? 0;
        url = (data[countryRefCode] as String?) ?? (data['refRU'] as String?) ?? '';
      }

      // Запасная официальная ссылка, если Firebase пуст
      if (url.isEmpty) {
        url = 'https://reg.eda.yandex.ru/?advertisement_campaign=forms';
      }

      if (!context.mounted) return;

      if (testValue == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StatWebViewScreen(url: url)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // При любой ошибке сети открываем безопасный fallback
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const StatWebViewScreen(
            url: 'https://reg.eda.yandex.ru/?advertisement_campaign=forms',
          ),
        ),
      );
    }
  }

  static String _getRefCode(String country) {
    switch (country.toLowerCase()) {
      case 'kz':
        return 'refKZ';
      case 'uz':
        return 'refUZ';
      case 'kg':
        return 'refKG';
      case 'by':
        return 'refBY';
      default:
        return 'refRU';
    }
  }
}
