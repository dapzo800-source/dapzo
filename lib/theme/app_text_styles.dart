import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography scale. Sticks to medium/semibold weights —
/// avoid using w700+ except for large headings.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.poppins(color: AppColors.textDark);

  // Large heading — splash, onboarding titles, screen hero titles
  static TextStyle heading = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  // Section heading — "Categories", "Popular Near You"
  static TextStyle sectionHeading = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Product name / card title
  static TextStyle productName = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Price
  static TextStyle price = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // Supporting / secondary info
  static TextStyle supporting = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle body = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle button = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle caption = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
