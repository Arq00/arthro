// lib/controllers/home_controller.dart
// CHANGE: Added progressSummary field + loads from ProgressService
// when user has an activeRapid3Score on their UserModel.

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:arthro/controllers/auth_controller.dart';
import '../services/home_service.dart';
import '../services/progress_service.dart';

export '../services/home_service.dart'
    show HomeBundle, HomeTodaySymptom, HomeMedSummary, HomeAppt;
export '../services/progress_service.dart' show ProgressSummary;

enum HomeState { idle, loading, ready, error }

class HomeController extends ChangeNotifier {
  final AuthController _auth;

  HomeController(this._auth) {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  // ── State ─────────────────────────────────────────────────────────────────
  HomeState _state = HomeState.idle;
  HomeState get state => _state;

  String _error = '';
  String get error => _error;

  // ── Data ──────────────────────────────────────────────────────────────────
  String            userName     = 'there';
  HomeTodaySymptom? todaySymptom;
  HomeMedSummary?   medSummary;
  HomeAppt?         nextAppt;
  ProgressSummary?  progressSummary;   // ← NEW

  // ── Derived ───────────────────────────────────────────────────────────────
  bool get hasLoggedToday => todaySymptom != null;

  double get rapid3 {
    if (todaySymptom == null) return 0.0;
    return todaySymptom!.rapid3Score;
  }

  String get tier {
    if (todaySymptom == null) return 'UNKNOWN';
    return todaySymptom!.rapid3Tier;
  }

  // Show progress card only when:
  // - user has a current score on their profile
  // - AND progress was successfully loaded (has a first log)
  bool get hasProgress => progressSummary != null;

  // ── Auth listener ─────────────────────────────────────────────────────────
  User? _lastUser;

  void _onAuthChanged(User? user) {
    if (user == null) { _reset(); return; }
    if (_lastUser?.uid == user.uid && _state == HomeState.ready) return;
    _lastUser = user;
    load();
  }

  void _reset() {
    userName        = 'there';
    todaySymptom    = null;
    medSummary      = null;
    nextAppt        = null;
    progressSummary = null;
    _setState(HomeState.idle);
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    final uid = _auth.effectiveDataId ??
                _lastUser?.uid ??
                FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      dev.log('[HomeController] uid null — waiting for auth');
      _setState(HomeState.idle);
      return;
    }

    _setState(HomeState.loading);
    try {
      // Load home bundle (existing)
      final bundle = await HomeService.instance.fetchHomeBundle(uid);
      userName     = bundle.userName;
      todaySymptom = bundle.todaySymptom;
      medSummary   = bundle.medSummary;
      nextAppt     = bundle.nextAppt;

      // ── Load progress summary ── NEW ──────────────────────────────────────
      // Use UserModel for current score (more reliable than today's log
      // since user might not have logged today)
      await _auth.reloadCurrentUser(); 
      final userModel = _auth.currentUser;
      final currentScore = userModel?.activeRapid3Score;
      final currentTier  = userModel?.activeRapid3Tier;

      if (currentScore != null && currentTier != null) {
        progressSummary = await ProgressService.instance.fetchProgress(
          uid:          uid,
          currentScore: currentScore,
          currentTier:  currentTier,
          currentDate:  userModel?.tierUpdatedAt,
        );
        dev.log('[HomeController] progress loaded: '
            '${progressSummary?.firstScore} → $currentScore');
      } else {
        // User hasn't completed any symptom log yet
        progressSummary = null;
        dev.log('[HomeController] no activeRapid3Score — skipping progress');
      }

      _setState(HomeState.ready);
    } catch (e) {
      dev.log('[HomeController] error: $e');
      _error = e.toString();
      _setState(HomeState.error);
    }
  }

  void _setState(HomeState s) {
    _state = s;
    notifyListeners();
  }
}