import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the splash screen has finished loading the app's data. The App
/// Lock overlay waits for it so the splash is never covered mid-load.
final StateProvider<bool> appReadyProvider = StateProvider<bool>((Ref ref) => false);
