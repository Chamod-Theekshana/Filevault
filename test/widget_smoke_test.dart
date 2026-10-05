import 'package:filevault/core/theme/app_theme.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) {
  return ProviderScope(
    child: MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

FileEntry sample({bool dir = false}) => FileEntry(
      path: '/storage/emulated/0/Download/Quarterly_Report.pdf',
      name: dir ? 'Download' : 'Quarterly_Report.pdf',
      isDirectory: dir,
      size: 8_400_000,
      modified: DateTime(2024, 10, 21, 9, 15),
      category: dir ? FileCategory.folders : FileCategory.documents,
      extension: dir ? '' : 'pdf',
      childCount: dir ? 24 : null,
    );

void main() {
  testWidgets('file row shows the name and the size/date meta line', (WidgetTester tester) async {
    await tester.pumpWidget(host(FvFileListTile(entry: sample(), onTap: () {})));
    await tester.pump();
    expect(find.text('Quarterly_Report.pdf'), findsOneWidget);
    expect(find.textContaining('8.0 MB'), findsOneWidget);
  });

  testWidgets('folder row shows the item count', (WidgetTester tester) async {
    await tester.pumpWidget(host(FvFileListTile(entry: sample(dir: true), onTap: () {})));
    await tester.pump();
    expect(find.textContaining('24 items'), findsOneWidget);
  });

  testWidgets('selection circle toggles with the selected flag', (WidgetTester tester) async {
    await tester.pumpWidget(host(
      FvFileListTile(entry: sample(), selecting: true, selected: true, onTap: () {}),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('empty state renders its title, message and action', (WidgetTester tester) async {
    await tester.pumpWidget(host(
      FvEmptyState(
        icon: Icons.delete_outline,
        title: 'Trash is empty',
        message: 'Deleted files land here.',
        action: FvTonalButton(label: 'Browse files', onPressed: () {}),
      ),
    ));
    await tester.pump();
    expect(find.text('Trash is empty'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
  });

  testWidgets('dark theme builds the same widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      host(FvFileListTile(entry: sample(), onTap: () {}), brightness: Brightness.dark),
    );
    await tester.pump();
    expect(find.text('Quarterly_Report.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips and badges render', (WidgetTester tester) async {
    await tester.pumpWidget(host(
      Column(
        children: <Widget>[
          FvChip(label: 'Documents', icon: Icons.description_outlined, onTap: () {}),
          const FvCountBadge('156'),
          const FvSegmentedBar(segments: <(double, Color)>[(0.4, Colors.blue), (0.2, Colors.amber)]),
        ],
      ),
    ));
    await tester.pump();
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('156'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
