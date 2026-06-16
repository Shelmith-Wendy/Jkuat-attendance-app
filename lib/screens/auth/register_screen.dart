// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

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
  final _confirmController = TextEditingController();
  final _regController = TextEditingController();
  final _staffIdController = TextEditingController();

  String _role = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _regController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  // ── Email domain validator ─────────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final email = value.trim().toLowerCase();

    if (_role == 'student') {
      if (!email.endsWith(studentEmailDomain)) {
        return 'Student email must end with $studentEmailDomain';
      }
    } else {
      // Lecturers: must end with @jkuat.ac.ke but NOT the student subdomain
      if (email.endsWith(studentEmailDomain)) {
        return 'Lecturer email must end with $lecturerEmailDomain, not $studentEmailDomain';
      }
      if (!email.endsWith(lecturerEmailDomain)) {
        return 'Lecturer email must end with $lecturerEmailDomain';
      }
    }
    return null;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final credential = await AuthService().register(
        email,
        _passwordController.text,
      );
      final uid = credential.user!.uid;

      final user = UserModel(
        id: uid,
        name: _nameController.text.trim(),
        email: email,
        role: _role,
        regNumber: _role == 'student' ? _regController.text.trim() : '',
        staffId: _role == 'lecturer' ? _staffIdController.text.trim() : '',
        enrolledClasses: [],
        createdAt: DateTime.now(),
      );

      await FirestoreService().createUser(user);
      if (!mounted) return;

      _role == 'lecturer'
          ? context.go('/lecturer-home')
          : context.go('/student-home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e.toString())),
          backgroundColor: accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Friendly Firebase errors ───────────────────────────────────────────────
  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with that email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (raw.contains('invalid-email')) {
      return 'That email address is not valid.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    return 'Registration failed. Please try again.';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Full name ──────────────────────────────────────────
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Role selector ──────────────────────────────────────
                    // (placed before email so the domain hint updates first)
                    _buildRoleSelector(),
                    const SizedBox(height: 16),

                    // ── Email ──────────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 6),

                    // ── Domain hint banner ─────────────────────────────────
                    _buildDomainHint(),
                    const SizedBox(height: 16),

                    // ── Password ───────────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: _visibilityButton(
                          obscure: _obscurePassword,
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Password must be at least 8 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm password ───────────────────────────────────
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: _visibilityButton(
                          obscure: _obscureConfirm,
                          onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Reg number / Staff ID ──────────────────────────────
                    if (_role == 'student') ...[
                      TextFormField(
                        controller: _regController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          hintText: 'e.g. SCT221-0001/2022',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Registration number is required'
                            : null,
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _staffIdController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Staff ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Staff ID is required'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Create Account button ──────────────────────────────
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Sign in link ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?  ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryGreen,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Role selector widget ───────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleChip(label: 'Student', value: 'student'),
            const SizedBox(width: 12),
            _roleChip(label: 'Lecturer', value: 'lecturer'),
          ],
        ),
      ],
    );
  }

  Widget _roleChip({required String label, required String value}) {
    final selected = _role == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? white : Colors.grey[700],
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: lightGreen,
      backgroundColor: surfaceGrey,
      side: BorderSide(color: selected ? lightGreen : cardBorder),
      onSelected: (_) {
        setState(() {
          _role = value;
          // Clear email so user re-enters with correct domain
          _emailController.clear();
        });
      },
    );
  }

  // ── Domain hint banner ─────────────────────────────────────────────────────
  Widget _buildDomainHint() {
    final domain = _role == 'student'
        ? studentEmailDomain
        : lecturerEmailDomain;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: primaryGreen),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Your email must end with $domain',
              style: const TextStyle(fontSize: 12, color: primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password visibility toggle ─────────────────────────────────────────────
  Widget _visibilityButton({
    required bool obscure,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: obscure ? Colors.grey : primaryGreen,
      ),
    );
  }
}
