import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/browser/browser_view.dart';
import 'features/operations/widgets/operation_progress_panel.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // The main content
          const BrowserView(),
          
          // The floating operation progress panel
          const OperationProgressPanel(),
        ],
      ),
    );
  }
}
