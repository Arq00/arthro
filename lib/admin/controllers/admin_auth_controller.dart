// lib/admin/controllers/admin_auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AdminAuthState { idle, loading, authenticated, denied, error }

class AdminAuthController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  AdminAuthState _state = AdminAuthState.idle;
  String         _error = '';
  String         _adminName = '';

  AdminAuthState get state     => _state;
  String         get error     => _error;
  String         get adminName => _adminName;
  bool get isAuthenticated => _state == AdminAuthState.authenticated;

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _setState(AdminAuthState.loading);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        _setError('User record not found.');
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] ?? '').toString().toLowerCase();

      if (role != 'admin') {
        await _auth.signOut();
        _setError('Access denied. Admin accounts only.');
        return;
      }

      _adminName = data['fullName'] ?? data['username'] ?? 'Admin';
      _setState(AdminAuthState.authenticated);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } catch (e) {
      _setError('An unexpected error occurred.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _adminName = '';
    _setState(AdminAuthState.idle);
  }

  // ── Check existing session on web reload ──────────────────────────────────
  Future<void> checkSession() async {
    final user = _auth.currentUser;
    if (user == null) { _setState(AdminAuthState.idle); return; }
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final role = (doc.data()?['role'] ?? '').toString().toLowerCase();
      if (role == 'admin') {
        _adminName = doc.data()?['fullName'] ?? 'Admin';
        _setState(AdminAuthState.authenticated);
      } else {
        await _auth.signOut();
        _setState(AdminAuthState.idle);
      }
    } catch (_) {
      _setState(AdminAuthState.idle);
    }
  }

  void _setState(AdminAuthState s) { _state = s; _error = ''; notifyListeners(); }
  void _setError(String msg) { _state = AdminAuthState.error; _error = msg; notifyListeners(); }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':    return 'No account found with this email.';
      case 'wrong-password':    return 'Incorrect password.';
      case 'invalid-email':     return 'Please enter a valid email.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default:                  return 'Login failed. Check your credentials.';
    }
  }
}