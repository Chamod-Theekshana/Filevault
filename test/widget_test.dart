import 'package:filevault/core/theme/app_theme.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, ThemeData theme) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Color? _resolve(WidgetStateProperty<Color?>? property) =>
    property?.resolve(const <WidgetState>{});

void main() {
  group('Dark theme buttons', () {
    final ThemeData dark = AppTheme.dark();

    test('filled, text and outlined button labels are white', () {
      expect(_resolve(dark.filledButtonTheme.style?.foregroundColor), Colors.white);
      expect(_resolve(dark.textButtonTheme.style?.foregroundColor), Colors.white);
      expect(_resolve(dark.outlinedButtonTheme.style?.foregroundColor), Colors.white);
    });

    test('content on the brand fill is white in both themes', () {
      expect(dark.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(AppTheme.light().colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(dark.floatingActionButtonTheme.foregroundColor, Colors.white);
    });

    test('custom accent colours keep white labels', () {
      final ThemeData custom = AppTheme.dark(accentArgb: 0xFFC2185B);
      expect(_resolve(custom.filledButtonTheme.style?.foregroundColor), Colors.white);
    });

    test('theme exposes the FileVault design tokens', () {
      final FvTokens? tokens = dark.extension<FvTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.onVault, const Color(0xFFFFFFFF));
    });
  });

  testWidgets('a filled button renders in the dark theme without errors', (WidgetTester tester) async {
    await tester.pumpWidget(_host(FilledButton(onPressed: () {}, child: const Text('Paste here')), AppTheme.dark()));
    expect(find.text('Paste here'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the brand mark uses the real app icon asset', (WidgetTester tester) async {
    await tester.pumpWidget(_host(const FvBrand(), AppTheme.light()));
    await tester.pump();
    final Image image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, FvAppIcon.asset);
    expect(find.text('FileVault'), findsOneWidget);
  });
}
