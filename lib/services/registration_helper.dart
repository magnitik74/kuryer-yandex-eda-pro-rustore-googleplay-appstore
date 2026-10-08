import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:country_flags/country_flags.dart';
import '../screens/onboarding/quiz_screen.dart';
import '../screens/onboarding/stat_webview_screen.dart';
import '../theme/app_theme.dart';
import 'local_push_service.dart';
import 'locale_service.dart';
import 'rating_service.dart';

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

  /// Главная точка входа: открывает шторку с выбором страны (прокладочка),
  /// затем запрашивает оценку (1 раз) и открывает анкету нужной страны.
  static Future<void> startRegistration(
    BuildContext context, {
    String? targetCountry,
    bool skipCountrySheet = false,
  }) async {
    if (targetCountry == null && !skipCountrySheet) {
      _showCountrySelectionSheet(context);
      return;
    }

    final country = targetCountry ?? LocaleService().workCountry;
    await _executeRegistration(context, country);
  }

  /// Фирменная шторка с выбором страны (прокладочка с флагами)
  static void _showCountrySelectionSheet(BuildContext context) {
    HapticFeedback.lightImpact();

    final countries = const [
      {'code': 'ru', 'name': 'Россия', 'flag': 'RU', 'domain': 'reg.eda.yandex.ru'},
      {'code': 'kz', 'name': 'Казахстан', 'flag': 'KZ', 'domain': 'reg.eda.yandex.kz'},
      {'code': 'uz', 'name': 'Узбекистан', 'flag': 'UZ', 'domain': 'reg.eda.yandex.uz'},
      {'code': 'kg', 'name': 'Кыргызстан', 'flag': 'KG', 'domain': 'reg.eda.yandex.kg'},
      {'code': 'by', 'name': 'Беларусь', 'flag': 'BY', 'domain': 'reg.eda.yandex.ru'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DFD8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Где планируете доставлять?',
                  style: TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Выберите страну для перехода к официальной анкете',
                  style: TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...countries.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBFBF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBEAE4), width: 1.2),
                    ),
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        Navigator.pop(sheetContext);

                        // 1. Запрос оценки перед переходом (если еще не оценивал)
                        try {
                          await RatingService().showRating(context);
                        } catch (_) {}

                        // 2. Открытие официальной анкеты выбранной страны
                        if (context.mounted) {
                          await _executeRegistration(context, c['code']!);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            ClipOval(
                              child: CountryFlag.fromCountryCode(
                                c['flag']!,
                                height: 32,
                                width: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['name']!,
                                    style: const TextStyle(
                                      fontFamily: 'MontFamily',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    c['domain']!,
                                    style: const TextStyle(
                                      fontFamily: 'MontFamily',
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Непосредственное открытие анкеты выбранной страны с проверкой модерации
  static Future<void> _executeRegistration(BuildContext context, String country) async {
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
      await LocaleService().setWorkCountry(country);

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
