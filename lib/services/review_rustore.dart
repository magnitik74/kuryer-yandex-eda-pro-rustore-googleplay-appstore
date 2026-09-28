import 'package:flutter/foundation.dart';
import 'package:flutter_rustore_review/flutter_rustore_review.dart';

/// Сервис вызова нативного диалога оценки RuStore.
/// Используется исключительно в сборке для RuStore (STORE=rustore).
Future<bool> requestRuStoreReview() async {
  try {
    await RustoreReviewClient.initialize();
    await RustoreReviewClient.request();
    await RustoreReviewClient.review();
    debugPrint('RuStore review dialog shown successfully');
    return true;
  } catch (e) {
    debugPrint('RatingService (RuStore): Ошибка вызова отзыва RuStore: $e');
    return false;
  }
}
