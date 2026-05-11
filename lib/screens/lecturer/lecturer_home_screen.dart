import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/class_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LecturerHomeScreen extends StatefulWidget {
  const LecturerHomeScreen({super.key});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  UserModel? _currentUser;
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = AuthService().currentUserId!;
      _currentUser = await FirestoreService().getUser(uid);
      _classes = await FirestoreService().getLecturerClasses(uid);
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: lightGreen,
              icon: const Icon(Icons.add, color: white),
              label: const Text('New Class', style: TextStyle(color: white)),
              onPressed: () async {
                await context.push('/class-form');
                _loadData();
              },
            )
          : null,
      body: _selectedIndex == 0 ? _buildClassesTab() : _buildProfileTab(),
    );
  }

  Widget _buildClassesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No classes yet'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await context.push('/class-form');
                _loadData();
              },
              child: const Text('Create First Class'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (_, i) =>
            _ClassCard(classModel: _classes[i], onRefresh: _loadData),
      ),
    );
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
            _currentUser?.email ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Staff ID: ${_currentUser?.staffId ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 32),
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

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onRefresh;

  const _ClassCard({required this.classModel, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.courseCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    classModel.courseName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.room, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        classModel.location['roomName'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${classModel.enrolledStudents.length} enrolled',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.radar, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${classModel.location['radiusMeters']}m radius',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () =>
                      context.push('/lecturer-report', extra: classModel.id),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await context.push('/class-form', extra: classModel);
                    onRefresh();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: accentRed),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete class?'),
                      content: Text(
                        'Delete ${classModel.courseCode}? This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirestoreService().deleteClass(classModel.id);
                            if (ctx.mounted) Navigator.pop(ctx);
                            onRefresh();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: accentRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
