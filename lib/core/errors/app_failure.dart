enum FailureKind {
  permission,
  permissionPermanent,
  camera,
  image,
  format,
  processing,
  storage,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, this.message, [this.cause]);
  final FailureKind kind;
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}
