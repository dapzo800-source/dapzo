import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography scale — Dapzo Premium.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.poppins(color: AppColors.textDark);

  // ─── Headings ─────────────────────────────────────────────────────────────
  static TextStyle heading = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textDark,
  );

  static TextStyle sectionHeading = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle shopName = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  // ─── Product / Card ───────────────────────────────────────────────────────
  static TextStyle productName = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
  );

  static TextStyle price = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle priceSmall = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle heroPrice = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // ─── Body / Supporting ────────────────────────────────────────────────────
  static TextStyle body = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.5,
  );

  static TextStyle supporting = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle caption = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ─── Badges / Tags ────────────────────────────────────────────────────────
  static TextStyle badge = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.2,
  );

  static TextStyle tag = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ─── Interactive ──────────────────────────────────────────────────────────
  static TextStyle button = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.3,
  );
}
