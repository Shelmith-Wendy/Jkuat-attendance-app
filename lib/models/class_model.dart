import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String lecturerId;
  final String joinCode;
  final List<String> enrolledStudents;
  final Map<String, dynamic> location;
  final List<Map<String, dynamic>> schedule;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.lecturerId,
    this.joinCode = '',
    this.enrolledStudents = const [],
    required this.location,
    this.schedule = const [],
    required this.createdAt,
  });

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      courseCode: map['courseCode'] ?? '',
      courseName: map['courseName'] ?? '',
      lecturerId: map['lecturerId'] ?? '',
      joinCode: map['joinCode'] ?? '',
      enrolledStudents: List<String>.from(map['enrolledStudents'] ?? []),
      location: Map<String, dynamic>.from(map['location'] ?? {}),
      schedule: List<Map<String, dynamic>>.from(map['schedule'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'lecturerId': lecturerId,
      'joinCode': joinCode,
      'enrolledStudents': enrolledStudents,
      'location': location,
      'schedule': schedule,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool isActiveNow() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    for (final slot in schedule) {
      if (slot['dayOfWeek'] == now.weekday) {
        if (currentMinutes >= _parseTime(slot['startTime']) &&
            currentMinutes < _parseTime(slot['endTime'])) {
          return true;
        }
      }
    }
    return false;
  }

  String? activeSessionDate() {
    if (!isActiveNow()) return null;
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
