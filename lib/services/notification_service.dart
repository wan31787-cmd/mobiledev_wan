import 'dart:io';
import 'dart:async'; // ✅ เพิ่มสำหรับ Timer
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz; // ใช้ all เพื่อครอบคลุมเขตเวลา
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // ✅ เพิ่มสำหรับรูปแบบเวลา

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // 🔹 Channel IDs
  static const String medicationChannelId = 'medication_channel';
  static const String appointmentChannelId = 'appointment_channel';
  static const String firebaseChannelId = 'firebase_channel';

  // ✅ ตัวแปรจับเวลา (ใช้หยุดได้)
  static Timer? _clockTimer;

  // 🔹 เริ่มต้นระบบแจ้งเตือน
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok')); // ✅ ตั้งค่าเขตเวลาไทย

    if (Platform.isAndroid) {
      await _createAndroidNotificationChannels();
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    final initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(initSettings,
        onDidReceiveNotificationResponse: (details) async {
      if (details.payload != null) {
        final id = details.payload!;
        final actionId = details.actionId;
        debugPrint('📬 รับแจ้งเตือน payload: $id, action: $actionId');

        if (actionId == 'TAKEN') {
          debugPrint('✅ ผู้ใช้กดยืนยันว่า “ทานยาแล้ว” ($id)');
        } else if (actionId == 'NOT_TAKEN') {
          debugPrint('⚠️ ผู้ใช้กดว่า “ยังไม่ได้ทานยา” ($id)');
        }
      }
    });

    debugPrint('🌍 Timezone ปัจจุบัน: ${tz.local}');
  }

  // 🔹 สร้าง Notification Channels
  static Future<void> _createAndroidNotificationChannels() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return;

    const channels = [
      AndroidNotificationChannel(
        medicationChannelId,
        'Medication Reminders',
        description: 'แจ้งเตือนการทานยาตามกำหนดเวลา',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('default'),
      ),
      AndroidNotificationChannel(
        appointmentChannelId,
        'Appointment Reminders',
        description: 'แจ้งเตือนการนัดหมาย',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        firebaseChannelId,
        'Firebase Notifications',
        description: 'แจ้งเตือนทั่วไปจากระบบ Firebase',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await androidImpl.createNotificationChannel(channel);
    }
    debugPrint('📢 สร้าง Android Notification Channels สำเร็จ');
  }

  // 🔹 ขอสิทธิ์สำคัญทั้งหมด
  static Future<bool> requestCrucialPermissions() async {
    if (Platform.isIOS) return true;

    // 1️⃣ ขอสิทธิ์ Notification (Android 13+)
    PermissionStatus notifStatus = await Permission.notification.request();
    if (!notifStatus.isGranted) {
      debugPrint('❌ สิทธิ์ Notification ถูกปฏิเสธ');
      return false;
    }

    // 2️⃣ ขอสิทธิ์ Exact Alarm (Android 12+)
    PermissionStatus exactAlarmStatus =
        await Permission.scheduleExactAlarm.request();
    if (!exactAlarmStatus.isGranted) {
      debugPrint('⚠️ ผู้ใช้ยังไม่อนุญาต SCHEDULE_EXACT_ALARM');
      await openAppSettings();
      return false;
    }

    // 3️⃣ ขอสิทธิ์ Ignore Battery Optimization
    final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
    if (batteryStatus.isDenied) {
      debugPrint('⚠️ ผู้ใช้อาจเปิดโหมดประหยัดพลังงาน');
    }

    debugPrint('✅ ได้รับสิทธิ์ทั้งหมดเรียบร้อยแล้ว');
    return true;
  }

  // 🔹 ตรวจสอบสิทธิ์สำคัญ (กรณีต้องเช็กอย่างเดียว)
  static Future<bool> checkCriticalPermissions() async {
    if (Platform.isAndroid) {
      final notifGranted = await Permission.notification.isGranted;
      final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
      return notifGranted && exactAlarmGranted;
    }
    return true;
  }

  // 🔹 แจ้งเตือน “ทานยา”
  static Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String payload = '',
    bool playSound = true,
    String? sound,
  }) async {
    debugPrint('💊 ตั้งแจ้งเตือนยา ID: $id เวลา: $scheduledTime');

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ เวลานี้ผ่านไปแล้ว ไม่ตั้งแจ้งเตือน');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      medicationChannelId,
      'Medication Reminders',
      channelDescription: 'แจ้งเตือนการทานยา',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      sound:
          sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: true,
      actions: const [
        AndroidNotificationAction('TAKEN', 'ทานยาแล้ว',
            showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('NOT_TAKEN', 'ยังไม่ได้ทาน',
            showsUserInterface: true, cancelNotification: true),
      ],
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('✅ ตั้งแจ้งเตือนยาเรียบร้อย ID: $id');
  }

  // 🔹 แจ้งเตือน “นัดหมาย”
  static Future<void> scheduleAppointmentNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String payload = '',
    bool playSound = true,
    String? sound,
  }) async {
    debugPrint('📅 ตั้งแจ้งเตือนนัดหมาย ID: $id เวลา: $scheduledTime');

    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ เวลานี้ผ่านไปแล้ว ไม่ตั้งแจ้งเตือน');
      return;
    }

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      appointmentChannelId,
      'Appointment Reminders',
      channelDescription: 'แจ้งเตือนการนัดหมาย',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      sound:
          sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: true,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    debugPrint('✅ ตั้งแจ้งเตือนนัดหมายเรียบร้อย ID: $id');
  }

  // 🔹 แสดงแจ้งเตือนทันที
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool playSound = true,
    String? sound,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      firebaseChannelId,
      'Firebase Notifications',
      channelDescription: 'แจ้งเตือนทั่วไปจากระบบ Firebase',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      sound:
          sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: true,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );

    debugPrint('📢 แสดงแจ้งเตือนทันที: $title');
  }

  // 🔹 ยกเลิกแจ้งเตือน
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('🗑 ยกเลิกแจ้งเตือน ID: $id');
  }

  // 🔹 ยกเลิกทั้งหมด
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🧹 ล้างแจ้งเตือนทั้งหมดแล้ว');
  }

  // ✅ เพิ่มส่วน "จับเวลา" เพื่อทดสอบเวลาปัจจุบันทุก 1 วินาที
  static void startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final formattedTime = DateFormat('HH:mm:ss').format(now);
      debugPrint('⏰ เวลาปัจจุบัน: $formattedTime');
    });
    debugPrint('🕒 เริ่มจับเวลาอัปเดตทุก 1 วินาทีแล้ว');
  }

  static void stopClock() {
    _clockTimer?.cancel();
    debugPrint('🛑 หยุดจับเวลาแล้ว');
  }
}
