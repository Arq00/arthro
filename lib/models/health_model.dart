// lib/models/health_models.dart
// Data models aligned with Firebase schema in the design doc.

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// RAPID3 QUESTION
// ─────────────────────────────────────────────
class Rapid3Question {
  final String id;
  final int questionNumber;
  final String question;
  final String questionDetail;
  final double minValue;
  final double maxValue;
  final String minLabel;
  final String maxLabel;
  final String unit;
  final String type; // 'slider' | 'radio'
  final String category; // 'pain' | 'function' | 'global'
  final String? configRef;         // for f1-f10: references 'function_config'
  final List<String>? subQuestions; // f1-f10 question texts, attached by service
  final List<Rapid3Option>? options; // for radio type

  const Rapid3Question({
    required this.id,
    required this.questionNumber,
    required this.question,
    required this.questionDetail,
    required this.minValue,
    required this.maxValue,
    required this.minLabel,
    required this.maxLabel,
    required this.unit,
    required this.type,
    required this.category,
    this.configRef,
    this.subQuestions,
    this.options,
  });

  factory Rapid3Question.fromMap(Map<String, dynamic> map) {
    // questionNumber can be int (1) or double (1.1) in Firestore
    final qNum = map['questionNumber'];
    final questionNumber = qNum is double ? qNum : (qNum ?? 1).toDouble();

    return Rapid3Question(
      id:             map['id'] ?? '',
      questionNumber: questionNumber.toInt(),
      question:       map['question'] ?? '',
      questionDetail: map['questionDetail'] ?? map['question'] ?? '',
      minValue:       (map['minValue'] ?? 0).toDouble(),
      maxValue:       (map['maxValue'] ?? 10).toDouble(),
      minLabel:       map['minLabel'] ?? '',
      maxLabel:       map['maxLabel'] ?? '',
      unit:           map['unit'] ?? '',
      type:           map['type'] ?? 'slider',
      category:       map['category'] ?? '',
      configRef:      map['configRef'] as String?,
      subQuestions:   map['subQuestions'] != null
          ? List<String>.from(map['subQuestions'] as List)
          : null,
      options:        map['options'] != null
          ? (map['options'] as List)
              .map((o) => Rapid3Option.fromMap(o))
              .toList()
          : null,
    );
  }
}

class Rapid3Option {
  final double value;
  final String label;
  const Rapid3Option({required this.value, required this.label});

  factory Rapid3Option.fromMap(Map<String, dynamic> map) =>
      Rapid3Option(value: (map['value'] ?? 0).toDouble(), label: map['label'] ?? '');
}

// ─────────────────────────────────────────────
// RAPID3 TIER DEFINITION
// ─────────────────────────────────────────────
class Rapid3TierDefinition {
  final String tierId;
  final String tierName;
  final String emoji;
  final String colorHex;
  final double rapid3Min;
  final double rapid3Max;
  final String statusText;
  final String statusDescription;
  final bool alert;
  final String alertMessage;

  const Rapid3TierDefinition({
    required this.tierId,
    required this.tierName,
    required this.emoji,
    required this.colorHex,
    required this.rapid3Min,
    required this.rapid3Max,
    required this.statusText,
    required this.statusDescription,
    required this.alert,
    required this.alertMessage,
  });

  factory Rapid3TierDefinition.fromMap(Map<String, dynamic> map) {
    // alert is a root-level field in rapid3def (not nested)
    return Rapid3TierDefinition(
      tierId:             map['tierId'] ?? (map['id'] ?? ''),
      tierName:           map['tierName'] ?? (map['name'] ?? ''),
      emoji:              map['emoji'] ?? '',
      colorHex:           map['colorHex'] ?? '#10B981',
      rapid3Min:          (map['rapid3Min'] ?? 0).toDouble(),
      rapid3Max:          (map['rapid3Max'] ?? 10).toDouble(),
      statusText:         map['statusText'] ?? '',
      statusDescription:  map['statusDescription'] ?? '',
      alert:              map['alert'] == true,
      alertMessage:       map['alertMessage'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// EXERCISE RECOMMENDATION
// ─────────────────────────────────────────────
class ExerciseRecommendation {
  final String id;
  final String name;
  final String duration;
  final String type;
  final String intensity;
  final String jointImpact;
  final List<String> benefits;
  final List<String> instructions;
  final List<String> warnings;
  final String equipmentNeeded;
  final String difficulty;
  final String tier;

  const ExerciseRecommendation({
    required this.id,
    required this.name,
    required this.duration,
    required this.type,
    required this.intensity,
    required this.jointImpact,
    required this.benefits,
    required this.instructions,
    required this.warnings,
    required this.equipmentNeeded,
    required this.difficulty,
    required this.tier,
  });

  factory ExerciseRecommendation.fromMap(Map<String, dynamic> map) =>
      ExerciseRecommendation(
        id:             map['id'] ?? '',
        name:           map['name'] ?? '',
        duration:       map['duration'] ?? '',
        type:           map['type'] ?? '',
        intensity:      map['intensity'] ?? '',
        jointImpact:    map['jointImpact'] ?? '',
        benefits:       List<String>.from(map['benefits'] ?? []),
        instructions:   List<String>.from(map['instructions'] ?? []),
        warnings:       List<String>.from(map['warnings'] ?? []),
        equipmentNeeded: map['equipmentNeeded'] ?? '',
        difficulty:     map['difficulty'] ?? '',
        // DB uses 'tierId' field name
        tier:           map['tierId'] ?? map['tier'] ?? '',
      );

  // Duration in minutes (parses "15-20 min" → 20)
  int get maxMinutes {
    final parts = duration.replaceAll(RegExp(r'[^0-9\-]'), '').split('-');
    if (parts.length == 2) return int.tryParse(parts[1]) ?? 20;
    if (parts.length == 1) return int.tryParse(parts[0]) ?? 20;
    return 20;
  }
}

// ─────────────────────────────────────────────
// NUTRITION RECOMMENDATION
// ─────────────────────────────────────────────
class NutritionRecommendation {
  final String id;
  final String name;
  final String description;
  final String dailyGoal;
  final int vegetablesTarget;
  final int fruitsTarget;
  final int waterGlassesTarget;
  final String focusArea;
  final List<String> examples;
  final List<String> avoidFoods;
  final List<String> tips;
  final String tier;

  const NutritionRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.dailyGoal,
    required this.vegetablesTarget,
    required this.fruitsTarget,
    required this.waterGlassesTarget,
    required this.focusArea,
    required this.examples,
    required this.avoidFoods,
    required this.tips,
    required this.tier,
  });

  factory NutritionRecommendation.fromMap(Map<String, dynamic> map) {
    final servings = map['servings'] as Map<String, dynamic>? ?? {};
    return NutritionRecommendation(
      id:                  map['id'] ?? '',
      name:                map['name'] ?? '',
      description:         map['description'] ?? '',
      dailyGoal:           map['dailyGoal'] ?? '',
      vegetablesTarget:    (servings['vegetables'] ?? 5) as int,
      fruitsTarget:        (servings['fruits'] ?? 2) as int,
      waterGlassesTarget:  _parseWaterGlasses(map['waterIntake']),
      focusArea:           map['focusArea'] ?? '',
      examples:            List<String>.from(map['examples'] ?? []),
      avoidFoods:          List<String>.from(map['avoidFoods'] ?? []),
      tips:                List<String>.from(map['tips'] ?? []),
      // DB uses 'tierId' field name
      tier:                map['tierId'] ?? map['tier'] ?? '',
    );
  }

  static int _parseWaterGlasses(dynamic raw) {
    if (raw == null) return 8;
    final str = raw.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return int.tryParse(match?.group(1) ?? '8') ?? 8;
  }
}

// ─────────────────────────────────────────────
// SYMPTOM LOG (users/{uid}/symptomLogs)
// ─────────────────────────────────────────────
class SymptomLog {
  final String logId;
  final String userId;
  final String logDate;
  final double pain;
  final double function;
  final double globalAssessment;
  final double rapid3Score;
  final String rapid3Tier;
  final List<String> affectedJoints;
  final int morningStiffnessMinutes;
  final double stressLevel;       // 0–10 in 0.5 steps; <4 low, 4–7.5 avg, >7.5 high
  final String additionalNotes;
  final DateTime createdAt;

  const SymptomLog({
    required this.logId,
    required this.userId,
    required this.logDate,
    required this.pain,
    required this.function,
    required this.globalAssessment,
    required this.rapid3Score,
    required this.rapid3Tier,
    required this.affectedJoints,
    required this.morningStiffnessMinutes,
    this.stressLevel = 0.0,       // optional — defaults to 0 for existing records
    this.additionalNotes = '',
    required this.createdAt,
  });

  /// RAPID3 Calculation:
  /// pain (0-10) + function avg (0-10 scaled) + global (0-10)
  /// Final score = sum / 3  → mapped to tier
  static double calculateRapid3(double pain, double function, double global) {
    // function is 0-3 per question × 10 questions = 0-30 → scale to 0-10
    final funcScaled = function * (10 / 3);
    final raw = pain + funcScaled + global;
    return double.parse((raw / 3).toStringAsFixed(1));
  }

  static String tierFromScore(double score) {
    if (score <= 1.0)  return 'REMISSION';
    if (score <= 2.0)  return 'LOW';
    if (score <= 4.0)  return 'MODERATE';
    return 'HIGH';
  }

  /// Stress level classification  
  static String stressLabel(double level) {
    if (level < 4.0)  return 'Low Stress';
    if (level <= 7.5) return 'Average Stress';
    return 'High Stress';
  }

  static String stressTier(double level) {
    if (level < 4.0)  return 'LOW';
    if (level <= 7.5) return 'AVERAGE';
    return 'HIGH';
  }

  Map<String, dynamic> toMap() => {
    'logId':                    logId,
    'userId':                   userId,
    'logDate':                  logDate,
    'logTime':                  createdAt.toIso8601String(),
    'timestamp':                Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
    'pain':                     pain,
    'function':                 function,
    'globalAssessment':         globalAssessment,
    'rapid3Score':              rapid3Score,
    'rapid3Tier':               rapid3Tier,
    'tireEmoij':               SymptomLog._emojiFor(rapid3Tier), // matches schema field name (schema has typo)
    'tierColor':               SymptomLog._colorFor(rapid3Tier),
    'affectedJoints':           affectedJoints,
    'morningStiffnessMinutes':  morningStiffnessMinutes,
    'stressLevel':              stressLevel,
    'additionalNotes':          additionalNotes,
    'createdAt':                Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
    'updatedAt':                Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
    'deviceType':               'Mobile',
    'appVersion':               '1.0.0',
  };

  static String _emojiFor(String tier) {
    switch (tier) {
      case 'REMISSION': return '🟢';
      case 'LOW':       return '🟡';
      case 'MODERATE':  return '🟠';
      case 'HIGH':      return '🔴';
      default:          return '⚪';
    }
  }

  // matches schema field: "tierColor": "#F97316"
  static String _colorFor(String tier) {
    switch (tier) {
      case 'REMISSION': return '#10B981';
      case 'LOW':       return '#F59E0B';
      case 'MODERATE':  return '#F97316';
      case 'HIGH':      return '#EF4444';
      default:          return '#6B7280';
    }
  }
}

// ─────────────────────────────────────────────
// LIFESTYLE PROGRESS LOG (users/{uid}/userLifestyleProgress)
// ─────────────────────────────────────────────
class LifestyleProgress {
  final String progressId;
  final String userId;
  final String progressDate;
  final String rapid3Tier;
  final double rapid3Score;

  // Exercise
  final bool exerciseCompleted;
  final int exerciseActualMinutes;
  final String exerciseName;
  final double? painBefore;
  final double? painAfter;

  // Nutrition
  final bool nutritionCompleted;
  final int vegetablesConsumed;
  final int fruitConsumed;
  final int waterGlasses;
  final int nutritionAdherencePercent;
  final List<String> foodsLogged;

  final int dailyAdherence;
  final String overallWellness;
  final String notes;
  final DateTime createdAt;

  const LifestyleProgress({
    required this.progressId,
    required this.userId,
    required this.progressDate,
    required this.rapid3Tier,
    required this.rapid3Score,
    required this.exerciseCompleted,
    required this.exerciseActualMinutes,
    required this.exerciseName,
    this.painBefore,
    this.painAfter,
    required this.nutritionCompleted,
    required this.vegetablesConsumed,
    required this.fruitConsumed,
    required this.waterGlasses,
    required this.nutritionAdherencePercent,
    required this.foodsLogged,
    required this.dailyAdherence,
    required this.overallWellness,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'progressId':    progressId,
    'userId':        userId,
    'progressDate':  progressDate,
    'timestamp':     Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
    'rapid3Score':   rapid3Score,
    'rapid3Tier':    rapid3Tier,
    'exerciseLogged': {
      'completed':      exerciseCompleted,
      'actualDuration': exerciseActualMinutes,
      'exerciseName':   exerciseName,
      'painBefore':     painBefore,
      'painAfter':      painAfter,
    },
    'nutritionLogged': {
      'completed':           nutritionCompleted,
      'vegetablesConsumed':  vegetablesConsumed,
      'fruitConsumed':       fruitConsumed,
      'waterGlasses':        waterGlasses,
      'foodsLogged':         foodsLogged,
      'adherencePercent':    nutritionAdherencePercent,
    },
    'dailyAdherence':  dailyAdherence,
    'overallWellness': overallWellness,
    'notes':           notes,
    'createdAt':       Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
    'updatedAt':       Timestamp.fromDate(createdAt).millisecondsSinceEpoch,
  };
}

// ─────────────────────────────────────────────
// WEATHER DATA (local state only)
// ─────────────────────────────────────────────
// How the weather data was obtained — shown in UI so user understands accuracy
enum WeatherSource {
  gps,        // GPS coordinates → OpenWeatherMap — most accurate
  manualCity, // User-selected city → Open-Meteo geocoding — reliable
  unavailable // No location, no city set — card shows picker prompt
}

class WeatherData {
  final double humidity;
  final double temperature;
  final double pressure;
  final String condition;
  final String stiffnessRisk; // 'low' | 'moderate' | 'high'
  final WeatherSource source;
  final String cityName; // empty when source == gps; set for manualCity

  const WeatherData({
    required this.humidity,
    required this.temperature,
    required this.pressure,
    required this.condition,
    required this.stiffnessRisk,
    this.source   = WeatherSource.gps,
    this.cityName = '',
  });

  // ── From OpenWeatherMap (GPS path) ────────────────────────────────────
  factory WeatherData.fromApi(Map<String, dynamic> json) {
    final main        = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List;
    final weather     = weatherList.isNotEmpty
        ? weatherList.first as Map<String, dynamic>
        : <String, dynamic>{};
    final humidity    = (main['humidity'] ?? 70).toDouble();
    final pressure    = (main['pressure'] ?? 1013).toDouble();
    final temperature = (main['temp'] ?? 28).toDouble(); // already °C with units=metric

    return WeatherData(
      humidity:      humidity,
      temperature:   temperature,
      pressure:      pressure,
      condition:     weather['description'] ?? '',
      stiffnessRisk: _assessRisk(humidity, pressure),
      source:        WeatherSource.gps,
    );
  }

  // ── From Open-Meteo (manual city path) ───────────────────────────────
  // Open-Meteo response: hourly.relativehumidity_2m[0], surface_pressure[0],
  // temperature_2m[0], weathercode[0]
  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json, String city) {
    final current = json['current_weather'] as Map<String, dynamic>? ?? {};
    final hourly  = json['hourly'] as Map<String, dynamic>? ?? {};

    final List humList  = hourly['relativehumidity_2m'] as List? ?? [];
    final List pressList = hourly['surface_pressure'] as List? ?? [];

    final humidity    = humList.isNotEmpty
        ? (humList.first as num).toDouble() : 75.0;
    final pressure    = pressList.isNotEmpty
        ? (pressList.first as num).toDouble() : 1010.0;
    final temperature = (current['temperature'] as num?)?.toDouble() ?? 28.0;
    final condition   = _wmoCodesToDescription(
        (current['weathercode'] as num?)?.toInt() ?? 0);

    return WeatherData(
      humidity:      humidity,
      temperature:   temperature,
      pressure:      pressure,
      condition:     condition,
      stiffnessRisk: _assessRisk(humidity, pressure),
      source:        WeatherSource.manualCity,
      cityName:      city,
    );
  }

  // ── Sentinel: no data available ──────────────────────────────────────
  factory WeatherData.unavailable() => const WeatherData(
    humidity: 0, temperature: 0, pressure: 0,
    condition: '', stiffnessRisk: 'low',
    source: WeatherSource.unavailable,
  );

  bool get isUnavailable => source == WeatherSource.unavailable;

  /// High humidity (>75%) + low/falling pressure → high stiffness risk
  static String _assessRisk(double humidity, double pressure) {
    if (humidity >= 80 || pressure < 1005) return 'high';
    if (humidity >= 65 || pressure < 1013) return 'moderate';
    return 'low';
  }

  String get riskLabel {
    switch (stiffnessRisk) {
      case 'high':     return 'High stiffness risk';
      case 'moderate': return 'Moderate stiffness risk';
      default:         return 'Low stiffness risk';
    }
  }

  // WMO weather code → human-readable description (subset)
  static String _wmoCodesToDescription(int code) {
    if (code == 0)              return 'Clear sky';
    if (code <= 3)              return 'Partly cloudy';
    if (code <= 49)             return 'Foggy';
    if (code <= 69)             return 'Drizzle';
    if (code <= 79)             return 'Rain';
    if (code <= 84)             return 'Rain showers';
    if (code <= 99)             return 'Thunderstorm';
    return 'Cloudy';
  }
}

// ─────────────────────────────────────────────
// BODY JOINT MODEL
// ─────────────────────────────────────────────
class BodyJoint {
  final String id;
  final String label;
  bool isSelected;       // never null — always false or true
  String severity;       // never null — always 'none', 'mild', or 'severe'

  BodyJoint({
    required this.id,
    required this.label,
    bool isSelected = false,
    String severity = 'none',
  })  : isSelected = isSelected,
        severity   = severity;

  void cycleSeverity() {
    switch (severity) {
      case 'none':   severity = 'mild';   isSelected = true;  break;
      case 'mild':   severity = 'severe'; isSelected = true;  break;
      case 'severe': severity = 'none';   isSelected = false; break;
    }
  }
}