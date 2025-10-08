// widgets/due_appointments_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_api.dart';

class DueAppointmentsWidget extends StatefulWidget {
  final String username;
  const DueAppointmentsWidget({super.key, required this.username});

  @override
  State<DueAppointmentsWidget> createState() => _DueAppointmentsWidgetState();
}

class _DueAppointmentsWidgetState extends State<DueAppointmentsWidget> {
  List<Map<String, dynamic>> dueAppointments = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadDueAppointments();

    // โหลดใหม่ทุก 5 นาที
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadDueAppointments();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadDueAppointments() async {
    setState(() => isLoading = true);
    final appts = await FirestoreAPI.getAppointments(widget.username);
    final now = DateTime.now();

    final due =
        appts.where((appt) {
          final date = appt['date'] as DateTime;

          // แสดงล่วงหน้า 1 วัน
          final diff = date.difference(now).inDays;
          return diff <= 1 && !date.isBefore(now);
        }).toList();

    setState(() {
      dueAppointments = due;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'นัดหมายที่ใกล้ถึง',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : dueAppointments.isEmpty
              ? const Text(
                'ยังไม่มีนัดหมายที่ใกล้ถึง',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              )
              : ListView.builder(
                shrinkWrap: true, // ✅ ให้ ListView ย่อขนาดตามจำนวน item
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dueAppointments.length,
                itemBuilder: (context, index) {
                  final appt = dueAppointments[index];
                  final date = appt['date'] as DateTime;
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
                            "วันที่: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                          ),
                          Text("แพทย์: ${appt['doctor']}"),
                          Text("สถานที่: ${appt['location']}"),
                          if (appt['preparation'] != null &&
                              appt['preparation'].toString().isNotEmpty)
                            Text("สิ่งที่ต้องเตรียม: ${appt['preparation']}"),
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
    );
  }
}
