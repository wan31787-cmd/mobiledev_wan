import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // 🔹 เริ่มต้นระบบแจ้งเตือน
  static Future<void> init() async {
    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      // ✅ ขอสิทธิ์แจ้งเตือน Android 13+
      var notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          print('⚠️ ผู้ใช้ไม่อนุญาตให้แจ้งเตือน');
        }
      }

      // ✅ ขอสิทธิ์ exact alarm (Android 12+)
      var exactStatus = await Permission.scheduleExactAlarm.status;
      if (!exactStatus.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        if (!result.isGranted) {
          print('⚠️ ผู้ใช้ไม่อนุญาต Exact Alarm — การแจ้งเตือนอาจไม่ตรงเวลา');
        }
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          final id = details.payload!;
          final actionId = details.actionId;

          print('📬 รับแจ้งเตือน payload: $id, action: $actionId');

          if (actionId == 'TAKEN') {
            print('✅ ผู้ใช้กดยืนยันว่า “ทานยาแล้ว” ($id)');
          } else if (actionId == 'NOT_TAKEN') {
            print('⚠️ ผู้ใช้กดว่า “ยังไม่ได้ทานยา” ($id)');
          }
        }
      },
    );
  }

  // 🔹 ตรวจสอบสถานะสิทธิ์
  static Future<bool> checkCriticalPermissions() async {
    if (Platform.isAndroid) {
      final notifGranted = await Permission.notification.isGranted;
      final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
      if (!notifGranted) print('⚠️ ยังไม่ได้รับสิทธิ์ Notification');
      if (!exactAlarmGranted) print('⚠️ ยังไม่ได้รับสิทธิ์ Exact Alarm');
      return notifGranted && exactAlarmGranted;
    }
    return true;
  }

  // 🔹 แจ้งเตือน "ทานยา"
  static Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String payload = '',
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('❌ ข้ามแจ้งเตือน เพราะเวลาที่ตั้งไว้อยู่ในอดีต (ID: $id)');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'แจ้งเตือนการทานยา',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'TAKEN',
              'ทานยาแล้ว',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'NOT_TAKEN',
              'ยังไม่ได้ทาน',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('💊 ตั้งแจ้งเตือนยา ID: $id เวลา: $tzDateTime');
  }

  // 🔹 แจ้งเตือน "นัดหมาย"
  static Future<void> scheduleAppointmentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String payload = '',
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      print('❌ ข้ามแจ้งเตือน เพราะเวลาที่ตั้งไว้อยู่ในอดีต (ID: $id)');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointment Reminders',
          channelDescription: 'แจ้งเตือนการนัดหมาย',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('📅 ตั้งแจ้งเตือนนัดหมาย ID: $id เวลา: $tzDateTime');
  }

  // 🔹 แสดงแจ้งเตือนแบบทันที (ใช้ตอน FCM หรือปุ่มทดสอบ)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'firebase_channel',
      'Firebase Notifications',
      channelDescription: 'แจ้งเตือนจาก Firebase',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    print('📢 แสดงการแจ้งเตือนทันที: $title');
  }

  // 🔹 ยกเลิกแจ้งเตือนตาม ID
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑 ยกเลิกแจ้งเตือน ID: $id');
  }

  // 🔹 ยกเลิกการแจ้งเตือนทั้งหมด
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🧹 ล้างแจ้งเตือนทั้งหมดแล้ว');
  }
}
