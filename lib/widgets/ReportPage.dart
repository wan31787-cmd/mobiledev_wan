import 'package:flutter/material.dart';
import '../services/firestore_api.dart';
import '../login_page.dart'; 

class ReportPage extends StatefulWidget {
  final String username;
  const ReportPage({super.key, required this.username});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;

  // เพิ่ม GlobalKey สำหรับ ScaffoldMessenger เพื่อแสดง SnackBar ได้แม้จะไม่มี BuildContext
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final meds = await FirestoreAPI.getTakenMedicationsReport(
        widget.username,
      );
      final apps = await FirestoreAPI.getTakenAppointmentsReport(
        widget.username,
      );
      setState(() {
        // เรียงข้อมูลตามชื่อยาหรือนัดหมายเพื่อให้ดูเป็นระเบียบยิ่งขึ้น
        medications = meds..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        appointments = apps..sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading data: $e');
      // ใช้ GlobalKey เพื่อแสดง SnackBar
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('โหลดข้อมูลล้มเหลว กรุณาลองอีกครั้ง')),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ยืนยันการออกจากระบบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Row สำหรับรายการยาแบบกระชับ (แทน _medicationCard)
  Widget _medicationRow(Map<String, dynamic> med) {
    final taken = med['takenToday'] ?? false;
    final importance = med['importance'] ?? 'ทั่วไป'; // Default value
    final importanceColor = importance == 'สำคัญมาก'
        ? Colors.red.shade700
        : importance == 'สำคัญ'
            ? Colors.orange.shade700
            : Colors.teal.shade700;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            taken ? Icons.check_circle_outline : Icons.highlight_off,
            color: taken ? Colors.green.shade600 : Colors.red.shade600,
            size: 28,
          ),
          title: Text(
            med['name'] ?? 'ไม่ระบุยา',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'เวลา: ${med['notifyTime'] ?? '-'} | จำนวน: ${med['dose'] ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: Chip(
            label: Text(
              importance,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: importanceColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const Divider(height: 1, thickness: 0.5), // ตัวแบ่งที่ทำให้ดูเรียงกัน
      ],
    );
  }

  // Row สำหรับรายการนัดหมายแบบกระชับ (แทน _appointmentCard)
  Widget _appointmentRow(Map<String, dynamic> app) {
    final attended = app['attended'] ?? false;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            attended ? Icons.event_available : Icons.event_busy,
            color: attended ? Colors.blue.shade600 : Colors.red.shade600,
            size: 28,
          ),
          title: Text(
            app['title'] ?? 'ไม่ระบุนัดหมาย',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'วันที่: ${app['date'] ?? '-'} | สถานที่: ${app['location'] ?? '-'}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: attended ? Colors.blue.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: attended ? Colors.blue.shade200 : Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Text(
              attended ? 'เข้าร่วมแล้ว' : 'พลาดนัด',
              style: TextStyle(
                color: attended ? Colors.blue.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5), // ตัวแบ่งที่ทำให้ดูเรียงกัน
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      // ใช้ ScaffoldMessenger เพื่อให้ SnackBar ทำงานได้
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // พื้นหลังสีอ่อนลง
        appBar: AppBar(
          title: const Text(
            'รายงานการรักษา', // ปรับชื่อ title ให้กระชับ
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal, // เปลี่ยนสี AppBar
          elevation: 4, // เพิ่มเงาเล็กน้อย
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ), // เปลี่ยนสีไอคอน
              onPressed: loadData, // เพิ่มปุ่ม Refresh
            ),
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ), // เปลี่ยนสีไอคอน
              onPressed: _logout,
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ) // เปลี่ยนสี Indicator
            : RefreshIndicator(
                onRefresh: loadData,
                color: Colors.teal, // สีของวงกลม Refresh
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
                  children: [
                    // --- Medications Section ---
                    Text(
                      '💊 รายงานการทานยา', // เพิ่ม Emoji
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: medications.isEmpty
                          ? const _NoDataMessage(
                              icon: Icons.medication_liquid,
                              message: 'ยังไม่มีข้อมูลการทานยาในรายงาน',
                            )
                          : Column(
                              children: medications.map(_medicationRow).toList(),
                            ),
                    ),
                    const SizedBox(height: 30),

                    // --- Appointments Section ---
                    Text(
                      '🗓️ รายงานการนัดหมาย', // เพิ่ม Emoji
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: appointments.isEmpty
                          ? const _NoDataMessage(
                              icon: Icons.calendar_today,
                              message: 'ยังไม่มีข้อมูลการนัดหมายในรายงาน',
                            )
                          : Column(
                              children:
                                  appointments.map(_appointmentRow).toList(),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Widget แยกสำหรับแสดงข้อความเมื่อไม่มีข้อมูล (ยังคงใช้ได้ดี)
class _NoDataMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const _NoDataMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


