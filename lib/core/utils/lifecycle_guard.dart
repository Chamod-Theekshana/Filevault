/// Marks periods in which FileVault itself sends the app to the background –
/// the system biometric prompt being the main case – so App Lock and the
/// Secure Folder auto-lock do not treat that as the user leaving the app.
abstract final class LifecycleGuard {
  static int _depth = 0;

  static bool get active => _depth > 0;

  /// Runs [body] with the guard raised. The guard stays up briefly after
  /// [body] completes because the "resumed" lifecycle event can arrive a few
  /// frames after the prompt has already returned its result.
  static Future<T> run<T>(Future<T> Function() body) async {
    _depth++;
    try {
      return await body();
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (_depth > 0) _depth--;
      });
    }
  }
}
