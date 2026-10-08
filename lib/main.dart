import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/locale_service.dart';
import 'services/local_push_service.dart';
import 'services/fcm_service.dart';
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
  await FcmService().init();
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
                      color: AppColors.bgWarm,
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
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          padding: const EdgeInsets.only(top: 44, bottom: 20),
                          viewPadding: const EdgeInsets.only(top: 44, bottom: 20),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: child ?? const SizedBox(),
                            ),
                            // Simulated Top Status Bar & Dynamic Island
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 44,
                              child: IgnorePointer(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '9:41',
                                        style: TextStyle(
                                          color: Color(0xFF111111),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      Container(
                                        width: 105,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(13),
                                        ),
                                      ),
                                      const Row(
                                        children: [
                                          Icon(Icons.signal_cellular_4_bar, size: 14, color: Color(0xFF111111)),
                                          SizedBox(width: 4),
                                          Icon(Icons.wifi, size: 14, color: Color(0xFF111111)),
                                          SizedBox(width: 4),
                                          Icon(Icons.battery_full_rounded, size: 18, color: Color(0xFF111111)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
