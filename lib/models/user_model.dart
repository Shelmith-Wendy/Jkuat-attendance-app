import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String regNumber;
  final String staffId;
  final String deviceId;
  final List<String> enrolledClasses;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.regNumber = '',
    this.staffId = '',
    this.deviceId = '',
    this.enrolledClasses = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      regNumber: map['regNumber'] ?? '',
      staffId: map['staffId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      enrolledClasses: List<String>.from(map['enrolledClasses'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'regNumber': regNumber,
      'staffId': staffId,
      'deviceId': deviceId,
      'enrolledClasses': enrolledClasses,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
