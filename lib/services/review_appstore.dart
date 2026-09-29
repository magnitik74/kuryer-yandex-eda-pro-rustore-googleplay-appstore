import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

/// Сервис вызова нативного диалога оценки App Store (StoreKit In-App Review).
/// Используется исключительно в сборке для Apple App Store (STORE=appstore).
Future<bool> requestAppStoreReview() async {
  try {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      debugPrint('App Store In-App Review requested successfully');
      return true;
    } else {
      debugPrint('RatingService (App Store): In-App Review недоступен на этом устройстве');
    }
  } catch (e) {
    debugPrint('RatingService (App Store): Ошибка вызова отзыва App Store: $e');
  }
  return false;
}
