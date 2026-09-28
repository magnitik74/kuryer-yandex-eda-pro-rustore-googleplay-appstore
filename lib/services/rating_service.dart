import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'review_rustore.dart';
import 'review_googleplay.dart';

/// Централизованный сервис оценки приложения.
///
/// Архитектура:
/// 1. Показываем КАСТОМНЫЙ диалог со звёздами (мы контролируем оценку).
/// 2. Если оценка 1–3 ⭐ → сохраняем фидбэк в Firebase (коллекция `ratings`),
///    показываем "Спасибо!", НЕ отправляем в стор.
/// 3. Если оценка 4–5 ⭐ → открываем НАТИВНОЕ окно стора строго по сборке:
///    - RuStore (STORE=rustore) → RuStore Review SDK
///    - Google Play (STORE=googleplay) → Google Play In-App Review
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  /// Главный метод. Вызывайте его из любого экрана.
  /// Возвращает true, если процесс оценки завершён (любой исход).
  Future<bool> showRating(BuildContext context) async {
    // Проверяем, показывали ли мы уже диалог в этой сессии
    final prefs = await SharedPreferences.getInstance();
    final alreadyRated = prefs.getBool('has_rated') ?? false;
    if (alreadyRated) return true;

    if (!context.mounted) return false;

    // Показываем кастомный диалог со звёздами
    final int? rating = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _RatingDialog(),
    );

    if (rating == null) return false; // Пользователь закрыл диалог

    // Сохраняем флаг, что оценка была поставлена
    await prefs.setBool('has_rated', true);

    if (rating >= 1 && rating <= 3) {
      // ⭐ 1–3: Тихо сохраняем в Firebase, благодарим
      await _saveToFirebase(rating);
      if (context.mounted) {
        _showThankYouSnackbar(context);
      }
    } else if (rating >= 4) {
      // ⭐ 4–5: Открываем нативное окно стора
      await _openNativeStoreReview();
    }

    return true;
  }

  /// Сохраняет низкую оценку в Firebase для внутренней аналитики.
  Future<void> _saveToFirebase(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countryId = prefs.getString('countryId') ?? 'unknown';

      await FirebaseFirestore.instance.collection('ratings').add({
        'rating': rating,
        'platform': 'android',
        'country': countryId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Молча проглатываем ошибку — оценка не критична
      debugPrint('RatingService: Ошибка записи в Firebase: $e');
    }
  }

  /// Открывает нативное окно оценки строго по сборке:
  /// - Google Play (STORE=googleplay) → вызывается ТОЛЬКО Google Play Review API
  /// - RuStore (STORE=rustore) → вызывается ТОЛЬКО RuStore Review SDK
  Future<void> _openNativeStoreReview() async {
    const String store = String.fromEnvironment('STORE', defaultValue: 'rustore');
    if (store == 'googleplay') {
      await requestGooglePlayReview();
    } else {
      await requestRuStoreReview();
    }
  }

  /// Показывает ненавязчивый снэкбар "Спасибо за отзыв!"
  void _showThankYouSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Спасибо за ваш отзыв! Мы обязательно его учтём.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF211B15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// =============================================================================
// Кастомный диалог со звёздами (премиальный iOS-стиль)
// =============================================================================

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE000).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFCE000),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Заголовок
              const Text(
                'Оцените приложение',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF211B15),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ваше мнение помогает нам стать лучше',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // Звёзды
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isSelected = starIndex <= _selectedRating;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedRating = starIndex);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isSelected
                              ? const Color(0xFFFCE000)
                              : Colors.grey.shade300,
                          size: 44,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              // Кнопка "Отправить"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedRating > 0
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(_selectedRating);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCE000),
                    foregroundColor: const Color(0xFF211B15),
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedRating > 0 ? 'Отправить оценку' : 'Выберите оценку',
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Кнопка "Позже"
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text(
                  'Позже',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
