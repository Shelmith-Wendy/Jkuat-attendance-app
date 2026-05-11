import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/lecturer/lecturer_home_screen.dart';
import '../screens/lecturer/class_form_screen.dart';
import '../screens/lecturer/attendance_report_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../models/class_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final onAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!loggedIn && !onAuth) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/lecturer-home',
      builder: (_, __) => const LecturerHomeScreen(),
    ),
    GoRoute(
      path: '/class-form',
      builder: (context, state) {
        final existing = state.extra as ClassModel?;
        return ClassFormScreen(existingClass: existing);
      },
    ),
    GoRoute(
      path: '/lecturer-report',
      builder: (context, state) {
        final classId = state.extra as String;
        return AttendanceReportScreen(classId: classId);
      },
    ),
    GoRoute(
      path: '/student-home',
      builder: (_, __) => const StudentHomeScreen(),
    ),
  ],
);
