// lib/models/scheduled_dose.dart
//
// A single dose event for a medication on a given day.
// DoseStatus.anytime = no reminder set, shows all day until logged or EOD.

import 'medication_model.dart';

enum DoseStatus {
  taken,    // logged — moves to Taken section
  missed,   // window expired >30 min ago (reminder ON) OR day ended (reminder OFF)
  dueSoon,  // within ±30 min of scheduled time (reminder ON only)
  upcoming, // scheduled later today (reminder ON only)
  anytime,  // no reminder set — due anytime, never "missed" until EOD
}

class ScheduledDose {
  final Medication medication;
  final DateTime   scheduledTime; // midnight (00:00) when reminder is OFF
  final bool       isMorning;     // distinguishes Twice Daily morning vs evening
  final DoseStatus status;

  const ScheduledDose({
    required this.medication,
    required this.scheduledTime,
    required this.isMorning,
    required this.status,
  });

  /// Time label shown in the schedule row.
  /// Returns 'Anytime' when no reminder is set.
  String get timeLabel {
    if (!medication.isReminderOn) return 'Anytime';
    final h      = scheduledTime.hour;
    final min    = scheduledTime.minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12${scheduledTime.minute > 0 ? ':$min' : ''} $period';
  }

  /// Short subtitle: "1 tablet · Before Meal".
  String get doseSubtitle {
    final parts = <String>[];
    parts.add('${medication.perDose} ${medication.medicationType.toLowerCase()}');
    if (medication.mealTiming != 'Any Time') parts.add(medication.mealTiming);
    return parts.join(' · ');
  }

  bool get isAnytime => status == DoseStatus.anytime;
  bool get isTaken   => status == DoseStatus.taken;
  bool get isMissed  => status == DoseStatus.missed;
  bool get isDueSoon => status == DoseStatus.dueSoon;
}