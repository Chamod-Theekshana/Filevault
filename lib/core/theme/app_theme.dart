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
    required this.tonal,
    required this.onTonal,
    required this.vault,
    required this.onVault,
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

  /// Soft brand-tinted fill for icon tiles, tonal buttons and active nav
  /// pills – the quiet counterpart of the brand fill.
  final Color tonal;

  /// Content colour on [tonal].
  final Color onTonal;

  /// Deep ink surface reserved for the Secure Folder card and lock screens,
  /// so "private" always looks the same everywhere in the app.
  final Color vault;
  final Color onVault;

  static const FvTokens light = FvTokens(
    chipFill: AppColors.lightChipFill,
    chipText: AppColors.lightChipText,
    amber: AppColors.lightAmber,
    onAmber: AppColors.lightOnSecondaryFixed,
    cardBorder: AppColors.lightCardBorder,
    ambientShadow: BoxShadow(
      color: Color(0x1418212B),
      blurRadius: 18,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
    fabShadow: BoxShadow(
      color: Color(0x330B6E99),
      blurRadius: 18,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
    selectedRow: AppColors.lightPrimaryFixed,
    success: Color(0xFF1F8A4C),
    tonal: AppColors.lightPrimaryFixed,
    onTonal: AppColors.lightPrimary,
    vault: Color(0xFF12324A),
    onVault: Color(0xFFFFFFFF),
  );

  static const FvTokens dark = FvTokens(
    chipFill: AppColors.darkChipFill,
    chipText: AppColors.darkChipText,
    amber: AppColors.darkAmber,
    onAmber: AppColors.darkOnSecondaryFixed,
    cardBorder: AppColors.darkCardBorder,
    ambientShadow: BoxShadow(
      color: Color(0x8C000000),
      blurRadius: 22,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
    fabShadow: BoxShadow(
      color: Color(0x59000000),
      blurRadius: 18,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
    selectedRow: Color(0xFF173445),
    success: Color(0xFF5BD18B),
    tonal: Color(0xFF173445),
    onTonal: AppColors.darkPrimary,
    vault: Color(0xFF14354C),
    onVault: Color(0xFFFFFFFF),
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
    Color? tonal,
    Color? onTonal,
    Color? vault,
    Color? onVault,
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
      tonal: tonal ?? this.tonal,
      onTonal: onTonal ?? this.onTonal,
      vault: vault ?? this.vault,
      onVault: onVault ?? this.onVault,
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
      tonal: Color.lerp(tonal, other.tonal, t)!,
      onTonal: Color.lerp(onTonal, other.onTonal, t)!,
      vault: Color.lerp(vault, other.vault, t)!,
      onVault: Color.lerp(onVault, other.onVault, t)!,
    );
  }
}

/// Builds Material 3 themes mapped onto the design tokens.
abstract final class AppTheme {
  static ThemeData light({int? accentArgb}) {
    final ColorScheme scheme = _lightScheme(accentArgb);
    return _build(
      scheme: scheme,
      tokens: FvTokens.light.copyWith(
        tonal: Color.lerp(scheme.primaryContainer, Colors.white, 0.86),
        onTonal: scheme.primary,
        selectedRow: Color.lerp(scheme.primaryContainer, Colors.white, 0.86),
      ),
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
      tokens: FvTokens.dark.copyWith(
        tonal: Color.lerp(scheme.primaryContainer, AppColors.darkSurface, 0.6),
        onTonal: scheme.primary,
        selectedRow: Color.lerp(scheme.primaryContainer, AppColors.darkSurface, 0.6),
      ),
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
      // Button labels: white on every fill, and white for text/outlined
      // buttons in the dark theme so every button reads clearly at night.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.10),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: isDark ? scheme.outline : scheme.outlineVariant, width: 1.2),
          foregroundColor: isDark ? Colors.white : scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: isDark ? Colors.white : scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        sizeConstraints: BoxConstraints.tight(const Size(58, 58)),
        extendedTextStyle: textTheme.labelLarge,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.cardBorder, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
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
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
          selectedForegroundColor: Colors.white,
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
        ? Color.lerp(accent, Colors.white, 0.5)!
        : AppColors.darkPrimary;
    // Strong enough for white labels (WCAG AA) but not neon on dark.
    final Color primaryContainer = custom
        ? Color.lerp(accent, Colors.black, 0.12)!
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
