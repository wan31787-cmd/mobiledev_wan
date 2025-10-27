import 'dart:io';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firestore_api.dart';
import '../services/notification_service.dart';

class AddAppointmentPage extends StatefulWidget {
  final String username;
  const AddAppointmentPage({super.key, required this.username});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _preparationController = TextEditingController();

  DateTime? _selectedDate;
  File? _selectedImage;
  String? _selectedDepartment;

  final List<String> _departments = [
    'อายุรกรรม',
    'ศัลยกรรม',
    'กุมารเวชกรรม',
    'สูตินรีเวช',
    'จักษุวิทยา',
    'ทันตกรรม',
    'หู คอ จมูก',
    'จิตเวช',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName =
          'appointments/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _pickDateTime() async {
    final bangkok = tz.getLocation('Asia/Bangkok');
    final now = tz.TZDateTime.now(bangkok);

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
      );

      if (time != null) {
        final dt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          _selectedDate = tz.TZDateTime.from(dt, bangkok).toLocal();
        });
      }
    }
  }

  void _saveAppointment() async {
    if (_titleController.text.isEmpty ||
        _selectedDate == null ||
        _doctorController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    final appointment = {
      "username": widget.username,
      "title": _titleController.text,
      "date": _selectedDate!,
      "doctor": _doctorController.text,
      "department": _selectedDepartment,
      "location": _locationController.text,
      "preparation": _preparationController.text,
      "imageUrl": imageUrl,
    };

    final success = await FirestoreAPI.addAppointment(appointment);

    if (success) {
      // ✅ ยิงแจ้งเตือนนัดหมาย
      await NotificationService.scheduleAppointmentNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'นัดหมาย: ${_titleController.text}',
        body:
            'วันที่: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} เวลา ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
        scheduledTime: _selectedDate!.subtract(
          const Duration(minutes: 10),
        ), // แจ้ง 10 นาทีล่วงหน้า
        payload: _titleController.text, // หรือ docId ถ้ามี
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("บันทึกนัดหมายสำเร็จ")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึก")),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green.shade700),
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มการนัดหมาย"),
        backgroundColor: Colors.green.shade700,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildTextField(
              controller: _titleController,
              label: "หัวข้อการนัดหมาย",
              icon: Icons.title,
            ),
            _buildTextField(
              controller: _doctorController,
              label: "ชื่อแพทย์",
              icon: Icons.person,
            ),
            // Dropdown แผนก
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.local_hospital,
                      color: Colors.green.shade700,
                    ),
                    labelText: "แผนก",
                    border: InputBorder.none,
                  ),
                  value: _selectedDepartment,
                  items:
                      _departments
                          .map(
                            (dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                ),
              ),
            ),
            _buildTextField(
              controller: _locationController,
              label: "สถานที่นัดหมาย",
              icon: Icons.location_on,
            ),
            _buildTextField(
              controller: _preparationController,
              label: "สิ่งที่ต้องเตรียมไป",
              icon: Icons.list_alt,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // ส่วนเลือกรูป
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.image, color: Colors.green),
                title: Text(
                  _selectedImage == null
                      ? "เลือกรูปภาพแนบนัดหมาย (ถ้ามี)"
                      : "เลือกรูปแล้ว ✅",
                ),
                onTap: _pickImage,
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.file(_selectedImage!, height: 150),
              ),
            const SizedBox(height: 12),
            // เลือกวันเวลา
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: Text(
                  _selectedDate == null
                      ? "เลือกวันและเวลา"
                      : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} "
                          "${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: _pickDateTime,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  "บันทึกนัดหมาย",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: _saveAppointment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
