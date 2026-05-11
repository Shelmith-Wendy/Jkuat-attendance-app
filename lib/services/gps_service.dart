import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import 'firestore_service.dart';

class GpsService {
  Future<bool> requestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print(e);
      return null;
    }
  }

  bool isWithinGeofence(double studentLat, double studentLng,
      double classLat, double classLng, double radiusMeters) {
    final distanceMeters = Geolocator.distanceBetween(
        studentLat, studentLng, classLat, classLng);
    return distanceMeters <= radiusMeters;
  }

  Future<String?> markAttendanceWithVerification({
    required String classId,
    required String courseCode,
    required String courseName,
    required String studentId,
    required String studentName,
    required String regNumber,
    required String sessionDate,
    required double classLat,
    required double classLng,
    required double radiusMeters,
  }) async {
    final permitted = await requestPermission();
    if (!permitted) return "Location permission denied.";

    final position = await getCurrentPosition();
    if (position == null) return "Could not get your location.";

    final withinFence = isWithinGeofence(
        position.latitude, position.longitude,
        classLat, classLng, radiusMeters);
    if (!withinFence) return "You are not inside the classroom.";

    final alreadyMarked = await FirestoreService().hasStudentMarkedAttendance(
        classId, studentId, sessionDate);
    if (alreadyMarked) return "Attendance already marked for this session.";

    final attendance = AttendanceModel(
      id: '',
      classId: classId,
      courseCode: courseCode,
      courseName: courseName,
      studentId: studentId,
      studentName: studentName,
      regNumber: regNumber,
      sessionDate: sessionDate,
      timestamp: DateTime.now(),
      coordinates: {
        'lat': position.latitude,
        'lng': position.longitude,
      },
    );

    await FirestoreService().recordAttendance(attendance);
    return null;
  }
}