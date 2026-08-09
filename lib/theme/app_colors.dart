import 'package:flutter/material.dart';

/// Dapzo brand color palette.
/// Keep usage disciplined: primary red for CTAs/active states only,
/// food orange / meat red for mode identification, not decoration.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE53935); // Dapzo Red
  static const Color foodOrange = Color(0xFFF57C00);
  static const Color meatRed = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);

  static const Color background = Color(0xFFF8F8F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E5E5);

  static const Color error = Color(0xFFD32F2F);

  /// Returns the identity color for a product/browse mode.
  static Color modeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'meat':
        return meatRed;
      case 'food':
      default:
        return foodOrange;
    }
  }
}
