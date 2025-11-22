import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firestore_api.dart';

class DueMedicationsWidget extends StatefulWidget {
  final String username;
  const DueMedicationsWidget({required this.username});

  @override
  State<DueMedicationsWidget> createState() => _DueMedicationsWidgetState();
}

class _DueMedicationsWidgetState extends State<DueMedicationsWidget> {
  List<Map<String, dynamic>> dueMeds = []; // <-- แก้ตรงนี้
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadDueMedications();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadDueMedications();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadDueMedications() async {
    setState(() => isLoading = true);

    final meds = await FirestoreAPI.getMedications(widget.username);
    final now = DateTime.now();

    final due = meds.where((med) {
      try {
        final notifyTimeStr = med['notifyTime']?.toString() ?? '';
        final medDateTime = DateTime.parse(notifyTimeStr);
        final medEndTime = medDateTime.add(const Duration(minutes: 15));

        return now.isAfter(medDateTime) && now.isBefore(medEndTime);
      } catch (e) {
        debugPrint("Error parsing notifyTime: $e");
        return false;
      }
    }).toList();

    setState(() {
      dueMeds = due;
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

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Welcome, ${widget.username}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildBody(maxWidth),
        ],
      ),
    );
  }

  Widget _buildBody(double maxWidth) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dueMeds.isEmpty) {
      return const Center(
        child: Text('ยังไม่มียาที่ถึงเวลา', style: TextStyle(fontSize: 16)),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: dueMeds.length,
        itemBuilder: (context, index) {
          final med = dueMeds[index];
          final importance = med['importance']?.toString() ?? '';
          final type = med['type']?.toString() ?? '';
          final name = med['name']?.toString() ?? '';
          final notifyTime = med['notifyTime']?.toString() ?? '';
          final dose = med['dose']?.toString() ?? '';
          final mealTime = med['mealTime']?.toString() ?? '';

          return Card(
            color: _importanceColor(importance).withOpacity(0.1),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: maxWidth * 0.06,
                        backgroundColor: _importanceColor(importance).withOpacity(0.2),
                        child: _typeIcon(type),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text(importance),
                        backgroundColor: _importanceColor(importance).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _importanceColor(importance),
                          fontWeight: FontWeight.bold,
                          fontSize: maxWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('เวลาแจ้งเตือน: $notifyTime', overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.medication, size: 16, color: Colors.grey),
                      Text('จำนวน: $dose'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(mealTime),
                        backgroundColor: Colors.blue[50],
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(type),
                        backgroundColor: Colors.purple[50],
                        labelStyle: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
