import 'dart:async';

/// Delays a callback until input settles. Used by search-as-you-type.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}

/// Simple counting semaphore to cap concurrent thumbnail decoding.
class Semaphore {
  Semaphore(this._permits);

  int _permits;
  final List<Completer<void>> _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_permits > 0) {
      _permits--;
      return Future<void>.value();
    }
    final Completer<void> c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _permits++;
    }
  }
}
