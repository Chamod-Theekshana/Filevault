import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Roboto Flex headlines and Inter body/label styles from Stitch.
abstract final class AppTypography {
  static TextTheme textTheme() {
    final TextStyle headlineBase = GoogleFonts.robotoFlex();
    final TextStyle bodyBase = GoogleFonts.inter();
    return TextTheme(
      headlineLarge: headlineBase.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.56,
      ),
      headlineMedium: headlineBase.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        letterSpacing: -0.22,
      ),
      headlineSmall: headlineBase.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
      ),
      bodyLarge: bodyBase.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      bodyMedium: bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      bodySmall: bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
      labelLarge: bodyBase.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.14,
      ),
      labelMedium: bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.24,
      ),
      labelSmall: bodyBase.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        letterSpacing: 0.44,
      ),
      titleMedium: bodyBase.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
