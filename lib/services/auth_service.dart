import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<String> getDeviceId() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.id;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.identifierForVendor ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('DeviceInfo error: $e');
      return '';
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;
}
