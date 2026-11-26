// lib/models/app_notification.dart
// The Notification Bell (our own backend, no Firebase):
//  - AppNotification   : one message (Class Teacher reminder or automatic Result Date reminder)
//  - NotificationInbox : GET /api/notifications  { unreadCount, resultDate, daysRemaining, items }
//  - ResultDateInfo    : GET /api/settings/result-date (set by the Principal / VP)

import 'json_helpers.dart';

// The API sends a DateOnly as "2026-12-03" (a calendar day, no time and no time zone)
DateTime? dayFromJson(dynamic value) => value == null ? null : DateTime.parse(value as String);

// 2026-12-03 -> "2026-12-03" (what the API expects)
String dayToJson(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// "Sat 28 Nov 2026"
String formatDay(DateTime day) =>
    '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]} ${day.year}';

// "26 Nov, 11:58"
String formatTimestamp(DateTime t) =>
    '${t.day} ${_months[t.month - 1]}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// "7 days left" / "1 day left" / "Today" / "Passed"
String daysLeftText(int? days) {
  if (days == null) return '';
  if (days < 0) return 'Passed';
  if (days == 0) return 'Today';
  return days == 1 ? '1 day left' : '$days days left';
}

class AppNotification {
  static const classTeacherReminder = 'class_teacher_reminder';

  final int id;
  final String type; // class_teacher_reminder / deadline_one_week / deadline_daily / deadline_urgent
  final String title;
  final String message;
  final bool isUrgent;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName; // null = automatic reminder
  final int? assignmentId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isUrgent,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.assignmentId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        message: json['message'],
        isUrgent: json['isUrgent'] ?? false,
        isRead: json['isRead'] ?? false,
        createdAt: dateFromJson(json['createdAt'])!,
        senderName: json['senderName'],
        assignmentId: json['assignmentId'],
      );

  bool get isClassTeacherReminder => type == classTeacherReminder;
  bool get isDeadline => type.startsWith('deadline_');

  AppNotification markedRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        isUrgent: isUrgent,
        isRead: true,
        createdAt: createdAt,
        senderName: senderName,
        assignmentId: assignmentId,
      );
}

class NotificationInbox {
  final int unreadCount;
  final DateTime? resultDate;
  final int? daysRemaining;
  final List<AppNotification> items;

  const NotificationInbox({
    required this.unreadCount,
    this.resultDate,
    this.daysRemaining,
    required this.items,
  });

  static const empty = NotificationInbox(unreadCount: 0, items: []);

  factory NotificationInbox.fromJson(Map<String, dynamic> json) => NotificationInbox(
        unreadCount: json['unreadCount'] ?? 0,
        resultDate: dayFromJson(json['resultDate']),
        daysRemaining: json['daysRemaining'],
        items: listFromJson(json['items'], AppNotification.fromJson),
      );
}

class ResultDateInfo {
  final DateTime? resultDate; // null = not set yet
  final int? daysRemaining;
  final DateTime today; // the school's "today" (from the server)
  final String? updatedByName;

  const ResultDateInfo({this.resultDate, this.daysRemaining, required this.today, this.updatedByName});

  factory ResultDateInfo.fromJson(Map<String, dynamic> json) => ResultDateInfo(
        resultDate: dayFromJson(json['resultDate']),
        daysRemaining: json['daysRemaining'],
        today: dayFromJson(json['today'])!,
        updatedByName: json['updatedByName'],
      );

  bool get isSet => resultDate != null;
}
