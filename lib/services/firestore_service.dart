import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<UserModel?> getUserByRegNumber(String regNumber) async {
    try {
      final query = await _db
          .collection('users')
          .where('regNumber', isEqualTo: regNumber)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromMap(query.docs.first.id, query.docs.first.data());
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  // Class methods
  Future<List<ClassModel>> getLecturerClasses(String lecturerId) async {
    try {
      final query = await _db
          .collection('classes')
          .where('lecturerId', isEqualTo: lecturerId)
          .get();
      return query.docs
          .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<List<ClassModel>> getStudentClasses(List<String> classIds) async {
    try {
      if (classIds.isEmpty) return [];
      final query = await _db
          .collection('classes')
          .where(FieldPath.documentId, whereIn: classIds)
          .get();
      return query.docs
          .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> createClass(ClassModel classModel) async {
    try {
      await _db.collection('classes').add(classModel.toMap());
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> updateClass(String classId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('classes').doc(classId).update(updates);
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      await _db.collection('classes').doc(classId).delete();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> addStudentToClass(String classId, String studentId) async {
    try {
      await _db.collection('classes').doc(classId).update({
        'enrolledStudents': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> addClassToStudent(String classId, String studentId) async {
    try {
      await _db.collection('users').doc(studentId).update({
        'enrolledClasses': FieldValue.arrayUnion([classId]),
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  // Attendance methods
  Future<bool> hasStudentMarkedAttendance(
    String classId,
    String studentId,
    String sessionDate,
  ) async {
    try {
      final query = await _db
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('studentId', isEqualTo: studentId)
          .where('sessionDate', isEqualTo: sessionDate)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> recordAttendance(AttendanceModel attendance) async {
    try {
      await _db.collection('attendance').add(attendance.toMap());
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getAttendanceForClass(String classId) async {
    try {
      final query = await _db
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .orderBy('timestamp', descending: true)
          .get();
      return query.docs
          .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getStudentAttendanceForClass(
    String studentId,
    String classId,
  ) async {
    try {
      final query = await _db
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .orderBy('timestamp', descending: true)
          .get();
      return query.docs
          .map((doc) => AttendanceModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}
