import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/locale_service.dart';
import 'services/local_push_service.dart';
import 'services/ab_test_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  await LocaleService().init();
  await LocalPushService().init();
  await ABTestService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Работа курьером-курьер PRO Еда',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.golosText().fontFamily,
        textTheme: GoogleFonts.golosTextTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandPrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgWarm,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textDarkWarm,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.golosText(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textDarkWarm,
          ),
        ),
      ),
      builder: (context, child) {
        if (!kIsWeb) return child ?? const SizedBox();
        return WebResponsiveWrapper(child: child ?? const SizedBox());
      },
      home: const SplashScreen(),
    );
  }
}

/// Адаптивная обёртка для Web:
/// - По умолчанию на мобильных и десктопах открывается на полный экран.
/// - На широких мониторах доступна кнопка переключения «Мобильный вид / На весь экран».
class WebResponsiveWrapper extends StatefulWidget {
  final Widget child;
  const WebResponsiveWrapper({super.key, required this.child});

  @override
  State<WebResponsiveWrapper> createState() => _WebResponsiveWrapperState();
}

class _WebResponsiveWrapperState extends State<WebResponsiveWrapper> {
  // На весь экран по умолчанию
  bool _isFullWidth = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 640;

    // Режим на весь экран
    if (!isDesktop || _isFullWidth) {
      return Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (isDesktop)
              Positioned(
                top: 14,
                right: 14,
                child: _buildToggle(
                  icon: Icons.smartphone,
                  label: 'Мобильный вид',
                  onTap: () => setState(() => _isFullWidth = false),
                ),
              ),
          ],
        ),
      );
    }

    // Режим компактного смартфона (по центру экрана)
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              decoration: BoxDecoration(
                color: AppColors.bgWarm,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: _buildToggle(
              icon: Icons.fullscreen,
              label: 'На весь экран',
              onTap: () => setState(() => _isFullWidth = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
