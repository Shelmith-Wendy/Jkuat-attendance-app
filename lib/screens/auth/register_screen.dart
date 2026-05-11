import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _staffIdController = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regNumberController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().register(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final uid = credential.user!.uid;
      final user = UserModel(
        id: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        regNumber: _role == 'student' ? _regNumberController.text.trim() : '',
        staffId: _role == 'lecturer' ? _staffIdController.text.trim() : '',
        enrolledClasses: const [],
        createdAt: DateTime.now(),
      );
      await FirestoreService().createUser(user);
      if (!mounted) return;
      if (_role == 'lecturer') {
        context.go('/lecturer-home');
      } else {
        context.go('/student-home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty || !v.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => v!.length < 8 ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                validator: (v) => v != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Role: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Student'),
                    selected: _role == 'student',
                    onSelected: (_) => setState(() => _role = 'student'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Lecturer'),
                    selected: _role == 'lecturer',
                    onSelected: (_) => setState(() => _role = 'lecturer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_role == 'student')
                TextFormField(
                  controller: _regNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    hintText: 'e.g. SCT221-0001/2022',
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Enter your registration number' : null,
                ),
              if (_role == 'lecturer')
                TextFormField(
                  controller: _staffIdController,
                  decoration: const InputDecoration(labelText: 'Staff ID'),
                  validator: (v) => v!.isEmpty ? 'Enter your staff ID' : null,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: white)
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
