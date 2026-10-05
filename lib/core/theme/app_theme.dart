import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Extra design tokens that Material's [ColorScheme] has no slot for.
@immutable
class FvTokens extends ThemeExtension<FvTokens> {
  const FvTokens({
    required this.chipFill,
    required this.chipText,
    required this.amber,
    required this.onAmber,
    required this.cardBorder,
    required this.ambientShadow,
    required this.fabShadow,
    required this.selectedRow,
    required this.success,
  });

  final Color chipFill;
  final Color chipText;
  final Color amber;
  final Color onAmber;
  final Color cardBorder;
  final BoxShadow ambientShadow;
  final BoxShadow fabShadow;
  final Color selectedRow;
  final Color success;

  static const FvTokens light = FvTokens(
    chipFill: AppColors.lightChipFill,
    chipText: AppColors.lightChipText,
    amber: AppColors.lightAmber,
    onAmber: AppColors.lightOnSecondaryFixed,
    cardBorder: AppColors.lightChipFill,
    ambientShadow: BoxShadow(
      color: Color(0x140B6E99),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
    fabShadow: BoxShadow(
      color: Color(0x3D0B6E99),
      blurRadius: 16,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
    selectedRow: AppColors.lightSurfaceContainerHigh,
    success: Color(0xFF16A34A),
  );

  static const FvTokens dark = FvTokens(
    chipFill: AppColors.darkSurfaceContainer,
    chipText: AppColors.darkOnSurfaceVariant,
    amber: AppColors.darkAmber,
    onAmber: AppColors.darkOnSecondaryFixed,
    cardBorder: AppColors.darkSurfaceContainerHigh,
    ambientShadow: BoxShadow(
      color: Color(0x99000000),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
    fabShadow: BoxShadow(
      color: Color(0x4038BDF8),
      blurRadius: 24,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
    selectedRow: AppColors.darkPrimaryContainer,
    success: Color(0xFF4ADE80),
  );

  @override
  FvTokens copyWith({
    Color? chipFill,
    Color? chipText,
    Color? amber,
    Color? onAmber,
    Color? cardBorder,
    BoxShadow? ambientShadow,
    BoxShadow? fabShadow,
    Color? selectedRow,
    Color? success,
  }) {
    return FvTokens(
      chipFill: chipFill ?? this.chipFill,
      chipText: chipText ?? this.chipText,
      amber: amber ?? this.amber,
      onAmber: onAmber ?? this.onAmber,
      cardBorder: cardBorder ?? this.cardBorder,
      ambientShadow: ambientShadow ?? this.ambientShadow,
      fabShadow: fabShadow ?? this.fabShadow,
      selectedRow: selectedRow ?? this.selectedRow,
      success: success ?? this.success,
    );
  }

  @override
  FvTokens lerp(ThemeExtension<FvTokens>? other, double t) {
    if (other is! FvTokens) return this;
    return FvTokens(
      chipFill: Color.lerp(chipFill, other.chipFill, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      onAmber: Color.lerp(onAmber, other.onAmber, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      ambientShadow: BoxShadow.lerp(ambientShadow, other.ambientShadow, t)!,
      fabShadow: BoxShadow.lerp(fabShadow, other.fabShadow, t)!,
      selectedRow: Color.lerp(selectedRow, other.selectedRow, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// Builds Material 3 themes mapped onto the design tokens.
abstract final class AppTheme {
  static ThemeData light({int? accentArgb}) {
    final ColorScheme scheme = _lightScheme(accentArgb);
    return _build(
      scheme: scheme,
      tokens: FvTokens.light,
      overlay: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: scheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static ThemeData dark({int? accentArgb}) {
    final ColorScheme scheme = _darkScheme(accentArgb);
    return _build(
      scheme: scheme,
      tokens: FvTokens.dark,
      overlay: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: scheme.surfaceContainer,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required FvTokens tokens,
    required SystemUiOverlayStyle overlay,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final TextTheme textTheme = AppTypography.textTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTypography.bodyFamily,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: tokens.cardBorder,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        systemOverlayStyle: overlay,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        toolbarHeight: 64,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        sizeConstraints: BoxConstraints.tight(const Size(56, 56)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        modalBackgroundColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.chipFill,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.chipText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const CircleBorder(),
        side: BorderSide(color: scheme.outline, width: 2),
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return scheme.primaryContainer;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return scheme.primaryContainer;
          return tokens.chipFill;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.chipFill,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelLarge?.copyWith(color: tokens.chipText),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: true,
        checkmarkColor: scheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleSmall?.copyWith(color: scheme.onSurface),
        subtitleTextStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primaryContainer,
        linearTrackColor: tokens.chipFill,
        circularTrackColor: tokens.chipFill,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimary,
          backgroundColor: tokens.chipFill,
          foregroundColor: scheme.onSurfaceVariant,
          side: BorderSide.none,
          textStyle: textTheme.labelLarge,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  static ColorScheme _lightScheme(int? accentArgb) {
    final bool custom =
        accentArgb != null && accentArgb != AppColors.lightPrimaryContainer.toARGB32();
    final Color accent = custom ? Color(accentArgb) : AppColors.lightPrimaryContainer;
    final Color primary = custom
        ? Color.lerp(accent, Colors.black, 0.18)!
        : AppColors.lightPrimary;
    return ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: accent,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      primaryFixed: custom
          ? Color.lerp(accent, Colors.white, 0.78)!
          : AppColors.lightPrimaryFixed,
      primaryFixedDim: AppColors.lightPrimaryFixedDim,
      onPrimaryFixed: AppColors.lightOnPrimaryFixed,
      onPrimaryFixedVariant: AppColors.lightOnPrimaryFixedVariant,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightOnSecondary,
      secondaryContainer: AppColors.lightSecondaryContainer,
      onSecondaryContainer: AppColors.lightOnSecondaryContainer,
      secondaryFixed: AppColors.lightSecondaryFixed,
      secondaryFixedDim: AppColors.lightSecondaryFixedDim,
      onSecondaryFixed: AppColors.lightOnSecondaryFixed,
      onSecondaryFixedVariant: AppColors.lightOnSecondaryFixedVariant,
      tertiary: AppColors.lightTertiary,
      onTertiary: AppColors.lightOnTertiary,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      onTertiaryContainer: AppColors.lightOnTertiaryContainer,
      error: AppColors.lightError,
      onError: AppColors.lightOnError,
      errorContainer: AppColors.lightErrorContainer,
      onErrorContainer: AppColors.lightOnErrorContainer,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      surfaceDim: AppColors.lightSurfaceDim,
      surfaceBright: AppColors.lightSurfaceBright,
      surfaceContainerLowest: AppColors.lightSurfaceContainerLowest,
      surfaceContainerLow: AppColors.lightSurfaceContainerLow,
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      inverseSurface: AppColors.lightInverseSurface,
      onInverseSurface: AppColors.lightInverseOnSurface,
      inversePrimary: AppColors.lightInversePrimary,
      surfaceTint: custom ? accent : AppColors.lightSurfaceTint,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  static ColorScheme _darkScheme(int? accentArgb) {
    final bool custom =
        accentArgb != null && accentArgb != AppColors.lightPrimaryContainer.toARGB32();
    final Color accent = custom ? Color(accentArgb) : AppColors.darkAccent;
    final Color primary = custom
        ? Color.lerp(accent, Colors.white, 0.45)!
        : AppColors.darkPrimary;
    final Color primaryContainer = custom
        ? Color.lerp(accent, Colors.black, 0.45)!
        : AppColors.darkPrimaryContainer;
    return ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      primaryFixed: AppColors.darkPrimaryFixed,
      primaryFixedDim: AppColors.darkPrimaryFixedDim,
      onPrimaryFixed: AppColors.darkOnPrimaryFixed,
      onPrimaryFixedVariant: AppColors.darkOnPrimaryFixedVariant,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      secondaryFixed: AppColors.darkSecondaryFixed,
      secondaryFixedDim: AppColors.darkSecondaryFixedDim,
      onSecondaryFixed: AppColors.darkOnSecondaryFixed,
      onSecondaryFixedVariant: AppColors.darkOnSecondaryFixedVariant,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      surfaceDim: AppColors.darkSurfaceDim,
      surfaceBright: AppColors.darkSurfaceBright,
      surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      inverseSurface: AppColors.darkInverseSurface,
      onInverseSurface: AppColors.darkInverseOnSurface,
      inversePrimary: AppColors.darkInversePrimary,
      surfaceTint: custom ? accent : AppColors.darkSurfaceTint,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }
}
