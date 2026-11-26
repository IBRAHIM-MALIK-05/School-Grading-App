// lib/services/notification_center.dart
// Keeps the Notification Bell up to date for a logged-in Teacher.
//  - start(): right after login, then every 30 seconds -> GET /api/notifications
//    (the server also runs the automatic Result Date check at that moment, no cron job)
//  - a notification that was not seen before in this session -> pop-up alert
//    (local_alerts.dart) + an in-app message on the screen (onNew)
//  - stop(): on logout / when the teacher home screen is closed -> the timer is cancelled
// The bell and the Notifications screen listen to it (ChangeNotifier) and redraw by themselves.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'current_service.dart';
import 'local_alerts.dart';

class NotificationCenter extends ChangeNotifier {
  static const pollEvery = Duration(seconds: 30);

  Timer? _timer;
  int _session = 0; // changes on start/stop, so an old answer after logout is ignored
  final Set<int> _alerted = {}; // ids already shown as a pop-up in this session

  NotificationInbox inbox = NotificationInbox.empty;

  // The teacher home screen sets this to show an in-app message for new notifications
  void Function(List<AppNotification> fresh)? onNew;

  int get unreadCount => inbox.unreadCount;

  void start() {
    stop();
    _session++;
    LocalAlerts.instance.enableIfAlreadyAllowed();
    refresh();
    _timer = Timer.periodic(pollEvery, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _session++;
    _alerted.clear();
    inbox = NotificationInbox.empty;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (dataService.currentUser == null) return;
    final session = _session;
    try {
      final latest = await dataService.getNotifications();
      if (session != _session) return; // logged out meanwhile
      inbox = latest;
      notifyListeners();

      final fresh = latest.items.where((n) => !n.isRead && !_alerted.contains(n.id)).toList();
      if (fresh.isEmpty) return;
      _alerted.addAll(fresh.map((n) => n.id));
      for (final n in fresh.take(3)) {
        await LocalAlerts.instance.show(id: n.id, title: n.title, body: n.message, urgent: n.isUrgent);
      }
      onNew?.call(fresh);
    } catch (_) {
      // No connection / server asleep: keep the old list, try again in 30 seconds
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    // Show it as read at once, then tell the server
    inbox = NotificationInbox(
      unreadCount: inbox.unreadCount > 0 ? inbox.unreadCount - 1 : 0,
      resultDate: inbox.resultDate,
      daysRemaining: inbox.daysRemaining,
      items: [for (final x in inbox.items) x.id == n.id ? x.markedRead() : x],
    );
    notifyListeners();
    await dataService.markNotificationRead(n.id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await dataService.markAllNotificationsRead();
    await refresh();
  }
}

final NotificationCenter notificationCenter = NotificationCenter();
