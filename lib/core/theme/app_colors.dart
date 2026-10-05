import 'package:flutter/material.dart';

/// Colour tokens taken 1:1 from the FileVault Stitch design system
/// (light + dark). Never use raw hex values in widgets – reference these.
abstract final class AppColors {
  // ----------------------------------------------------------- light
  static const Color lightSurface = Color(0xFFF8F9FF);
  static const Color lightSurfaceDim = Color(0xFFCBDBF5);
  static const Color lightSurfaceBright = Color(0xFFF8F9FF);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEFF4FF);
  static const Color lightSurfaceContainer = Color(0xFFE5EEFF);
  static const Color lightSurfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color lightSurfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color lightOnSurface = Color(0xFF0B1C30);
  static const Color lightOnSurfaceVariant = Color(0xFF40484E);
  static const Color lightInverseSurface = Color(0xFF213145);
  static const Color lightInverseOnSurface = Color(0xFFEAF1FF);
  static const Color lightOutline = Color(0xFF70787F);
  static const Color lightOutlineVariant = Color(0xFFBFC7CF);
  static const Color lightSurfaceTint = Color(0xFF00658E);
  static const Color lightPrimary = Color(0xFF005578);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFF0B6E99);
  static const Color lightOnPrimaryContainer = Color(0xFFCFEAFF);
  static const Color lightInversePrimary = Color(0xFF84CFFF);
  static const Color lightSecondary = Color(0xFF835400);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFFDB244);
  static const Color lightOnSecondaryContainer = Color(0xFF6E4600);
  static const Color lightTertiary = Color(0xFF0045B9);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFF185CE4);
  static const Color lightOnTertiaryContainer = Color(0xFFE0E5FF);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF93000A);
  static const Color lightPrimaryFixed = Color(0xFFC7E7FF);
  static const Color lightPrimaryFixedDim = Color(0xFF84CFFF);
  static const Color lightOnPrimaryFixed = Color(0xFF001E2E);
  static const Color lightOnPrimaryFixedVariant = Color(0xFF004C6C);
  static const Color lightSecondaryFixed = Color(0xFFFFDDB5);
  static const Color lightSecondaryFixedDim = Color(0xFFFFB956);
  static const Color lightOnSecondaryFixed = Color(0xFF2A1800);
  static const Color lightOnSecondaryFixedVariant = Color(0xFF633F00);
  static const Color lightChipFill = Color(0xFFEEF2F5);
  static const Color lightChipText = Color(0xFF64748B);
  static const Color lightAmber = Color(0xFFF2A93B);

  // ------------------------------------------------------------ dark
  static const Color darkSurface = Color(0xFF101418);
  static const Color darkSurfaceDim = Color(0xFF101418);
  static const Color darkSurfaceBright = Color(0xFF363A40);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B0F12);
  static const Color darkSurfaceContainerLow = Color(0xFF191D21);
  static const Color darkSurfaceContainer = Color(0xFF1D2126);
  static const Color darkSurfaceContainerHigh = Color(0xFF282C31);
  static const Color darkSurfaceContainerHighest = Color(0xFF33373C);
  static const Color darkOnSurface = Color(0xFFE1E2E8);
  static const Color darkOnSurfaceVariant = Color(0xFFC4C6CF);
  static const Color darkInverseSurface = Color(0xFFE0E3E8);
  static const Color darkInverseOnSurface = Color(0xFF2D3135);
  static const Color darkOutline = Color(0xFF8E9099);
  static const Color darkOutlineVariant = Color(0xFF43474E);
  static const Color darkSurfaceTint = Color(0xFF7BD0FF);
  static const Color darkPrimary = Color(0xFF8ED5FF);
  static const Color darkOnPrimary = Color(0xFF00354A);
  static const Color darkPrimaryContainer = Color(0xFF004C6C);
  static const Color darkOnPrimaryContainer = Color(0xFFC7E7FF);
  static const Color darkInversePrimary = Color(0xFF00658E);
  static const Color darkSecondary = Color(0xFFFFB956);
  static const Color darkOnSecondary = Color(0xFF462B00);
  static const Color darkSecondaryContainer = Color(0xFF9E6600);
  static const Color darkOnSecondaryContainer = Color(0xFFFFF7F1);
  static const Color darkTertiary = Color(0xFFBCCBFF);
  static const Color darkOnTertiary = Color(0xFF1C2E5E);
  static const Color darkTertiaryContainer = Color(0xFF9EAFE8);
  static const Color darkOnTertiaryContainer = Color(0xFF304173);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  static const Color darkPrimaryFixed = Color(0xFFC4E7FF);
  static const Color darkPrimaryFixedDim = Color(0xFF7BD0FF);
  static const Color darkOnPrimaryFixed = Color(0xFF001E2C);
  static const Color darkOnPrimaryFixedVariant = Color(0xFF004C69);
  static const Color darkSecondaryFixed = Color(0xFFFFDDB5);
  static const Color darkSecondaryFixedDim = Color(0xFFFFB956);
  static const Color darkOnSecondaryFixed = Color(0xFF2A1800);
  static const Color darkOnSecondaryFixedVariant = Color(0xFF643F00);
  static const Color darkAccent = Color(0xFF38BDF8);
  static const Color darkAmber = Color(0xFFFFB956);

  // Accent presets offered in Settings.
  static const List<int> accentPresets = <int>[
    0xFF0B6E99,
    0xFF2E7D32,
    0xFF6750A4,
    0xFFC2185B,
    0xFFE65100,
  ];
}
