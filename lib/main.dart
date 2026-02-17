import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/posts_screen.dart';

void main() {
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A1A1A);
    const accent = Color(0xFFC5A47E);
    const background = Color(0xFFF8F9FB);

    final textTheme = TextTheme(
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: primary,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.15,
        color: primary,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        height: 1.55,
        color: const Color(0xFF6B7280),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: const Color(0xFF4B5563),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.6,
        color: accent,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: const Color(0xFF9CA3AF),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Journal',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: Colors.white,
        ),
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: primary),
        dividerColor: const Color(0xFFE5E7EB),
      ),
      home: const PostsScreen(),
    );
  }
}
