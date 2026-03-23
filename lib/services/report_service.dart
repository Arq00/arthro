// lib/services/report_service.dart
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/health_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log_model.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _db = FirebaseFirestore.instance;

  static String _logDateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  // ─── SYMPTOM LOGS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSymptomLogs(
    String uid, {
    int       days      = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final from    = startDate ?? DateTime.now().subtract(Duration(days: days));
      final to      = endDate   ?? DateTime.now();
      final fromKey = _logDateKey(from);
      final toKey   = _logDateKey(to);

      final snap = await _db
          .collection('users').doc(uid)
          .collection('symptomLogs')
          .where('logDate', isGreaterThanOrEqualTo: fromKey)
          .where('logDate', isLessThanOrEqualTo:    toKey)
          .orderBy('logDate', descending: true)
          .get();

      dev.log('[ReportService] symptomLogs: ${snap.docs.length} ($fromKey→$toKey)');
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      dev.log('[ReportService] fetchSymptomLogs error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllSymptomLogs(String uid) async {
    try {
      final snap = await _db
          .collection('users').doc(uid)
          .collection('symptomLogs')
          .orderBy('logDate', descending: false)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      dev.log('[ReportService] fetchAllSymptomLogs error: $e');
      return [];
    }
  }

  // ─── LIFESTYLE PROGRESS ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchLifestyleProgress(
    String uid, {
    int       days      = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final from    = startDate ?? DateTime.now().subtract(Duration(days: days));
      final to      = endDate   ?? DateTime.now();
      final fromKey = _logDateKey(from);
      final toKey   = _logDateKey(to);

      final snap = await _db
          .collection('users').doc(uid)
          .collection('userLifestyleProgress')
          .where('progressDate', isGreaterThanOrEqualTo: fromKey)
          .where('progressDate', isLessThanOrEqualTo:    toKey)
          .orderBy('progressDate', descending: true)
          .get();

      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      dev.log('[ReportService] fetchLifestyleProgress error: $e');
      return [];
    }
  }

  // ─── MEDICATIONS ─────────────────────────────────────────────────────────

  Future<List<Medication>> fetchMedications(String uid) async {
    try {
      final snap = await _db
          .collection('users').doc(uid)
          .collection('medications')
          .get();
      return snap.docs
          .map((d) => Medication.fromFirestore(d.id, _sanitiseMed(d.data())))
          .toList();
    } catch (e) {
      dev.log('[ReportService] fetchMedications error: $e');
      return [];
    }
  }

  Future<List<MedicationLog>> fetchMedLogs(
    String uid, {
    int       days      = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final from   = startDate ?? DateTime.now().subtract(Duration(days: days));
      final to     = endDate   ?? DateTime.now();
      final fromMs = DateTime(from.year, from.month, from.day)
          .millisecondsSinceEpoch;
      final toMs   = DateTime(to.year, to.month, to.day, 23, 59, 59)
          .millisecondsSinceEpoch;

      final snap = await _db
          .collection('users').doc(uid)
          .collection('logs')
          .where('timestamp', isGreaterThanOrEqualTo: fromMs)
          .where('timestamp', isLessThanOrEqualTo:    toMs)
          .orderBy('timestamp', descending: false)
          .get();

      return snap.docs
          .map((d) => MedicationLog.fromFirestore(d.id, _sanitiseLog(d.data())))
          .toList();
    } catch (e) {
      dev.log('[ReportService] fetchMedLogs error: $e');
      return [];
    }
  }

  static Map<String, dynamic> _sanitiseMed(Map<String, dynamic> d) => {
    ...d, 'isReminderOn': _asBool(d['isReminderOn'], fallback: true),
  };

  static Map<String, dynamic> _sanitiseLog(Map<String, dynamic> d) => {
    ...d, 'wasLate': _asBool(d['wasLate']),
  };

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null)   return fallback;
    if (v is bool)   return v;
    if (v is int)    return v != 0;
    if (v is double) return v != 0.0;
    return fallback;
  }

  // ─── USER PROFILE ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data() ?? {};
    } catch (e) {
      dev.log('[ReportService] fetchUserProfile error: $e');
      return {};
    }
  }

  // ─── APPOINTMENTS ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchUpcomingAppointments(
      String uid) async {
    try {
      final snap = await _db
          .collection('users').doc(uid)
          .collection('appointments')
          .where('isCompleted', isEqualTo: false)
          .orderBy('dateTime')
          .limit(3)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      dev.log('[ReportService] fetchUpcomingAppointments error: $e');
      return [];
    }
  }

  // ─── BUILD BUNDLE ────────────────────────────────────────────────────────

  Future<ReportBundle> buildReportBundle(
    String uid, {
    int       days      = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final from       = startDate ?? DateTime.now().subtract(Duration(days: days));
    final to         = endDate   ?? DateTime.now();
    final actualDays = to.difference(from).inDays + 1;

    final results = await Future.wait([
      fetchSymptomLogs(uid,       startDate: from, endDate: to),
      fetchLifestyleProgress(uid, startDate: from, endDate: to),
      fetchMedications(uid),
      fetchMedLogs(uid,           startDate: from, endDate: to),
      fetchUserProfile(uid),
      fetchAllSymptomLogs(uid),
    ]);

    dev.log('[ReportService] bundle: ${(results[0] as List).length} logs, '
        '${(results[2] as List).length} meds, span=$actualDays days');

    return ReportBundle(
      symptomRaw:   results[0] as List<Map<String, dynamic>>,
      lifestyleRaw: results[1] as List<Map<String, dynamic>>,
      medications:  results[2] as List<Medication>,
      medLogs:      results[3] as List<MedicationLog>,
      userProfile:  results[4] as Map<String, dynamic>,
      allSymptoms:  results[5] as List<Map<String, dynamic>>,
      periodDays:   actualDays,
      startDate:    from,
      endDate:      to,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ReportBundle {
  final List<Map<String, dynamic>> symptomRaw;
  final List<Map<String, dynamic>> lifestyleRaw;
  final List<Medication>           medications;
  final List<MedicationLog>        medLogs;
  final Map<String, dynamic>       userProfile;
  final List<Map<String, dynamic>> allSymptoms;
  final int                        periodDays;
  final DateTime                   startDate;
  final DateTime                   endDate;

  const ReportBundle({
    required this.symptomRaw,
    required this.lifestyleRaw,
    required this.medications,
    required this.medLogs,
    required this.userProfile,
    required this.allSymptoms,
    required this.periodDays,
    required this.startDate,
    required this.endDate,
  });
}