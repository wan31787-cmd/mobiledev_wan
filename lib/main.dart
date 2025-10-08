import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      var result = await Permission.notification.request();
      debugPrint('Notification permission: $result');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ขอ permission runtime
  await requestNotificationPermission();

  // init NotificationService
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Login',
      home: const LoginPage(),
    );
  }
}
