import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/class_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gps_service.dart';

class ClassFormScreen extends StatefulWidget {
  final ClassModel? existingClass;
  const ClassFormScreen({super.key, this.existingClass});

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _roomNameController   = TextEditingController();
  final _radiusController     = TextEditingController();
  final _latController        = TextEditingController();
  final _lngController        = TextEditingController();
  List<Map<String, dynamic>> _scheduleSlots = [];
  bool _isLoading = false;

  bool get _isEdit => widget.existingClass != null;

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.existingClass!;
      _courseCodeController.text = c.courseCode;
      _courseNameController.text = c.courseName;
      _roomNameController.text   = c.location['roomName'] ?? '';
      _radiusController.text     = c.location['radiusMeters']?.toString() ?? '';
      _latController.text        = c.location['lat']?.toString() ?? '';
      _lngController.text        = c.location['lng']?.toString() ?? '';
      _scheduleSlots = List<Map<String, dynamic>>.from(c.schedule);
    }
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _roomNameController.dispose();
    _radiusController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final position = await GpsService().getCurrentPosition();
    if (position != null) {
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location')),
        );
      }
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one schedule slot')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final joinCode = _isEdit
          ? widget.existingClass!.joinCode
          : _generateJoinCode();

      final classData = ClassModel(
        id: _isEdit ? widget.existingClass!.id : '',
        courseCode: _courseCodeController.text.trim().toUpperCase(),
        courseName: _courseNameController.text.trim(),
        lecturerId: AuthService().currentUserId!,
        joinCode: joinCode,
        enrolledStudents: _isEdit
            ? widget.existingClass!.enrolledStudents
            : [],
        location: {
          'roomName':     _roomNameController.text.trim(),
          'radiusMeters': double.parse(_radiusController.text),
          'lat':          double.parse(_latController.text),
          'lng':          double.parse(_lngController.text),
        },
        schedule:  _scheduleSlots,
        createdAt: _isEdit
            ? widget.existingClass!.createdAt
            : DateTime.now(),
      );

      if (_isEdit) {
        await FirestoreService().updateClass(
          widget.existingClass!.id,
          classData.toMap(),
        );
        if (mounted) context.pop();
      } else {
        await FirebaseFirestore.instance
            .collection('classes')
            .add(classData.toMap());
        if (mounted) _showJoinCodeDialog(joinCode, classData.courseName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinCodeDialog(String joinCode, String courseName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Class Created!',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this join code with your $courseName students:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    joinCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: primaryGreen),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: joinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Join code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Students enter this code in the app to join your class.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _dayName(int day) {
    const days = {
      1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
      4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
    };
    return days[day] ?? 'Monday';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Class' : 'Create Class')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(labelText: 'Course Code'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomNameController,
                decoration: const InputDecoration(labelText: 'Room Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              const Text('Geofence Radius',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _radiusController,
                decoration: const InputDecoration(
                  labelText: 'Geofence Radius (metres)',
                  helperText: 'Small room: 20–30m · Lecture hall: 60–100m',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null) return 'Enter a valid number';
                  if (d < 10 || d > 500) return 'Must be between 10 and 500';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Classroom GPS Coordinates',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (v) {
                        if (v!.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text('Use My Current Location'),
                onPressed: _useMyLocation,
              ),
              const SizedBox(height: 20),

              const Text('Class Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._scheduleSlots.asMap().entries.map((entry) {
                final i    = entry.key;
                final slot = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: slot['dayOfWeek'] as int,
                          decoration: const InputDecoration(labelText: 'Day of Week'),
                          items: [1, 2, 3, 4, 5, 6, 7]
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(_dayName(d)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _scheduleSlots[i]['dayOfWeek'] = v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null) {
                                    setState(() => _scheduleSlots[i]['startTime'] =
                                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Start Time'),
                                  child: Text(slot['startTime'] ?? '08:00'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null) {
                                    setState(() => _scheduleSlots[i]['endTime'] =
                                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'End Time'),
                                  child: Text(slot['endTime'] ?? '10:00'),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: accentRed),
                              onPressed: () =>
                                  setState(() => _scheduleSlots.removeAt(i)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              OutlinedButton(
                onPressed: () => setState(() => _scheduleSlots.add({
                      'dayOfWeek': 1,
                      'startTime': '08:00',
                      'endTime':   '10:00',
                    })),
                child: const Text('+ Add Schedule Slot'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveClass,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: white)
                      : Text(_isEdit ? 'Update Class' : 'Create Class'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
