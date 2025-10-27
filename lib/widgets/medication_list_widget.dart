import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_api.dart';
import '../addMedicationPage.dart';

class MedicationListWidget extends StatefulWidget {
  final String username;
  const MedicationListWidget({required this.username});

  @override
  State<MedicationListWidget> createState() => _MedicationListWidgetState();
}

class _MedicationListWidgetState extends State<MedicationListWidget> {
  List<Map<String, String>> medications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  Future<void> loadMedications() async {
    setState(() => isLoading = true);

    final meds = await FirestoreAPI.getMedications(widget.username);

    setState(() {
      medications = meds
          .map((med) => med.map((key, value) => MapEntry(key, value.toString())))
          .toList();
      isLoading = false;
    });
  }

  Color _importanceColor(String importance) {
    switch (importance) {
      case 'สำคัญมาก':
        return Colors.redAccent;
      case 'สำคัญ':
        return Colors.orangeAccent;
      default:
        return Colors.green;
    }
  }

  Icon _typeIcon(String type) {
    switch (type) {
      case 'ยาทา':
        return const Icon(Icons.healing, color: Colors.purple);
      case 'ยาฉีด':
        return const Icon(Icons.medical_services, color: Colors.blue);
      default:
        return const Icon(Icons.local_hospital, color: Colors.green);
    }
  }

  String formatTime(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return '-';
      return DateFormat('HH:mm').format(dt.toLocal());
    } catch (_) {
      return '-';
    }
  }

  String formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return '-';
      return DateFormat('dd/MM/yyyy').format(dt.toLocal());
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการยา"),
        backgroundColor: Colors.green.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medications.isEmpty
              ? const Center(
                  child: Text('ยังไม่มีรายการยา', style: TextStyle(fontSize: 18)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    final importance = med['importance'] ?? '-';
                    final type = med['type'] ?? '-';

                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(med['name'] ?? '-'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('เวลาแจ้งเตือน: ${formatTime(med['notifyTime'])}'),
                                Text('จำนวน: ${med['dose'] ?? '-'}'),
                                Text('ความสำคัญ: ${med['importance'] ?? '-'}'),
                                Text('ประเภท: ${med['type'] ?? '-'}'),
                                Text('ช่วงเวลา: ${med['mealTime'] ?? '-'}'),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () async {
                                  // แก้ไขยา
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddMedicationPage(
                                        username: widget.username,
                                        medication: med,
                                      ),
                                    ),
                                  );
                                  loadMedications();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('แก้ไข'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  // ลบยา
                                  if (med['id'] != null) {
                                    await FirestoreAPI.deleteMedication(med['id']!);
                                    loadMedications();
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: const Text('ลบ'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('ปิด'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: _importanceColor(
                                      importance,
                                    ).withOpacity(0.2),
                                    child: _typeIcon(type),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      med['name'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(importance),
                                    backgroundColor: _importanceColor(
                                      importance,
                                    ).withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: _importanceColor(importance),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'เวลาแจ้งเตือน: ${formatTime(med['notifyTime'])}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.medication, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'จำนวน: ${med['dose'] ?? '-'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.category, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('ประเภท: $type', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.event_note, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('ช่วงเวลา: ${med['mealTime'] ?? '-'}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'บันทึกเมื่อ: ${formatDate(med['createdAt'])}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMedicationPage(username: widget.username),
            ),
          );
          loadMedications();
        },
      ),
    );
  }
}
