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
  /// Открывает официальную регистрацию с сохранением рубильников модерации и ГЕО
  static Future<void> startRegistration(BuildContext context, {String? targetCountry}) async {
    final locale = LocaleService();
    final country = targetCountry ?? locale.workCountry;
    final countryRefCode = locale.refCode;
    final defaultUrl = locale.defaultRefUrl;

    // 1. Запускаем умные PUSH-напоминания (event-driven)
    try {
      await LocalPushService().onRegistrationSent();
    } catch (_) {}

    // 2. Сохраняем реф-код и страну
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('countryRef', countryRefCode);
      await prefs.setString('countryId', country);
    } catch (_) {}

    // 3. Получаем ссылку и флаг модерации из Firebase
    int testValue = 0;
    String url = '';

    try {
      if (kIsWeb) {
        // В Web-версии запрашиваем актуальные ссылки через REST API Firestore
        try {
          const restUrl = 'https://firestore.googleapis.com/v1/projects/courier-f5652/databases/(default)/documents/testAdmin/showTest?key=«redacted:AIza…»';
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
    } catch (e) {
      debugPrint('RegistrationHelper: Firestore fetch error: $e');
    }

    // Всегда гарантируем партнерскую реферальную ссылку владельца
    if (url.isEmpty) {
      url = defaultUrl;
    }

    debugPrint('RegistrationHelper: opening ref link: $url');

    // Track registration clicked
    await locale.trackEvent('registration_clicked', params: {
      'country': country,
      'format': locale.courierType,
      'source': 'chat_cta',
    });

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
  }
}
