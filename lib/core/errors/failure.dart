/// Domain failures. UI must consume these instead of raw exceptions.
sealed class Failure {
  const Failure({this.message});

  final String? message;
}

final class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({super.message});
}

final class PermanentlyDeniedFailure extends Failure {
  const PermanentlyDeniedFailure({super.message});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.path, super.message});

  final String path;
}

final class DiskFullFailure extends Failure {
  const DiskFullFailure({super.message});
}

final class NameTooLongFailure extends Failure {
  const NameTooLongFailure({required this.name, super.message});

  final String name;
}

final class IoFailure extends Failure {
  const IoFailure({required String message}) : super(message: message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure({required String message}) : super(message: message);
}
