import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String classId;
  final String courseCode;
  final String courseName;
  final String studentId;
  final String studentName;
  final String regNumber;
  final String sessionDate;
  final DateTime timestamp;
  final Map<String, dynamic> coordinates;

  AttendanceModel({
    required this.id,
    required this.classId,
    required this.courseCode,
    required this.courseName,
    required this.studentId,
    required this.studentName,
    required this.regNumber,
    required this.sessionDate,
    required this.timestamp,
    required this.coordinates,
  });

  factory AttendanceModel.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceModel(
      id: id,
      classId: map['classId'] ?? '',
      courseCode: map['courseCode'] ?? '',
      courseName: map['courseName'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      regNumber: map['regNumber'] ?? '',
      sessionDate: map['sessionDate'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      coordinates: Map<String, dynamic>.from(map['coordinates'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'courseCode': courseCode,
      'courseName': courseName,
      'studentId': studentId,
      'studentName': studentName,
      'regNumber': regNumber,
      'sessionDate': sessionDate,
      'timestamp': Timestamp.fromDate(timestamp),
      'coordinates': coordinates,
    };
  }
}
