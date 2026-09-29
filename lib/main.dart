import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/onboarding/permission_screen.dart';
import 'services/locale_service.dart';
import 'services/local_push_service.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Базовая тема Manrope для всего приложения
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      title: 'Fast Courier Job',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: baseTextTheme,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFCE000)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F4F2), // Тёплый серо-белый
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _animController.forward();
    _initApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    await LocalPushService().init();

    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PermissionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Тёплый градиент на Splash (не белый, не холодный)
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFFFFF9E6), // Тёплое жёлтое свечение в центре
              Color(0xFFFFFCF5), // Переход к тёплому белому
              Color(0xFFF5F4F2), // Тёплый серый на краях
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/app_icon.png', width: 140, height: 140),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Работа курьером ЕдаGo",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
