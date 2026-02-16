import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/posts_screen.dart';

void main() {
  runApp(const PostStreamApp());
}

class PostStreamApp extends StatelessWidget {
  const PostStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B3C49);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: const Color(0xFF0B3C49),
      secondary: const Color(0xFFF39C6B),
      tertiary: const Color(0xFF2B7A78),
      surface: const Color(0xFFFDF9F3),
      primaryContainer: const Color(0xFFE0F4F4),
      secondaryContainer: const Color(0xFFFFE8D6),
      shadow: const Color(0xFF1E2328),
    );

    final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Post Stream',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F2EC),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          iconTheme: IconThemeData(color: colorScheme.onSurface),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ),
      home: const PostsScreen(),
    );
  }
}
