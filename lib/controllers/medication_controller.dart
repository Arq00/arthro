// lib/controllers/medication_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../models/medication_log_model.dart';
import '../models/scheduled_dose.dart';
import '../services/medication_service.dart';

class MedicationController extends ChangeNotifier {
  late final MedicationService _service;

  List<Medication>    medications = [];
  List<MedicationLog> historyLogs = [];

  MedicationController({String? uid}) {
  // ✅ SAFE: Wait for auth OR use provided uid
  final safeUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
  if (safeUid != null) {
    _service = MedicationService(uid: safeUid);
    _listenMedications();
    _listenHistory();
  } else {
    // Fallback: Initialize empty, auth will trigger navigation later
    _service = MedicationService(uid: 'temp');
    print('MedicationController: Waiting for auth...');
  }
}


  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STREAMS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _listenMedications() {
    _service.streamMedications().listen((meds) {
      medications = meds;
      notifyListeners();
    });
  }

  void _listenHistory() {
    _service.streamHistory().listen((logs) {
      historyLogs = logs;
      notifyListeners();
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DATE HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DOSE COUNTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int _takenCountOnDay(Medication med, DateTime day) => historyLogs
      .where((l) => l.medicationId == med.id && isSameDay(l.timestamp, day))
      .length;

  int takenCountToday(Medication med) =>
      _takenCountOnDay(med, DateTime.now());

  bool isFullyTakenToday(Medication med) =>
      takenCountToday(med) >= med.expectedDosesPerDay;

  bool isMorningTaken(Medication med) => historyLogs.any(
        (l) => l.medicationId == med.id &&
            isSameDay(l.timestamp, DateTime.now()) &&
            l.doseNumber == 1,
      );

  bool isEveningTaken(Medication med) => historyLogs.any(
        (l) => l.medicationId == med.id &&
            isSameDay(l.timestamp, DateTime.now()) &&
            l.doseNumber == 2,
      );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SCHEDULED DOSES — TODAY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<ScheduledDose> getScheduledDosesToday() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final doses = <ScheduledDose>[];

    for (final med in medications) {
      if (!med.isScheduledFor(today)) continue;

      if (med.frequency == 'Twice Daily') {
        final morningTime = DateTime(today.year, today.month, today.day,
            med.reminderTime.hour, med.reminderTime.minute);
        final morningTaken = isMorningTaken(med);
        doses.add(ScheduledDose(
          medication:    med,
          scheduledTime: morningTime,
          isMorning:     true,
          status: morningTaken ? DoseStatus.taken : _resolveStatus(med, morningTime, now),
        ));

        final eveningTod = med.eveningReminderTime ??
            TimeOfDay(
              hour:   (med.reminderTime.hour + 8).clamp(0, 23),
              minute: med.reminderTime.minute,
            );
        final eveningTime = DateTime(today.year, today.month, today.day,
            eveningTod.hour, eveningTod.minute);
        final eveningTaken = isEveningTaken(med);
        doses.add(ScheduledDose(
          medication:    med,
          scheduledTime: eveningTime,
          isMorning:     false,
          status: eveningTaken ? DoseStatus.taken : _resolveStatus(med, eveningTime, now),
        ));
      } else {
        final taken = isFullyTakenToday(med);
        final scheduledTime = med.isReminderOn
            ? DateTime(today.year, today.month, today.day,
                med.reminderTime.hour, med.reminderTime.minute)
            : today;
        doses.add(ScheduledDose(
          medication:    med,
          scheduledTime: scheduledTime,
          isMorning:     true,
          status: taken ? DoseStatus.taken : _resolveStatus(med, scheduledTime, now),
        ));
      }
    }

    doses.sort((a, b) {
      if (a.isAnytime && !b.isAnytime) return -1;
      if (!a.isAnytime && b.isAnytime) return 1;
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    return doses;
  }

  DoseStatus _resolveStatus(Medication med, DateTime scheduled, DateTime now) {
    if (!med.isReminderOn) return DoseStatus.anytime;
    final diff = scheduled.difference(now).inMinutes;
    if (diff < -30) return DoseStatus.missed;
    if (diff <= 30)  return DoseStatus.dueSoon;
    return DoseStatus.upcoming;
  }

  List<ScheduledDose> get _todayDoses  => getScheduledDosesToday();
  List<ScheduledDose> get dosesAnytime => _todayDoses.where((d) => d.status == DoseStatus.anytime).toList();
  List<ScheduledDose> get dosesDueSoon => _todayDoses.where((d) => d.status == DoseStatus.dueSoon).toList();
  List<ScheduledDose> get dosesMissed  => _todayDoses.where((d) => d.status == DoseStatus.missed).toList();
  List<ScheduledDose> get dosesUpcoming=> _todayDoses.where((d) => d.status == DoseStatus.upcoming).toList();
  List<ScheduledDose> get dosesTaken   => _todayDoses.where((d) => d.status == DoseStatus.taken).toList();

  (int done, int total) get todaySummary {
    final all  = _todayDoses;
    final done = all.where((d) => d.isTaken).length;
    return (done, all.length);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEATMAP DAY DETAIL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<DayMedDetail> getDayDetail(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final details  = <DayMedDetail>[];
    final now      = DateTime.now();
    final isToday  = isSameDay(day, now);

    for (final med in medications) {
      if (!med.isScheduledFor(dayStart)) continue;

      final taken    = _takenCountOnDay(med, dayStart);
      final expected = med.expectedDosesPerDay;

      final logs = historyLogs
          .where((l) => l.medicationId == med.id && isSameDay(l.timestamp, dayStart))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      DayMedStatus status;
      if (taken >= expected) {
        status = DayMedStatus.taken;
      } else if (taken > 0) {
        status = DayMedStatus.partial;
      } else if (isToday) {
        status = DayMedStatus.pending;
      } else {
        status = DayMedStatus.missed;
      }

      details.add(DayMedDetail(
        medication:  med,
        status:      status,
        taken:       taken,
        expected:    expected,
        loggedTimes: logs.map((l) => l.timestamp).toList(),
      ));
    }

    details.sort((a, b) => a.status.index.compareTo(b.status.index));
    return details;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7-DAY HEATMAP
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<HeatmapDay> get weeklyHeatmap {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));

      final activeMeds = medications.where((m) => m.isScheduledFor(day)).toList();
      if (activeMeds.isEmpty) {
        return HeatmapDay(date: day, status: HeatmapStatus.none);
      }

      if (isSameDay(day, today)) {
        final done = activeMeds
            .where((m) => _takenCountOnDay(m, day) >= m.expectedDosesPerDay)
            .length;
        if (done == activeMeds.length) return HeatmapDay(date: day, status: HeatmapStatus.taken);
        if (done > 0)                  return HeatmapDay(date: day, status: HeatmapStatus.partial);
        return HeatmapDay(date: day, status: HeatmapStatus.pending);
      }

      int totalExpected = 0, totalTaken = 0;
      for (final med in activeMeds) {
        totalExpected += med.expectedDosesPerDay;
        totalTaken    += _takenCountOnDay(med, day).clamp(0, med.expectedDosesPerDay);
      }

      if (totalTaken == 0)             return HeatmapDay(date: day, status: HeatmapStatus.missed);
      if (totalTaken >= totalExpected) return HeatmapDay(date: day, status: HeatmapStatus.taken);
      return HeatmapDay(date: day, status: HeatmapStatus.partial);
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 30-DAY ADHERENCE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  int get adherencePct {
    if (medications.isEmpty) return 100;
    int te = 0, tt = 0;
    final today = DateTime.now();
    for (int offset = 1; offset <= 30; offset++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      for (final med in medications) {
        if (!med.isScheduledFor(day)) continue;
        te += med.expectedDosesPerDay;
        tt += _takenCountOnDay(med, day).clamp(0, med.expectedDosesPerDay);
      }
    }
    if (te == 0) return 100;
    return ((tt / te) * 100).round().clamp(0, 100);
  }

  (int taken, int expected) get adherenceCounts {
    int te = 0, tt = 0;
    final today = DateTime.now();
    for (int offset = 1; offset <= 30; offset++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      for (final med in medications) {
        if (!med.isScheduledFor(day)) continue;
        te += med.expectedDosesPerDay;
        tt += _takenCountOnDay(med, day).clamp(0, med.expectedDosesPerDay);
      }
    }
    return (tt, te);
  }

  int get adherenceStreak {
    if (historyLogs.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    for (int offset = 1; offset <= 365; offset++) {
      final day  = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: offset));
      final meds = medications.where((m) => m.isScheduledFor(day)).toList();
      if (meds.isEmpty) break;
      final allTaken =
          meds.every((m) => _takenCountOnDay(m, day) >= m.expectedDosesPerDay);
      if (allTaken) { streak++; } else { break; }
    }
    return streak;
  }

  List<String> adherenceDots(Medication med, {int days = 14}) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: days - 1 - i));
      if (!med.isScheduledFor(day)) return 'future';
      if (isSameDay(day, today))    return 'future';
      final count    = _takenCountOnDay(med, day);
      final expected = med.expectedDosesPerDay;
      if (count == 0)        return 'missed';
      if (count >= expected) return 'taken';
      return 'partial';
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STOCK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  List<Medication> get lowStockMedications   => medications.where((m) => m.isLowStock).toList();
  List<Medication> get outOfStockMedications => medications.where((m) => m.isOutOfStock).toList();
  bool get hasLowStock   => lowStockMedications.isNotEmpty;
  bool get hasOutOfStock => outOfStockMedications.isNotEmpty;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CRUD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> addMedication(Medication med)    => _service.addMedication(med);
  Future<void> updateMedication(Medication med) => _service.updateMedication(med);
  Future<void> deleteMedication(String id)      => _service.deleteMedication(id);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MARK TAKEN
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> markDoseTaken(
    ScheduledDose dose, {
    List<String> sideEffects = const [],
    String? notes,
  }) async {
    final now     = DateTime.now();
    final wasLate = dose.medication.isReminderOn &&
        dose.scheduledTime.difference(now).inMinutes < -30;

    await _service.markTaken(
      dose.medication,
      wasLate:       wasLate,
      sideEffects:   sideEffects,
      notes:         notes,
      scheduledTime: dose.scheduledTime,
    );

    dose.medication.stockCurrent =
        (dose.medication.stockCurrent - dose.medication.perDose)
            .clamp(0, dose.medication.stockMax);
    dose.medication.firstTaken ??= now;
    dose.medication.lastTaken   = now;
    notifyListeners();
  }

  List<Medication> getAllTodayMedications() {
    final today = DateTime.now();
    return medications.where((m) => m.isScheduledFor(today)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEATMAP DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum HeatmapStatus { taken, partial, missed, pending, none }

class HeatmapDay {
  final DateTime      date;
  final HeatmapStatus status;
  const HeatmapDay({required this.date, required this.status});

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String get dayLabel {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[date.weekday - 1];
  }

  String get dayNum => date.day.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY DETAIL
// ─────────────────────────────────────────────────────────────────────────────

enum DayMedStatus { taken, partial, pending, missed }

class DayMedDetail {
  final Medication      medication;
  final DayMedStatus    status;
  final int             taken;
  final int             expected;
  final List<DateTime>  loggedTimes;

  const DayMedDetail({
    required this.medication,
    required this.status,
    required this.taken,
    required this.expected,
    required this.loggedTimes,
  });

  String get takenLabel => '$taken / $expected doses taken';

  String get timeLabel {
    if (loggedTimes.isEmpty) return '';
    return loggedTimes.map((t) {
      final h   = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
      final min = t.minute.toString().padLeft(2, '0');
      final per = t.hour < 12 ? 'AM' : 'PM';
      return '$h:$min $per';
    }).join(' · ');
  }
}