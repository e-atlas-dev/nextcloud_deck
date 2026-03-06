import 'package:flutter/material.dart';

/// The Nextcloud Deck app icon, optionally clipped to rounded corners.
///
/// Tries to load `assets/icons/nextcloud_deck_icon.png`. Falls back to
/// [Icons.dashboard_rounded] in [fallbackColor] if the asset is missing.
///
/// Usage:
/// ```dart
/// AppIcon(size: 64)                            // sharp corners, white fallback
/// AppIcon(size: 80, borderRadius: 20)          // rounded square (launcher shape)
/// AppIcon(size: 36, fallbackColor: AppColors.brand) // brand-coloured fallback
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.size,
    this.fallbackColor = Colors.white,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double size;
  final Color fallbackColor;
  final BoxFit fit;

  /// If set, the icon is clipped to a rounded rectangle with this radius.
  /// Matches the Android adaptive icon shape (use 24 for launcher look).
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      'assets/icons/nextcloud_deck_icon.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => Icon(
        Icons.dashboard_rounded,
        size: size * 0.65,
        color: fallbackColor,
      ),
    );

    if (borderRadius != null) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: img,
      );
    }

    return SizedBox(width: size, height: size, child: img);
  }
}
