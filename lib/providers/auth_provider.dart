import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _sub;

  User? user;
  AppUser? profile;
  bool initialized = false;
  bool loading = false;
  String? error;

  AuthProvider() {
    _sub = _service.authChanges.listen(_onAuthChanged);
  }

  bool get isLoggedIn => user != null;
  bool get isVerified => user?.emailVerified ?? false;
  bool get isStaff => profile?.isStaff ?? false;

  Future<void> _onAuthChanged(User? u) async {
    user = u;
    profile = u == null ? null : await _service.fetchProfile(u.uid);
    initialized = true;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      error = _friendly(e.code);
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) =>
      _run(() => _service.register(name: name, email: email, password: password));

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email, password));

  Future<void> logout() => _service.logout();

  Future<bool> resendVerification() => _run(_service.resendVerification);

  Future<void> checkVerified() async {
    await _service.reloadUser();
    user = _service.currentUser;
    notifyListeners();
  }

  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Authentication failed ($code).';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}