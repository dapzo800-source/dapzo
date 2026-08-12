import 'package:flutter/material.dart';

/// Dapzo brand color palette — Premium edition.
class AppColors {
  AppColors._();

  // ─── Brand Core ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFC8019); // Warm Orange
  static const Color primaryDark = Color(0xFFD9660A);
  static const Color primaryLight = Color(0xFFFFA94D);

  // ─── Mode Colors ─────────────────────────────────────────────────────────────
  static const Color foodOrange = Color(0xFF10B981); // Fresh Emerald/Teal
  static const Color foodOrangeLight = Color(0xFF34D399);
  static const Color meatRed = Color(0xFFE11D48); // Rich Rose/Crimson
  static const Color meatRedLight = Color(0xFFFB7185);

  // ─── Gradients ────────────────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [Color(0xFFFFA94D), Color(0xFFFC8019)];
  static const List<Color> foodGradient    = [Color(0xFF34D399), Color(0xFF10B981)];
  static const List<Color> meatGradient    = [Color(0xFFFB7185), Color(0xFFE11D48)];
  static const List<Color> heroGradient    = [Color(0xFF312E81), Color(0xFF1E1B4B)];
  static const List<Color> cardGradient    = [Color(0xFFFFFFFF), Color(0xFFF9FAFB)];


  // ─── Category Accents ────────────────────────────────────────────────────────
  static const Color biryaniAmber    = Color(0xFFF59E0B);
  static const Color pizzaRed        = Color(0xFFDC2626);
  static const Color chickenGold     = Color(0xFFD97706);
  static const Color juiceGreen      = Color(0xFF16A34A);
  static const Color grillBrown      = Color(0xFF92400E);
  static const Color breakfastYellow = Color(0xFFFBBF24);
  static const Color chatPurple      = Color(0xFF7C3AED);
  static const Color dessertPink     = Color(0xFFDB2777);
  static const Color seaBlue         = Color(0xFF0284C7);
  static const Color muttonBrown     = Color(0xFF78350F);
  static const Color sheepGray       = Color(0xFF6B7280);
  static const Color beefDark        = Color(0xFF7F1D1D);

  // ─── Semantic ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFDC2626);

  // ─── Neutrals ────────────────────────────────────────────────────────────────
  static const Color textDark       = Color(0xFF111827);
  static const Color textMedium     = Color(0xFF374151);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textHint       = Color(0xFF9CA3AF);

  static const Color background     = Color(0xFFF8F7F5);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color white          = Color(0xFFFFFFFF);
  static const Color divider        = Color(0xFFE5E7EB);

  // ─── Glassmorphism ───────────────────────────────────────────────────────────
  static const Color glassWhite   = Color(0xCCFFFFFF);
  static const Color glassDark    = Color(0x99000000);
  static const Color glassOverlay = Color(0x33FFFFFF);

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  static Color modeColor(String mode) =>
      mode == 'meat' ? meatRed : foodOrange;

  static List<Color> modeGradient(String mode) =>
      mode == 'meat' ? meatGradient : foodGradient;

  static Color categoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'biryani':        return biryaniAmber;
      case 'pizzas':
      case 'pizza':          return pizzaRed;
      case 'crispy chicken': return chickenGold;
      case 'juice':
      case 'juices':         return juiceGreen;
      case 'grills':
      case 'grill':          return grillBrown;
      case 'breakfast':      return breakfastYellow;
      case 'chats':
      case 'chat':           return chatPurple;
      case 'desserts':
      case 'dessert':        return dessertPink;
      case 'chicken':        return chickenGold;
      case 'mutton':         return muttonBrown;
      case 'sheep':          return sheepGray;
      case 'beef':           return beefDark;
      case 'sea foods':
      case 'seafood':        return seaBlue;
      default:               return primary;
    }
  }
}