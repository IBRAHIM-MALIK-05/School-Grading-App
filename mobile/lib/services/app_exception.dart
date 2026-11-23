// lib/services/app_exception.dart
// One error type for the whole app.
// statusCode follows HTTP: 400 bad input, 401 not logged in / wrong password,
// 403 not allowed, 404 not found, 409 conflict (e.g. class is locked).
// The mock service throws it now; the real API service will throw it later,
// so screens handle errors the same way in both milestones.

class AppException implements Exception {
  final int statusCode;
  final String message;

  AppException(this.statusCode, this.message);

  @override
  String toString() => message;
}
