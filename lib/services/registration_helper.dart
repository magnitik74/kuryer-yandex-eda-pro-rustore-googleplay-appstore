import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/onboarding/quiz_screen.dart';
import '../screens/onboarding/stat_webview_screen.dart';
import 'local_push_service.dart';
import 'locale_service.dart';

class RegistrationHelper {
  /// Официальные партнерские реферальные ссылки владельца по странам (запасные)
  static String getDefaultRefUrl(String countryRefCode) {
    switch (countryRefCode) {
      case 'refKZ':
        return 'https://reg.eda.yandex.kz/?advertisement_campaign=forms_for_agents&user_invite_code=0406a57492ba44cbb65241657068b221&utm_content=blank';
      case 'refUZ':
        return 'https://reg.eda.yandex.uz/?advertisement_campaign=forms_for_agents&user_invite_code=0406a57492ba44cbb65241657068b221&utm_content=blank';
      case 'refKG':
        return 'https://reg.eda.yandex.kg/?advertisement_campaign=forms_for_agents&user_invite_code=0406a57492ba44cbb65241657068b221&utm_content=blank';
      case 'refBY':
        return 'https://reg.eda.yandex.ru/?advertisement_campaign=forms_for_agents&user_invite_code=0406a57492ba44cbb65241657068b221&utm_content=blank';
      case 'refRU':
      default:
        return 'https://reg.eda.yandex.ru/?advertisement_campaign=forms_for_agents&user_invite_code=7b1bdeee34104317aaa663af62ff42f5&utm_content=blank&utm_campaign=Eda_anid_samoreg';
    }
  }

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

      int testValue = 0;
      String url = '';

      if (kIsWeb) {
        // В Web-версии запрашиваем актуальные ссылки через REST API Firestore
        try {
          const restUrl = 'https://firestore.googleapis.com/v1/projects/courier-f5652/databases/(default)/documents/testAdmin/showTest?key=AIzaSyDXwODJZEWsUpPnBC4E9x-GpuWadhBTUSg';
          final res = await http.get(Uri.parse(restUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final data = jsonDecode(utf8.decode(res.bodyBytes));
            final fields = data['fields'] as Map<String, dynamic>?;
            if (fields != null) {
              url = fields[countryRefCode]?['stringValue'] ?? fields['refRU']?['stringValue'] ?? '';
            }
          }
        } catch (e) {
          debugPrint('Web Firestore ref fetch error: $e');
        }
      } else {
        // На мобильных устройствах (Android / iOS) читаем нативный Firestore
        final db = FirebaseFirestore.instance;
        DocumentSnapshot<Map<String, dynamic>> doc =
            await db.collection('testAdmin').doc('showTest').get();
        if (!doc.exists) {
          doc = await db.collection('тестАдминистратор теста').doc('показатьТест').get();
        }

        if (doc.exists) {
          final data = doc.data()!;
          const String store = String.fromEnvironment('STORE', defaultValue: 'rustore');
          
          final String testField = (store == 'googleplay') 
              ? 'test_googleplay' 
              : (store == 'appstore') ? 'test_ios' : 'test';
              
          final rawTest = data[testField] ?? data['test'];
          testValue = (rawTest as num?)?.toInt() ?? 0;
          url = (data[countryRefCode] as String?) ?? (data['refRU'] as String?) ?? '';
        }
      }

      // Всегда гарантируем партнерскую реферальную ссылку владельца
      if (url.isEmpty) {
        url = getDefaultRefUrl(countryRefCode);
      }

      debugPrint('RegistrationHelper: opening ref link: $url');

      if (kIsWeb) {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
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
      final fallbackUrl = getDefaultRefUrl(countryRefCode);
      debugPrint('RegistrationHelper: fallback to: $fallbackUrl (error: $e)');
      if (kIsWeb) {
        try {
          await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {}
        return;
      }
      if (!context.mounted) return;
      // При любой ошибке открываем проверенную партнерскую ссылку
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StatWebViewScreen(url: fallbackUrl),
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
