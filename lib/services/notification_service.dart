import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      // ✅ Runtime permission สำหรับแจ้งเตือน Android 13+
      var notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }

      // ✅ Runtime permission สำหรับ exact alarm Android 12+
      var exactStatus = await Permission.scheduleExactAlarm.status;
      if (!exactStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication Reminders',
          channelDescription: 'เตือนกินยา',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false, // ไม่มีเสียง
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
