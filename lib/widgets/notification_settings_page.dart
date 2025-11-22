import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// ✅ ตรวจสอบสิทธิ์แจ้งเตือนและ Exact Alarm
  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.isGranted;
    final alarm = await Permission.scheduleExactAlarm.isGranted;
    setState(() {
      _notificationGranted = notif;
      _exactAlarmGranted = alarm;
    });
  }

  /// ✅ ขอสิทธิ์การแจ้งเตือน
  Future<void> _openNotificationSettings() async {
    final result = await Permission.notification.request();
    if (result.isGranted) {
      setState(() => _notificationGranted = true);
    } else {
      await openAppSettings();
    }
  }

  /// ✅ เปิดหน้าตั้งค่าสำหรับ Exact Alarm
  Future<void> _openExactAlarmSettings() async {
    if (!(await Permission.scheduleExactAlarm.isGranted)) {
      await openAppSettings(); // พาผู้ใช้ไปเปิดใน Settings เอง
    } else {
      setState(() => _exactAlarmGranted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่าการแจ้งเตือน'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'โปรดตรวจสอบให้แน่ใจว่าเปิดสิทธิ์การแจ้งเตือนและสิทธิ์การตั้งเวลาแจ้งเตือน (Exact Alarm) '
            'เพื่อให้ระบบเตือนการทานยาและนัดหมายทำงานได้ถูกต้อง',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // 🔹 การตั้งค่าการแจ้งเตือน
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.teal),
              title: const Text('สิทธิ์การแจ้งเตือน (Notification Permission)'),
              subtitle: Text(_notificationGranted ? 'เปิดใช้งานแล้ว ✅' : 'ยังไม่ได้เปิด ❌'),
              trailing: ElevatedButton(
                onPressed: _openNotificationSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('จัดการ'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 🔹 การตั้งค่า Exact Alarm
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.alarm, color: Colors.orange),
              title: const Text('สิทธิ์ตั้งเวลาแจ้งเตือน (Exact Alarm Permission)'),
              subtitle: Text(_exactAlarmGranted ? 'เปิดใช้งานแล้ว ✅' : 'ยังไม่ได้เปิด ❌'),
              trailing: ElevatedButton(
                onPressed: _openExactAlarmSettings,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('เปิด Settings'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 🔹 ปุ่มตรวจสอบสิทธิ์อีกครั้ง
          ElevatedButton.icon(
            onPressed: _checkPermissions,
            icon: const Icon(Icons.refresh),
            label: const Text('ตรวจสอบสิทธิ์อีกครั้ง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}
