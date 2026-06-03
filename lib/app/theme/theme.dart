import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTheme {
  // Brand Palette: Nature-inspired HSL equivalent colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep forest green
  static const Color lightGreen = Color(0xFF81C784);   // Fresh leaf green
  static const Color softGreenBg = Color(0xFFE8F5E9);  // Pastel green background
  static const Color darkGreen = Color(0xFF1B5E20);    // Dense foliage green
  
  static const Color primaryAmber = Color(0xFFFFA000);  // Warm sun amber
  static const Color lightAmber = Color(0xFFFFD54F);   // Sunshine yellow
  
  static const Color skyBlue = Color(0xFFE3F2FD);      // Light sky blue
  static const Color creamBg = Color(0xFFFFFDF6);      // Warm cream paper
  
  static const Color woodBrown = Color(0xFF8D6E63);    // Trunk brown
  static const Color darkWood = Color(0xFF4E342E);     // Dark bark
  
  // Custom Card/Border Shadow for Playful Cartoonish look
  static List<BoxShadow> softShadows = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> playfulShadow = [
    const BoxShadow(
      color: Color(0x3F000000),
      blurRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  // Gradients for UI elements
  static const LinearGradient forestGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sunGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF80DEEA), Color(0xFF4DD0E1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient woodGradient = LinearGradient(
    colors: [Color(0xFFA1887F), Color(0xFF8D6E63)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Generates the main ThemeData
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryAmber,
        surface: creamBg,
      ),
      scaffoldBackgroundColor: creamBg,
    );

    // Apply Fredoka Google Font as it is rounded, bold, and extremely playful/child-friendly
    return baseTheme.copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
        titleLarge: GoogleFonts.fredoka(
          fontWeight: FontWeight.w600,
          color: darkWood,
        ),
        bodyLarge: GoogleFonts.fredoka(
          color: Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black12, width: 1.5),
          ),
          backgroundColor: primaryAmber,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
