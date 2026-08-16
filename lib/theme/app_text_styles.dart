import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central dynamic typography scale — Dapzo Premium with full Dark Mode support.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.poppins(color: AppColors.textDark);

  // ─── Headings ─────────────────────────────────────────────────────────────
  static TextStyle get heading => _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textDark,
      );

  static TextStyle get sectionHeading => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get shopName => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      );

  // ─── Product / Card ───────────────────────────────────────────────────────
  static TextStyle get productName => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      );

  static TextStyle get price => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
      );

  static TextStyle get priceSmall => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
      );

  static TextStyle get heroPrice => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
      );

  // ─── Body / Supporting ────────────────────────────────────────────────────
  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
        height: 1.5,
      );

  static TextStyle get supporting => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ─── Badges / Tags ────────────────────────────────────────────────────────
  static TextStyle get badge => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get tag => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.isDarkMode ? AppColors.primaryLight : AppColors.primary,
      );

  // ─── Interactive ──────────────────────────────────────────────────────────
  static TextStyle get button => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.3,
      );
}
