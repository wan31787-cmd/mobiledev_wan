import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'firestore_api.dart';
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

/// 🔔 ฟังก์ชันดึงข้อมูลจาก Firestore แล้วตั้งเวลาแจ้งเตือน
Future<void> scheduleRemindersFromFirestore(String username) async {
  // ดึงรายการยา
  final meds = await FirestoreAPI.getMedications(username);
  for (var med in meds) {
    final notifyTimeStr = med['notifyTime'] ?? '';
    if (notifyTimeStr.isEmpty) continue;

    DateTime notifyTime;
    try {
      notifyTime = DateTime.parse(notifyTimeStr);
    } catch (_) {
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

  // ดึงรายการนัดหมาย
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

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize Notification Service
  await NotificationService.init();

  // ✅ ขอสิทธิ์แจ้งเตือน
  final status = await Permission.notification.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    debugPrint('⚠️ ผู้ใช้ยังไม่อนุญาตการแจ้งเตือน');
  }

  // ✅ ตั้งค่า FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ เมื่อแอปเปิดอยู่ (foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      NotificationService.showNotification(
        title: notification.title ?? 'แจ้งเตือน',
        body: notification.body ?? '',
      );
    }
  });

  // ✅ เมื่อผู้ใช้กดแจ้งเตือนเปิดแอปขึ้นมา
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📩 ผู้ใช้กดแจ้งเตือน: ${message.notification?.title}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ปุ่มทดสอบแจ้งเตือน (แจ้งเตือนใน 3 วินาที)
  Future<void> _showTestNotification() async {
    await NotificationService.scheduleMedicationNotification(
      id: 9999,
      title: '🔔 แจ้งเตือนทดสอบ',
      body: 'ระบบแจ้งเตือนทำงานได้แล้ว! ✅',
      scheduledTime: DateTime.now().add(const Duration(seconds: 3)),
      payload: 'TEST_DOC_ID_001',
    );
  }

  /// ✅ ฟังก์ชันเมื่อผู้ใช้ล็อกอินสำเร็จ
  void _onUserLogin(BuildContext context, String username, String email) async {
    await scheduleRemindersFromFirestore(username);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainMobile(username: username, email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'แอปช่วยแจ้งเตือนการรักษา',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Medication App'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: _showTestNotification, // ปุ่มทดสอบแจ้งเตือน
            ),
          ],
        ),
        body: LoginPage(
          onLoginSuccess: (username, email) =>
              _onUserLogin(context, username, email),
        ),
      ),
    );
  }
}
