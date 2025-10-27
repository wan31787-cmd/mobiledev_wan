import 'package:flutter/material.dart';
import 'add_appointment_page.dart';
import '../firestore_api.dart';
import '../services/notification_service.dart';

class AppointmentsPage extends StatefulWidget {
  final String username;
  const AppointmentsPage({super.key, required this.username});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final appts = await FirestoreAPI.getAppointments(widget.username);

    // เรียงตามวันที่
    appts.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateA.compareTo(dateB);
    });

    setState(() => appointments = appts);

    // ตั้งแจ้งเตือนล่วงหน้า 1 วัน เวลา 09:00
    for (var appt in appts) {
      final DateTime date = appt['date'] as DateTime;
      DateTime scheduledTime = DateTime(
        date.year,
        date.month,
        date.day,
        9,
      ).subtract(const Duration(days: 1));

      if (scheduledTime.isBefore(DateTime.now())) continue;

      final int id = int.tryParse(appt['id'].toString()) ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // เรียกฟังก์ชัน notification แบบใหม่
      await NotificationService.scheduleAppointmentNotification(
        id: id,
        title: 'นัดหมาย: ${appt['title']}',
        body:
            'วันที่: ${date.day}/${date.month}/${date.year} เวลา ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
        scheduledTime: scheduledTime,
        payload: (appt['id'] != null ? appt['id'].toString() : ''),
      );
    }
  }

  void _navigateToAddAppointment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAppointmentPage(username: widget.username),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      await loadAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มนัดหมายเรียบร้อยแล้ว')),
      );
    }
  }

  void _editAppointment(int index) async {
    final appt = appointments[index];
    final titleController = TextEditingController(text: appt['title']);
    final locationController = TextEditingController(text: appt['location']);
    final departmentController =
        TextEditingController(text: appt['department'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขนัดหมาย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'หัวข้อ'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'สถานที่'),
            ),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: 'แผนก'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final updatedAppt = {
                'username': appt['username'],
                'title': titleController.text,
                'date': appt['date'],
                'doctor': appt['doctor'],
                'location': locationController.text,
                'department': departmentController.text,
                'preparation': appt['preparation'],
              };

              final success =
                  await FirestoreAPI.updateAppointment(appt['id'], updatedAppt);
              if (success) {
                await loadAppointments();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขนัดหมายเรียบร้อยแล้ว')),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เกิดข้อผิดพลาดในการแก้ไข')),
                );
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบนัดหมายนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final apptId = appointments[index]['id'];
              final success = await FirestoreAPI.deleteAppointment(apptId);
              if (success) {
                setState(() => appointments.removeAt(index));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบนัดหมายเรียบร้อยแล้ว')),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ')),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "รายการนัดหมาย",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    appointments.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'ยังไม่มีการนัดหมาย',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final appt = appointments[index];
                              final date = appt['date'] as DateTime;
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade200,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(
                                    appt['title'] ?? 'ไม่มีหัวข้อ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                          "วันที่: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"),
                                      Text("แพทย์: ${appt['doctor'] ?? ''}"),
                                      Text("แผนก: ${appt['department'] ?? '-'}"),
                                      Text("สถานที่: ${appt['location'] ?? ''}"),
                                      if (appt['preparation'] != null &&
                                          appt['preparation']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          "สิ่งที่ต้องเตรียม: ${appt['preparation']}",
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _editAppointment(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteAppointment(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: _navigateToAddAppointment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
