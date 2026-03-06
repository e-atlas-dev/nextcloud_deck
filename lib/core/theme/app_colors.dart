import 'package:flutter/material.dart';

/// Nextcloud-inspired colour palette.
/// Light and dark variants are defined separately and consumed
/// by [AppTheme] to build full [ThemeData] objects.
abstract final class AppColors {
  // Brand
  static const Color brand = Color(0xFF0082C9);
  static const Color brandDark = Color(
    0xFF006CA3,
  ); // pressed / dark-mode primary
  static const Color brandLight = Color(0xFFE6F2FA); // tinted backgrounds

  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightSurfaceVariant = Color(0xFFEEEEEE);
  static const Color lightDivider = Color(0xFFEDEDED);
  static const Color lightBorder = Color(0xFFDDDDDD);

  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextMuted = Color(0xFF9B9B9B);
  static const Color lightTextOnBrand = Color(0xFFFFFFFF);

  // Dark theme
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkSurfaceVariant = Color(0xFF323232);
  static const Color darkDivider = Color(0xFF3A3A3A);
  static const Color darkBorder = Color(0xFF444444);

  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextMuted = Color(0xFF787878);
  static const Color darkTextOnBrand = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF46BA61);
  static const Color successLight = Color(0xFFE9F7ED);
  static const Color warning = Color(0xFFF7C948);
  static const Color warningLight = Color(0xFFFEF8E7);
  static const Color error = Color(0xFFD64545);
  static const Color errorLight = Color(0xFFFBEAEA);
  static const Color info = Color(0xFF0082C9);
  static const Color infoLight = Color(0xFFE6F2FA);

  // Board accent colours (user-selectable)
  static const List<Color> boardColors = [
    Color(0xFF0082C9), // Nextcloud blue
    Color(0xFF46BA61), // Green
    Color(0xFFF7C948), // Yellow
    Color(0xFFD64545), // Red
    Color(0xFF9D5BD2), // Purple
    Color(0xFFFF7043), // Deep orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF26A69A), // Teal
    Color(0xFFEC407A), // Pink
  ];

  /// Parses a hex color string (e.g. `"#0082C9"` or `"0082C9"`) into a [Color].
  /// Returns [brand] if the string is malformed or contains invalid characters.
  static Color fromHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    try {
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return brand;
  }

  /// Converts a [Color] to a 6-digit uppercase hex string without a leading #.
  ///
  /// The first two hex digits (alpha channel) are stripped, leaving RGB only.
  static String toHex(Color color) => color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2)
      .toUpperCase();
}
