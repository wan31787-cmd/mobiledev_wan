import 'dart:convert';
import 'package:http/http.dart' as http;

// Firestore URL สำหรับ Users
const String baseUsersUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/users';

// Firestore URL สำหรับ Medications
const String baseMedicationsUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/medications';

const String baseAppointmentsUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/appointments';

class FirestoreAPI {
  // Register user
  static Future<void> registerUser(String username, String password) async {
    final response = await http.post(
      Uri.parse(baseUsersUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "fields": {
          "username": {"stringValue": username},
          "password": {"stringValue": password},
        },
      }),
    );
    print('Register User Response: ${response.body}');
  }

  // ดึงผู้ใช้ทั้งหมด
  static Future<List<Map<String, String>>> getUsers() async {
    final response = await http.get(Uri.parse(baseUsersUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<Map<String, String>> users = [];
      if (data['documents'] != null) {
        for (var doc in data['documents']) {
          final fields = doc['fields'];
          users.add({
            'username': fields['username']['stringValue'],
            'password': fields['password']['stringValue'],
          });
        }
      }
      return users;
    }
    return [];
  }

  // ดึงรายการยาของผู้ใช้
  static Future<List<Map<String, String>>> getMedications(
    String username,
  ) async {
    final response = await http.get(Uri.parse(baseMedicationsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<Map<String, String>> meds = [];
      if (data['documents'] != null) {
        for (var doc in data['documents']) {
          final fields = doc['fields'];
          if (fields['username']['stringValue'] == username) {
            meds.add({
              'name': fields['name']['stringValue'],
              'mealTime': fields['mealTime']['stringValue'],
              'notifyTime': fields['notifyTime']['stringValue'], // ISO8601
              'dose': fields['dose']['stringValue'],
              'type': fields['type']['stringValue'],
              'importance': fields['importance']['stringValue'],
            });
          }
        }
      }
      return meds;
    }
    return [];
  }

  // เพิ่มยาใหม่
  static Future<bool> addMedication(Map<String, String> medication) async {
    final body = {
      "fields": {
        "username": {"stringValue": medication['username']},
        "name": {"stringValue": medication['name']},
        "mealTime": {"stringValue": medication['mealTime']},
        "notifyTime": {"stringValue": medication['notifyTime']}, // ISO8601
        "dose": {"stringValue": medication['dose']},
        "type": {"stringValue": medication['type']},
        "importance": {"stringValue": medication['importance']},
        "createdAt": {"stringValue": medication['createdAt']},

        // เพิ่ม 2 ฟิลด์ boolean
        "takenToday": {"booleanValue": false},
        "taken": {"booleanValue": false},
      },
    };

    final response = await http.post(
      Uri.parse(baseMedicationsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ดึงรายการนัดหมายของผู้ใช้
  static Future<List<Map<String, dynamic>>> getAppointments(
    String username,
  ) async {
    final response = await http.get(Uri.parse(baseAppointmentsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<Map<String, dynamic>> appointments = [];
      if (data['documents'] != null) {
        for (var doc in data['documents']) {
          final fields = doc['fields'];
          if (fields['username']['stringValue'] == username) {
            appointments.add({
              'title': fields['title']['stringValue'],
              'date': DateTime.parse(fields['date']['timestampValue']),
              'doctor': fields['doctor']['stringValue'],
              'location': fields['location']['stringValue'],
              'preparation': fields['preparation']['stringValue'],
            });
          }
        }
      }
      return appointments;
    }
    return [];
  }

  // เพิ่มนัดหมายใหม่
  static Future<bool> addAppointment(Map<String, dynamic> appointment) async {
    final body = {
      "fields": {
        "username": {"stringValue": appointment['username']},
        "title": {"stringValue": appointment['title']},
        "date": {
          "timestampValue":
              (appointment['date'] as DateTime).toUtc().toIso8601String(),
        },
        "doctor": {"stringValue": appointment['doctor']},
        "location": {"stringValue": appointment['location']},
        "preparation": {"stringValue": appointment['preparation']},
        "createdAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String(),
        },
      },
    };

    final response = await http.post(
      Uri.parse(baseAppointmentsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('Add Appointment Response: ${response.statusCode}, ${response.body}');
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
