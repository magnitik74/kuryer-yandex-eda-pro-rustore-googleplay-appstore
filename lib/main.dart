import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/locale_service.dart';
import 'services/local_push_service.dart';
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
        fontFamily: AppTypography.fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brandPrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgSecondary,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      builder: (context, child) {
        if (kIsWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFF18181B), // Dark desk background
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 390,
                    height: 844,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(46),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF27272A),
                        width: 10,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: child ?? const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return child ?? const SizedBox();
      },
      home: const SplashScreen(),
    );
  }
}
