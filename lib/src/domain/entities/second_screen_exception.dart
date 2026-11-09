/// Exception thrown when a secondary screen operation cannot be completed.
class SecondScreenException implements Exception {
  /// The native app runner has not been set up to register plugins on
  /// secondary window engines. See the package README "Platform Setup".
  static const String setupRequired = 'setup-required';

  /// The native window could not be created.
  static const String createFailed = 'create-failed';

  /// Machine-readable error code, one of the constants on this class.
  final String code;

  /// Human-readable description of the problem and how to fix it.
  final String message;

  const SecondScreenException(this.code, this.message);

  @override
  String toString() => 'SecondScreenException($code): $message';
}
