import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_accent.dart';
import 'app_colors.dart';

/// Central theme factory for the Menly design system.
///
/// Use [AppTheme.build] to generate a light/dark [ThemeData] for a chosen
/// accent. The legacy static color constants below are kept for screens that
/// have not been migrated to the new [AppColors] tokens yet.
class AppTheme {
  AppTheme._();

  // Shared corner-radius scale (design tokens). These seven values are the only
  // radii used in the app, so every surface rounds off consistently.
  static const double radiusXs = 6; // sale tags, tiny markers
  static const double radiusSm = 10; // small buttons, inputs, search fields
  static const double radiusMd = 12; // primary buttons, size pickers
  static const double radiusCard = 14; // product cards, 3:4 images, large buttons
  static const double radiusLg = 16; // panels, stat cards
  static const double radiusXl = 20; // hero images, bottom sheets
  static const double radiusPill = 999; // chips, dots, swatches, avatars

  // Mau chu dao: Den sau tham & Xam kim loai (Zara, Coolmate, Routine)
  static const Color primary = Color(0xFF1C1B17); // Ink neutral
  static const Color primaryLight = Color(0xFF2E2B25);
  static const Color primaryAccent = Color(0xFFB8824A); // Camel gold
  static const Color primaryDark = Color(0xFF0F172A);

  // Mau nhan (Sale, Hot, Voucher, Gia)
  static const Color accentRed = Color(0xFFC0564B);
  static const Color accentGreen = Color(0xFF3E7C5A);

  // Mau nen & Mat be mat
  static const Color scaffoldBackground = Color(0xFFF7F5F1); // Boutique cream
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color cardColor = Colors.white;

  // Mau van ban
  static const Color textPrimary = Color(0xFF15140F);
  static const Color textSecondary = Color(0xFF6E6A5F);
  static const Color textMuted = Color(0xFFA7A294);

  // Mau vien & Duong chia
  static const Color border = Color(0xFFE8E2D7);
  static const Color divider = Color(0xFFE8E2D7);

  // Shadow nhe sang trong
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  /// Builds a themed [ThemeData] with the [AppColors] extension attached.
  static ThemeData build({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? AppColors.dark(accent) : AppColors.light(accent);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent.color,
        brightness: brightness,
        primary: c.primary,
        surface: c.surface,
        error: c.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceVariant,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: c.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inkCard,
        contentTextStyle: TextStyle(color: c.onInk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }

  /// Default Light Theme
  static ThemeData get lightTheme => build(
        brightness: Brightness.light,
        accent: AppAccent.camel,
      );

  /// Default Dark Theme
  static ThemeData get darkTheme => build(
        brightness: Brightness.dark,
        accent: AppAccent.camel,
      );

  /// Alias for dark theme
  static ThemeData get dark => darkTheme;
}
