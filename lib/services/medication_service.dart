// lib/services/medication_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';
import '../models/medication_log_model.dart';
import 'notification_service.dart';

class MedicationService {
  final _db = FirebaseFirestore.instance;
  final String? _overrideUid;
  MedicationService({String? uid}) : _overrideUid = uid;
  String get _uid => _overrideUid ?? FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _medRef =>
      _db.collection('users').doc(_uid).collection('medications');

  CollectionReference get _logRef =>
      _db.collection('users').doc(_uid).collection('logs');

  CollectionReference _summaryRef(String medId) =>
      _medRef.doc(medId).collection('dailySummary');

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<List<Medication>> streamMedications() {
    return _medRef.snapshots().map(
      (snap) => snap.docs
          .map((d) => Medication.fromFirestore(
              d.id, d.data() as Map<String, dynamic>))
          .toList(),
    );
  }

  Stream<List<MedicationLog>> streamHistory() {
    return _logRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MedicationLog.fromFirestore(
                d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addMedication(Medication med) async {
    final doc = await _medRef.add(med.toMap());
    // Schedule notifications using the Firestore-assigned ID
    await _scheduleNotification(med.copyWithId(doc.id));
  }

  Future<void> updateMedication(Medication med) async {
    await _medRef.doc(med.id).update(med.toMap());
    // Re-schedule — cancels old ones first inside scheduleMedication()
    await _scheduleNotification(med);
  }

  Future<void> deleteMedication(String medId) async {
    // 1. Cancel notifications
    await NotificationService.cancelMedication(medId);
    // 2. Delete doc — stream fires immediately, UI updates
    await _medRef.doc(medId).delete();
    // 3. Cleanup logs in background
    _cleanupLogsAndSummaries(medId);
  }

  // ─── Mark taken ───────────────────────────────────────────────────────────

  Future<void> markTaken(
    Medication med, {
    bool wasLate = false,
    List<String> sideEffects = const [],
    String? notes,
    DateTime? scheduledTime,
  }) async {
    final now = DateTime.now();

    final todayStart  = DateTime(now.year, now.month, now.day);
    final takenToday  = (await _logRef
            .where('medicationId', isEqualTo: med.id)
            .where('timestamp',
                isGreaterThanOrEqualTo:
                    todayStart.millisecondsSinceEpoch)
            .get())
        .docs
        .length;

    final maxPerDay = med.frequency == 'Twice Daily' ? 2 : 1;
    if (takenToday >= maxPerDay) return;

    final doseNumber = takenToday + 1;

    await _logRef.add(MedicationLog(
      id:                  '',
      medicationId:        med.id,
      medicationName:      med.name,
      timestamp:           now,
      doseNumber:          doseNumber,
      wasLate:             wasLate,
      sideEffectsReported: sideEffects,
      notes:               notes,
    ).toMap());

    final dayKey = _dayKey(scheduledTime ?? now);
    await _summaryRef(med.id).doc(dayKey).set({
      'taken':    FieldValue.increment(1),
      'expected': med.frequency == 'Twice Daily' ? 2 : 1,
      'date':     dayKey,
    }, SetOptions(merge: true));

    final updates = <String, dynamic>{
      'stockCurrent':
          (med.stockCurrent - med.perDose).clamp(0, med.stockMax),
      'lastTaken': now.millisecondsSinceEpoch,
    };
    if (med.firstTaken == null) {
      updates['firstTaken'] = now.millisecondsSinceEpoch;
    }
    await _medRef.doc(med.id).update(updates);

    // Re-check stock — show alert if now low/out after this dose
    final newStock =
        (med.stockCurrent - med.perDose).clamp(0, med.stockMax);
    if (newStock == 0 || (med.stockMax > 0 && newStock / med.stockMax <= 0.2)) {
      await _scheduleNotification(med..stockCurrent = newStock);
    }
  }

  // ─── Adherence summary ────────────────────────────────────────────────────

  Future<Map<String, Map<String, int>>> getDailySummary(
    String medId, {
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap   = await _summaryRef(medId)
        .where('date', isGreaterThanOrEqualTo: _dayKey(cutoff))
        .get();

    final result = <String, Map<String, int>>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      result[doc.id] = {
        'taken':    (data['taken']    as num?)?.toInt() ?? 0,
        'expected': (data['expected'] as num?)?.toInt() ?? 1,
      };
    }
    return result;
  }

  // ─── Notification helper ──────────────────────────────────────────────────

  Future<void> _scheduleNotification(Medication med) async {
    await NotificationService.scheduleMedication(
      medId:               med.id,
      medName:             med.name,
      dosage:              med.dosage,
      isReminderOn:        med.isReminderOn,
      reminderTime:        med.reminderTime,
      eveningReminderTime: med.eveningReminderTime,
      frequency:           med.frequency,
      weeklyDays:          med.weeklyDays,
      stockCurrent:        med.stockCurrent,
      stockMax:            med.stockMax,
    );
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  Future<void> _cleanupLogsAndSummaries(String medId) async {
    try {
      final snap = await _logRef
          .where('medicationId', isEqualTo: medId)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('[MedicationService] Could not delete logs: $e');
    }
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}