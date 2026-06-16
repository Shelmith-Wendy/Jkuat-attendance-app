// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe      = false;
  bool _isLoading       = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final uid = credential.user!.uid;
      final user = await FirestoreService().getUser(uid);
      if (!mounted) return;
      if (user == null) throw Exception('User record not found.');

      // ── Device fingerprint check ──────────────────────────────────────
      final currentDeviceId = await AuthService().getDeviceId();
      if (user.deviceId.isEmpty) {
        // First login on any device — register this device
        await FirestoreService().updateUserDeviceId(uid, currentDeviceId);
      } else if (user.deviceId != currentDeviceId) {
        // Different device detected — block and sign out
        await AuthService().signOut();
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text('Unrecognised Device',
                style: TextStyle(
                    color: accentRed, fontWeight: FontWeight.bold)),
            content: const Text(
              'Your account was last used on a different device. '
              'Contact your lecturer if this is a mistake.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: accentRed),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      // ── Navigate based on role ────────────────────────────────────────
      if (!mounted) return;
      user.role == 'lecturer'
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

  void _showResetDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset Password',
            style: TextStyle(
                color: primaryGreen, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: resetController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetController.text.trim().isNotEmpty) {
                await AuthService()
                    .sendPasswordReset(resetController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent.'),
                      backgroundColor: lightGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found for that email.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect password. Please try again.';
    }
    if (raw.contains('too-many-requests')) return 'Too many attempts. Please try again later.';
    if (raw.contains('network-request-failed')) return 'Network error. Check your connection.';
    return 'Sign in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFormCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      child: Column(
        children: [
          Image.asset(
            'assets/images/jkuat_logo.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, size: 52, color: white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hi, welcome back',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please fill in your details to log in',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    hintText: 'Student No / Employee No',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Username / Email is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _obscurePassword ? Colors.grey : primaryGreen,
                      ),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: primaryGreen,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        const Text('Remember me',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    TextButton(
                      onPressed: _showResetDialog,
                      style: TextButton.styleFrom(
                          foregroundColor: primaryGreen,
                          padding: EdgeInsets.zero),
                      child: const Text('Forgot Password?',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: white, strokeWidth: 2))
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account ?  ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryGreen,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
