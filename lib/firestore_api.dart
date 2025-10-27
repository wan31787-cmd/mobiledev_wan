import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobiledev_wan/services/notification_service.dart';

// ======================= Firestore Base URLs =======================
const String baseUsersUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/users';
const String baseMedicationsUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/medications';
const String baseAppointmentsUrl =
    'https://firestore.googleapis.com/v1/projects/dbmobileapp-1f398/databases/(default)/documents/appointments';

class FirestoreAPI {
  // ======================= Users =======================
  static Future<bool> registerUser(String username, String password, String email) async {
    final body = {
      "fields": {
        "username": {"stringValue": username},
        "password": {"stringValue": password},
        "email": {"stringValue": email},
      },
    };

    final response = await http.post(
      Uri.parse(baseUsersUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Map<String, String>>> getUsers() async {
    final response = await http.get(Uri.parse(baseUsersUrl));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final List<Map<String, String>> users = [];

    if (data['documents'] != null) {
      for (var doc in data['documents']) {
        final fields = doc['fields'];
        users.add({
          'username': fields['username']?['stringValue'] ?? '',
          'password': fields['password']?['stringValue'] ?? '',
          'email': fields['email']?['stringValue'] ?? '',
        });
      }
    }
    return users;
  }

  // ======================= Medications =======================
  static Future<bool> addMedication(Map<String, dynamic> medication) async {
    final body = {
      "fields": {
        "username": {"stringValue": medication['username'] ?? ''},
        "email": {"stringValue": medication['email'] ?? ''},
        "name": {"stringValue": medication['name'] ?? ''},
        "mealTime": {"stringValue": medication['mealTime'] ?? ''},
        "notifyTime": {"stringValue": medication['notifyTime'] ?? ''},
        "dose": {"stringValue": medication['dose'] ?? ''},
        "type": {"stringValue": medication['type'] ?? ''},
        "importance": {"stringValue": medication['importance'] ?? ''},
        "takenToday": {"booleanValue": medication['takenToday'] ?? false},
        "taken": {"booleanValue": medication['taken'] ?? false},
        "createdAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String(),
        },
      },
    };

    final response = await http.post(
      Uri.parse(baseMedicationsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final notifyTimeString = medication['notifyTime'] ?? '';
        if (notifyTimeString.isNotEmpty) {
          final scheduledTime = DateTime.parse(notifyTimeString);
          final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

          await NotificationService.scheduleMedicationNotification(
            id: id,
            title: 'ถึงเวลาทานยา: ${medication['name']}',
            body: 'กรุณากดปุ่มเพื่อยืนยันว่าทานยาแล้ว',
            scheduledTime: scheduledTime,
            payload: id.toString(),
          );
        }
      } catch (e) {
        print('Error scheduling notification: $e');
      }

      return true;
    }

    return false;
  }

  static Future<bool> updateMedication(String docId, Map<String, dynamic> medication) async {
    final body = {
      "fields": {
        "username": {"stringValue": medication['username'] ?? ''},
        "email": {"stringValue": medication['email'] ?? ''},
        "name": {"stringValue": medication['name'] ?? ''},
        "mealTime": {"stringValue": medication['mealTime'] ?? ''},
        "notifyTime": {"stringValue": medication['notifyTime'] ?? ''},
        "dose": {"stringValue": medication['dose'] ?? ''},
        "type": {"stringValue": medication['type'] ?? ''},
        "importance": {"stringValue": medication['importance'] ?? ''},
        "takenToday": {"booleanValue": medication['takenToday'] ?? false},
        "taken": {"booleanValue": medication['taken'] ?? false},
        "createdAt": {
          "timestampValue": DateTime.now().toUtc().toIso8601String(),
        },
      },
    };

    final url = '$baseMedicationsUrl/$docId';
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteMedication(String docId) async {
    final url = '$baseMedicationsUrl/$docId';
    final response = await http.delete(Uri.parse(url));
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getMedications(String username) async {
    final response = await http.get(Uri.parse(baseMedicationsUrl));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final List<Map<String, dynamic>> meds = [];

    if (data['documents'] != null) {
      for (var doc in data['documents']) {
        final fields = doc['fields'];
        if (fields['username']?['stringValue'] == username) {
          meds.add({
            'id': doc['name'].toString().split('/').last,
            'name': fields['name']?['stringValue'] ?? '',
            'mealTime': fields['mealTime']?['stringValue'] ?? '',
            'notifyTime': fields['notifyTime']?['stringValue'] ?? '',
            'dose': fields['dose']?['stringValue'] ?? '',
            'type': fields['type']?['stringValue'] ?? '',
            'importance': fields['importance']?['stringValue'] ?? '',
            'takenToday': fields['takenToday']?['booleanValue'] ?? false,
            'taken': fields['taken']?['booleanValue'] ?? false,
            'email': fields['email']?['stringValue'] ?? '',
          });
        }
      }
    }

    return meds;
  }

  // ======================= Appointments =======================
  static Future<bool> addAppointment(Map<String, dynamic> appointment) async {
    final body = {
      "fields": {
        "username": {"stringValue": appointment['username'] ?? ''},
        "email": {"stringValue": appointment['email'] ?? ''},
        "title": {"stringValue": appointment['title'] ?? ''},
        "date": {
          "timestampValue": (appointment['date'] as DateTime).toUtc().toIso8601String(),
        },
        "doctor": {"stringValue": appointment['doctor'] ?? ''},
        "location": {"stringValue": appointment['location'] ?? ''},
        "preparation": {"stringValue": appointment['preparation'] ?? ''},
        "attended": {"booleanValue": appointment['attended'] ?? false},
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

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<bool> updateAppointment(String docId, Map<String, dynamic> appointment) async {
    final body = {
      "fields": {
        "username": {"stringValue": appointment['username'] ?? ''},
        "email": {"stringValue": appointment['email'] ?? ''},
        "title": {"stringValue": appointment['title'] ?? ''},
        "date": {
          "timestampValue": (appointment['date'] as DateTime).toUtc().toIso8601String(),
        },
        "doctor": {"stringValue": appointment['doctor'] ?? ''},
        "location": {"stringValue": appointment['location'] ?? ''},
        "preparation": {"stringValue": appointment['preparation'] ?? ''},
        "attended": {"booleanValue": appointment['attended'] ?? false},
      },
    };

    final url = '$baseAppointmentsUrl/$docId';
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteAppointment(String docId) async {
    final url = '$baseAppointmentsUrl/$docId';
    final response = await http.delete(Uri.parse(url));
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getAppointments(String username) async {
    final response = await http.get(Uri.parse(baseAppointmentsUrl));
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final List<Map<String, dynamic>> apps = [];

    if (data['documents'] != null) {
      for (var doc in data['documents']) {
        final fields = doc['fields'];
        if (fields['username']?['stringValue'] != username) continue;

        DateTime date;
        try {
          date = fields['date']?['timestampValue'] != null
              ? DateTime.parse(fields['date']['timestampValue'])
              : DateTime.now();
        } catch (_) {
          date = DateTime.now();
        }

        apps.add({
          'id': doc['name'].toString().split('/').last,
          'username': username,
          'email': fields['email']?['stringValue'] ?? '',
          'title': fields['title']?['stringValue'] ?? '',
          'date': date,
          'doctor': fields['doctor']?['stringValue'] ?? '',
          'location': fields['location']?['stringValue'] ?? '',
          'preparation': fields['preparation']?['stringValue'] ?? '',
          'attended': fields['attended']?['booleanValue'] ?? false,
        });
      }
    }

    return apps;
  }

  // ======================= Reports =======================
  static Future<List<Map<String, dynamic>>> getTakenMedicationsReport(String username) async {
    final meds = await getMedications(username);
    return meds;
  }

  static Future<List<Map<String, dynamic>>> getTakenAppointmentsReport(String username) async {
    final apps = await getAppointments(username);
    return apps;
  }
}
