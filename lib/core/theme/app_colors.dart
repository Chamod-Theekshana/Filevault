import 'package:flutter/material.dart';

/// Colour tokens for FileVault (light + dark).
///
/// The palette is deliberately small: warm paper neutrals, one ink-blue brand
/// colour taken from the app icon, and the icon's amber keyhole as the only
/// accent. Everything else (categories, errors) is semantic. Never use raw
/// hex values in widgets – reference these tokens or the theme.
abstract final class AppColors {
  // ------------------------------------------------------------- brand
  /// Ink blue from the app icon. Fills (buttons, FAB, selection) use it in
  /// both themes, always with white content on top.
  static const Color brand = Color(0xFF0B6E99);
  static const Color brandDark = Color(0xFF1E77A6);

  /// Amber keyhole from the app icon – used sparingly for "attention".
  static const Color amber = Color(0xFFE9A23B);

  // ----------------------------------------------------------- light
  static const Color lightSurface = Color(0xFFF7F6F3);
  static const Color lightSurfaceDim = Color(0xFFE3E1DB);
  static const Color lightSurfaceBright = Color(0xFFFBFAF8);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF1EFEA);
  static const Color lightSurfaceContainer = Color(0xFFEBE9E3);
  static const Color lightSurfaceContainerHigh = Color(0xFFE4E2DB);
  static const Color lightSurfaceContainerHighest = Color(0xFFDCDAD2);
  static const Color lightOnSurface = Color(0xFF18212B);
  static const Color lightOnSurfaceVariant = Color(0xFF59626C);
  static const Color lightInverseSurface = Color(0xFF283037);
  static const Color lightInverseOnSurface = Color(0xFFF1EFEA);
  static const Color lightOutline = Color(0xFF8A9097);
  static const Color lightOutlineVariant = Color(0xFFD6D3CB);
  static const Color lightSurfaceTint = Color(0xFF0B6E99);
  static const Color lightPrimary = Color(0xFF0A5C86);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = brand;
  static const Color lightOnPrimaryContainer = Color(0xFFE3F2FA);
  static const Color lightInversePrimary = Color(0xFF8ED0F2);
  static const Color lightSecondary = Color(0xFF8F5700);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFFCDDAE);
  static const Color lightOnSecondaryContainer = Color(0xFF4A2C00);
  static const Color lightTertiary = Color(0xFF3D5A80);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFD7E3F4);
  static const Color lightOnTertiaryContainer = Color(0xFF14263D);
  static const Color lightError = Color(0xFFB3261E);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF7A1410);
  static const Color lightPrimaryFixed = Color(0xFFDCECF4);
  static const Color lightPrimaryFixedDim = Color(0xFFA9D3E8);
  static const Color lightOnPrimaryFixed = Color(0xFF00293D);
  static const Color lightOnPrimaryFixedVariant = Color(0xFF0A4A6B);
  static const Color lightSecondaryFixed = Color(0xFFFFE2BC);
  static const Color lightSecondaryFixedDim = Color(0xFFF4BE6E);
  static const Color lightOnSecondaryFixed = Color(0xFF2A1800);
  static const Color lightOnSecondaryFixedVariant = Color(0xFF633F00);
  static const Color lightChipFill = Color(0xFFEEECE6);
  static const Color lightChipText = Color(0xFF59626C);
  static const Color lightCardBorder = Color(0xFFE7E4DD);
  static const Color lightAmber = amber;

  // ------------------------------------------------------------ dark
  static const Color darkSurface = Color(0xFF101316);
  static const Color darkSurfaceDim = Color(0xFF101316);
  static const Color darkSurfaceBright = Color(0xFF353A40);
  static const Color darkSurfaceContainerLowest = Color(0xFF0B0D0F);
  static const Color darkSurfaceContainerLow = Color(0xFF161A1E);
  static const Color darkSurfaceContainer = Color(0xFF1B2025);
  static const Color darkSurfaceContainerHigh = Color(0xFF23292F);
  static const Color darkSurfaceContainerHighest = Color(0xFF2C3339);
  static const Color darkOnSurface = Color(0xFFE7E9EC);
  static const Color darkOnSurfaceVariant = Color(0xFFA5ADB6);
  static const Color darkInverseSurface = Color(0xFFE7E9EC);
  static const Color darkInverseOnSurface = Color(0xFF22272C);
  static const Color darkOutline = Color(0xFF7F8790);
  static const Color darkOutlineVariant = Color(0xFF3A4148);
  static const Color darkSurfaceTint = Color(0xFF8ED0F2);
  static const Color darkPrimary = Color(0xFF8ED0F2);

  /// White: in the dark theme `onPrimary` is drawn on the brand fill
  /// ([darkPrimaryContainer]), so button labels are always white.
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkPrimaryContainer = brandDark;
  static const Color darkOnPrimaryContainer = Color(0xFFE6F4FB);
  static const Color darkInversePrimary = Color(0xFF0A5C86);
  static const Color darkSecondary = Color(0xFFF2B45A);
  static const Color darkOnSecondary = Color(0xFF462B00);
  static const Color darkSecondaryContainer = Color(0xFF6B4300);
  static const Color darkOnSecondaryContainer = Color(0xFFFFE2BC);
  static const Color darkTertiary = Color(0xFFB4C8E6);
  static const Color darkOnTertiary = Color(0xFF1C2E47);
  static const Color darkTertiaryContainer = Color(0xFF2C405C);
  static const Color darkOnTertiaryContainer = Color(0xFFD7E3F4);
  static const Color darkError = Color(0xFFF2B8B5);
  static const Color darkOnError = Color(0xFF601410);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFF9DEDC);
  static const Color darkPrimaryFixed = Color(0xFFCDE8F6);
  static const Color darkPrimaryFixedDim = Color(0xFF8ED0F2);
  static const Color darkOnPrimaryFixed = Color(0xFF001E2C);
  static const Color darkOnPrimaryFixedVariant = Color(0xFF004C69);
  static const Color darkSecondaryFixed = Color(0xFFFFE2BC);
  static const Color darkSecondaryFixedDim = Color(0xFFF2B45A);
  static const Color darkOnSecondaryFixed = Color(0xFF2A1800);
  static const Color darkOnSecondaryFixedVariant = Color(0xFF643F00);
  static const Color darkChipFill = Color(0xFF1E2328);
  static const Color darkChipText = Color(0xFFA5ADB6);
  static const Color darkCardBorder = Color(0xFF252B31);
  static const Color darkAccent = brandDark;
  static const Color darkAmber = Color(0xFFF2B45A);

  // Accent presets offered in Settings.
  static const List<int> accentPresets = <int>[
    0xFF0B6E99,
    0xFF2E7D32,
    0xFF6750A4,
    0xFFC2185B,
    0xFFE65100,
  ];
}
