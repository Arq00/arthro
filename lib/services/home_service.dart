// lib/services/home_service.dart
// All Firestore paths and field names verified against:
//   - health_service.dart  → symptomLogs doc id = "log_YYYYMMDD"
//   - medication_model.dart → reminderTime = {hour, minute} map, frequency field
//   - medication_service.dart → logs collection = users/{uid}/logs, timestamp = ms
//   - appointment_model.dart → personInCharge, location, isCompleted, dateTime

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class HomeBundle {
  final String            userName;
  final HomeTodaySymptom? todaySymptom;
  final HomeMedSummary?   medSummary;
  final HomeAppt?         nextAppt;

  const HomeBundle({
    required this.userName,
    required this.todaySymptom,
    required this.medSummary,
    required this.nextAppt,
  });
}

class HomeTodaySymptom {
  final double       rapid3Score;
  final String       rapid3Tier;
  final double       pain;
  final double       function;
  final double       globalAssessment;
  final int          morningStiffnessMinutes;
  final double       stressLevel;
  final List<String> affectedJoints;

  const HomeTodaySymptom({
    required this.rapid3Score,
    required this.rapid3Tier,
    required this.pain,
    required this.function,
    required this.globalAssessment,
    required this.morningStiffnessMinutes,
    required this.stressLevel,
    required this.affectedJoints,
  });

  factory HomeTodaySymptom.fromMap(Map<String, dynamic> m) => HomeTodaySymptom(
    rapid3Score:             (m['rapid3Score']             as num?)?.toDouble() ?? 0,
    rapid3Tier:               m['rapid3Tier']              as String? ?? 'UNKNOWN',
    pain:                    (m['pain']                    as num?)?.toDouble() ?? 0,
    function:                (m['function']                as num?)?.toDouble() ?? 0,
    globalAssessment:        (m['globalAssessment']        as num?)?.toDouble() ?? 0,
    morningStiffnessMinutes: (m['morningStiffnessMinutes'] as num?)?.toInt()    ?? 0,
    stressLevel:             (m['stressLevel']             as num?)?.toDouble() ?? 0,
    affectedJoints:           List<String>.from(m['affectedJoints'] ?? []),
  );
}

class HomeMedSummary {
  final String name;        // first medication name
  final String dosage;      // e.g. "10mg"
  final String displayTime; // "9:00 AM"
  final int    takenToday;  // count of logs today (users/{uid}/logs)
  final int    totalDoses;  // expected doses today across all scheduled meds

  const HomeMedSummary({
    required this.name,
    required this.dosage,
    required this.displayTime,
    required this.takenToday,
    required this.totalDoses,
  });
}

class HomeAppt {
  final String   title;
  final String   personInCharge; // exact field from Appointment model
  final String   location;       // exact field from Appointment model
  final DateTime dateTime;

  const HomeAppt({
    required this.title,
    required this.personInCharge,
    required this.location,
    required this.dateTime,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class HomeService {
  HomeService._();
  static final HomeService instance = HomeService._();

  final _db = FirebaseFirestore.instance;

  // HealthService.dateString() → "YYYYMMDD" e.g. "20260306"
  static String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<HomeBundle> fetchHomeBundle(String uid) async {
    dev.log('[HomeService] fetchHomeBundle uid=$uid');

    final now      = DateTime.now();
    final today    = _dateKey(now);
    final dayStart = DateTime(now.year, now.month, now.day);

    // ── 1. User profile ──────────────────────────────────────────────────────
    String firstName = 'there';
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final p   = doc.data() ?? {};
      // UserModel stores as 'fullName' (see auth_controller.dart signUp call)
      final full = (
        p['fullName']    as String? ??
        p['name']        as String? ??
        p['displayName'] as String? ?? ''
      ).trim();
      if (full.isNotEmpty) firstName = full.split(' ').first;
      dev.log('[HomeService] profile: firstName=$firstName');
    } catch (e) {
      dev.log('[HomeService] profile error: $e');
    }

    // ── 2. Today's symptom log ───────────────────────────────────────────────
    // HealthService.saveSymptomLog() doc id = "log_YYYYMMDD"
    HomeTodaySymptom? todaySymptom;
    try {
      final doc = await _db
          .collection('users').doc(uid)
          .collection('symptomLogs').doc('log_$today')
          .get();
      if (doc.exists && doc.data() != null) {
        todaySymptom = HomeTodaySymptom.fromMap(doc.data()!);
        dev.log('[HomeService] symptom ✓  rapid3=${todaySymptom.rapid3Score} tier=${todaySymptom.rapid3Tier}');
      } else {
        dev.log('[HomeService] no symptom doc for log_$today');
      }
    } catch (e) {
      dev.log('[HomeService] symptomLog error: $e');
    }

    // ── 3. Medications + today's taken count ─────────────────────────────────
    // Medication config: users/{uid}/medications/{medId}
    //   Fields used: name, dosage, frequency ('Daily'|'Twice Daily'|'Weekly'),
    //                reminderTime: {hour:int, minute:int},
    //                startDate: millisecondsSinceEpoch,
    //                endDate:   millisecondsSinceEpoch (nullable),
    //                weeklyDays: List<int> (1=Mon, 7=Sun)
    //
    // Dose logs: users/{uid}/logs/{logId}
    //   Fields used: timestamp: millisecondsSinceEpoch
    //
    // "Expected today" = sum of expectedDosesPerDay for meds scheduled today
    HomeMedSummary? medSummary;
    try {
      final medsSnap = await _db
          .collection('users').doc(uid)
          .collection('medications')
          .get();

      if (medsSnap.docs.isNotEmpty) {
        // ── Count expected doses for today ──────────────────────────────────
        int totalExpected = 0;
        for (final doc in medsSnap.docs) {
          final m        = doc.data();
          final freq     = m['frequency'] as String? ?? 'Daily';
          final startMs  = m['startDate'] as int?;
          final endMs    = m['endDate']   as int?;
          final startDt  = startMs != null
              ? DateTime.fromMillisecondsSinceEpoch(startMs)
              : DateTime(2000);
          final endDt    = endMs != null
              ? DateTime.fromMillisecondsSinceEpoch(endMs)
              : null;

          // Skip meds not yet started or already ended
          if (dayStart.isBefore(startDt)) continue;
          if (endDt != null && dayStart.isAfter(endDt)) continue;

          if (freq == 'Weekly') {
            final weeklyDays = List<int>.from(m['weeklyDays'] ?? []);
            if (!weeklyDays.contains(now.weekday)) continue;
            totalExpected += 1;
          } else if (freq == 'Twice Daily') {
            totalExpected += 2;
          } else {
            // 'Daily' and anything else = 1 dose
            totalExpected += 1;
          }
        }

        // ── Count logs written today ────────────────────────────────────────
        // MedicationService uses users/{uid}/logs, timestamp = millisecondsSinceEpoch
        final logsSnap = await _db
            .collection('users').doc(uid)
            .collection('logs')
            .where('timestamp',
                isGreaterThanOrEqualTo: dayStart.millisecondsSinceEpoch)
            .get();
        final takenToday = logsSnap.docs.length;

        // ── First med for display name / dosage / reminder time ─────────────
        final first = medsSnap.docs.first.data();
        String displayTime = '—';
        final rt = first['reminderTime'];
        if (rt is Map) {
          final h   = (rt['hour']   as num?)?.toInt() ?? 9;
          final min = (rt['minute'] as num?)?.toInt() ?? 0;
          final period = h < 12 ? 'AM' : 'PM';
          final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
          final mm     = min.toString().padLeft(2, '0');
          displayTime  = '$h12:$mm $period';
        }

        medSummary = HomeMedSummary(
          name:        first['name']   as String? ?? 'Medication',
          dosage:      first['dosage'] as String? ?? '',
          displayTime: displayTime,
          takenToday:  takenToday,
          totalDoses:  totalExpected,
        );
        dev.log('[HomeService] meds ✓  taken=$takenToday/$totalExpected  name=${medSummary.name}');
      } else {
        dev.log('[HomeService] no medications found');
      }
    } catch (e) {
      dev.log('[HomeService] medications error: $e');
    }

    // ── 4. Next appointment ──────────────────────────────────────────────────
    // Appointment model fields: title, personInCharge, location, dateTime (Timestamp),
    //                           isCompleted (bool)
    // Strategy: fetch all incomplete, sort client-side → no compound index needed
    HomeAppt? nextAppt;
    try {
      final snap = await _db
          .collection('users').doc(uid)
          .collection('appointments')
          .where('isCompleted', isEqualTo: false)
          .get();

      if (snap.docs.isNotEmpty) {
        // Parse dateTime, filter to today-or-future, sort ascending
        final upcoming = <({Map<String, dynamic> data, DateTime dt})>[];
        for (final doc in snap.docs) {
          final d  = doc.data();
          final ts = d['dateTime'] as Timestamp?;
          if (ts == null) continue;
          final dt = ts.toDate();
          // Include today even if time already passed (might still be relevant)
          if (!dt.isBefore(dayStart)) {
            upcoming.add((data: d, dt: dt));
          }
        }
        upcoming.sort((a, b) => a.dt.compareTo(b.dt));

        if (upcoming.isNotEmpty) {
          final appt = upcoming.first;
          nextAppt = HomeAppt(
            title:          appt.data['title']          as String? ?? 'Appointment',
            personInCharge: appt.data['personInCharge'] as String? ?? '',
            location:       appt.data['location']       as String? ?? '',
            dateTime:       appt.dt,
          );
          dev.log('[HomeService] appt ✓  title=${nextAppt.title}  dt=${nextAppt.dateTime}');
        } else {
          dev.log('[HomeService] no future appointments');
        }
      } else {
        dev.log('[HomeService] no incomplete appointments');
      }
    } catch (e) {
      dev.log('[HomeService] appointments error: $e');
    }

    return HomeBundle(
      userName:     firstName,
      todaySymptom: todaySymptom,
      medSummary:   medSummary,
      nextAppt:     nextAppt,
    );
  }
}