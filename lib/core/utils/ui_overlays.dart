import 'dart:async';

import 'package:flutter/widgets.dart';

/// Number of popup routes (dialogs, bottom sheets, menus) currently open in
/// any navigator. The global progress card hides while one is showing so it
/// never covers a sheet's buttons or a dialog.
final ValueNotifier<int> openPopupCount = ValueNotifier<int>(0);

/// Extra space (in logical pixels) that bottom bars – selection actions,
/// paste bar – currently occupy, so the progress card can sit above them.
final ValueNotifier<double> reservedBottomSpace = ValueNotifier<double>(0);

/// Keeps [openPopupCount] up to date. One instance per navigator.
class PopupTracker extends NavigatorObserver {
  void _changed(Route<dynamic>? route, int delta) {
    if (route is! PopupRoute<dynamic>) return;
    // Deferred: navigators can report removals in the middle of a build,
    // where notifying the progress card would be illegal.
    scheduleMicrotask(() {
      final int next = openPopupCount.value + delta;
      openPopupCount.value = next < 0 ? 0 : next;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _changed(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _changed(oldRoute, -1);
    _changed(newRoute, 1);
  }
}

/// Wrap a bottom bar with this to reserve its height for the progress card.
class ReserveBottomSpace extends StatefulWidget {
  const ReserveBottomSpace({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  State<ReserveBottomSpace> createState() => _ReserveBottomSpaceState();
}

class _ReserveBottomSpaceState extends State<ReserveBottomSpace> {
  static final Map<Object, double> _active = <Object, double>{};
  final Object _token = Object();

  static void _publish() {
    double max = 0;
    for (final double h in _active.values) {
      if (h > max) max = h;
    }
    reservedBottomSpace.value = max;
  }

  @override
  void initState() {
    super.initState();
    _active[_token] = widget.height;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void didUpdateWidget(ReserveBottomSpace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.height != widget.height) {
      _active[_token] = widget.height;
      WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
    }
  }

  @override
  void dispose() {
    _active.remove(_token);
    // Notifying listeners during tree teardown is not allowed; defer it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
