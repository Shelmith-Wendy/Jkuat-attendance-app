import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/attendance_model.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gps_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  UserModel? _currentUser;
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = AuthService().currentUserId!;
      _currentUser = await FirestoreService().getUser(uid);
      _classes = await FirestoreService().getStudentClasses(
        _currentUser?.enrolledClasses ?? [],
      );
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showJoinClassDialog() async {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask your lecturer for the course code and enter it below.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                hintText: 'e.g. SCT2413',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              await _joinClass(code);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClass(String courseCode) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .where('courseCode', isEqualTo: courseCode)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No class found with that course code.'),
            ),
          );
        }
        return;
      }

      final classDoc = query.docs.first;
      final classId = classDoc.id;
      final studentId = _currentUser!.id;

      final enrolledStudents = List<String>.from(
        classDoc.data()['enrolledStudents'] ?? [],
      );
      if (enrolledStudents.contains(studentId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already enrolled in this class.'),
            ),
          );
        }
        return;
      }

      await FirestoreService().addStudentToClass(classId, studentId);
      await FirestoreService().addClassToStudent(classId, studentId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully joined ${classDoc.data()['courseName']}!',
            ),
            backgroundColor: lightGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: _selectedIndex == 0 ? _buildHomeTab() : _buildProfileTab(),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Live Sessions'),
              Tab(text: 'My History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildLiveSessionsTab(), _buildHistoryTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSessionsTab() {
    final activeClasses = _classes.where((c) => c.isActiveNow()).toList();
    if (activeClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No active sessions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The mark button appears automatically when your class starts',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeClasses.length,
      itemBuilder: (_, i) => _ActiveSessionCard(
        classModel: activeClasses[i],
        currentUser: _currentUser!,
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<AttendanceModel>>(
      future: _loadAllAttendance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No attendance history yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (_, i) {
            final record = records[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record.courseCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy').format(record.timestamp),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Marked at ${DateFormat('HH:mm').format(record.timestamp)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        label: const Text(
                          'Present',
                          style: TextStyle(color: white),
                        ),
                        backgroundColor: lightGreen,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<AttendanceModel>> _loadAllAttendance() async {
    final all = <AttendanceModel>[];
    for (final c in _classes) {
      final records = await FirestoreService().getStudentAttendanceForClass(
        _currentUser!.id,
        c.id,
      );
      all.addAll(records);
    }
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: lightGreen,
            child: Text(
              _currentUser?.name.isNotEmpty == true
                  ? _currentUser!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 28, color: white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentUser?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'Reg: ${_currentUser?.regNumber ?? ''}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            _currentUser?.email ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            '${_currentUser?.enrolledClasses.length ?? 0} classes enrolled',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Join a Class'),
              onPressed: _showJoinClassDialog,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accentRed,
                side: const BorderSide(color: accentRed),
              ),
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) context.go('/login');
              },
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends StatefulWidget {
  final ClassModel classModel;
  final UserModel currentUser;

  const _ActiveSessionCard({
    required this.classModel,
    required this.currentUser,
  });

  @override
  State<_ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<_ActiveSessionCard> {
  bool _isLoading = false;

  Future<void> _markAttendance() async {
    setState(() => _isLoading = true);
    final result = await GpsService().markAttendanceWithVerification(
      classId: widget.classModel.id,
      courseCode: widget.classModel.courseCode,
      courseName: widget.classModel.courseName,
      studentId: widget.currentUser.id,
      studentName: widget.currentUser.name,
      regNumber: widget.currentUser.regNumber,
      sessionDate: widget.classModel.activeSessionDate()!,
      classLat: widget.classModel.location['lat'],
      classLng: widget.classModel.location['lng'],
      radiusMeters: (widget.classModel.location['radiusMeters'] as num)
          .toDouble(),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (result == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: lightGreen),
              const SizedBox(height: 12),
              const Text(
                'Attendance Marked!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Recorded at ${DateFormat('HH:mm').format(DateTime.now())}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: accentRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightGreen, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classModel.courseCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.classModel.courseName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.room, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.classModel.location['roomName'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.radar, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${widget.classModel.location['radiusMeters']}m radius',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _markAttendance,
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: white),
                      )
                    : const Text('Mark My Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
