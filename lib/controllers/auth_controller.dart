// lib/controllers/auth_controller.dart

import 'dart:async';
import 'dart:math';
import 'package:arthro/views/auth/welcome_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/connection_request_model.dart';
import '../views/navigation/global_navigation.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  String     _status = '';
  UserModel? _currentUser;
  bool       _isLoading = false;

  // Real-time listener on the logged-in user's Firestore doc.
  // This is what makes the guardian's UI update the moment patientId is written.
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  String     get status      => _status;
  UserModel? get currentUser => _currentUser;
  bool       get isLoading   => _isLoading;

  // ── Constructor ───────────────────────────────────────────────────────────
  AuthController() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
      _startUserDocListener(firebaseUser.uid);
      
      // ✅ NEW: Update lastLogin EVERY app open
      _updateLastLogin(firebaseUser.uid);
    } else {
      _stopUserDocListener();
      _currentUser = null;
      notifyListeners();
    }
      
    });
  }

  // ── Real-time user doc listener ───────────────────────────────────────────
  // Whenever Firestore writes patientId to the guardian's doc,
  // this fires and updates _currentUser → notifyListeners() →
  // GlobalNavigation rebuilds → GuardianLinkView replaced by HomeView.
  void _startUserDocListener(String uid) {
    _stopUserDocListener(); // cancel any existing subscription first
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('[AuthController] userDoc listener error: $e');
    });
  }

  void _stopUserDocListener() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
  }

  @override
  void dispose() {
    _stopUserDocListener();
    super.dispose();
  }

  // ── Reload user from Firestore (one-shot, used on hot restart) ────────────
  Future<void> reloadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    try {
      final user = await _service.fetchUserByUid(firebaseUser.uid);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthController] reloadCurrentUser error: $e');
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  void _updateStatus(String msg) {
    _status = msg;
    notifyListeners();
  }

  void setStatus(String msg) => _updateStatus(msg);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearStatus() {
    _status = '';
    notifyListeners();
  }

  // ── effectiveDataId ───────────────────────────────────────────────────────
  String? get effectiveDataId {
  if (_currentUser == null) return null;
  if (_currentUser!.role == 'guardian') {
    final pid = _currentUser!.patientId;
    return (pid != null && pid.isNotEmpty) ? pid : null;
  }
  return _currentUser!.uid;
}

  // ==========================================================================
  // SIGN UP
  // ==========================================================================
  Future<void> signUp(
    String email,
    String password,
    String fullName,
    String username,
    String role,
  ) async {
    try {
      _setLoading(true);
      _updateStatus('Creating account...');
      await _service.registerUser(email, password, fullName, username, role);
      _updateStatus(
        'Account created! Please check your email to verify your account.',
      );
    } catch (e) {
      _updateStatus(_formatErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // LOGIN
  // ==========================================================================
  Future<void> login(
      String email, String password, BuildContext context) async {
    try {
      _setLoading(true);
      _updateStatus('Logging in...');
      _currentUser = await _service.loginUser(email, password);

      if (_currentUser == null) {
        _updateStatus('User data not found.');
        return;
      }

      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        firebaseUser = FirebaseAuth.instance.currentUser;

        if (firebaseUser != null)  { /* && firebaseUser.emailVerified*/ 
          _updateStatus('Welcome ${_currentUser!.fullName}!');
          notifyListeners();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const GlobalNavigation()),
            (route) => false,  // Remove ALL previous routes
          );
        /*} else {
          await FirebaseAuth.instance.signOut();
          _currentUser = null;
          _updateStatus(
            'Please verify your email first. '
            'Check your inbox (or spam folder).',
          );
        }*/}
      } else {
        _updateStatus('User not found.');
      }
    } catch (e) {
      _updateStatus(_formatErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // FORGOT PASSWORD
  // ==========================================================================
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _updateStatus('Sending reset email...');
      await _service.sendPasswordReset(email);
      _updateStatus('Password reset email sent!');
    } catch (e) {
      _updateStatus(_formatErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // UPDATE USERNAME
  // ==========================================================================
  Future<void> changeUsername(String newUsername) async {
    try {
      _setLoading(true);
      if (_currentUser == null) throw Exception('No logged-in user.');
      final trimmed = newUsername.trim();
      if (trimmed == _currentUser!.username) {
        _updateStatus('Username is unchanged.');
        return;
      }
      _updateStatus('Updating username...');
      await _service.updateUsername(_currentUser!.uid, trimmed);
      final updated = await _service.fetchUserByUid(_currentUser!.uid);
      if (updated == null) throw Exception('Failed to refresh user data.');
      _currentUser = updated;
      _updateStatus('Username updated successfully.');
    } catch (e) {
      _updateStatus(_formatErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // GUARDIAN LINKING
  // ==========================================================================

  Future<void> generateGuardianCode() async {
    try {
      _setLoading(true);
      if (_currentUser == null) return;
      if (isCodeValid()) {
        _updateStatus('Existing code is still valid (30 mins).');
        return;
      }
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rng   = Random.secure();
      final part  = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
      final newCode = 'PAT-$part';
      await _service.updateLinkCode(_currentUser!.uid, newCode);
      _currentUser = _currentUser!.copyWith(
        linkCode:          newCode,
        linkCodeCreatedAt: DateTime.now(),
      );
      notifyListeners();
      _updateStatus('Code generated: $newCode');
    } catch (e) {
      _updateStatus('Failed to generate code: $e');
    } finally {
      _setLoading(false);
    }
  }

  bool isCodeValid() {
    if (_currentUser == null) return false;
    if (_currentUser!.linkCode == null) return false;
    final createdAt = _currentUser!.linkCodeCreatedAt;
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inMinutes <= 30;
  }

  Stream<ConnectionRequest?> pendingRequestStream() {
    if (_currentUser == null) return const Stream.empty();
    return _service.streamPendingRequest(_currentUser!.uid);
  }

  Future<ConnectionRequest?> fetchPendingRequest() async {
    if (_currentUser == null) return null;
    return await _service.fetchPendingRequest(_currentUser!.uid);
  }

  Future<UserModel?> findPatientByCode(String code) async {
    try {
      _setLoading(true);
      return await _service.findPatientByCode(code);
    } catch (e) {
      _updateStatus('Search failed: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestToLink(String patientId) async {
    try {
      _setLoading(true);
      if (_currentUser == null) return;
      final request = ConnectionRequest(
        requestId:    _currentUser!.uid,
        guardianId:   _currentUser!.uid,
        patientId:    patientId,
        guardianName: _currentUser!.fullName,
        status:       'pending',
        createdAt:    DateTime.now(),
      );
      await _service.sendConnectionRequest(request);
      _updateStatus('Request sent successfully!');
    } catch (e) {
      _updateStatus('Failed to send request: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveGuardianRequest(String guardianId) async {
    try {
      _setLoading(true);
      if (_currentUser == null) return;
      final patientId = _currentUser!.uid;
      // establishLink: writes patientId→guardian, guardianId→patient, deletes request doc
      // The guardian's _userDocListener will auto-fire and update their UI
      await _service.establishLink(patientId, guardianId);
      // Refresh patient's own local data
      final updated = await _service.fetchUserByUid(patientId);
      if (updated != null) _currentUser = updated;
      _updateStatus('Guardian linked successfully!');
      notifyListeners();
    } catch (e) {
      _updateStatus('Error approving: $e');
    } finally {
      _setLoading(false);
    }
  }


  Future<void> revokeGuardian() async {
    try {
      _setLoading(true);
      if (_currentUser == null) return;
      
      await _service.revokeGuardianship(_currentUser!);
      
      // Refresh local user data
      final updatedUser = await _service.fetchUserByUid(_currentUser!.uid);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
      
      // Role-specific messages
      if (_currentUser!.role == 'patient') {
        _updateStatus('Guardian removed successfully.');
      } else {
        _updateStatus('Patient unlinked successfully.');
      }
    } catch (e) {
      _updateStatus('Error unlinking: ${_formatErrorMessage(e.toString())}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectGuardianRequest() async {
    try {
      _setLoading(true);
      if (_currentUser == null) return;
      await _service.rejectRequest(_currentUser!.uid);
      _updateStatus('Request rejected.');
    } catch (e) {
      _updateStatus('Error rejecting request: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateLastLogin(String uid) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'lastLogin': FieldValue.serverTimestamp(),
          'active': true,
        }, SetOptions(merge: true));  // merge = safe, won't delete other fields
  } catch (e) {
    debugPrint('lastLogin update failed: $e');  // Silent fail OK
  }
}

  // ==========================================================================
  // UPDATE PASSWORD
  // ==========================================================================
  Future<void> changePassword(String newPassword) async {
    try {
      _setLoading(true);
      _updateStatus('Updating password...');
      await _service.updatePassword(newPassword);
      _updateStatus('Password updated successfully.');
    } catch (e) {
      _updateStatus(_formatErrorMessage(e.toString()));
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================
  Future<void> logout(BuildContext context) async {
  try {
    _setLoading(true);
    
    // ✅ CRITICAL: Cancel listener BEFORE signout
    _stopUserDocListener();
    _currentUser = null;
    notifyListeners(); // Clear UI first
    
    // ✅ Sign out Firebase Auth
    await _service.logoutUser();
    
    _updateStatus('Logged out successfully');
    
    // ✅ Safe navigation using root navigator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeView()),
        (route) => false,
      );
    });
    
  } catch (e) {
    debugPrint('Logout error: $e');
    _updateStatus('Logout failed: $_formatErrorMessage(e.toString())');
    
    // Force clear even on error
    _stopUserDocListener();
    _currentUser = null;
    notifyListeners();
    
  } finally {
    _setLoading(false);
  }
}


  // ==========================================================================
  // ERROR FORMATTING
  // ==========================================================================
  String _formatErrorMessage(String error) {
    if (error.contains('user-not-found'))      return 'No user found for this email';
    if (error.contains('wrong-password'))       return 'Incorrect password';
    if (error.contains('invalid-email'))        return 'Invalid email address';
    if (error.contains('user-disabled'))        return 'This user account has been disabled';
    if (error.contains('email-already-in-use')) return 'Email is already registered';
    if (error.contains('weak-password'))        return 'Password is too weak';
    if (error.contains('network'))              return 'Network error. Please check your connection';
    return error;
  }
}