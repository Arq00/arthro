// ============================================================
// services/timeline_service.dart
//
// Single responsibility: given a userId + dateStr ("2026-02-25"),
// fetch everything that happened on that day from every module.
//
// Returns a DaySnapshot — one object, all modules, one date.
// Used by: HomeView Timeline + DayDetailSheet
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────
// Data classes — one per module
// ─────────────────────────────────────────────────────────────

class SymptomSnapshot {
  final double rapid3Score;
  final String rapid3Tier;
  final double pain;
  final double functionScore;
  final double globalAssessment;
  final String logTime;
  final int attempt; // retake count

  SymptomSnapshot({
    required this.rapid3Score,
    required this.rapid3Tier,
    required this.pain,
    required this.functionScore,
    required this.globalAssessment,
    required this.logTime,
    required this.attempt,
  });

  factory SymptomSnapshot.fromMap(Map<String, dynamic> d) => SymptomSnapshot(
        rapid3Score:      (d['rapid3Score']      ?? 0).toDouble(),
        rapid3Tier:       d['rapid3Tier']        ?? 'REMISSION',
        pain:             (d['pain']             ?? 0).toDouble(),
        functionScore:    (d['function']         ?? 0).toDouble(),
        globalAssessment: (d['globalAssessment'] ?? 0).toDouble(),
        logTime:          d['logTime']           ?? '',
        attempt:          (d['attempt']          ?? 1).toInt(),
      );
}

class LifestyleSnapshot {
  final bool exerciseDone;
  final String? exerciseName;
  final int? durationMinutes;
  final bool nutritionDone;
  final String? nutritionFocus;
  final int? waterGlasses;
  final bool? avoidedTriggers;
  final int adherenceScore;

  LifestyleSnapshot({
    required this.exerciseDone,
    this.exerciseName,
    this.durationMinutes,
    required this.nutritionDone,
    this.nutritionFocus,
    this.waterGlasses,
    this.avoidedTriggers,
    required this.adherenceScore,
  });

  factory LifestyleSnapshot.fromMap(Map<String, dynamic> d) {
    final ex  = d['exerciseLogged']  as Map<String, dynamic>?;
    final nut = d['nutritionLogged'] as Map<String, dynamic>?;
    return LifestyleSnapshot(
      exerciseDone:    ex?['completed']      == true,
      exerciseName:    ex?['exerciseName']   as String?,
      durationMinutes: (ex?['durationMinutes'] as num?)?.toInt(),
      nutritionDone:   nut?['completed']     == true,
      nutritionFocus:  nut?['focusArea']     as String?,
      waterGlasses:    (nut?['waterGlasses'] as num?)?.toInt(),
      avoidedTriggers: nut?['avoidedTriggers'] as bool?,
      adherenceScore:  (d['adherenceScore']  ?? 0).toInt(),
    );
  }
}

class MedicationSnapshot {
  final int taken;
  final int total;
  final List<MedDose> doses;

  MedicationSnapshot({
    required this.taken,
    required this.total,
    required this.doses,
  });

  double get adherencePct => total > 0 ? taken / total : 0;
}

class MedDose {
  final String name;
  final String dosage;
  final bool taken;
  final String? takenAt;

  MedDose({
    required this.name,
    required this.dosage,
    required this.taken,
    this.takenAt,
  });
}

class AppointmentSnapshot {
  final String title;
  final String doctorName;
  final String time;
  final String location;
  final String status; // "scheduled"|"completed"|"cancelled"

  AppointmentSnapshot({
    required this.title,
    required this.doctorName,
    required this.time,
    required this.location,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────
// The combined snapshot for one day
// ─────────────────────────────────────────────────────────────

class DaySnapshot {
  final String dateStr;       // "2026-02-25"
  final String dateLabel;     // "Feb 25"
  final SymptomSnapshot?    symptom;
  final LifestyleSnapshot?  lifestyle;
  final MedicationSnapshot? medication;
  final List<AppointmentSnapshot> appointments;

  DaySnapshot({
    required this.dateStr,
    required this.dateLabel,
    this.symptom,
    this.lifestyle,
    this.medication,
    this.appointments = const [],
  });

  // True if any module has data for this day
  bool get hasAnyData =>
      symptom != null ||
      lifestyle != null ||
      (medication != null && medication!.total > 0) ||
      appointments.isNotEmpty;

  // Overall day score 0–100 (used for timeline dot colour)
  int get overallScore {
    int points = 0;
    int weight = 0;
    if (symptom != null) {
      // Lower RAPID3 = better = higher score
      final s = ((10 - symptom!.rapid3Score) / 10 * 100).clamp(0, 100).toInt();
      points += s; weight++;
    }
    if (lifestyle != null) {
      points += lifestyle!.adherenceScore; weight++;
    }
    if (medication != null && medication!.total > 0) {
      points += (medication!.adherencePct * 100).toInt(); weight++;
    }
    return weight > 0 ? (points / weight).round() : -1;
  }
}

// ─────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────

class TimelineService {
  final _db = FirebaseFirestore.instance;

  // Fetch snapshots for the last [days] days — for the date strip
  Future<List<DaySnapshot>> fetchRecentSnapshots({
    required String userId,
    int days = 30,
  }) async {
    final now = DateTime.now();
    final dates = List.generate(
      days,
      (i) => now.subtract(Duration(days: i)),
    ); // newest first

    // Fetch all module data in parallel
    final results = await Future.wait([
      _fetchSymptomRange(userId, days),
      _fetchLifestyleRange(userId, days),
      _fetchMedicationRange(userId, days),
      _fetchAppointmentRange(userId, days),
    ]);

    final symptomMap     = results[0] as Map<String, SymptomSnapshot>;
    final lifestyleMap   = results[1] as Map<String, LifestyleSnapshot>;
    final medMap         = results[2] as Map<String, MedicationSnapshot>;
    final apptMap        = results[3] as Map<String, List<AppointmentSnapshot>>;

    return dates.map((dt) {
      final ds = dt.toIso8601String().split('T')[0];
      return DaySnapshot(
        dateStr:      ds,
        dateLabel:    _label(dt),
        symptom:      symptomMap[ds],
        lifestyle:    lifestyleMap[ds],
        medication:   medMap[ds],
        appointments: apptMap[ds] ?? [],
      );
    }).toList();
  }

  // Fetch single day — for DayDetailSheet
  Future<DaySnapshot> fetchDay({
    required String userId,
    required String dateStr,
  }) async {
    final results = await Future.wait([
      _fetchSymptomDoc(userId, dateStr),
      _fetchLifestyleDoc(userId, dateStr),
      _fetchMedicationDoc(userId, dateStr),
      _fetchAppointmentsForDay(userId, dateStr),
    ]);

    final dt = DateTime.parse(dateStr);
    return DaySnapshot(
      dateStr:      dateStr,
      dateLabel:    _label(dt),
      symptom:      results[0] as SymptomSnapshot?,
      lifestyle:    results[1] as LifestyleSnapshot?,
      medication:   results[2] as MedicationSnapshot?,
      appointments: results[3] as List<AppointmentSnapshot>,
    );
  }

  // ── symptomLogs ──────────────────────────────────────────
  Future<Map<String, SymptomSnapshot>> _fetchSymptomRange(
      String userId, int days) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('symptomLogs')
          .where('logDate', isGreaterThanOrEqualTo: cutoff)
          .get();
      return {
        for (final doc in snap.docs)
          (doc.data()['logDate'] ?? doc.id.replaceFirst('log_', '')):
              SymptomSnapshot.fromMap(doc.data())
      };
    } catch (_) {
      return {};
    }
  }

  Future<SymptomSnapshot?> _fetchSymptomDoc(
      String userId, String dateStr) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('symptomLogs')
          .doc('log_$dateStr')
          .get();
      if (!doc.exists) return null;
      return SymptomSnapshot.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── userLifestyleProgress ────────────────────────────────
  Future<Map<String, LifestyleSnapshot>> _fetchLifestyleRange(
      String userId, int days) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('userLifestyleProgress')
          .where('progressDate', isGreaterThanOrEqualTo: cutoff)
          .get();
      return {
        for (final doc in snap.docs)
          (doc.data()['progressDate'] ?? doc.id):
              LifestyleSnapshot.fromMap(doc.data())
      };
    } catch (_) {
      return {};
    }
  }

  Future<LifestyleSnapshot?> _fetchLifestyleDoc(
      String userId, String dateStr) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('userLifestyleProgress')
          .doc(dateStr)
          .get();
      if (!doc.exists) return null;
      return LifestyleSnapshot.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ── medication logs ───────────────────────────────────────
  // Assumes subcollection: users/{uid}/medicationLogs/{date}
  // Adapt doc ID / field names to match your actual medication module.
  Future<Map<String, MedicationSnapshot>> _fetchMedicationRange(
      String userId, int days) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('medicationLogs')
          .where('logDate', isGreaterThanOrEqualTo: cutoff)
          .get();
      final map = <String, MedicationSnapshot>{};
      for (final doc in snap.docs) {
        final d    = doc.data();
        final date = d['logDate'] as String? ?? doc.id;
        final doses = (d['doses'] as List<dynamic>? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return MedDose(
            name:    m['name']    ?? '',
            dosage:  m['dosage']  ?? '',
            taken:   m['taken']   == true,
            takenAt: m['takenAt'] as String?,
          );
        }).toList();
        map[date] = MedicationSnapshot(
          taken: doses.where((d) => d.taken).length,
          total: doses.length,
          doses: doses,
        );
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<MedicationSnapshot?> _fetchMedicationDoc(
      String userId, String dateStr) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('medicationLogs')
          .doc(dateStr)
          .get();
      if (!doc.exists) return null;
      final d = doc.data()!;
      final doses = (d['doses'] as List<dynamic>? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return MedDose(
          name:    m['name']    ?? '',
          dosage:  m['dosage']  ?? '',
          taken:   m['taken']   == true,
          takenAt: m['takenAt'] as String?,
        );
      }).toList();
      return MedicationSnapshot(
        taken: doses.where((d) => d.taken).length,
        total: doses.length,
        doses: doses,
      );
    } catch (_) {
      return null;
    }
  }

  // ── appointments ─────────────────────────────────────────
  Future<Map<String, List<AppointmentSnapshot>>> _fetchAppointmentRange(
      String userId, int days) async {
    try {
      final cutoff = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .where('appointmentDate', isGreaterThanOrEqualTo: cutoff)
          .get();
      final map = <String, List<AppointmentSnapshot>>{};
      for (final doc in snap.docs) {
        final d    = doc.data();
        final date = (d['appointmentDate'] as String? ?? '').split('T')[0];
        map.putIfAbsent(date, () => []).add(AppointmentSnapshot(
          title:       d['title']       ?? d['type']        ?? 'Appointment',
          doctorName:  d['doctorName']  ?? d['doctor']      ?? '',
          time:        d['appointmentTime'] ?? d['time']    ?? '',
          location:    d['location']    ?? d['clinic']      ?? '',
          status:      d['status']      ?? 'scheduled',
        ));
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<List<AppointmentSnapshot>> _fetchAppointmentsForDay(
      String userId, String dateStr) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('appointments')
          .where('appointmentDate', isGreaterThanOrEqualTo: dateStr)
          .where('appointmentDate', isLessThan: '${dateStr}T99')
          .get();
      return snap.docs.map((doc) {
        final d = doc.data();
        return AppointmentSnapshot(
          title:      d['title']           ?? d['type']   ?? 'Appointment',
          doctorName: d['doctorName']      ?? d['doctor'] ?? '',
          time:       d['appointmentTime'] ?? d['time']   ?? '',
          location:   d['location']        ?? d['clinic'] ?? '',
          status:     d['status']          ?? 'scheduled',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Monthly report data ───────────────────────────────────
  Future<MonthlyReport> fetchMonthlyReport({
    required String userId,
    required int year,
    required int month,
  }) async {
    final snapshots = await fetchRecentSnapshots(userId: userId, days: 90);
    final monthStr  = '$year-${month.toString().padLeft(2, '0')}';
    final inMonth   = snapshots
        .where((s) => s.dateStr.startsWith(monthStr))
        .toList();

    final symptomDays   = inMonth.where((s) => s.symptom != null).toList();
    final lifestyleDays = inMonth.where((s) => s.lifestyle != null).toList();
    final medDays       = inMonth.where((s) => s.medication != null).toList();

    final avgRapid3 = symptomDays.isNotEmpty
        ? symptomDays
                .map((s) => s.symptom!.rapid3Score)
                .reduce((a, b) => a + b) /
            symptomDays.length
        : null;

    final avgAdherence = lifestyleDays.isNotEmpty
        ? lifestyleDays
                .map((s) => s.lifestyle!.adherenceScore)
                .reduce((a, b) => a + b) /
            lifestyleDays.length
        : null;

    final avgMedAdherence = medDays.isNotEmpty
        ? medDays
                .map((s) => s.medication!.adherencePct * 100)
                .reduce((a, b) => a + b) /
            medDays.length
        : null;

    // Dominant tier this month
    final tierCounts = <String, int>{};
    for (final s in symptomDays) {
      tierCounts[s.symptom!.rapid3Tier] =
          (tierCounts[s.symptom!.rapid3Tier] ?? 0) + 1;
    }
    final dominantTier = tierCounts.isEmpty
        ? null
        : tierCounts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;

    return MonthlyReport(
      year:              year,
      month:             month,
      totalDaysLogged:   symptomDays.length,
      avgRapid3:         avgRapid3,
      dominantTier:      dominantTier,
      lifestyleDaysLogged:   lifestyleDays.length,
      avgLifestyleAdherence: avgAdherence,
      avgMedAdherence:   avgMedAdherence,
      allAppointments:   inMonth.expand((s) => s.appointments).toList(),
    );
  }

  String _label(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}';
  }
}

// ─────────────────────────────────────────────────────────────
// Monthly report model
// ─────────────────────────────────────────────────────────────

class MonthlyReport {
  final int year;
  final int month;
  final int totalDaysLogged;
  final double? avgRapid3;
  final String? dominantTier;
  final int lifestyleDaysLogged;
  final double? avgLifestyleAdherence;
  final double? avgMedAdherence;
  final List<AppointmentSnapshot> allAppointments;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.totalDaysLogged,
    this.avgRapid3,
    this.dominantTier,
    required this.lifestyleDaysLogged,
    this.avgLifestyleAdherence,
    this.avgMedAdherence,
    required this.allAppointments,
  });

  String get monthLabel {
    const months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    return '${months[month - 1]} $year';
  }
}