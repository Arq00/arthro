// lib/admin/controllers/admin_user_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminUserModel {
  final String uid, fullName, email, role, status;
  final String? patientId, guardianId, tier;
  final double? rapid3Score;
  final DateTime? lastActive, createdAt;
  final int logCount30d;

  const AdminUserModel({
    required this.uid, required this.fullName,
    required this.email, required this.role, required this.status,
    this.patientId, this.guardianId, this.tier, this.rapid3Score,
    this.lastActive, this.createdAt, this.logCount30d = 0,
  });

  bool get isTerminated => status == 'terminated';
  bool get isInactive   => status == 'inactive';
  bool get isActive     => status == 'active';

  String get displayRole => role == 'guardian' ? 'Guardian'
      : role == 'patient' ? 'Patient' : role;

  /// Activity % based on logs in last 30 days
  double get activityPct => (logCount30d / 30).clamp(0.0, 1.0);

  String get activityLabel {
    final p = activityPct;
    if (p >= 0.7) return 'Excellent';
    if (p >= 0.3) return 'Fair';
    return 'Poor';
  }

  Color get activityColor {
    final p = activityPct;
    if (p >= 0.7) return const Color(0xFF10B981);
    if (p >= 0.3) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

enum UserFilter { all, active, inactive, terminated }
enum SortField  { name, lastActive, tier, role, activity }

class AdminUserController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool   _loading = true;
  String _error   = '';

  List<AdminUserModel> _allUsers  = [];
  List<AdminUserModel> _filtered  = [];
  UserFilter _filter      = UserFilter.all;
  SortField  _sortField   = SortField.lastActive;
  bool       _sortAsc     = false;
  String     _searchQuery = '';

  // Bulk selection
  final Set<String> _selected = {};

  StreamSubscription? _sub;

  bool                 get loading        => _loading;
  String               get error          => _error;
  List<AdminUserModel> get users          => _filtered;
  UserFilter           get filter         => _filter;
  SortField            get sortField      => _sortField;
  bool                 get sortAsc        => _sortAsc;
  Set<String>          get selected       => _selected;
  bool                 get hasSelection   => _selected.isNotEmpty;

  int get totalCount      => _allUsers.where((u) => u.role != 'admin').length;
  int get activeCount     => _allUsers.where((u) => u.isActive).length;
  int get inactiveCount   => _allUsers.where((u) => u.isInactive).length;
  int get terminatedCount => _allUsers.where((u) => u.isTerminated).length;

  void init() {
    _sub?.cancel();
    _sub = _db.collection('users').snapshots().listen(
      (snap) => _process(snap),
      onError: (e) { _error = e.toString(); notifyListeners(); },
    );
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _process(QuerySnapshot snap) async {
    _loading = true; notifyListeners();

    final now   = DateTime.now();
    final sixMo = now.subtract(const Duration(days: 180));

    final users = <AdminUserModel>[];
    for (final doc in snap.docs) {
      final d    = doc.data() as Map<String, dynamic>;
      final role = (d['role'] ?? 'patient').toString().toLowerCase();
      if (role == 'admin') continue;

      // ── STATUS RESOLUTION (priority order) ────────────────────────────────
      // 1. If Firestore explicitly says 'terminated' → always terminated
      // 2. If last active > 6 months → inactive
      // 3. Otherwise → active
      final storedStatus = (d['status'] ?? '').toString().toLowerCase();

      DateTime? lastActive;
      final tua = d['tierUpdatedAt'];
      if (tua is Timestamp) lastActive = tua.toDate();
      final ca = d['createdAt'];
      DateTime? createdAt;
      if (ca is Timestamp) createdAt = ca.toDate();

      String status;
      if (storedStatus == 'terminated') {
        status = 'terminated';
      } else if (lastActive != null && lastActive.isBefore(sixMo)) {
        status = 'inactive';
      } else {
        status = 'active';
      }

      // ── Log count (cached field written during terminate/update) ───────────
      final logCount = (d['logCount30d'] as num?)?.toInt() ?? 0;

      users.add(AdminUserModel(
        uid:         doc.id,
        fullName:    d['fullName'] ?? d['username'] ?? 'Unknown',
        email:       d['email']   ?? '',
        role:        role,
        status:      status,
        patientId:   d['patientId']  as String?,
        guardianId:  d['guardianId'] as String?,
        tier:        d['activeRapid3Tier'] as String?,
        rapid3Score: (d['activeRapid3Score'] as num?)?.toDouble(),
        lastActive:  lastActive,
        createdAt:   createdAt,
        logCount30d: logCount,
      ));
    }

    _allUsers = users;
    _applyFilter();
    _loading = false;
    notifyListeners();
  }

  void setFilter(UserFilter f) { _filter = f; _applyFilter(); }
  void setSearch(String q)     { _searchQuery = q.toLowerCase(); _applyFilter(); }

  void setSort(SortField field) {
    _sortField == field ? _sortAsc = !_sortAsc : (_sortField = field, _sortAsc = true);
    _applyFilter();
  }

  // ── Bulk selection ─────────────────────────────────────────────────────────
  void toggleSelect(String uid) {
    _selected.contains(uid) ? _selected.remove(uid) : _selected.add(uid);
    notifyListeners();
  }

  void selectAll()   { _selected.addAll(_filtered.map((u) => u.uid)); notifyListeners(); }
  void clearSelect() { _selected.clear(); notifyListeners(); }

  void _applyFilter() {
    var list = _allUsers.where((u) {
      switch (_filter) {
        case UserFilter.active:     return u.isActive;
        case UserFilter.inactive:   return u.isInactive;
        case UserFilter.terminated: return u.isTerminated;
        case UserFilter.all:        return true;
      }
    }).toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(_searchQuery) ||
        u.email.toLowerCase().contains(_searchQuery)).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case SortField.name:
          cmp = a.fullName.compareTo(b.fullName); break;
        case SortField.lastActive:
          cmp = (a.lastActive ?? DateTime(2000))
              .compareTo(b.lastActive ?? DateTime(2000)); break;
        case SortField.tier:
          cmp = (a.tier ?? '').compareTo(b.tier ?? ''); break;
        case SortField.role:
          cmp = a.role.compareTo(b.role); break;
        case SortField.activity:
          cmp = a.logCount30d.compareTo(b.logCount30d); break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    _filtered = list;
    notifyListeners();
  }

  // ── TERMINATE — hard deletes all data + marks doc ─────────────────────────
  // FIX: now writes status='terminated' AND clears tier fields so the
  // status check in _process() always resolves to 'terminated' correctly.
  Future<bool> terminateUser(String uid) async {
    try {
      final subs = ['symptomLogs','userLifestyleProgress',
                    'medications','logs','appointments'];
      for (final sub in subs) {
        bool hasMore = true;
        while (hasMore) {
          final snap = await _db.collection('users').doc(uid)
              .collection(sub).limit(400).get();
          if (snap.docs.isEmpty) { hasMore = false; break; }
          final batch = _db.batch();
          for (final d in snap.docs) batch.delete(d.reference);
          await batch.commit();
        }
      }

      // Write status + clear tier so _process can't accidentally flip back
      await _db.collection('users').doc(uid).update({
        'status':            'terminated',
        'activeRapid3Tier':  FieldValue.delete(),
        'activeRapid3Score': FieldValue.delete(),
        'tierUpdatedAt':     FieldValue.delete(),
        'terminatedAt':      FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Terminate failed: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Bulk terminate ─────────────────────────────────────────────────────────
  Future<int> terminateBulk() async {
    int count = 0;
    final ids = List<String>.from(_selected);
    for (final uid in ids) {
      if (await terminateUser(uid)) count++;
    }
    clearSelect();
    return count;
  }

  // ── Auto-terminate inactive ────────────────────────────────────────────────
  Future<int> autoTerminateInactive() async {
    final inactive = _allUsers.where((u) => u.isInactive).toList();
    int count = 0;
    for (final u in inactive) {
      if (await terminateUser(u.uid)) count++;
    }
    return count;
  }

  String? getLinkedName(String? uid) {
    if (uid == null) return null;
    try { return _allUsers.firstWhere((u) => u.uid == uid).fullName; }
    catch (_) { return uid; }
  }
}