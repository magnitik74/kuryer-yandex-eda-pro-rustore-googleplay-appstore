import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/auth/register_cabinet_screen.dart';
import 'screens/onboarding/language_select_screen.dart';
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
    final locale = LocaleService();

    // Instant determination of the starting screen (0ms delay)
    Widget initialScreen;
    if (locale.hasRegisteredCabinet) {
      initialScreen = const MainScreen();
    } else if (locale.hasCompletedOnboarding) {
      initialScreen = const RegisterCabinetScreen();
    } else {
      initialScreen = const LanguageSelectScreen();
    }

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
      home: initialScreen,
    );
  }
}
