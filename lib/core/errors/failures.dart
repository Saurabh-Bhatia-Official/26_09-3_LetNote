/// Base failure class for Clean Architecture domain & data layers
abstract class Failure implements Exception {
  final String message;
  final dynamic error;

  const Failure(this.message, [this.error]);

  @override
  String toString() => '$runtimeType: $message${error != null ? ' ($error)' : ''}';
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.error]);
}

class CryptoFailure extends Failure {
  const CryptoFailure(super.message, [super.error]);
}

class BackupFailure extends Failure {
  const BackupFailure(super.message, [super.error]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.error]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.error]);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message, [super.error]);
}
