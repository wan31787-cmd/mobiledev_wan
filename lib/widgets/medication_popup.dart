import 'package:flutter/material.dart';
import 'package:mobiledev_wan/addMedicationPage.dart';
import 'package:mobiledev_wan/appointments_page.dart';
import 'package:mobiledev_wan/firestore_api.dart';
import 'package:mobiledev_wan/widgets/due_appointments_widget.dart';
import 'package:mobiledev_wan/widgets/medication_list_widget.dart';


// --- Popup Widget แยกออกมา ---
class MedicationPopup extends StatelessWidget {
  final Map<String, dynamic> medication;

  const MedicationPopup({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(medication['name'].toString()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เวลาแจ้งเตือน: ${medication['notifyTime']}'),
          Text('จำนวน: ${medication['dose']}'),
          Text('ความสำคัญ: ${medication['importance']}'),
          Text('ประเภท: ${medication['type']}'),
          Text('เวลากิน: ${medication['mealTime']}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            // TODO: อัพเดตสถานะ taken/finished ถ้าต้องการ
            Navigator.of(context).pop();
          },
          child: const Text('สำเร็จ'),
        ),
      ],
    );
  }
}

class MainMobile extends StatefulWidget {
  final String username;
  const MainMobile({super.key, required this.username});

  @override
  State<MainMobile> createState() => _MainMobileState();
}

class _MainMobileState extends State<MainMobile> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const CircularProgressIndicator();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text(
                              'ยังไม่มีรายการยา',
                              style: TextStyle(fontSize: 16),
                            );
                          }

                          final meds = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meds.length,
                            itemBuilder: (context, index) {
                              final med = meds[index];

                              Color importanceColor;
                              switch (med['importance'].toString()) {
                                case 'สำคัญมาก':
                                  importanceColor = Colors.redAccent;
                                  break;
                                case 'สำคัญ':
                                  importanceColor = Colors.orangeAccent;
                                  break;
                                default:
                                  importanceColor = Colors.green;
                              }

                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) =>
                                            MedicationPopup(medication: med),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 25,
                                          backgroundColor: importanceColor
                                              .withOpacity(0.2),
                                          child: Icon(
                                            Icons.medical_services,
                                            color: importanceColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                med['name'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'เวลาแจ้งเตือน: ${med['notifyTime']} | จำนวน: ${med['dose']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            med['importance'].toString(),
                                          ),
                                          backgroundColor: importanceColor
                                              .withOpacity(0.2),
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

  Widget _addMedicationPage() =>
      MedicationListWidget(username: widget.username);
  Widget _appointmentsPage() => AppointmentsPage(username: widget.username);
  Widget _settingsPage() => Center(
    child: ElevatedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Logout'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      _addMedicationPage(),
      _appointmentsPage(),
      _settingsPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
