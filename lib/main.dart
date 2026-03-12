import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService().initialize();
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF17161B);
    const accent = Color(0xFFC2A17A);
    const tertiary = Color(0xFF736454);
    const background = Color(0xFFF4F0E8);

    final textTheme = TextTheme(
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 54,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: primary,
        height: 1.0,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 38,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: primary,
        height: 1.0,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.08,
        color: primary,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: const Color(0xFF57555D),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: const Color(0xFF383740),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.9,
        color: accent,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: const Color(0xFF88828F),
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'The Journal',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          tertiary: tertiary,
          surface: Color(0xFFF8F5EE),
          primaryContainer: Color(0xFFE9DACA),
          secondaryContainer: Color(0xFFF1E9DF),
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: primary),
        dividerColor: const Color(0xFFD8CEC2),
      ),
      routerConfig: appRouter,
    );
  }
}
