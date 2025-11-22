import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  String _statusMessage = '✨ ระบบพร้อมสำหรับการทดสอบแจ้งเตือน';
  bool _permissionsGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // ✅ ตรวจสอบสิทธิ์ Notification + Exact Alarm
  Future<void> _checkPermissions() async {
    final granted = await NotificationService.checkCriticalPermissions();
    setState(() {
      _permissionsGranted = granted;
      _statusMessage = granted
          ? '✅ ระบบพร้อมทำงาน — คุณอนุญาตสิทธิ์ครบแล้ว'
          : '🛑 สิทธิ์ไม่สมบูรณ์! โปรดอนุญาต Notification และ Exact Alarm';
    });
  }

  // 📢 แสดงแจ้งเตือนทันที (ให้ผู้ใช้เลือกประเภท)
  void _showInstantNotification() async {
    final selectedType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกประเภทการแจ้งเตือน'),
        content: const Text('กรุณาเลือกประเภทที่ต้องการทดสอบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'medication'),
            child: const Text('💊 ทดสอบแจ้งเตือนทานยา'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'appointment'),
            child: const Text('🩺 ทดสอบแจ้งเตือนนัดหมาย'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('❌ ยกเลิก'),
          ),
        ],
      ),
    );

    if (selectedType == null) return;

    if (selectedType == 'medication') {
      NotificationService.showNotification(
        title: '💊 ถึงเวลาทานยาแล้ว!',
        body: 'อย่าลืมทานยาของคุณให้ตรงเวลานะ 😊',
        payload: 'TEST_MEDICATION',
      );
      setState(() => _statusMessage = '📢 แสดงแจ้งเตือนประเภท "ทานยา" แล้ว');
    } else {
      NotificationService.showNotification(
        title: '🩺 การแจ้งเตือนนัดหมายแพทย์',
        body: 'คุณมีนัดกับแพทย์วันนี้ เวลา 14:00 น.',
        payload: 'TEST_APPOINTMENT',
      );
      setState(() => _statusMessage = '📢 แสดงแจ้งเตือนประเภท "นัดหมาย" แล้ว');
    }
  }

  // 🧹 ยกเลิกแจ้งเตือนทั้งหมด
  void _cancelAll() {
    NotificationService.cancelAllNotifications();
    setState(() => _statusMessage = '🧹 ยกเลิกแจ้งเตือนทั้งหมดแล้ว');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('🧪 ทดสอบระบบแจ้งเตือน'),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: _permissionsGranted ? Colors.lightBlue[100] : Colors.red[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 25),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionsGranted
                          ? '🔓 สถานะ: สิทธิ์สมบูรณ์'
                          : '🔒 สถานะ: สิทธิ์ไม่ครบ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _permissionsGranted ? Colors.blue[800] : Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14.5, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            // 💊 ปุ่มแสดงแจ้งเตือนทันที
            ElevatedButton.icon(
              onPressed: _permissionsGranted ? _showInstantNotification : null,
              icon: const Icon(Icons.flash_on),
              label: const Text('แสดงแจ้งเตือนทันที (เลือกประเภท)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            // ❌ ปุ่มยกเลิก
            OutlinedButton.icon(
              onPressed: _cancelAll,
              icon: const Icon(Icons.clear_all),
              label: const Text('ยกเลิกแจ้งเตือนทั้งหมด'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[800],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
