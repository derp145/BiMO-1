import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle displayLarge(bool isDark) => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.1,
    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  static TextStyle displayMedium(bool isDark) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.15,
    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  static TextStyle headingLarge(bool isDark) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  static TextStyle headingMedium(bool isDark) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
  );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
  );

  static TextStyle bodySmall(bool isDark) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
  );

  static TextStyle labelUppercase({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.8,
    color: color ?? AppColors.emeraldLight,
  );

  static TextStyle codeFont({Color? color, double size = 13}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.emeraldLight,
      );
}
