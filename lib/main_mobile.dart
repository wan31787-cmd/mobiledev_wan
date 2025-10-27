import 'dart:async'; // ✅ สำหรับ Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobiledev_wan/addMedicationPage.dart';
import 'package:mobiledev_wan/firestore_api.dart';
import 'package:mobiledev_wan/widgets/ReportPage.dart';
import 'widgets/due_medications_widget.dart';
import 'widgets/due_appointments_widget.dart';
import 'widgets/medication_list_widget.dart';
import 'appointments_page.dart';

// --- Popup Widget แยก ---
class MedicationPopup extends StatelessWidget {
  final Map<String, dynamic> medication;
  const MedicationPopup({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    final name = medication['name']?.toString() ?? '-';
    final notifyTime = medication['notifyTime']?.toString() ?? '-';
    final dose = medication['dose']?.toString() ?? '-';
    final importance = medication['importance']?.toString() ?? '-';
    final type = medication['type']?.toString() ?? '-';
    final mealTime = medication['mealTime']?.toString() ?? '-';

    return AlertDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เวลาแจ้งเตือน: $notifyTime'),
          Text('จำนวน: $dose'),
          Text('ความสำคัญ: $importance'),
          Text('ประเภท: $type'),
          Text('เวลากิน: $mealTime'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('สำเร็จ'),
        ),
      ],
    );
  }
}

class MainMobile extends StatefulWidget {
  final String username;
  final String email; // ✅ เพิ่มฟิลด์อีเมล

  const MainMobile({
    super.key,
    required this.username,
    required this.email, // ✅ ต้องรับค่า email มาด้วย
  });

  @override
  State<MainMobile> createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  int _selectedIndex = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();

    // ✅ ตั้งเวลาให้ตรวจทุก 30 วินาที
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMedicationTime();
    });
  }

  Future<void> _loadMedications() async {
    final meds = await FirestoreAPI.getMedications(widget.username);
    setState(() {
      _medications = meds;
    });
  }

  void _checkMedicationTime() {
    final now = DateFormat('HH:mm').format(DateTime.now());
    for (var med in _medications) {
      final notifyTime = med['notifyTime']?.toString();
      if (notifyTime == now) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('แจ้งเตือนการทานยา 💊'),
            content: Text('ถึงเวลาทานยา ${med['name']} แล้ว\nเวลา: $notifyTime'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('รับทราบ'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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

  // --- Home Page ---
  Widget _homePage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;
    final padding = screenWidth * 0.04;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ✅ แสดงชื่อและอีเมลของผู้ใช้
            Text(
              'สวัสดีคุณ ${widget.username}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'อีเมลของคุณ: ${widget.email}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- ยาที่ถึงเวลา ---
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ยาที่ถึงเวลา',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: FirestoreAPI.getMedications(widget.username),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('ยังไม่มีรายการยา',
                                style: TextStyle(fontSize: 16));
                          }

                          final meds = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meds.length,
                            itemBuilder: (context, index) {
                              final med = meds[index];
                              final name = med['name']?.toString() ?? '-';
                              final notifyTime =
                                  med['notifyTime']?.toString() ?? '-';
                              final dose = med['dose']?.toString() ?? '-';
                              final importance =
                                  med['importance']?.toString() ?? '-';
                              final importanceColor =
                                  _importanceColor(importance);

                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        MedicationPopup(medication: med),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor:
                                              importanceColor.withOpacity(0.2),
                                          child: Icon(Icons.medical_services,
                                              color: importanceColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'เวลาแจ้งเตือน: $notifyTime | จำนวน: $dose',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(importance),
                                          backgroundColor:
                                              importanceColor.withOpacity(0.2),
                                          labelStyle: TextStyle(
                                            color: importanceColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- นัดหมายล่วงหน้า ---
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'นัดหมายล่วงหน้า',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DueAppointmentsWidget(username: widget.username),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ ส่ง email ต่อไปด้วย
  Widget _addMedicationPage() =>
      MedicationListWidget(username: widget.username);
  Widget _appointmentsPage() =>
      AppointmentsPage(username: widget.username);
  Widget _ReportPage() => ReportPage(username: widget.username);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      _addMedicationPage(),
      _appointmentsPage(),
      _ReportPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Mobile'),
        backgroundColor: Colors.green,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'ยาของฉัน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'นัดหมายของฉัน'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'รายงาน'),
        ],
      ),
    );
  }
}
