import 'package:flutter/material.dart';
import 'add_appointment_page.dart';
import '../firestore_api.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp

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

    // เรียงจากวัน/เวลาที่ใกล้ที่สุด
    appts.sort((a, b) {
      final dateA = _getDateTime(a['date']);
      final dateB = _getDateTime(b['date']);
      return dateA.compareTo(dateB);
    });
    setState(() => appointments = appts);

    // ตั้งแจ้งเตือนนัดหมายล่วงหน้า 1 วัน เวลา 09:00
    for (var appt in appts) {
      final DateTime date = _getDateTime(appt['date']);
      final scheduledTime = DateTime(
        date.subtract(const Duration(days: 1)).year,
        date.subtract(const Duration(days: 1)).month,
        date.subtract(const Duration(days: 1)).day,
        9,
        0,
      );

      final int id =
          appt['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    }
  }

  DateTime _getDateTime(dynamic timestampOrDate) {
    if (timestampOrDate is Timestamp) {
      return timestampOrDate.toDate();
    } else if (timestampOrDate is DateTime) {
      return timestampOrDate;
    } else {
      throw Exception("Invalid date format");
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

      final DateTime date = _getDateTime(result['date']);
      final scheduledTime = DateTime(
        date.subtract(const Duration(days: 1)).year,
        date.subtract(const Duration(days: 1)).month,
        date.subtract(const Duration(days: 1)).day,
        9,
        0,
      );

      final int id =
          result['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;


    }
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
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600 : double.infinity,
                ),
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
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appt = appointments[index];
                            final date = _getDateTime(appt['date']);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
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
                                  appt['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "วันที่: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                                    ),
                                    Text("แพทย์: ${appt['doctor']}"),
                                    Text("สถานที่: ${appt['location']}"),
                                    if (appt['preparation'] != null &&
                                        appt['preparation']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        "สิ่งที่ต้องเตรียม: ${appt['preparation']}",
                                      ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.event_note,
                                  color: Colors.green,
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
