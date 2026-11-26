// lib/services/local_alerts.dart
// Real pop-up alerts (Android / iOS notification, Windows toast, browser notification)
// with the flutter_local_notifications package. NO Firebase: the app itself shows the popup
// when the 30-second check (notification_center.dart) finds a new notification.
//
// Web safety:
//  - Only show() is used. zonedSchedule() (scheduled alerts) is NOT used: it does not work on web,
//    and the server already decides WHEN a reminder is due.
//  - The browser only asks "Allow notifications?" after the teacher presses
//    "Enable Browser Alerts" (browsers block permission requests without a click).
//  - Every call is inside try/catch: if alerts are blocked or not supported, the in-app
//    bell + message still work.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum AlertStatus { unsupported, off, on, blocked }

class LocalAlerts {
  LocalAlerts._();
  static final LocalAlerts instance = LocalAlerts._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _enabled = false;

  static const _settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    // false = do not ask at start-up; we ask when the teacher presses "Enable"
    iOS: DarwinInitializationSettings(
        requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    macOS: DarwinInitializationSettings(
        requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
    linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    windows: WindowsInitializationSettings(
      appName: 'School Grading App',
      appUserModelId: 'SchoolGrading.App',
      guid: '6f1d9b52-3c2e-4b7a-9d0e-5a8c4f2b1e73',
    ),
    web: WebInitializationSettings(),
  );

  WebFlutterLocalNotificationsPlugin? get _web =>
      _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>();

  bool get isSupported {
    if (kIsWeb) return WebFlutterLocalNotificationsPlugin.isSupported;
    return true; // Android, iOS, macOS, Windows, Linux
  }

  AlertStatus get status {
    if (!isSupported) return AlertStatus.unsupported;
    if (_enabled) return AlertStatus.on;
    if (kIsWeb) {
      try {
        if (_web?.permissionStatus == WebNotificationPermission.denied) return AlertStatus.blocked;
      } catch (_) {
        return AlertStatus.unsupported;
      }
    }
    return AlertStatus.off;
  }

  Future<bool> _initialize() async {
    if (_initialized) return true;
    _initialized = await _plugin.initialize(settings: _settings) ?? false;
    return _initialized;
  }

  // At login: switch alerts on WITHOUT asking, if the browser / phone already allowed them.
  Future<void> enableIfAlreadyAllowed() async {
    if (!isSupported || _enabled) return;
    try {
      if (kIsWeb) {
        if (_web?.permissionStatus == WebNotificationPermission.granted) {
          _enabled = await _initialize();
        }
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _initialize();
        final android =
            _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        _enabled = await android?.areNotificationsEnabled() ?? false;
      }
    } catch (_) {
      _enabled = false; // the in-app bell still works
    }
  }

  // Called ONLY from the "Enable ... Alerts" button (a real user click).
  // Returns true when pop-ups are now allowed.
  Future<bool> enable() async {
    if (!isSupported) return false;
    try {
      if (kIsWeb) {
        // Ask first (still inside the click), then register the notification service worker
        final allowed = await _web?.requestNotificationsPermission() ?? false;
        _enabled = allowed && await _initialize();
      } else {
        await _initialize();
        bool allowed = true;
        if (defaultTargetPlatform == TargetPlatform.android) {
          allowed = await _plugin
                  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                  ?.requestNotificationsPermission() ??
              false;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          allowed = await _plugin
                  .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true, badge: true) ??
              false;
        } else if (defaultTargetPlatform == TargetPlatform.macOS) {
          allowed = await _plugin
                  .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
                  ?.requestPermissions(alert: true, sound: true, badge: true) ??
              false;
        }
        _enabled = allowed && _initialized;
      }
    } catch (_) {
      _enabled = false;
    }
    return _enabled;
  }

  // Shows ONE pop-up straight away (never scheduled). Does nothing if alerts are off.
  Future<void> show({required int id, required String title, required String body, bool urgent = false}) async {
    if (!_enabled) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'marks_reminders',
            'Marks reminders',
            channelDescription: 'Class Teacher reminders and Result Date alerts',
            importance: urgent ? Importance.max : Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
          linux: const LinuxNotificationDetails(),
          windows: const WindowsNotificationDetails(),
          web: WebNotificationDetails(requireInteraction: urgent),
        ),
      );
    } catch (_) {
      // blocked / unsupported: the in-app bell and message are enough
    }
  }
}
