import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/permission_screen.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast Courier Job',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'MontFamily',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFCE000)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF211B15),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'MontFamily',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF211B15),
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

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase init error: $e");
    }

    // Инициализируем локальные пуши и планируем воронку
    await LocalPushService().init();
    // TODO: Проверять статус заказа. Если первый заказ сделан, вызывать cancelAllNotifications().
    // Пока что перепланируем воронку при каждом запуске.
    await LocalPushService().scheduleFunnelNotifications();
    
    // Задержка на 2 секунды как просил пользователь
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PermissionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE000), // Жёлтый фон
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset('assets/app_icon.png', width: 140, height: 140),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Работа курьером ЕдаGo",
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF211B15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
