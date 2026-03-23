// lib/admin/controllers/admin_dashboard_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── Models ────────────────────────────────────────────────────────────────────
class TierDistribution {
  final int remission, low, moderate, high, unknown;
  const TierDistribution({this.remission=0, this.low=0,
      this.moderate=0, this.high=0, this.unknown=0});
  int get total => remission + low + moderate + high + unknown;
}

class Rapid3DayPoint {
  final DateTime date;
  final double   avgScore;
  final int      count;
  const Rapid3DayPoint(
      {required this.date, required this.avgScore, required this.count});
}

class UserActivitySummary {
  final int totalUsers, activeUsers, inactiveUsers, terminatedUsers, newThisWeek;
  const UserActivitySummary({
    this.totalUsers=0, this.activeUsers=0, this.inactiveUsers=0,
    this.terminatedUsers=0, this.newThisWeek=0,
  });
}

class CorrelationPoint {
  final double rapid3Score, lifestyleScore;
  final String uid, tier;
  const CorrelationPoint({required this.rapid3Score,
      required this.lifestyleScore, required this.uid, required this.tier});
}

// EULAR response model
class EularSummary {
  final int good, moderate, none, total;
  const EularSummary({this.good=0, this.moderate=0, this.none=0, this.total=0});
  double get goodPct     => total == 0 ? 0 : good     / total * 100;
  double get moderatePct => total == 0 ? 0 : moderate / total * 100;
  double get nonePct     => total == 0 ? 0 : none     / total * 100;
}

class EularPatient {
  final String uid, name;
  final double startScore, currentScore, delta;
  final String response; // 'good' | 'moderate' | 'none'
  const EularPatient({required this.uid, required this.name,
      required this.startScore, required this.currentScore,
      required this.delta, required this.response});
}

// ── Controller ────────────────────────────────────────────────────────────────
class AdminDashboardController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool   _loading = true;
  String _error   = '';

  TierDistribution       _tierDist    = const TierDistribution();
  UserActivitySummary    _activity    = const UserActivitySummary();
  List<Rapid3DayPoint>   _trend       = [];
  List<CorrelationPoint> _correlation = [];
  EularSummary           _eular       = const EularSummary();
  List<EularPatient>     _eularList   = [];
  double _avgRapid3 = 0;
  int    _totalLogs = 0;

  bool                   get loading     => _loading;
  String                 get error       => _error;
  TierDistribution       get tierDist    => _tierDist;
  UserActivitySummary    get activity    => _activity;
  List<Rapid3DayPoint>   get trend       => _trend;
  List<CorrelationPoint> get correlation => _correlation;
  EularSummary           get eular       => _eular;
  List<EularPatient>     get eularList   => _eularList;
  double                 get avgRapid3   => _avgRapid3;
  int                    get totalLogs   => _totalLogs;

  StreamSubscription? _sub;

  void init() {
    _sub?.cancel();
    _sub = _db.collection('users').snapshots().listen(
      _processUsers, onError: (e) { _error = e.toString(); notifyListeners(); });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Future<void> _processUsers(QuerySnapshot snap) async {
    _loading = true; notifyListeners();
    try {
      final docs  = snap.docs;
      final now   = DateTime.now();
      final week  = now.subtract(const Duration(days: 7));
      final sixMo = now.subtract(const Duration(days: 180));

      int remission=0, low=0, moderate=0, high=0, unknown=0;
      int active=0, inactive=0, terminated=0, newThisWeek=0;
      final allScores = <double>[];

      for (final doc in docs) {
        final d    = doc.data() as Map<String, dynamic>;
        if ((d['role'] ?? '') == 'admin') continue;

        final stored = (d['status'] ?? '').toString().toLowerCase();
        if (stored == 'terminated') { terminated++; continue; }

        DateTime? lastActive;
        final tua = d['tierUpdatedAt'];
        if (tua is Timestamp) lastActive = tua.toDate();
        final ca = d['createdAt'];

        final isInact = lastActive != null && lastActive.isBefore(sixMo);
        isInact ? inactive++ : active++;

        if (ca is Timestamp && ca.toDate().isAfter(week)) newThisWeek++;

        final tier  = (d['activeRapid3Tier'] ?? '').toString().toUpperCase();
        switch (tier) {
          case 'REMISSION': remission++; break;
          case 'LOW':       low++;       break;
          case 'MODERATE':  moderate++;  break;
          case 'HIGH':      high++;      break;
          default:          unknown++;
        }

        final s = d['activeRapid3Score'];
        if (s != null) allScores.add((s as num).toDouble());
      }

      _tierDist = TierDistribution(remission: remission, low: low,
          moderate: moderate, high: high, unknown: unknown);
      _activity = UserActivitySummary(totalUsers: docs.length,
          activeUsers: active, inactiveUsers: inactive,
          terminatedUsers: terminated, newThisWeek: newThisWeek);
      _avgRapid3 = allScores.isEmpty ? 0
          : allScores.reduce((a,b)=>a+b) / allScores.length;

      await Future.wait([
        _loadTrend(docs),
        _loadCorrelation(docs),
        _loadEular(docs),
      ]);

      _loading = false; _error = '';
    } catch (e) {
      _error = e.toString(); _loading = false;
    }
    notifyListeners();
  }

  Future<void> _loadTrend(List<QueryDocumentSnapshot> userDocs) async {
    final now  = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final byDay = <String, List<double>>{
      for (final d in days) _dk(d): [],
    };

    await Future.wait(userDocs.take(60).map((doc) async {
      try {
        final logs = await _db.collection('users').doc(doc.id)
            .collection('symptomLogs')
            .where('timestamp',
                isGreaterThanOrEqualTo: days.first.millisecondsSinceEpoch,
                isLessThanOrEqualTo: now.millisecondsSinceEpoch)
            .get();
        for (final l in logs.docs) {
          final d  = l.data();
          final ts = d['timestamp'];
          if (ts == null) continue;
          final dt  = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());
          final key = _dk(dt);
          final sc  = d['rapid3Score'];
          if (sc != null && byDay.containsKey(key)) {
            byDay[key]!.add((sc as num).toDouble());
          }
        }
      } catch (_) {}
    }));

    _trend = days.map((d) {
      final sc  = byDay[_dk(d)] ?? [];
      final avg = sc.isEmpty ? 0.0 : sc.reduce((a,b)=>a+b) / sc.length;
      return Rapid3DayPoint(date: d, avgScore: avg, count: sc.length);
    }).toList();
    _totalLogs = _trend.fold(0, (s, p) => s + p.count);
  }

  Future<void> _loadCorrelation(List<QueryDocumentSnapshot> userDocs) async {
    final pts = <CorrelationPoint>[];
    await Future.wait(userDocs.take(40).map((doc) async {
      try {
        final d    = doc.data() as Map<String, dynamic>;
        if ((d['status'] ?? '') == 'terminated') return;
        final tier = (d['activeRapid3Tier'] ?? '').toString();
        final score= (d['activeRapid3Score'] as num?)?.toDouble();
        if (score == null) return;

        final prog = await _db.collection('users').doc(doc.id)
            .collection('userLifestyleProgress')
            .orderBy('timestamp', descending: true).limit(7).get();
        if (prog.docs.isEmpty) return;

        double total = 0; int cnt = 0;
        for (final p in prog.docs) {
          final nut = p.data()['nutritionLogged'] as Map<String,dynamic>?;
          final adh = (nut?['adherencePercent'] as num?)?.toDouble();
          if (adh != null) { total += adh; cnt++; }
        }
        if (cnt == 0) return;
        pts.add(CorrelationPoint(rapid3Score: score,
            lifestyleScore: total/cnt, uid: doc.id, tier: tier));
      } catch (_) {}
    }));
    _correlation = pts;
  }

  // ── EULAR response: compare first ever log vs current score ───────────────
  Future<void> _loadEular(List<QueryDocumentSnapshot> userDocs) async {
    int good=0, moderate=0, none=0;
    final patients = <EularPatient>[];

    await Future.wait(userDocs.take(50).map((doc) async {
      try {
        final d = doc.data() as Map<String, dynamic>;
        if ((d['role'] ?? '') == 'admin') return;
        if ((d['status'] ?? '') == 'terminated') return;
        final current = (d['activeRapid3Score'] as num?)?.toDouble();
        if (current == null) return;

        // Oldest symptom log = baseline
        final oldest = await _db.collection('users').doc(doc.id)
            .collection('symptomLogs')
            .orderBy('timestamp').limit(1).get();
        if (oldest.docs.isEmpty) return;

        final baseline = (oldest.docs.first.data()['rapid3Score'] as num?)
            ?.toDouble();
        if (baseline == null) return;

        final delta    = baseline - current;
        final response = delta > 1.2 ? 'good'
            : delta >= 0.6 ? 'moderate' : 'none';

        if (response == 'good')     good++;
        else if (response=='moderate') moderate++;
        else none++;

        patients.add(EularPatient(
          uid: doc.id,
          name: d['fullName'] ?? d['username'] ?? 'Unknown',
          startScore: baseline, currentScore: current,
          delta: delta, response: response,
        ));
      } catch (_) {}
    }));

    final total = good + moderate + none;
    _eular     = EularSummary(good: good, moderate: moderate,
        none: none, total: total);
    // Sort: best improvers first
    _eularList = patients..sort((a,b) => b.delta.compareTo(a.delta));
  }

  Future<void> refresh() async {
    final snap = await _db.collection('users').get();
    await _processUsers(snap);
  }

  String _dk(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}';
}