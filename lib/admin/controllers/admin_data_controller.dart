// lib/admin/controllers/admin_data_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── Mismatch model ────────────────────────────────────────────────────────────
class LifestyleMismatch {
  final String uid;
  final String userName;
  final String tier;
  final double rapid3Score;
  final String mismatchType; // 'over_exercising' | 'under_nutrition' | 'high_stress'
  final String description;
  const LifestyleMismatch({
    required this.uid, required this.userName, required this.tier,
    required this.rapid3Score, required this.mismatchType,
    required this.description,
  });
}

// ── CRUD item (for global libraries) ─────────────────────────────────────────
class AdminCrudItem {
  final String id;
  final String collection;
  final Map<String, dynamic> data;
  const AdminCrudItem({required this.id, required this.collection, required this.data});
}

class AdminDataController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool   _loading   = false;
  String _error     = '';
  List<LifestyleMismatch> _mismatches = [];
  List<AdminCrudItem>     _exercises  = [];
  List<AdminCrudItem>     _nutrition  = [];
  String? _selectedCollection; // 'exercise_library' | 'nutrition_library'

  bool                    get loading    => _loading;
  String                  get error      => _error;
  List<LifestyleMismatch> get mismatches => _mismatches;
  List<AdminCrudItem>     get exercises  => _exercises;
  List<AdminCrudItem>     get nutrition  => _nutrition;
  String?                 get selectedCollection => _selectedCollection;

  // ── Load mismatches ───────────────────────────────────────────────────────
  Future<void> loadMismatches() async {
    _loading = true; notifyListeners();
    try {
      final users = await _db.collection('users').get();
      final results = <LifestyleMismatch>[];

      for (final userDoc in users.docs) {
        final data = userDoc.data();
        if ((data['role'] ?? '') == 'admin') continue;
        final tier  = (data['activeRapid3Tier'] ?? '').toString().toUpperCase();
        final score = (data['activeRapid3Score'] as num?)?.toDouble() ?? 0;
        if (tier.isEmpty) continue;

        // Get latest lifestyle entry
        final prog = await _db
            .collection('users').doc(userDoc.id)
            .collection('userLifestyleProgress')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (prog.docs.isEmpty) continue;
        final pd  = prog.docs.first.data();
        final nut = pd['nutritionLogged'] as Map<String, dynamic>?;
        final ex  = pd['exerciseLogs']   as Map<String, dynamic>?;

        final waterGlasses = (nut?['waterGlasses']    as num?)?.toInt() ?? 0;
        final adherence    = (nut?['adherencePercent'] as num?)?.toInt() ?? 0;
        final stressLevel  = (pd['stressLevel']        as num?)?.toDouble() ?? 0;

        final userName = data['fullName'] ?? data['username'] ?? userDoc.id;

        // Rule 1: HIGH tier but doing intense exercise
        if ((tier == 'HIGH' || tier == 'MODERATE') && ex != null) {
          for (final entry in ex.values) {
            final exId = (entry as Map<String, dynamic>?)?['exerciseId'] ?? '';
            if (exId.contains('remission') || exId.contains('low')) {
              results.add(LifestyleMismatch(
                uid: userDoc.id, userName: userName,
                tier: tier, rapid3Score: score,
                mismatchType: 'over_exercising',
                description: 'Performing high-intensity exercise during $tier tier. '
                    'Recommended: rest/gentle stretching only.',
              ));
              break;
            }
          }
        }

        // Rule 2: HIGH tier but low water intake
        if (tier == 'HIGH' && waterGlasses < 8) {
          results.add(LifestyleMismatch(
            uid: userDoc.id, userName: userName,
            tier: tier, rapid3Score: score,
            mismatchType: 'under_nutrition',
            description: 'Only $waterGlasses glasses of water during HIGH flare. '
                'Minimum 10 glasses recommended.',
          ));
        }

        // Rule 3: High stress + MODERATE/HIGH tier
        if (stressLevel >= 7 && (tier == 'MODERATE' || tier == 'HIGH')) {
          results.add(LifestyleMismatch(
            uid: userDoc.id, userName: userName,
            tier: tier, rapid3Score: score,
            mismatchType: 'high_stress',
            description: 'Stress level ${stressLevel.toStringAsFixed(1)}/10 '
                'during $tier tier. High stress is a known RA flare trigger.',
          ));
        }

        // Rule 4: LOW nutrition adherence during MODERATE
        if (tier == 'MODERATE' && adherence < 60) {
          results.add(LifestyleMismatch(
            uid: userDoc.id, userName: userName,
            tier: tier, rapid3Score: score,
            mismatchType: 'under_nutrition',
            description: 'Nutrition adherence $adherence% during MODERATE tier. '
                'Poor diet may worsen inflammation.',
          ));
        }
      }

      _mismatches = results;
      _loading = false; _error = '';
    } catch (e) {
      _error = e.toString(); _loading = false;
    }
    notifyListeners();
  }

  // ── Load exercise/nutrition library ──────────────────────────────────────
  Future<void> loadLibrary(String collection) async {
    _selectedCollection = collection;
    _loading = true; notifyListeners();
    try {
      final snap = await _db.collection(collection).get();
      final items = snap.docs.map((d) =>
          AdminCrudItem(id: d.id, collection: collection, data: d.data())).toList();
      if (collection == 'exercise_library') _exercises = items;
      else _nutrition = items;
      _loading = false; _error = '';
    } catch (e) {
      _error = e.toString(); _loading = false;
    }
    notifyListeners();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<void> createItem(String collection, Map<String, dynamic> data) async {
    try {
      final ref = await _db.collection(collection).add(data);
      data['id'] = ref.id;
      await ref.update({'id': ref.id});
      await loadLibrary(collection);
    } catch (e) {
      _error = e.toString(); notifyListeners();
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> updateItem(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(id).update(data);
      await loadLibrary(collection);
    } catch (e) {
      _error = e.toString(); notifyListeners();
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteItem(String collection, String id) async {
    try {
      await _db.collection(collection).doc(id).delete();
      await loadLibrary(collection);
    } catch (e) {
      _error = e.toString(); notifyListeners();
    }
  }
}