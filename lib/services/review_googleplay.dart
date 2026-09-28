import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Сервис вызова нативного диалога оценки Google Play (In-App Review API).
/// Используется исключительно в сборке для Google Play (STORE=googleplay).
Future<bool> requestGooglePlayReview() async {
  try {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      debugPrint('Google Play In-App Review requested successfully');
      return true;
    } else {
      debugPrint('RatingService (Google Play): In-App Review недоступен на этом устройстве');
    }
  } catch (e) {
    debugPrint('RatingService (Google Play): Ошибка вызова отзыва Google Play: $e');
  }
  return false;
}
