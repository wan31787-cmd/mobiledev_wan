import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobiledev_wan/services/notification_service.dart';
import 'firestore_api.dart';

class AddMedicationPage extends StatefulWidget {
  final String username;
  const AddMedicationPage({super.key, required this.username});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  List<Map<String, String>> medications = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController doseController = TextEditingController();

  String mealTime = 'ก่อนอาหาร';
  String type = 'ยากิน';
  String importance = 'ธรรมดา';

  final List<String> mealTimesForOral = ['ก่อนอาหาร', 'หลังอาหาร', 'ก่อนนอน'];
  final List<String> mealTimesForOther = ['ก่อนนอน', 'ทุกเวลาที่มีอาการ'];

  final List<String> types = ['ยากิน', 'ยาทา', 'ยาฉีด'];
  final List<String> importances = ['ธรรมดา', 'สำคัญ', 'สำคัญมาก'];

  @override
  void initState() {
    super.initState();
    NotificationService.init(); // เรียก init notification
    loadMedications();
  }

  List<String> getMealTimesByType(String type) {
    return type == 'ยากิน' ? mealTimesForOral : mealTimesForOther;
  }

  Future<void> loadMedications() async {
    final meds = await FirestoreAPI.getMedications(widget.username);
    final medsString =
        meds
            .map(
              (med) => med.map((key, value) => MapEntry(key, value.toString())),
            )
            .toList();
    setState(() => medications = medsString);
  }

  Future<void> addMedication() async {
    if (_formKey.currentState!.validate()) {
      try {
        final parts = timeController.text.trim().split(":");
        final now = DateTime.now();
        DateTime scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        final medication = {
          'username': widget.username,
          'name': nameController.text.trim(),
          'mealTime': mealTime,
          'notifyTime': scheduledTime.toIso8601String(),
          'dose': doseController.text.trim(),
          'type': type,
          'importance': importance,
          'createdAt': now.toIso8601String(),
        };

        final success = await FirestoreAPI.addMedication(medication);

        if (success) {
          // ✅ ใช้ NotificationService แบบไม่ต้อง NotificationType
          await NotificationService.scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'ถึงเวลาทานยา 💊',
            body: '${nameController.text} - ${doseController.text} เม็ด',
            scheduledTime: scheduledTime,
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('บันทึกยาสำเร็จ!')));

          nameController.clear();
          timeController.clear();
          doseController.clear();
          setState(() {
            type = 'ยากิน';
            mealTime = 'ก่อนอาหาร';
            importance = 'ธรรมดา';
          });
          loadMedications();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกยา')),
          );
        }
      } catch (e) {
        debugPrint("บันทึกยาหรือแจ้งเตือนล้มเหลว: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการตั้งค่าเวลาแจ้งเตือน'),
          ),
        );
      }
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMealTimes = getMealTimesByType(type);
    if (!currentMealTimes.contains(mealTime)) mealTime = currentMealTimes.first;

    return Scaffold(
      appBar: AppBar(
        title: Text("เพิ่มยา - ${widget.username}"),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        nameController,
                        'ชื่อยา',
                        Icons.medication,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'ประเภทยา',
                        value: type,
                        items: types,
                        icon: Icons.category,
                        onChanged: (val) {
                          setState(() {
                            type = val!;
                            mealTime = getMealTimesByType(type).first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'เวลาที่กินยา',
                        value: mealTime,
                        items: currentMealTimes,
                        icon: Icons.access_time,
                        onChanged: (val) => setState(() => mealTime = val!),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: pickTime,
                        child: AbsorbPointer(
                          child: _buildTextField(
                            timeController,
                            'เวลาแจ้งเตือน (HH:mm)',
                            Icons.notifications,
                            validator:
                                (v) =>
                                    v!.isEmpty
                                        ? 'กรุณาเลือกเวลาแจ้งเตือน'
                                        : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        doseController,
                        'จำนวนเม็ดต่อครั้ง',
                        Icons.format_list_numbered,
                        keyboard: TextInputType.number,
                        validator:
                            (v) => v!.isEmpty ? 'กรุณากรอกจำนวนเม็ด' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'ความสำคัญ',
                        value: importance,
                        items: importances,
                        icon: Icons.priority_high,
                        onChanged: (val) => setState(() => importance = val!),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: addMedication,
                          icon: const Icon(Icons.save),
                          label: const Text("บันทึกยา"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "รายการยาทั้งหมด",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            medications.isEmpty
                ? const Text('ยังไม่มีรายการยา')
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return ListTile(
                      title: Text(
                        med['name']!,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'แจ้งเตือน: ${med['notifyTime']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('จำนวน: ${med['dose']}'),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator ?? (v) => v!.isEmpty ? 'กรุณากรอก $label' : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
