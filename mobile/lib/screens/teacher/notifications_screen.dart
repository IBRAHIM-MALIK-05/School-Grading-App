// lib/screens/teacher/notifications_screen.dart
// The Teacher's Notifications: unread first, then earlier ones.
//  - URGENT (2 days or less before the Result Date): red card
//  - Class Teacher reminders: "From Class Teacher" badge
//  - tap a card = Mark as Read, "Mark all read" in the AppBar
//  - "Enable Browser Alerts": asks for pop-up permission only after a real click (web safe)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/local_alerts.dart';
import '../../services/notification_center.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    notificationCenter.refresh(); // fresh list as soon as the screen opens
  }

  Future<void> _markAllRead() async {
    try {
      await notificationCenter.markAllRead();
      if (mounted) showMessage(context, 'All notifications marked as read.');
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  Future<void> _open(AppNotification n) async {
    try {
      await notificationCenter.markRead(n);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  Future<void> _enableAlerts() async {
    setState(() => _enabling = true);
    final on = await LocalAlerts.instance.enable();
    if (!mounted) return;
    setState(() => _enabling = false);
    showMessage(
      context,
      on
          ? 'Pop-up alerts are on. New notifications will pop up even in another tab.'
          : 'Pop-up alerts were not allowed. The bell in the app still shows every notification.',
      isError: !on,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationCenter,
      builder: (context, _) {
        final inbox = notificationCenter.inbox;
        final unread = inbox.items.where((n) => !n.isRead).toList();
        final earlier = inbox.items.where((n) => n.isRead).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              TextButton.icon(
                onPressed: inbox.unreadCount > 0 ? _markAllRead : null,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white, disabledForegroundColor: Colors.white38),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all read'),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: notificationCenter.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _alertsCard(),
                if (inbox.resultDate != null && (inbox.daysRemaining ?? -1) >= 0) _resultDateLine(inbox),
                const SizedBox(height: 8),
                if (inbox.items.isEmpty)
                  const EmptyView(message: 'No notifications yet.\nReminders about your marks will appear here.'),
                if (unread.isNotEmpty) _heading('Unread (${unread.length})'),
                for (final n in unread) _card(n),
                if (earlier.isNotEmpty) _heading('Earlier'),
                for (final n in earlier) _card(n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _resultDateLine(NotificationInbox inbox) {
    final urgent = (inbox.daysRemaining ?? 99) <= 2;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.event, size: 18, color: urgent ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Result Date: ${formatDay(inbox.resultDate!)}  •  ${daysLeftText(inbox.daysRemaining)}',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: urgent ? AppColors.danger : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // "Enable Browser Alerts" (or a short note if pop-ups are on / blocked / not available)
  Widget _alertsCard() {
    final status = LocalAlerts.instance.status;
    final where = kIsWeb ? 'Browser' : 'Pop-up';
    switch (status) {
      case AlertStatus.on:
        return _note(Icons.notifications_active, AppColors.success, '$where alerts are on.');
      case AlertStatus.blocked:
        return _note(Icons.notifications_off_outlined, AppColors.warning,
            '$where alerts are blocked in the browser settings. The bell still shows everything.');
      case AlertStatus.unsupported:
        return _note(Icons.info_outline, AppColors.muted,
            'Pop-up alerts are not available here. The bell still shows everything.');
      case AlertStatus.off:
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Get a pop-up when a reminder arrives',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Optional. Without it, new reminders still show on the bell.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _enabling ? null : _enableAlerts,
                    icon: const Icon(Icons.notifications_on_outlined, size: 18),
                    label: Text(kIsWeb ? 'Enable Desktop/Browser Alerts' : 'Enable Pop-up Alerts'),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _note(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color))),
          ],
        ),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      );

  Widget _card(AppNotification n) {
    final Color color;
    final IconData icon;
    final String badge;
    if (n.isUrgent) {
      color = AppColors.danger;
      icon = Icons.warning_amber_rounded;
      badge = 'URGENT';
    } else if (n.isClassTeacherReminder) {
      color = AppColors.primary;
      icon = Icons.campaign_outlined;
      badge = 'From Class Teacher';
    } else {
      color = AppColors.warning;
      icon = Icons.event_note;
      badge = 'Result Date';
    }

    return Card(
      color: n.isUrgent && !n.isRead ? const Color(0xFFFFEBEE) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: n.isRead ? Colors.black12 : color.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(n),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: n.isRead ? AppColors.muted : color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge(badge, color),
                        const Spacer(),
                        Text(formatTimestamp(n.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: n.isRead ? Colors.black87 : color)),
                    const SizedBox(height: 2),
                    Text(n.message, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(n.isRead ? 'Read' : 'Tap to mark as read',
                        style: TextStyle(
                            fontSize: 12,
                            color: n.isRead ? AppColors.muted : AppColors.primary,
                            fontStyle: n.isRead ? FontStyle.normal : FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
