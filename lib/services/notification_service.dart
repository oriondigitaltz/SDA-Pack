import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// One notification id per weekday: 1000 + DateTime.monday..sunday (1..7).
const int _kDevotionIdBase = 1000;

/// Local (on-device) daily devotion reminder. No backend involved:
/// the notification is scheduled with the OS alarm manager.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // Keep the default (UTC) location; times will still fire daily.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  /// Asks for notification permission where required (Android 13+/iOS).
  /// Returns true when notifications are allowed.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? true;
  }

  /// Schedules the reminder on the selected weekdays
  /// (DateTime.monday..sunday = 1..7). Days not selected are cancelled.
  Future<void> scheduleWeekly({
    required int hour,
    required int minute,
    required Set<int> weekdays,
  }) async {
    if (!_supported) return;
    await init();

    final now = tz.TZDateTime.now(tz.local);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      if (!weekdays.contains(weekday)) {
        await _plugin.cancel(_kDevotionIdBase + weekday);
        continue;
      }

      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _kDevotionIdBase + weekday,
        'Morning Devotion',
        'Your devotion for today is ready. Start your day with the Word.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_devotion',
            'Daily Devotion',
            channelDescription: 'Daily morning devotion reminder',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelDaily() async {
    if (!_supported) return;
    await init();
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(_kDevotionIdBase + weekday);
    }
  }
}

final NotificationService notificationService = NotificationService();
