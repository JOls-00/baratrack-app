import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../presentation/providers/theme_provider.dart';

class AppTheme {
  // Spacing Scale Tokens (Constants: 4, 8, 12, 16, 24, 32)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  /// Responsive screen side margin: 12px at <=320px width, 16px on normal phones
  static double sideMargin(BuildContext context) =>
      MediaQuery.of(context).size.width <= 320 ? space12 : space16;

  // Official Brand Hue Shades (Crimson #D61314: 5 shades of varying saturation & brightness)
  static const Color brand50 = Color(0xFFFEF2F2);   // soft tinted background / subtle pills
  static const Color brand100 = Color(0xFFFEE2E2);  // borders / alert badge backgrounds
  static const Color brand500 = Color(0xFFD61314);  // primary brand hue
  static const Color brand700 = Color(0xFFB91C1C);  // interactive hover / active
  static const Color brand900 = Color(0xFF7F1D1D);  // deep headings / primary dark

  // Semantic Alert & Feedback Tokens
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color errorBg = Color(0xFFFEF2F2);

  // Accessible High-Contrast Neutral Tokens (WCAG 4.5:1 compliant)
  static const Color textPrimaryLight = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600 (>5.9:1 against white)
  static const Color textMutedLight = Color(0xFF334155);     // Slate 700 (>8.3:1 against white)
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC);    // Slate 50
  static const Color textSecondaryDark = Color(0xFFCBD5E1);  // Slate 300 (>9.2:1 against surfaceDark)
  static const Color textMutedDark = Color(0xFF94A3B8);      // Slate 400 (>5.4:1 against surfaceDark)

  // Legacy compatibility tokens
  static const Color blackish = Color(0xFF020617);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color wheat = Color(0xFFF5DEB3);
  static const Color caramel = Color(0xFFD97706);
  static const Color dustyRose = Color(0xFFFDA4AF);
  static const Color wind = Color(0xFFF8FAFC);
  static const Color breath = Color(0xFFE2E8F0);
  static const Color textDark = textPrimaryLight;
  static const Color logoRed = brand500;
  static const Color sunYellow = Color(0xFFF1FE0A);
  static const Color laurelGreen = Color(0xFF155228);
  static const Color burstBlue = Color(0xFF3D7FBB);
  static const Color burstTeal = Color(0xFF3D9897);
  static const Color burstOrange = Color(0xFFF9B239);
  static const Color inkDark = Color(0xFF1F1416);
  static const Color primaryBlue = brand500;
  static const Color accentOrange = warning;
  static const Color backgroundLight = wind;
  static const Color textSecondary = textSecondaryLight;
  static const Color bgSoftGray = Color(0xFFF1F5F9);
  static const Color slateGray = Color(0xFF475569);
  static const Color darkNavy = textPrimaryLight;

  static Color onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : const Color(0xFF0F172A);

  static Color deepen(Color c, [double amount = 0.25]) => Color.lerp(c, Colors.black, amount)!;

  static ThemeData getTheme(ThemeCombo combo, {Color? primaryOverride}) {
    switch (combo) {
      case ThemeCombo.barangayRosario:
        return _buildTheme(
          brightness: Brightness.light,
          primary: primaryOverride ?? brand500,
          secondary: brand700,
          background: const Color(0xFFFFFBFA),
          surface: Colors.white,
          onSurface: textPrimaryLight,
        );
      case ThemeCombo.dustyRoseWind:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFFE11D48),
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
          background: const Color(0xFFFFFBEB),
          surface: Colors.white,
          onSurface: textDark,
        );
      case ThemeCombo.blackishCaramel:
        return _buildTheme(
          brightness: Brightness.dark,
          primary: brand500,
          secondary: brand700,
          background: blackish,
          surface: surfaceDark,
          onSurface: textPrimaryDark,
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
    final secTextColor = isDark ? textSecondaryDark : textSecondaryLight;

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
      ),
      scaffoldBackgroundColor: isDark ? background : Color.alphaBlend(primary.withValues(alpha: 0.05), background),
      textTheme: GoogleFonts.interTextTheme(textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          color: onSurface,
          fontWeight: FontWeight.w900,
          fontSize: 32,
        ),
        titleMedium: GoogleFonts.inter(
          color: secTextColor,
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
        bodySmall: GoogleFonts.inter(
          color: secTextColor,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: primary.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: space12, vertical: space8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), width: 1),
        ),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onColor(primary),
          elevation: 0,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 44),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(44, 44),
          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), space: 1),
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
        unselectedLabelTextStyle: GoogleFonts.inter(color: secTextColor, fontWeight: FontWeight.w500, fontSize: 13),
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

extension BrandColors on BuildContext {
  Color get brand => Theme.of(this).colorScheme.primary;
  Color get onBrand => AppTheme.onColor(Theme.of(this).colorScheme.primary);
}
