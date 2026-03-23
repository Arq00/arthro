// lib/models/report_model.dart
// All computed data structures used by the Report/Trend module.
// These are pure Dart objects — no Firestore types — so they are
// safe to construct, compare, and pass between layers.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REPORT SUMMARY  (top KPI bar)
// ─────────────────────────────────────────────────────────────────────────────
class ReportSummary {
  final double avgRapid3;       // 30-day average score
  final int    flareCount;      // days with tier == HIGH
  final double medAdherence;    // 0–100 %
  final int    logStreakDays;   // consecutive days with a log
  final String avgTier;         // dominant tier in period

  const ReportSummary({
    required this.avgRapid3,
    required this.flareCount,
    required this.medAdherence,
    required this.logStreakDays,
    required this.avgTier,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART DATA POINT  (RAPID3 sparkline)
// ─────────────────────────────────────────────────────────────────────────────
class ChartPoint {
  final DateTime date;
  final double   score;
  final String   tier;
  final bool     isFlare;   // tier == HIGH
  final bool     isToday;

  const ChartPoint({
    required this.date,
    required this.score,
    required this.tier,
    this.isFlare = false,
    this.isToday = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY LOG ROW  (table inside the trend view)
// ─────────────────────────────────────────────────────────────────────────────
class DailyLogRow {
  final DateTime date;
  final double   rapid3Score;
  final String   tier;
  final String   medsStatus;      // e.g. "MTX ✓  HCQ ○"
  final String   exerciseName;    // "" = rest day
  final bool     exerciseDone;
  final int      humidityPct;     // 0 if not available
  final int      stiffnessMin;
  final double   stressLevel;
  final List<String> affectedJoints;
  final double   pain;
  final double   function;
  final double   globalAssessment;

  const DailyLogRow({
    required this.date,
    required this.rapid3Score,
    required this.tier,
    required this.medsStatus,
    required this.exerciseName,
    required this.exerciseDone,
    required this.humidityPct,
    required this.stiffnessMin,
    required this.stressLevel,
    required this.affectedJoints,
    required this.pain,
    required this.function,
    required this.globalAssessment,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FLARE ALERT  (banner at top of trends when rising trend detected)
// ─────────────────────────────────────────────────────────────────────────────
class FlareAlert {
  final bool   isActive;
  final String title;
  final String body;
  final double fromScore;
  final double toScore;
  final int    consecutiveDays;   // how many days the trend has been rising

  const FlareAlert({
    required this.isActive,
    this.title = '',
    this.body  = '',
    this.fromScore       = 0,
    this.toScore         = 0,
    this.consecutiveDays = 0,
  });

  factory FlareAlert.none() => const FlareAlert(isActive: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// CORRELATION DATA
// ─────────────────────────────────────────────────────────────────────────────

/// One entry in the missed-meds timeline
class MissedMedEvent {
  final DateTime date;
  final String   medName;
  final double   nextDayScore;    // RAPID3 the day after
  final bool     wasMissed;       // false = taken (for comparison rows)

  const MissedMedEvent({
    required this.date,
    required this.medName,
    required this.nextDayScore,
    required this.wasMissed,
  });
}

class MedAdherenceCorrelation {
  final double avgScoreOnMissedDay;
  final double avgScoreOnAdherentDay;
  final int    flaresAfterMissed;
  final int    totalFlares;
  final List<MissedMedEvent> events;

  const MedAdherenceCorrelation({
    required this.avgScoreOnMissedDay,
    required this.avgScoreOnAdherentDay,
    required this.flaresAfterMissed,
    required this.totalFlares,
    required this.events,
  });

  String get headlineStat => '$flaresAfterMissed/$totalFlares';
}

/// Monthly stiffness KPIs for the accordion
class StiffnessMonthData {
  final String   monthLabel;   // "February 2026"
  final double   avgMinutes;
  final int      daysAbove30;
  final int      bestMinutes;
  final int      worstMinutes;
  final double?  prevMonthAvg; // for MoM comparison in subtitle

  const StiffnessMonthData({
    required this.monthLabel,
    required this.avgMinutes,
    required this.daysAbove30,
    required this.bestMinutes,
    required this.worstMinutes,
    this.prevMonthAvg,
  });

  String get subtitle {
    final abbr = monthLabel.split(' ').first;
    if (prevMonthAvg == null) return '$abbr avg ${avgMinutes.round()} min';
    final prev = prevMonthAvg!.round();
    final curr = avgMinutes.round();
    if (curr < prev) {
      return '$abbr avg ${curr} min · down from ${_prevAbbr} ${prev} min ↓';
    } else if (curr > prev) {
      return '$abbr avg ${curr} min · up from ${_prevAbbr} ${prev} min ↑';
    }
    return '$abbr avg ${curr} min · same as ${_prevAbbr}';
  }

  String get _prevAbbr => '';   // filled from caller context
}

/// One data point for the stress x pain scatter
class StressPoint {
  final DateTime date;
  final double   stressLevel;
  final double   painScore;
  final String   tier;

  const StressPoint({
    required this.date,
    required this.stressLevel,
    required this.painScore,
    required this.tier,
  });
}

class StressCorrelation {
  final double   correlationCoeff;
  final double   avgPainLowStress;
  final double   avgPainHighStress;
  final List<StressPoint> points;

  const StressCorrelation({
    required this.correlationCoeff,
    required this.avgPainLowStress,
    required this.avgPainHighStress,
    required this.points,
  });

  String get headlineStat {
    if (correlationCoeff.isNaN) return 'r=—';
    return 'r=${correlationCoeff.toStringAsFixed(2)}';
  }

  String get strengthLabel {
    final r = correlationCoeff.abs();
    if (r >= 0.7) return 'strong';
    if (r >= 0.4) return 'moderate';
    if (r >= 0.2) return 'weak';
    return 'negligible';
  }
}

/// All 3 correlation groups
class CorrelationData {
  final MedAdherenceCorrelation  medAdherence;
  final StressCorrelation        stress;
  final List<StiffnessMonthData> stiffnessByMonth;

  const CorrelationData({
    required this.medAdherence,
    required this.stress,
    required this.stiffnessByMonth,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF REPORT DATA  (passed to the PDF preview sheet)
// ─────────────────────────────────────────────────────────────────────────────
class PdfReportData {
  // Patient
  final String patientName;
  final String patientIc;
  final String patientGender;
  final int    patientAge;
  final String doctorName;

  // Period
  final DateTime periodFrom;
  final DateTime periodTo;

  // Summary KPIs
  final double avgRapid3;
  final String avgTier;
  final int    flareDays;
  final double medAdherence;
  final double bestScore;
  final DateTime bestScoreDate;

  // Joint heatmap: joint name → avg score
  final Map<String, double> jointAvgScores;

  // Medication adherence per drug
  final List<MedAdherenceItem> medItems;

  // Timeline rows (last 5–7 for the table)
  final List<DailyLogRow> recentLogs;

  // Action items for next visit
  final List<String> actionItems;

  // Flare dates
  final List<DateTime> flareDates;

  // EULAR response
  final String eularResponse;   // "MODERATE IMPROVEMENT" etc.
  final double baselineRapid3;

  const PdfReportData({
    required this.patientName,
    required this.patientIc,
    required this.patientGender,
    required this.patientAge,
    required this.doctorName,
    required this.periodFrom,
    required this.periodTo,
    required this.avgRapid3,
    required this.avgTier,
    required this.flareDays,
    required this.medAdherence,
    required this.bestScore,
    required this.bestScoreDate,
    required this.jointAvgScores,
    required this.medItems,
    required this.recentLogs,
    required this.actionItems,
    required this.flareDates,
    required this.eularResponse,
    required this.baselineRapid3,
  });
}

class MedAdherenceItem {
  final String medName;
  final double adherencePct;   // 0–100
  final List<DateTime> missedDates;
  final String dosage;

  const MedAdherenceItem({
    required this.medName,
    required this.adherencePct,
    required this.missedDates,
    required this.dosage,
  });
}