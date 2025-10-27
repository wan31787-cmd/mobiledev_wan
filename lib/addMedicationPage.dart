import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobiledev_wan/services/notification_service.dart';
import 'firestore_api.dart';

class AddMedicationPage extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? medication;
  const AddMedicationPage({super.key, required this.username, this.medication});

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
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
    NotificationService.init();

    if (widget.medication != null) {
      final med = widget.medication!;
      nameController.text = med['name'] ?? '';
      timeController.text =
          med['notifyTime'] != null
              ? DateTime.tryParse(med['notifyTime']) != null
                  ? DateFormat('HH:mm').format(DateTime.parse(med['notifyTime']).toLocal())
                  : ''
              : '';
      doseController.text = med['dose'] ?? '';
      type = med['type'] ?? 'ยากิน';
      mealTime = med['mealTime'] ?? getMealTimesByType(type).first;
      importance = med['importance'] ?? 'ธรรมดา';
    }
  }

  List<String> getMealTimesByType(String type) {
    return type == 'ยากิน' ? mealTimesForOral : mealTimesForOther;
  }

  Future<void> saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

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
      if (scheduledTime.isBefore(now))
        scheduledTime = scheduledTime.add(const Duration(days: 1));

      final medicationData = {
        'username': widget.username,
        'name': nameController.text.trim(),
        'mealTime': mealTime,
        'notifyTime': scheduledTime.toIso8601String(),
        'dose': doseController.text.trim(),
        'type': type,
        'importance': importance,
        'createdAt': now.toIso8601String(),
      };

      bool success;
      if (widget.medication != null && widget.medication?['id'] != null) {
        success = await FirestoreAPI.updateMedication(
          widget.medication!['id'],
          medicationData,
        );
      } else {
        success = await FirestoreAPI.addMedication(medicationData);
      }

      if (success) {
        // ✅ ใช้ฟังก์ชันใหม่ของ NotificationService
        await NotificationService.scheduleMedicationNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'ถึงเวลาทานยา 💊',
          body: '${nameController.text} - ${doseController.text} เม็ด',
          scheduledTime: scheduledTime,
          payload: widget.medication?['id'] ?? nameController.text, // เก็บ id หรือชื่อยา
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medication != null ? 'แก้ไขยาสำเร็จ!' : 'บันทึกยาสำเร็จ!'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด')),
        );
      }
    } catch (e) {
      debugPrint("บันทึกยาหรือแจ้งเตือนล้มเหลว: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการตั้งค่าเวลาแจ้งเตือน')),
      );
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
        title: Text(widget.medication != null ? "แก้ไขยา" : "เพิ่มยา"),
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
                      _buildTextField(nameController, 'ชื่อยา', Icons.medication),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'ประเภทยา',
                        value: type,
                        items: types,
                        icon: Icons.category,
                        onChanged: (val) => setState(() {
                          type = val!;
                          mealTime = getMealTimesByType(type).first;
                        }),
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
                          child: _buildTextField(timeController, 'เวลาแจ้งเตือน (HH:mm)', Icons.notifications),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(doseController, 'จำนวนเม็ดต่อครั้ง', Icons.format_list_numbered, keyboard: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildDropdown(label: 'ความสำคัญ', value: importance, items: importances, icon: Icons.priority_high, onChanged: (val) => setState(() => importance = val!)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saveMedication,
                          icon: const Icon(Icons.save),
                          label: Text(widget.medication != null ? "อัพเดตยา" : "บันทึกยา"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: (v) => v!.isEmpty ? 'กรุณากรอก $label' : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required IconData icon, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
