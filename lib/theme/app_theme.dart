import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for "Курьер PRO Еда"
/// Directly mapped from design_tokens/courier_pro_tokens.json
class AppColors {
  // Brand
  static const Color brandPrimary = Color(0xFFFCE000);
  static const Color brandPrimaryPressed = Color(0xFFE8CC00);
  static const Color brandPrimaryMuted = Color(0xFFFFF9CC);
  static const Color brandPrimarySurface = Color(0xFFFFFBE6);

  // Backgrounds
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF6F5F3);
  static const Color bgTertiary = Color(0xFFEBEBEB);
  static const Color bgMap = Color(0xFFF0EDE8);
  static const Color bgWarm = Color(0xFFF8F6F2);

  // Surface
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceCardWarm = Color(0xFFF4F1EA);
  static const Color surfaceChip = Color(0xFFF6F5F3);
  static const Color surfaceInput = Color(0xFFF6F5F3);

  // Text
  static const Color textPrimary = Color(0xFF21201F);
  static const Color textDarkWarm = Color(0xFF201E1C);
  static const Color textMutedWarm = Color(0xFF78746D);
  static const Color textSecondary = Color(0xFF6D6B69);
  static const Color textTertiary = Color(0xFF9E9B98);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFF21201F);
  static const Color textLink = Color(0xFF007AFF);

  // Borders & Dividers
  static const Color borderDefault = Color(0xFFE8E6E3);
  static const Color borderStrong = Color(0xFFD4D2CF);

  // Chips & Segmented Selectors
  static const Color chipDark = Color(0xFF211F1D);
  static const Color chipLight = Color(0xFFFFFFFF);
  static const Color chipBorder = Color(0xFFE5E2DA);

  // Slider track
  static const Color sliderTrackInactive = Color(0xFFE8E5DD);
  static const Color sliderTrackActive = Color(0xFFFCE000);

  // Feedback
  static const Color feedbackSuccess = Color(0xFF00B341);
  static const Color feedbackSuccessLight = Color(0xFFE6F9ED);
  static const Color feedbackError = Color(0xFFF5222D);
  static const Color feedbackErrorLight = Color(0xFFFFF1F0);
  static const Color feedbackWarning = Color(0xFFFF8800);

  // Toggle Switches (Clean minimal style)
  static const Color toggleTrackOn = Color(0xFFFCE000);
  static const Color toggleTrackOff = Color(0xFFD4D2CF);
  static const Color toggleThumb = Color(0xFFFFFFFF);
}

class AppRadius {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double cardL = 28.0;
  static const double pill = 100.0;
  static const double circle = 9999.0;

  static BorderRadius get r8 => BorderRadius.circular(s);
  static BorderRadius get r12 => BorderRadius.circular(m);
  static BorderRadius get r16 => BorderRadius.circular(l);
  static BorderRadius get r20 => BorderRadius.circular(xl);
  static BorderRadius get r24 => BorderRadius.circular(xxl);
  static BorderRadius get r28 => BorderRadius.circular(cardL);
  static BorderRadius get rPill => BorderRadius.circular(pill);
  static BorderRadius get sheetTop => const BorderRadius.vertical(top: Radius.circular(xxl));
}

class AppShadows {
  // Ultra-subtle elevation (from token spec)
  static final List<BoxShadow> none = [];

  static final List<BoxShadow> xs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 4,
    ),
  ];

  static final List<BoxShadow> s = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static final List<BoxShadow> m = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static final List<BoxShadow> top = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, -2),
      blurRadius: 12,
    ),
  ];
}

class AppTypography {
  static const String fontFamily = 'Golos Text';

  // Card Header (Yandex Go style: bold, tight letter spacing, lowercase)
  static TextStyle get cardHeader => GoogleFonts.golosText(
    fontSize: 22,
    height: 26 / 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textDarkWarm,
  );

  // Card Subtitle (soft muted warm tone)
  static TextStyle get cardSubtitle => GoogleFonts.golosText(
    fontSize: 14,
    height: 19 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textMutedWarm,
  );

  // Massive Income Display Number (108 000 ₽ / 250 000 ₽)
  static TextStyle get incomeDisplay => GoogleFonts.golosText(
    fontSize: 38,
    height: 42 / 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textDarkWarm,
  );

  // Chip Label for selectors (авто, вело, пеший)
  static TextStyle get chipLabel => GoogleFonts.golosText(
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // Display (34 / 40 w700)
  static TextStyle get display => GoogleFonts.golosText(
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  // Heading XL (28 / 34 w700)
  static TextStyle get headingXL => GoogleFonts.golosText(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // Heading L (22 / 28 w700)
  static TextStyle get headingL => GoogleFonts.golosText(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // Heading M (18 / 24 w600)
  static TextStyle get headingM => GoogleFonts.golosText(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Heading S (16 / 22 w600)
  static TextStyle get headingS => GoogleFonts.golosText(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Body L (16 / 22 w400)
  static TextStyle get bodyL => GoogleFonts.golosText(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // Body M (14 / 20 w400)
  static TextStyle get bodyM => GoogleFonts.golosText(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // Body S (13 / 18 w400)
  static TextStyle get bodyS => GoogleFonts.golosText(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // Caption (12 / 16 w400)
  static TextStyle get caption => GoogleFonts.golosText(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.textTertiary,
  );

  // Caption Bold (12 / 16 w600)
  static TextStyle get captionBold => GoogleFonts.golosText(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  // Button (16 / 22 w700)
  static TextStyle get button => GoogleFonts.golosText(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textOnPrimary,
  );
}
