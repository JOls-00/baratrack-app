import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/providers/theme_provider.dart';

class AppTheme {
  // Official Palette Colors
  static const Color blackish = Color(0xFF020617);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color wheat = Color(0xFFF5DEB3);
  static const Color caramel = Color(0xFFD97706);
  static const Color dustyRose = Color(0xFFFDA4AF);
  static const Color wind = Color(0xFFF8FAFC);
  static const Color breath = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF1E293B);

  // Barangay Rosario logo palette (sampled from the official seal)
  static const Color logoRed = Color(0xFFD61314);       // seal ring
  static const Color sunYellow = Color(0xFFF1FE0A);     // rising sun
  static const Color laurelGreen = Color(0xFF155228);   // laurel wreath
  static const Color burstBlue = Color(0xFF3D7FBB);
  static const Color burstTeal = Color(0xFF3D9897);
  static const Color burstOrange = Color(0xFFF9B239);
  static const Color inkDark = Color(0xFF1F1416);

  // Constants for usage in const constructors (used across many screens)
  static const Color primaryBlue = logoRed;             // name kept so existing screens need no edits
  static const Color accentOrange = Color(0xFFC77700);  // logo orange, darkened so text stays readable on white
  static const Color backgroundLight = wind;
  static const Color slateGray = Color(0xFF64748B);
  static const Color darkNavy = inkDark;                // headings
  static const Color textSecondary = Color(0xFF64748B);
  static const Color bgSoftGray = Color(0xFFF1F5F9);

  /// Readable text/icon colour to put on top of [c] (white on dark colours, dark on light ones).
  static Color onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : const Color(0xFF1F1416);

  /// A deeper shade of [c], used for gradients.
  static Color deepen(Color c, [double amount = 0.25]) => Color.lerp(c, Colors.black, amount)!;

  static ThemeData getTheme(ThemeCombo combo, {Color? primaryOverride}) {
    switch (combo) {
      case ThemeCombo.barangayRosario:
        return _buildTheme(
          brightness: Brightness.light,
          primary: primaryOverride ?? logoRed,
          secondary: laurelGreen,
          background: const Color(0xFFFFFBFA), // barely-warm white
          surface: Colors.white,
          onSurface: inkDark,
        );
      case ThemeCombo.dustyRoseWind:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFFE11D48), // Deep Rose
          secondary: dustyRose,
          background: wind,
          surface: Colors.white,
          onSurface: textDark,
        );
      case ThemeCombo.caramelWheat:
        return _buildTheme(
          brightness: Brightness.light,
          primary: caramel,
          secondary: const Color(0xFFB45309),
          background: const Color(0xFFFFFBEB), // Very light wheat
          surface: Colors.white,
          onSurface: textDark,
        );
      case ThemeCombo.blackishCaramel:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: caramel,
          secondary: wheat,
          background: blackish,
          surface: surfaceDark,
          onSurface: wind,
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        background: background,
      ),
      // A light wash of the brand colour so every screen feels like "your" barangay.
      scaffoldBackgroundColor: isDark ? background : Color.alphaBlend(primary.withValues(alpha: 0.05), background),
      textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          color: onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 32,
        ),
        titleMedium: GoogleFonts.inter(
          color: onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.inter(
          color: onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        bodyMedium: GoogleFonts.inter(
          color: onSurface,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: primary.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white10 : primary.withValues(alpha: 0.10), width: 1),
        ),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onColor(primary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(color: isDark ? Colors.white12 : primary.withValues(alpha: 0.10), space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        useIndicator: true,
        indicatorColor: primary.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: onSurface.withValues(alpha: 0.45)),
        selectedLabelTextStyle: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelTextStyle: GoogleFonts.inter(color: onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w500, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData get lightTheme => getTheme(ThemeCombo.barangayRosario);
  static ThemeData get darkTheme => getTheme(ThemeCombo.blackishCaramel);
}


/// `context.brand` is the colour the admin picked in Settings (it follows the active theme).
extension BrandColors on BuildContext {
  Color get brand => Theme.of(this).colorScheme.primary;
  Color get onBrand => AppTheme.onColor(Theme.of(this).colorScheme.primary);
}
