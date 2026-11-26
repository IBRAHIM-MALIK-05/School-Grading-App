// test/notification_model_test.dart
// Reads the JSON of GET /api/notifications and GET /api/settings/result-date into the models.
// Run:  flutter test test/notification_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:school_grading_app/models/app_notification.dart';

void main() {
  test('notification inbox is read from the API JSON', () {
    final inbox = NotificationInbox.fromJson({
      'unreadCount': 2,
      'resultDate': '2026-11-28',
      'daysRemaining': 2,
      'items': [
        {
          'id': 3,
          'type': 'deadline_urgent',
          'title': 'URGENT: Result Date in 2 days',
          'message': 'URGENT: Only 2 days remaining until Result Date (28 Nov 2026)!',
          'isUrgent': true,
          'isRead': false,
          'createdAt': '2026-11-26T06:58:22.98',
          'notificationDate': '2026-11-26',
          'senderName': null,
          'assignmentId': null,
        },
        {
          'id': 4,
          'type': 'class_teacher_reminder',
          'title': 'Marks Reminder — Class 8 - B (Physics)',
          'message': 'Teacher Sania, the Class Teacher of Class 8 - B, is waiting for your Physics marks.',
          'isUrgent': false,
          'isRead': true,
          'createdAt': '2026-11-26T07:00:00Z',
          'notificationDate': '2026-11-26',
          'senderName': 'Teacher Sania',
          'assignmentId': 8,
        },
      ],
    });

    expect(inbox.unreadCount, 2);
    expect(inbox.resultDate, DateTime(2026, 11, 28)); // a calendar day, no time zone shift
    expect(inbox.items.first.isUrgent, isTrue);
    expect(inbox.items.first.isDeadline, isTrue);
    expect(inbox.items.last.isClassTeacherReminder, isTrue);
    expect(inbox.items.last.senderName, 'Teacher Sania');
    expect(inbox.items.first.markedRead().isRead, isTrue);
  });

  test('result date helpers', () {
    final info = ResultDateInfo.fromJson(
        {'resultDate': null, 'daysRemaining': null, 'today': '2026-11-26', 'updatedByName': null});
    expect(info.isSet, isFalse);
    expect(dayToJson(DateTime(2026, 12, 3)), '2026-12-03');
    expect(formatDay(DateTime(2026, 11, 28)), 'Sat 28 Nov 2026');
    expect(daysLeftText(7), '7 days left');
    expect(daysLeftText(1), '1 day left');
    expect(daysLeftText(0), 'Today');
    expect(daysLeftText(-1), 'Passed');
  });
}
