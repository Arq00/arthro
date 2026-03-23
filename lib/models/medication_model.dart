import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency; // 'Daily' | 'Twice Daily' | 'Weekly'
  final String medicationType; // 'Tablet' | 'Capsule' | 'Liquid' | 'Injection'
  final String mealTiming; // 'Before Meal' | 'With Meal' | 'After Meal' | 'Any Time'
  int stockCurrent;
  final int stockMax;
  final int perDose;
  final bool isReminderOn;
  final TimeOfDay reminderTime;
  final TimeOfDay? eveningReminderTime; // second time for Twice Daily
  final List<int> weeklyDays; // [1..7] Mon=1, Sun=7 — used when frequency == 'Weekly'
  final List<String> knownSideEffects; // pre-configured side effects to watch for
  final DateTime startDate;
  final DateTime? endDate;
  DateTime? firstTaken;
  DateTime? lastTaken;
  final String description;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.medicationType,
    this.mealTiming = 'Any Time',
    required this.stockCurrent,
    required this.stockMax,
    required this.perDose,
    required this.isReminderOn,
    required this.reminderTime,
    this.eveningReminderTime,
    this.weeklyDays = const [],
    this.knownSideEffects = const [],
    required this.startDate,
    this.endDate,
    this.firstTaken,
    this.lastTaken,
    required this.description,
  });

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// How many doses are expected per day for this medication.
  int get expectedDosesPerDay {
    if (frequency == 'Twice Daily') return 2;
    if (frequency == 'Weekly') return 1; // 1 per scheduled day
    return 1;
  }

  /// Whether this medication is scheduled for a given day.
  bool isScheduledFor(DateTime day) {
    if (startDate.isAfter(day)) return false;
    if (endDate != null && endDate!.isBefore(DateTime(day.year, day.month, day.day))) {
      return false;
    }
    if (frequency == 'Weekly') {
      return weeklyDays.contains(day.weekday); // weekday: 1=Mon, 7=Sun
    }
    return true;
  }

  bool get isLowStock =>
      stockMax > 0 && stockCurrent / stockMax < 0.2;

  bool get isOutOfStock => stockCurrent <= 0;

  // ─── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'medicationType': medicationType,
      'mealTiming': mealTiming,
      'stockCurrent': stockCurrent,
      'stockMax': stockMax,
      'perDose': perDose,
      'isReminderOn': isReminderOn,
      'reminderTime': {
        'hour': reminderTime.hour,
        'minute': reminderTime.minute,
      },
      'eveningReminderTime': eveningReminderTime != null
          ? {
              'hour': eveningReminderTime!.hour,
              'minute': eveningReminderTime!.minute,
            }
          : null,
      'weeklyDays': weeklyDays,
      'knownSideEffects': knownSideEffects,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'firstTaken': firstTaken?.millisecondsSinceEpoch,
      'lastTaken': lastTaken?.millisecondsSinceEpoch,
      'description': description,
    };
  }

  factory Medication.fromFirestore(String id, Map<String, dynamic> data) {
    TimeOfDay? eveningTime;
    if (data['eveningReminderTime'] != null) {
      eveningTime = TimeOfDay(
        hour: data['eveningReminderTime']['hour'] ?? 18,
        minute: data['eveningReminderTime']['minute'] ?? 0,
      );
    }

    return Medication(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? 'Daily',
      medicationType: data['medicationType'] ?? 'Tablet',
      mealTiming: data['mealTiming'] ?? 'Any Time',
      stockCurrent: data['stockCurrent'] ?? 0,
      stockMax: data['stockMax'] ?? 30,
      perDose: data['perDose'] ?? 1,
      isReminderOn: data['isReminderOn'] ?? true,
      reminderTime: TimeOfDay(
        hour: data['reminderTime']?['hour'] ?? 9,
        minute: data['reminderTime']?['minute'] ?? 0,
      ),
      eveningReminderTime: eveningTime,
      weeklyDays: List<int>.from(data['weeklyDays'] ?? []),
      knownSideEffects: List<String>.from(data['knownSideEffects'] ?? []),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        data['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endDate: data['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
          : null,
      firstTaken: data['firstTaken'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['firstTaken'])
          : null,
      lastTaken: data['lastTaken'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastTaken'])
          : null,
      description: data['description'] ?? '',
    );
  }


  /// Returns a copy with a new Firestore-assigned ID.
  /// Used after addMedication() to get the real doc ID for notification scheduling.
  Medication copyWithId(String newId) => Medication(
    id:                  newId,
    name:                name,
    dosage:              dosage,
    frequency:           frequency,
    medicationType:      medicationType,
    mealTiming:          mealTiming,
    stockCurrent:        stockCurrent,
    stockMax:            stockMax,
    perDose:             perDose,
    isReminderOn:        isReminderOn,
    reminderTime:        reminderTime,
    eveningReminderTime: eveningReminderTime,
    weeklyDays:          weeklyDays,
    knownSideEffects:    knownSideEffects,
    startDate:           startDate,
    endDate:             endDate,
    firstTaken:          firstTaken,
    lastTaken:           lastTaken,
    description:         description,
  );

  /// Common RA medication side effects shown as suggestions in the form.
  static const List<String> commonSideEffects = [
    'Nausea',
    'Stomach upset',
    'Dizziness',
    'Headache',
    'Fatigue',
    'Loss of appetite',
    'Joint pain',
    'Skin rash',
    'Mouth sores',
    'Hair thinning',
    'Blurred vision',
    'Increased bruising',
  ];
}