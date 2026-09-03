class ApiException implements Exception {
  ApiException(String message, {this.statusCode})
      : message = userFacingMessage(message);

  final String message;
  final int? statusCode;

  /// Map raw API / Mongo dumps to short UI copy.
  static String userFacingMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Something went wrong. Please try again.';

    final lower = trimmed.toLowerCase();
    if (lower.contains('extract geo') ||
        lower.contains('out of bounds') ||
        lower.contains('longitude/latitude') ||
        lower.contains("can't extract geo") ||
        lower.contains('unable to extract geo')) {
      return 'Your location looks invalid. Turn on GPS and try again.';
    }
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('failed host lookup')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (trimmed.length > 140) {
      return 'Something went wrong. Please try again.';
    }
    return trimmed;
  }

  /// Safe copy for snackbars from any thrown object.
  static String fromError(Object error) {
    if (error is ApiException) return error.message;
    return userFacingMessage(error.toString());
  }

  @override
  String toString() => message;
}
