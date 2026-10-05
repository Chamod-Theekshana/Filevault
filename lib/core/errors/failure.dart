import 'dart:io';

/// Domain-level failure. UI layers map these to localized messages and never
/// see raw exceptions.
sealed class Failure {
  const Failure({this.message});

  final String? message;

  /// Translate a thrown [Object] into a typed [Failure].
  static Failure fromException(Object error, {String? path}) {
    if (error is Failure) return error;
    if (error is FileSystemException) {
      final int code = error.osError?.errorCode ?? -1;
      final String p = path ?? error.path ?? '';
      return switch (code) {
        1 || 13 => PermissionFailure(path: p, message: error.message),
        2 => NotFoundFailure(path: p, message: error.message),
        17 => AlreadyExistsFailure(path: p, message: error.message),
        28 => DiskFullFailure(path: p, message: error.message),
        36 => NameTooLongFailure(path: p, message: error.message),
        18 => CrossDeviceFailure(path: p, message: error.message),
        _ => IoFailure(path: p, message: error.message),
      };
    }
    return UnknownFailure(message: error.toString());
  }
}

final class PermissionFailure extends Failure {
  const PermissionFailure({this.path, super.message});
  final String? path;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({this.path, super.message});
  final String? path;
}

final class AlreadyExistsFailure extends Failure {
  const AlreadyExistsFailure({this.path, super.message});
  final String? path;
}

final class DiskFullFailure extends Failure {
  const DiskFullFailure({this.path, super.message});
  final String? path;
}

final class NameTooLongFailure extends Failure {
  const NameTooLongFailure({this.path, super.message});
  final String? path;
}

final class CrossDeviceFailure extends Failure {
  const CrossDeviceFailure({this.path, super.message});
  final String? path;
}

final class InvalidNameFailure extends Failure {
  const InvalidNameFailure({super.message});
}

final class IoFailure extends Failure {
  const IoFailure({this.path, super.message});
  final String? path;
}

final class CancelledFailure extends Failure {
  const CancelledFailure() : super(message: 'cancelled');
}

final class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure({super.message});
}

final class WrongPasswordFailure extends Failure {
  const WrongPasswordFailure({super.message});
}

/// Too many wrong PIN attempts; try again after [secondsRemaining].
final class VaultLockedFailure extends Failure {
  const VaultLockedFailure({required this.secondsRemaining, super.message});
  final int secondsRemaining;
}

/// Wrong PIN; [attemptsLeft] before a cooldown kicks in.
final class WrongPinFailure extends Failure {
  const WrongPinFailure({required this.attemptsLeft, super.message});
  final int attemptsLeft;
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message});
}
