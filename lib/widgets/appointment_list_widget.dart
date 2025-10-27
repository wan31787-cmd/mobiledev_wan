import 'package:flutter/material.dart';

class AppointmentListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final void Function(int index) onEdit; // ฟังก์ชันเรียกตอนแก้ไข
  final void Function(int index) onDelete; // ฟังก์ชันเรียกตอนลบ

  const AppointmentListWidget({
    super.key,
    required this.appointments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'ยังไม่มีนัดหมายที่ถึงเวลา',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "วันที่: ${date.day}/${date.month}/${date.year} "
                  "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                ),
                Text("แพทย์: ${appt['doctor']}"),
                if (appt['department'] != null &&
                    appt['department'].toString().isNotEmpty)
                  Text("แผนก: ${appt['department']}"), // ✅ แสดงแผนก
                Text("สถานที่: ${appt['location']}"),
                if (appt['preparation'] != null &&
                    appt['preparation'].toString().isNotEmpty)
                  Text("สิ่งที่ต้องเตรียม: ${appt['preparation']}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(index),
                  tooltip: 'แก้ไขนัดหมาย',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                  tooltip: 'ลบนัดหมาย',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
