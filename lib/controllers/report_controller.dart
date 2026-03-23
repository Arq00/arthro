// lib/controllers/report_controller.dart

import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../models/medication_model.dart';
import '../models/medication_log_model.dart';
import '../services/report_service.dart';

enum ReportState { idle, loading, ready, error }

// Preset period options — null means custom range
const _kPresets = [7, 30, 90];

class ReportController extends ChangeNotifier {

  // ─── state ────────────────────────────────────────────────────────────────
  ReportState _state = ReportState.idle;
  ReportState get state => _state;

  String _error = '';
  String get error => _error;

  // ─── period mode ─────────────────────────────────────────────────────────
  // _periodDays == null  →  custom range (_customStart/_customEnd are set)
  // _periodDays == 7/30/90 → preset mode
  int?     _periodDays  = 30;
  DateTime? _customStart;
  DateTime? _customEnd;

  int?     get periodDays    => _periodDays;
  bool     get isCustomRange => _periodDays == null;

  /// Human-readable range label shown below the selector chips.
  String get dateRangeLabel {
    if (_periodDays != null) {
      final from = DateTime.now().subtract(Duration(days: _periodDays!));
      return '${_fmt(from)} – ${_fmt(DateTime.now())}';
    }
    if (_customStart != null && _customEnd != null) {
      return '${_fmt(_customStart!)} – ${_fmt(_customEnd!)}';
    }
    return '';
  }

  // ─── computed data ────────────────────────────────────────────────────────
  ReportSummary?     summary;
  List<ChartPoint>   chartPoints   = [];
  List<DailyLogRow>  dailyRows     = [];
  List<DailyLogRow>  allDailyRows  = [];
  FlareAlert?        flareAlert;
  CorrelationData?   correlations;
  PdfReportData?     pdfData;

  // ─── calendar month navigator ─────────────────────────────────────────────
  int _calYear  = DateTime.now().year;
  int _calMonth = DateTime.now().month;

  int get calYear  => _calYear;
  int get calMonth => _calMonth;

  List<DateTime> get availableMonths {
    final seen   = <String>{};
    final months = <DateTime>[];
    for (final r in allDailyRows) {
      final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}';
      if (seen.add(key)) months.add(DateTime(r.date.year, r.date.month));
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  List<DailyLogRow> get calendarMonthRows => allDailyRows
      .where((r) => r.date.year == _calYear && r.date.month == _calMonth)
      .toList();

  bool get calCanGoPrev {
    final months = availableMonths;
    if (months.isEmpty) return false;
    final oldest = months.last;
    return !(_calYear == oldest.year && _calMonth == oldest.month);
  }

  bool get calCanGoNext {
    final now = DateTime.now();
    return !(_calYear == now.year && _calMonth == now.month);
  }

  void calGoToPrev() {
    if (!calCanGoPrev) return;
    if (_calMonth == 1) { _calMonth = 12; _calYear--; }
    else { _calMonth--; }
    notifyListeners();
  }

  void calGoToNext() {
    if (!calCanGoNext) return;
    if (_calMonth == 12) { _calMonth = 1; _calYear++; }
    else { _calMonth++; }
    notifyListeners();
  }

  void calJumpToMonth(int year, int month) {
    _calYear = year; _calMonth = month;
    notifyListeners();
  }

  // ─── correlation accordion ────────────────────────────────────────────────
  int? _expandedCorrelation;
  int? get expandedCorrelation => _expandedCorrelation;

  void toggleCorrelation(int index) {
    _expandedCorrelation = _expandedCorrelation == index ? null : index;
    notifyListeners();
  }

  // ─── stiffness month navigator ────────────────────────────────────────────
  List<StiffnessMonthData> _stiffnessMonths    = [];
  int                      _stiffnessMonthIdx  = 0;

  StiffnessMonthData? get currentStiffnessMonth =>
      _stiffnessMonths.isEmpty ? null : _stiffnessMonths[_stiffnessMonthIdx];

  bool get canGoPrevStiffMonth => _stiffnessMonthIdx > 0;
  bool get canGoNextStiffMonth =>
      _stiffnessMonthIdx < _stiffnessMonths.length - 1;

  void changeStiffnessMonth(int delta) {
    final next = _stiffnessMonthIdx + delta;
    if (next < 0 || next >= _stiffnessMonths.length) return;
    _stiffnessMonthIdx = next;
    notifyListeners();
  }

  final String? _overrideUid;
  ReportController({String? uid}) : _overrideUid = uid;

  ReportBundle? _bundle;

  // ─── init / load ──────────────────────────────────────────────────────────

  Future<void> load() async {
    final uid = _overrideUid ?? FirebaseAuth.instance.currentUser ?.uid;
    if (uid == null) { _setError('Not authenticated'); return; }

    _setState(ReportState.loading);
    try {
      _bundle = await ReportService.instance.buildReportBundle(
        uid,
        days:      _periodDays ?? 30,
        startDate: _customStart,
        endDate:   _customEnd,
      );
      _compute(_bundle!);
      _setState(ReportState.ready);
    } catch (e) {
      dev.log('[ReportController] load error: $e');
      _setError('Failed to load report: $e');
    }
  }

  /// Switch to a preset period (7, 30, 90 days).
  Future<void> switchPeriod(int days) async {
    if (_periodDays == days && !isCustomRange) return;
    _periodDays  = days;
    _customStart = null;
    _customEnd   = null;
    await load();
  }

  /// Set a custom date range — clears any preset selection.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    _periodDays  = null;
    _customStart = _dateOnly(start);
    _customEnd   = _dateOnly(end);
    await load();
  }

  // ─── computation ──────────────────────────────────────────────────────────

  void _compute(ReportBundle bundle) {
    final syms  = bundle.symptomRaw;
    final life  = bundle.lifestyleRaw;
    final meds  = bundle.medications;
    final logs  = bundle.medLogs;
    final allSy = bundle.allSymptoms;

    dev.log('[RC] _compute: syms=${syms.length} meds=${meds.length} logs=${logs.length}');

    if (syms.isEmpty) {
      summary      = const ReportSummary(
          avgRapid3: 0, flareCount: 0, medAdherence: 0,
          logStreakDays: 0, avgTier: 'UNKNOWN');
      chartPoints  = [];
      dailyRows    = [];
      allDailyRows = [];
      flareAlert   = FlareAlert.none();
      correlations = _emptyCorrelations();
      _stiffnessMonths = [];
      _buildPdfData(bundle, summary!, []);
      return;
    }

    final sortedAsc = [...syms]
      ..sort((a, b) => (a['logDate'] as String).compareTo(b['logDate'] as String));

    _safe('chart',        () { chartPoints  = _buildChartPoints(sortedAsc); });
    _safe('summary',      () { summary      = _buildSummary(sortedAsc, logs, meds, bundle.periodDays); });
    _safe('flare',        () { flareAlert   = _detectFlareAlert(sortedAsc); });

    final lifestyleMap = _buildLifestyleMap(life);
    _safe('dailyRows',    () { dailyRows    = _buildDailyRows([...sortedAsc]..sort((a,b) => (b['logDate'] as String).compareTo(a['logDate'] as String)), lifestyleMap, logs); });
    _safe('allDailyRows', () {
      final allSorted = [...allSy]
        ..sort((a, b) => (b['logDate'] as String).compareTo(a['logDate'] as String));
      allDailyRows = _buildDailyRows(allSorted, lifestyleMap, logs);
      if (allDailyRows.isNotEmpty) {
        final newest = allDailyRows.first.date;
        _calYear  = newest.year;
        _calMonth = newest.month;
      }
    });
    _safe('correlations', () { correlations = _buildCorrelations(sortedAsc, life, logs, meds, allSy); });
    _safe('stiffness',    () {
      _stiffnessMonths   = _buildStiffnessMonths(allSy);
      _stiffnessMonthIdx = _stiffnessMonths.isEmpty ? 0 : _stiffnessMonths.length - 1;
    });
    _safe('pdf',          () { _buildPdfData(bundle, summary!, sortedAsc); });
  }

  void _safe(String label, void Function() fn) {
    try { fn(); } catch (e, st) { dev.log('[RC] $label FAIL: $e\n$st'); }
  }

  // ── Chart Points ──────────────────────────────────────────────────────────

  List<ChartPoint> _buildChartPoints(List<Map<String, dynamic>> sorted) {
    final today = _dateOnly(DateTime.now());
    return sorted.map((s) {
      final dt    = _parseDate(s['logDate'] as String? ?? '');
      final score = (s['rapid3Score'] as num?)?.toDouble() ?? 0;
      final tier  = s['rapid3Tier']  as String? ?? '';
      return ChartPoint(
        date: dt, score: score, tier: tier,
        isFlare: tier == 'HIGH',
        isToday: _dateOnly(dt) == today,
      );
    }).toList();
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  ReportSummary _buildSummary(
    List<Map<String, dynamic>> syms,
    List<MedicationLog> logs,
    List<Medication> meds,
    int periodDays,
  ) {
    final scores = syms.map((s) => (s['rapid3Score'] as num?)?.toDouble() ?? 0).toList();
    final avg    = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final flares = syms.where((s) => s['rapid3Tier'] == 'HIGH').length;
    final adh    = _calcMedAdherence(logs, meds, periodDays);
    final streak = _calcStreak(syms);

    final tierCounts = <String, int>{};
    for (final s in syms) {
      final t = s['rapid3Tier'] as String? ?? '';
      tierCounts[t] = (tierCounts[t] ?? 0) + 1;
    }
    final domTier = tierCounts.isEmpty
        ? 'UNKNOWN'
        : tierCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return ReportSummary(
      avgRapid3:    double.parse(avg.toStringAsFixed(1)),
      flareCount:   flares,
      medAdherence: adh,
      logStreakDays: streak,
      avgTier:      domTier,
    );
  }

  double _calcMedAdherence(
      List<MedicationLog> logs, List<Medication> meds, int periodDays) {
    if (meds.isEmpty || logs.isEmpty) return 0;
    final takenSet = <String>{};
    for (final l in logs) {
      final day = _logDateKey(l.timestamp);
      takenSet.add('${l.medicationId}_$day');
    }
    int expected = 0;
    final now = DateTime.now();
    for (final med in meds) {
      for (int i = 0; i < periodDays; i++) {
        final day = now.subtract(Duration(days: i));
        if (med.isScheduledFor(day)) expected += med.expectedDosesPerDay;
      }
    }
    if (expected == 0) return 100;
    final pct = (takenSet.length / expected * 100).clamp(0.0, 100.0);
    return double.parse(pct.toStringAsFixed(0));
  }

  int _calcStreak(List<Map<String, dynamic>> syms) {
    if (syms.isEmpty) return 0;
    final desc = [...syms]
      ..sort((a, b) => (b['logDate'] as String).compareTo(a['logDate'] as String));
    int      streak   = 0;
    DateTime expected = _dateOnly(DateTime.now());
    for (final s in desc) {
      final dt = _dateOnly(_parseDate(s['logDate'] as String? ?? ''));
      if (dt == expected) { streak++; expected = dt.subtract(const Duration(days: 1)); }
      else { break; }
    }
    return streak;
  }

  // ── Flare Alert ───────────────────────────────────────────────────────────

  FlareAlert _detectFlareAlert(List<Map<String, dynamic>> sorted) {
    if (sorted.length < 2) return FlareAlert.none();
    final recent = sorted.length >= 5
        ? sorted.sublist(sorted.length - 5) : sorted;
    final scores = recent.map((s) => (s['rapid3Score'] as num?)?.toDouble() ?? 0).toList();
    int risingDays = 0;
    for (int i = scores.length - 1; i > 0; i--) {
      if (scores[i] > scores[i - 1]) risingDays++;
      else break;
    }
    if (risingDays < 2) return FlareAlert.none();
    final from = scores[scores.length - 1 - risingDays];
    final to   = scores.last;
    return FlareAlert(
      isActive: true,
      title: 'Flare Risk Detected',
      body:  'Your RAPID3 score has risen from ${from.toStringAsFixed(1)} → '
             '${to.toStringAsFixed(1)} over the past $risingDays days. '
             'Consider contacting your rheumatologist if the score exceeds 12.',
      fromScore: from, toScore: to, consecutiveDays: risingDays,
    );
  }

  // ── Daily Rows ────────────────────────────────────────────────────────────

  Map<String, Map<String, dynamic>> _buildLifestyleMap(
      List<Map<String, dynamic>> life) {
    final map = <String, Map<String, dynamic>>{};
    for (final l in life) {
      final key = l['progressDate'] as String? ?? '';
      if (key.isNotEmpty) map[key] = l;
    }
    return map;
  }

  List<DailyLogRow> _buildDailyRows(
    List<Map<String, dynamic>> sortedDesc,
    Map<String, Map<String, dynamic>> lifestyleMap,
    List<MedicationLog> logs,
  ) {
    final medByDay = <String, List<MedicationLog>>{};
    for (final l in logs) {
      final key = _logDateKey(l.timestamp);
      medByDay.putIfAbsent(key, () => []).add(l);
    }
    return sortedDesc.map((s) {
      final dateKey = s['logDate'] as String? ?? '';
      final dt      = _parseDate(dateKey);
      final life    = lifestyleMap[dateKey];
      final dayMeds = medByDay[dateKey] ?? [];
      final medsStr = dayMeds.isEmpty ? '—'
          : dayMeds.map((m) {
              final a = m.medicationName.length > 3
                  ? m.medicationName.substring(0, 3)
                  : m.medicationName;
              return '$a ✓';
            }).join('  ');

      String exName = ''; bool exDone = false;
      if (life != null) {
        final exLogs = life['exerciseLogs'] as Map<String, dynamic>? ?? {};
        if (exLogs.isNotEmpty) {
          final first = exLogs.values.first as Map<String, dynamic>;
          exName = first['exerciseName'] as String? ?? '';
          exDone = _asBool(first['completed']);
        }
      }

      return DailyLogRow(
        date: dt,
        rapid3Score:      (s['rapid3Score'] as num?)?.toDouble() ?? 0,
        tier:              s['rapid3Tier']  as String? ?? '',
        medsStatus:       medsStr,
        exerciseName:     exName,
        exerciseDone:     exDone,
        humidityPct:      0,
        stiffnessMin:     (s['morningStiffnessMinutes'] as num?)?.toInt()    ?? 0,
        stressLevel:      (s['stressLevel'] as num?)?.toDouble()             ?? 0,
        affectedJoints:    List<String>.from(s['affectedJoints'] ?? []),
        pain:             (s['pain']             as num?)?.toDouble() ?? 0,
        function:         (s['function']         as num?)?.toDouble() ?? 0,
        globalAssessment: (s['globalAssessment'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  // ── Correlations ──────────────────────────────────────────────────────────

  CorrelationData _buildCorrelations(
    List<Map<String, dynamic>> syms,
    List<Map<String, dynamic>> life,
    List<MedicationLog> logs,
    List<Medication> meds,
    List<Map<String, dynamic>> allSyms,
  ) {
    return CorrelationData(
      medAdherence:     _buildMedCorr(syms, logs, meds),
      stress:           _buildStressCorr(syms),
      stiffnessByMonth: _buildStiffnessMonths(allSyms),
    );
  }

  MedAdherenceCorrelation _buildMedCorr(
    List<Map<String, dynamic>> syms,
    List<MedicationLog> logs,
    List<Medication> meds,
  ) {
    final scoreByDate = <String, double>{};
    for (final s in syms) {
      scoreByDate[s['logDate'] as String? ?? ''] =
          (s['rapid3Score'] as num?)?.toDouble() ?? 0;
    }
    final events = <MissedMedEvent>[];
    if (meds.isNotEmpty) {
      final med      = meds.first;
      final takenDays = <String>{};
      for (final l in logs) {
        if (l.medicationId == med.id) takenDays.add(_logDateKey(l.timestamp));
      }
      final sorted = [...syms]
        ..sort((a, b) => (a['logDate'] as String).compareTo(b['logDate'] as String));
      for (int i = 0; i < sorted.length - 1; i++) {
        final today   = sorted[i]['logDate'] as String? ?? '';
        final nextKey = sorted[i + 1]['logDate'] as String? ?? '';
        final wasMissed = !takenDays.contains(today) && med.isScheduledFor(_parseDate(today));
        if (wasMissed || events.length < 3) {
          events.add(MissedMedEvent(
            date: _parseDate(today), medName: med.name,
            nextDayScore: scoreByDate[nextKey] ?? 0, wasMissed: wasMissed,
          ));
        }
        if (events.length >= 6) break;
      }
    }
    final missedScores = events.where((e) => e.wasMissed).map((e) => e.nextDayScore).toList();
    final takenScores  = events.where((e) => !e.wasMissed).map((e) => e.nextDayScore).toList();
    double avg(List<double> v) => v.isEmpty ? 0 : double.parse((v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1));
    return MedAdherenceCorrelation(
      avgScoreOnMissedDay:   avg(missedScores),
      avgScoreOnAdherentDay: avg(takenScores),
      flaresAfterMissed: events.where((e) => e.wasMissed && e.nextDayScore > 4).length,
      totalFlares: syms.where((s) => s['rapid3Tier'] == 'HIGH').length.clamp(1, 999),
      events: events,
    );
  }

  StressCorrelation _buildStressCorr(List<Map<String, dynamic>> syms) {
    final points = syms.map((s) => StressPoint(
      date:        _parseDate(s['logDate'] as String? ?? ''),
      stressLevel: (s['stressLevel']  as num?)?.toDouble() ?? 0,
      painScore:   (s['rapid3Score']  as num?)?.toDouble() ?? 0,
      tier:         s['rapid3Tier']   as String? ?? '',
    )).toList();

    if (points.length < 3) {
      return const StressCorrelation(
          correlationCoeff: double.nan,
          avgPainLowStress: 0, avgPainHighStress: 0, points: []);
    }
    final n     = points.length.toDouble();
    final meanX = points.fold(0.0, (a, p) => a + p.stressLevel) / n;
    final meanY = points.fold(0.0, (a, p) => a + p.painScore)   / n;
    double covXY = 0, varX = 0, varY = 0;
    for (final p in points) {
      final dx = p.stressLevel - meanX;
      final dy = p.painScore   - meanY;
      covXY += dx * dy; varX += dx * dx; varY += dy * dy;
    }
    final den = varX * varY;
    final r   = den <= 0 ? double.nan : covXY / math.sqrt(den);
    double avg2(List<double> v) => v.isEmpty ? 0 : double.parse((v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1));
    return StressCorrelation(
      correlationCoeff: r.isNaN ? double.nan : double.parse(r.toStringAsFixed(2)),
      avgPainLowStress:  avg2(points.where((p) => p.stressLevel <= 3).map((p) => p.painScore).toList()),
      avgPainHighStress: avg2(points.where((p) => p.stressLevel >= 7).map((p) => p.painScore).toList()),
      points: points,
    );
  }

  List<StiffnessMonthData> _buildStiffnessMonths(
      List<Map<String, dynamic>> allSyms) {
    if (allSyms.isEmpty) return [];
    final byMonth = <String, List<int>>{};
    for (final s in allSyms) {
      final dateKey  = s['logDate'] as String? ?? '';
      if (dateKey.length < 6) continue;
      final monthKey = dateKey.substring(0, 6);
      final stiff    = (s['morningStiffnessMinutes'] as num?)?.toInt() ?? 0;
      byMonth.putIfAbsent(monthKey, () => []).add(stiff);
    }
    final sorted = byMonth.keys.toList()..sort();
    double? prevAvg;
    return sorted.map((key) {
      final values = byMonth[key]!;
      final avg    = values.reduce((a, b) => a + b) / values.length;
      final year   = int.parse(key.substring(0, 4));
      final month  = int.parse(key.substring(4, 6));
      final data   = StiffnessMonthData(
        monthLabel:   _monthLabel(year, month),
        avgMinutes:   double.parse(avg.toStringAsFixed(0)),
        daysAbove30:  values.where((v) => v > 30).length,
        bestMinutes:  values.reduce((a, b) => a < b ? a : b),
        worstMinutes: values.reduce((a, b) => a > b ? a : b),
        prevMonthAvg: prevAvg,
      );
      prevAvg = avg;
      return data;
    }).toList();
  }

  // ── PDF data ──────────────────────────────────────────────────────────────

  void _buildPdfData(
    ReportBundle bundle,
    ReportSummary sum,
    List<Map<String, dynamic>> sorted,
  ) {
    final prof = bundle.userProfile;
    final meds = bundle.medications;

    final jointScores = <String, List<double>>{};
    for (final s in sorted) {
      final joints = List<String>.from(s['affectedJoints'] ?? []);
      final score  = (s['rapid3Score'] as num?)?.toDouble() ?? 0;
      for (final j in joints) jointScores.putIfAbsent(j, () => []).add(score);
    }
    final jointAvg = <String, double>{};
    jointScores.forEach((j, sc) {
      jointAvg[j] = sc.reduce((a, b) => a + b) / sc.length;
    });

    final medItems = meds.map((m) {
      final logs     = bundle.medLogs.where((l) => l.medicationId == m.id).toList();
      final expected = bundle.periodDays * (m.frequency == 'Weekly' ? 1.0 / 7 : m.expectedDosesPerDay.toDouble());
      final adh      = expected == 0 ? 100.0 : (logs.length / expected * 100).clamp(0.0, 100.0);
      return MedAdherenceItem(
        medName: m.name, adherencePct: double.parse(adh.toStringAsFixed(0)),
        missedDates: [], dosage: m.dosage,
      );
    }).toList();

    final flareDates = sorted
        .where((s) => s['rapid3Tier'] == 'HIGH')
        .map((s) => _parseDate(s['logDate'] as String? ?? ''))
        .toList();

    final baselineScore = sorted.isNotEmpty
        ? (sorted.first['rapid3Score'] as num?)?.toDouble() ?? 0.0 : 0.0;
    final delta = sum.avgRapid3 - baselineScore;
    final eular = delta <= -2.4 ? 'GOOD IMPROVEMENT'
        : delta <= -1.2 ? 'MODERATE IMPROVEMENT'
        : delta <= 0    ? 'MINIMAL IMPROVEMENT'
                        : 'NO RESPONSE';

    pdfData = PdfReportData(
      patientName:    prof['displayName'] ?? prof['name'] ?? 'Patient',
      patientIc:      prof['ic']          ?? 'N/A',
      patientGender:  prof['gender']      ?? '',
      patientAge:     (prof['age'] as num?)?.toInt() ?? 0,
      doctorName:     prof['doctorName']  ?? 'Rheumatologist',
      periodFrom:     bundle.startDate,
      periodTo:       bundle.endDate,
      avgRapid3:      sum.avgRapid3,
      avgTier:        sum.avgTier,
      flareDays:      sum.flareCount,
      medAdherence:   sum.medAdherence,
      bestScore: sorted.isEmpty ? 0
          : sorted.map((s) => (s['rapid3Score'] as num?)?.toDouble() ?? 0)
              .reduce((a, b) => a < b ? a : b),
      bestScoreDate: sorted.isEmpty ? DateTime.now()
          : _parseDate((sorted
              ..sort((a, b) => ((a['rapid3Score'] as num?) ?? 99)
                  .compareTo((b['rapid3Score'] as num?) ?? 99)))
              .first['logDate'] as String? ?? ''),
      jointAvgScores: jointAvg,
      medItems:       medItems,
      recentLogs:     dailyRows.take(5).toList(),
      actionItems:    _generateActionItems(sum, bundle),
      flareDates:     flareDates,
      eularResponse:  eular,
      baselineRapid3: baselineScore,
    );
  }

  List<String> _generateActionItems(ReportSummary sum, ReportBundle bundle) {
    final items = <String>[];
    if (sum.medAdherence < 90) items.add('Review medication adherence — currently ${sum.medAdherence.round()}%');
    if (sum.avgRapid3 > 6)     items.add('Consider dose review — sustained RAPID3 avg ${sum.avgRapid3.toStringAsFixed(1)} over ${bundle.periodDays} days');
    if (sum.flareCount >= 3)   items.add('${sum.flareCount} flare days detected — discuss flare prevention strategy');
    items.add('Monitor LFT if on Methotrexate — routine blood test recommended');
    items.add('Review stiffness duration trend — correlates with daily RAPID3 score');
    return items.take(4).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  CorrelationData _emptyCorrelations() => const CorrelationData(
    medAdherence: MedAdherenceCorrelation(
      avgScoreOnMissedDay: 0, avgScoreOnAdherentDay: 0,
      flaresAfterMissed: 0, totalFlares: 1, events: [],
    ),
    stress: StressCorrelation(
      correlationCoeff: double.nan,
      avgPainLowStress: 0, avgPainHighStress: 0, points: [],
    ),
    stiffnessByMonth: [],
  );

  static bool _asBool(dynamic v) {
    if (v == null)   return false;
    if (v is bool)   return v;
    if (v is int)    return v != 0;
    if (v is double) return v != 0.0;
    return false;
  }

  String _logDateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  DateTime _parseDate(String s) {
    if (s.length != 8) return DateTime.now();
    return DateTime(int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)), int.parse(s.substring(6, 8)));
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _monthLabel(int year, int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${names[month]} $year';
  }

  /// Format date as "6 Mar 2026"
  static String _fmt(DateTime d) {
    const mo = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${mo[d.month]} ${d.year}';
  }

  void _setState(ReportState s) { _state = s; notifyListeners(); }
  void _setError(String msg)    { _error = msg; _state = ReportState.error; notifyListeners(); }
}