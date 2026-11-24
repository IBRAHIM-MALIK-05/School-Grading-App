// lib/models/json_helpers.dart
// The API saves dates in UTC (DateTime.UtcNow) and MySQL gives them back
// without a time zone, e.g. "2026-11-24T03:18:25". We mark them as UTC
// and convert to the phone's local time so the UI shows the right date.

DateTime? dateFromJson(dynamic value) {
  if (value == null) return null;
  var text = value as String;
  final hasZone = text.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(text);
  if (!hasZone) text = '${text}Z';
  return DateTime.parse(text).toLocal();
}

// JSON list -> list of models, e.g. listFromJson(json['students'], Student.fromJson)
List<T> listFromJson<T>(dynamic list, T Function(Map<String, dynamic>) fromJson) =>
    (list as List).map((item) => fromJson(item as Map<String, dynamic>)).toList();
