import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/firestore_api.dart';
import 'login_page.dart';
import 'main_mobile.dart';

/// 🧩 ฟังก์ชันรับข้อความ FCM ตอนอยู่เบื้องหลัง
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showNotification(
    title: message.notification?.title ?? 'การแจ้งเตือนใหม่',
    body: message.notification?.body ?? 'คุณมีข้อความใหม่',
  );
}

/// 🔔 ดึงข้อมูลจาก Firestore แล้วตั้งเวลาแจ้งเตือน
Future<void> scheduleRemindersFromFirestore(String username) async {
  final meds = await FirestoreAPI.getMedications(username);
  for (var med in meds) {
    final notifyTimeStr = med['notifyTime'] ?? '';
    if (notifyTimeStr.isEmpty) continue;

    DateTime? notifyTime;
    try {
      notifyTime = DateTime.parse(notifyTimeStr);
    } catch (_) {
      debugPrint('⚠️ Error parsing notifyTime: $notifyTimeStr. Skipping reminder.');
      continue;
    }

    await NotificationService.scheduleMedicationNotification(
      id: med['id'].hashCode,
      title: 'ถึงเวลาทานยา: ${med['name']}',
      body: 'กรุณากดเพื่อยืนยันว่าทานแล้ว ✅',
      scheduledTime: notifyTime,
      payload: med['id'],
    );
  }

  final apps = await FirestoreAPI.getAppointments(username);
  for (var app in apps) {
    final date = app['date'] is DateTime
        ? app['date']
        : DateTime.tryParse(app['date'].toString()) ?? DateTime.now();

    await NotificationService.scheduleAppointmentNotification(
      id: app['id'].hashCode,
      title: 'ถึงเวลานัดหมาย: ${app['title']}',
      body: 'อย่าลืมไปตามนัดหมายของคุณนะ!',
      scheduledTime: date,
      payload: app['id'],
    );
  }

  debugPrint('✅ All reminders from Firestore scheduled.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1. ตั้งค่า Timezone
  tz.initializeTimeZones();

  // ✅ 2. เริ่มต้น Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ 3. ตั้งค่า Notification Service
  await NotificationService.init();

  // ✅ 4. ขอสิทธิ์แจ้งเตือนพื้นฐาน
  await NotificationService.requestCrucialPermissions();

  // ✅ 5. ขอสิทธิ์แจ้งเตือนเพิ่มเติม (Android 13+)
  final status = await Permission.notification.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    debugPrint('⚠️ ผู้ใช้ยังไม่อนุญาตการแจ้งเตือน');
  }

  // ✅ 6. ตั้งค่า Firebase Messaging (FCM)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      NotificationService.showNotification(
        title: notification.title ?? 'แจ้งเตือน',
        body: notification.body ?? '',
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📩 ผู้ใช้กดแจ้งเตือน: ${message.notification?.title}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 🔔 ปุ่มทดสอบแจ้งเตือน
  Future<void> _showTestNotification() async {
    await NotificationService.scheduleMedicationNotification(
      id: 9999,
      title: '🔔 แจ้งเตือนทดสอบ',
      body: 'ระบบแจ้งเตือนทำงานได้แล้ว! ✅',
      scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
      payload: 'TEST_DOC_ID_001',
    );
  }

  /// ✅ เมื่อผู้ใช้ล็อกอินสำเร็จ
  void _onUserLogin(BuildContext context, String username) async {
    await scheduleRemindersFromFirestore(username);

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainMobile(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'แอปช่วยแจ้งเตือนการรักษา',
      home: Builder(
        builder: (innerContext) => Scaffold(
          appBar: AppBar(
            title: const Text('Medication App'),
            backgroundColor: Colors.green,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                onPressed: _showTestNotification,
              ),
            ],
          ),
          body: LoginPage(
            onLoginSuccess: (username) {
              _onUserLogin(innerContext, username);
            },
          ),
        ),
      ),
    );
  }
}
