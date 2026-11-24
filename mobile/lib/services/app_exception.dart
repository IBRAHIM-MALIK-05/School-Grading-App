// lib/services/app_exception.dart
// One error type for the whole app.
// statusCode follows HTTP: 400 bad input, 401 not logged in / wrong password,
// 403 not allowed, 404 not found, 409 conflict (e.g. class is locked).
// 0 = no answer from the server (API off / no internet / timeout).
// ApiDataService turns every failed request into one of these,
// so all screens show errors the same way.

class AppException implements Exception {
  final int statusCode;
  final String message;

  AppException(this.statusCode, this.message);

  @override
  String toString() => message;
}
