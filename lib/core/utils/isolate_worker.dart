import 'dart:async';
import 'dart:isolate';

import 'package:filevault/core/errors/failure.dart';

/// Cooperative cancellation flag shared between a caller and a long task.
class CancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final void Function() l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void throwIfCancelled() {
    if (_cancelled) throw const CancelledFailure();
  }
}

/// Lets a long-running loop be paused and resumed cooperatively.
class PauseGate {
  Completer<void>? _blocked;

  bool get isPaused => _blocked != null;

  void pause() {
    _blocked ??= Completer<void>();
  }

  void resume() {
    final Completer<void>? c = _blocked;
    _blocked = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Returns immediately unless paused, in which case it waits for [resume].
  Future<void> wait() {
    final Completer<void>? c = _blocked;
    return c == null ? Future<void>.value() : c.future;
  }
}

/// Progress callback: [fraction] is 0..1, [label] is free text (current file).
typedef ProgressCallback = void Function(double fraction, String? label);

/// Context handed to a job running inside a worker isolate.
class WorkerContext {
  WorkerContext._(this._port);

  final SendPort _port;
  bool _cancelled = false;
  double _lastFraction = -1;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isCancelled => _cancelled;

  /// Report progress to the caller. Throttled so UI updates stay cheap.
  void report(double fraction, [String? label]) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < 120 && fraction < 1) {
      return;
    }
    _lastFraction = fraction;
    _lastSent = now;
    _port.send(_ProgressMsg(fraction.clamp(0.0, 1.0), label));
  }

  /// Yields to the event loop so cancellation messages can arrive, then
  /// throws [CancelledFailure] if the caller cancelled.
  Future<void> checkpoint() async {
    await Future<void>.delayed(Duration.zero);
    if (_cancelled) throw const CancelledFailure();
  }
}

class _ProgressMsg {
  const _ProgressMsg(this.fraction, this.label);
  final double fraction;
  final String? label;
}

class _DoneMsg {
  const _DoneMsg(this.result);
  final Object? result;
}

class _ErrorMsg {
  const _ErrorMsg(this.error, this.stack);
  final Object error;
  final String stack;
}

typedef _UntypedJob = Future<Object?> Function(Object? args, WorkerContext ctx);

class _WorkerInit {
  const _WorkerInit(this.replyTo, this.args, this.job);
  final SendPort replyTo;
  final Object? args;
  final _UntypedJob job;
}

/// Wraps a typed job in a closure whose only captured variable is the job
/// itself, which keeps the message sendable across isolates.
_UntypedJob _wrapJob<A, R>(Future<R> Function(A args, WorkerContext ctx) job) {
  return (Object? a, WorkerContext ctx) => job(a as A, ctx);
}

Future<void> _workerEntry(_WorkerInit init) async {
  final ReceivePort control = ReceivePort();
  final WorkerContext ctx = WorkerContext._(init.replyTo);
  control.listen((dynamic message) {
    if (message == 'cancel') ctx._cancelled = true;
  });
  init.replyTo.send(control.sendPort);
  try {
    final Object? result = await init.job(init.args, ctx);
    init.replyTo.send(_DoneMsg(result));
  } catch (error, stack) {
    // Map I/O errors to typed failures inside the worker so "disk full" or
    // "permission denied" survive the trip back to the UI.
    final Failure payload = Failure.fromException(error);
    init.replyTo.send(_ErrorMsg(payload, stack.toString()));
  } finally {
    control.close();
  }
}

/// Runs CPU-heavy work (hashing, archiving, encryption) off the UI isolate
/// with progress reporting and cooperative cancellation.
///
/// [job] must be a top-level or static function and [args] must be sendable
/// (plain data), because both are copied into the worker isolate.
abstract final class IsolateWorker {
  static Future<R> run<A, R>(
    A args,
    Future<R> Function(A args, WorkerContext ctx) job, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    String debugName = 'filevault-worker',
  }) async {
    final ReceivePort receive = ReceivePort();
    final Completer<R> completer = Completer<R>();
    SendPort? control;
    bool cancelRequested = cancelToken?.isCancelled ?? false;

    void forwardCancel() {
      cancelRequested = true;
      control?.send('cancel');
    }

    cancelToken?.addListener(forwardCancel);

    final StreamSubscription<dynamic> sub = receive.listen((dynamic message) {
      if (message is SendPort) {
        control = message;
        if (cancelRequested) control!.send('cancel');
      } else if (message is _ProgressMsg) {
        onProgress?.call(message.fraction, message.label);
      } else if (message is _DoneMsg) {
        if (!completer.isCompleted) completer.complete(message.result as R);
      } else if (message is _ErrorMsg) {
        if (!completer.isCompleted) {
          final Object error = message.error;
          completer.completeError(
            error is Failure ? error : UnknownFailure(message: error.toString()),
            StackTrace.fromString(message.stack),
          );
        }
      }
    });

    // If the worker dies without replying (OOM, uncaught error) these ports
    // complete the future instead of leaving the caller hanging forever.
    final ReceivePort exitPort = ReceivePort();
    final ReceivePort errorPort = ReceivePort();
    exitPort.listen((dynamic _) {
      if (!completer.isCompleted) {
        completer.completeError(
          const UnknownFailure(message: 'Worker isolate exited unexpectedly'),
        );
      }
    });
    errorPort.listen((dynamic message) {
      if (completer.isCompleted) return;
      final String text = message is List && message.isNotEmpty
          ? message.first.toString()
          : message.toString();
      completer.completeError(UnknownFailure(message: text));
    });

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<_WorkerInit>(
        _workerEntry,
        _WorkerInit(receive.sendPort, args, _wrapJob<A, R>(job)),
        debugName: debugName,
        errorsAreFatal: true,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
      );
      return await completer.future;
    } finally {
      cancelToken?.removeListener(forwardCancel);
      await sub.cancel();
      receive.close();
      exitPort.close();
      errorPort.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }
}
