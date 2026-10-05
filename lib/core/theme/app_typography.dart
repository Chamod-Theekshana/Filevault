
import 'package:flutter/material.dart';

/// Type scale from the design system: Roboto Flex for headlines, Inter for
/// body and labels. Both fonts are bundled as variable fonts, so weight is
/// expressed through the `wght` axis as well as [FontWeight].
abstract final class AppTypography {
  static const String headlineFamily = 'RobotoFlex';
  static const String bodyFamily = 'Inter';

  static TextStyle headline({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: headlineFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: <FontVariation>[
        FontVariation('wght', _axisWeight(weight)),
        const FontVariation('opsz', 24),
      ],
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: <FontVariation>[FontVariation('wght', _axisWeight(weight))],
      fontFeatures: tabular
          ? const <FontFeature>[FontFeature.tabularFigures()]
          : null,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static double _axisWeight(FontWeight weight) => (weight.index + 1) * 100.0;

  /// Tabular-figure body style for sizes, dates and counts.
  static TextStyle get numeric =>
      body(size: 12, weight: FontWeight.w400, height: 16 / 12, tabular: true);

  static TextTheme textTheme() {
    return TextTheme(
      displaySmall: headline(size: 34, weight: FontWeight.w700, height: 40 / 34,
          letterSpacing: -0.6),
      headlineLarge: headline(size: 28, weight: FontWeight.w700, height: 36 / 28,
          letterSpacing: -0.56),
      headlineMedium: headline(size: 22, weight: FontWeight.w600, height: 28 / 22,
          letterSpacing: -0.22),
      headlineSmall: headline(size: 18, weight: FontWeight.w600, height: 24 / 18),
      titleLarge: headline(size: 20, weight: FontWeight.w600, height: 26 / 20),
      titleMedium: body(size: 16, weight: FontWeight.w600, height: 22 / 16),
      titleSmall: body(size: 14, weight: FontWeight.w600, height: 20 / 14),
      bodyLarge: body(size: 16, weight: FontWeight.w400, height: 24 / 16),
      bodyMedium: body(size: 14, weight: FontWeight.w400, height: 20 / 14),
      bodySmall: body(size: 12, weight: FontWeight.w400, height: 16 / 12,
          letterSpacing: 0.12),
      labelLarge: body(size: 14, weight: FontWeight.w600, height: 20 / 14,
          letterSpacing: 0.14),
      labelMedium: body(size: 12, weight: FontWeight.w600, height: 16 / 12,
          letterSpacing: 0.24),
      labelSmall: body(size: 11, weight: FontWeight.w600, height: 14 / 11,
          letterSpacing: 0.44),
    );
  }
}
