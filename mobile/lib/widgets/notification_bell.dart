// lib/widgets/notification_bell.dart
//  - NotificationBell : the bell in a Teacher's AppBar with a red unread-count badge
//  - ResultDateBanner : "Result Date: Sat 28 Nov 2026 - 2 days left" on the Teacher home screen
// Both redraw by themselves whenever notificationCenter gets new data (every 30 seconds).

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../screens/teacher/notifications_screen.dart';
import '../services/notification_center.dart';
import 'app_theme.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationCenter,
      builder: (context, _) {
        final count = notificationCenter.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            notificationCenter.refresh();
          },
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: AppColors.danger,
            label: Text(count > 99 ? '99+' : '$count'),
            child: Icon(count > 0 ? Icons.notifications_active : Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class ResultDateBanner extends StatelessWidget {
  const ResultDateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationCenter,
      builder: (context, _) {
        final inbox = notificationCenter.inbox;
        final date = inbox.resultDate;
        final days = inbox.daysRemaining;
        if (date == null || days == null || days < 0) return const SizedBox.shrink();

        final urgent = days <= 2;
        final color = urgent ? AppColors.danger : AppColors.primary;
        return Card(
          color: urgent ? const Color(0xFFFFEBEE) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: Icon(urgent ? Icons.warning_amber_rounded : Icons.event, color: color),
            title: Text('Result Date: ${formatDay(date)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            subtitle: Text(urgent
                ? '${daysLeftText(days)} - please submit all your marks now.'
                : '${daysLeftText(days)} - set by the Principal / VP.'),
          ),
        );
      },
    );
  }
}
