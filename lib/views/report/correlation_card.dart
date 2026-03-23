// lib/views/report/widgets/correlation_cards.dart
// 3 expandable correlation accordion cards:
//   1. Missed Meds → Flare Risk  (adherence-based, clearly explained)
//   2. Stress × Pain Level       (scatter chart, Pearson r)
//   3. Morning Stiffness         (monthly nav + MoM bars)

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../controllers/report_controller.dart';
import '../../../models/report_model.dart';
import 'package:arthro/widgets/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SECTION WRAPPER
// ─────────────────────────────────────────────────────────────────────────────
class CorrelationSection extends StatelessWidget {
  final ReportController controller;
  const CorrelationSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final corr = controller.correlations;
    if (corr == null) return const SizedBox.shrink();

    return Column(
      children: [
        // 1. Missed Meds → Flare Risk
        _CorrCard(
          index: 0,
          icon:      '💊',
          title:     'Missed Meds → Flare Risk',
          subtitle:  '${corr.medAdherence.flaresAfterMissed} of ${corr.medAdherence.totalFlares} flares followed a missed dose',
          statLabel: corr.medAdherence.headlineStat,
          statColor: AppColors.tierHigh,
          controller: controller,
          body: _MedBody(data: corr.medAdherence),
        ),
        const SizedBox(height: 8),
        // 2. Stress × Pain
        _CorrCard(
          index: 1,
          icon:      '🧠',
          title:     'Stress × Pain Level',
          subtitle:  corr.stress.correlationCoeff.isNaN
              ? 'Log more days to see your stress–pain link'
              : '${corr.stress.strengthLabel.toUpperCase()} correlation · ${corr.stress.headlineStat}',
          statLabel: corr.stress.headlineStat,
          statColor: AppColors.tierModerate,
          controller: controller,
          body: _StressBody(data: corr.stress),
        ),
        const SizedBox(height: 8),
        // 3. Morning Stiffness
        _CorrCard(
          index: 2,
          icon:      '⏱️',
          title:     'Morning Stiffness',
          subtitle:  controller.currentStiffnessMonth?.subtitle ?? '',
          statLabel: controller.currentStiffnessMonth == null
              ? '—'
              : '${controller.currentStiffnessMonth!.avgMinutes.round()}m',
          statColor: AppColors.tierLow,
          controller: controller,
          body: _StiffnessBody(controller: controller),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE ACCORDION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CorrCard extends StatelessWidget {
  final int              index;
  final String           icon;
  final String           title;
  final String           subtitle;
  final String           statLabel;
  final Color            statColor;
  final ReportController controller;
  final Widget           body;

  const _CorrCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statLabel,
    required this.statColor,
    required this.controller,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = controller.expandedCorrelation == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(
            color: isOpen
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border),
        boxShadow: AppShadows.subtle(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => controller.toggleCorrelation(index),
            borderRadius: BorderRadius.vertical(
              top:    const Radius.circular(AppRadius.lg),
              bottom: isOpen
                  ? Radius.zero
                  : const Radius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.cardTitle()),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTextStyles.caption(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(statLabel,
                    style: AppTextStyles.scoreMedium(statColor)
                        .copyWith(fontSize: 20)),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns:    isOpen ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:    Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 20),
                ),
              ]),
            ),
          ),
          // Body
          AnimatedCrossFade(
            firstChild:  const SizedBox(width: double.infinity, height: 0),
            secondChild: ClipRect(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.divider)),
                ),
                padding: const EdgeInsets.all(AppSpacing.base),
                child: body,
              ),
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration:  const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. MISSED MEDS BODY
// Clearly explains HOW the correlation is determined.
// ─────────────────────────────────────────────────────────────────────────────
class _MedBody extends StatelessWidget {
  final MedAdherenceCorrelation data;
  const _MedBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasMissed = data.events.any((e) => e.wasMissed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // How we determine this
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.bgSection,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How is this calculated?',
                  style: AppTextStyles.label()
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'We check each day your primary DMARD (Methotrexate) was '
                'scheduled but not logged as taken, then look at your '
                'RAPID3 score the next day. If that score is above 4 '
                '(Flare threshold), it counts as a flare following a missed dose.',
                style: AppTextStyles.bodySmall(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!hasMissed) ...[
          _InsightChip(
              text: '✅ No missed primary DMARD doses detected in this period. '
                    'Perfect adherence — keep it up!'),
        ] else ...[
          Row(children: [
            _StatBox(
              value: data.avgScoreOnMissedDay.toStringAsFixed(1),
              label: 'Avg RAPID3 day after missed dose',
              color: AppColors.tierHigh,
            ),
            const SizedBox(width: 8),
            _StatBox(
              value: data.avgScoreOnAdherentDay.toStringAsFixed(1),
              label: 'Avg RAPID3 on adherent days',
              color: AppColors.tierRemission,
            ),
          ]),
          const SizedBox(height: 10),
          ...data.events.take(5).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _MedEventRow(event: e),
          )),
          const SizedBox(height: 6),
          _InsightChip(
            text: 'Medication adherence is your strongest flare prevention lever. '
                  'Set a daily alarm for your primary DMARD.',
          ),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color:        AppColors.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.scoreMedium(color).copyWith(fontSize: 22)),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption()),
        ],
      ),
    ),
  );
}

class _MedEventRow extends StatelessWidget {
  final MissedMedEvent event;
  const _MedEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color  = event.wasMissed ? AppColors.tierHigh : AppColors.tierRemission;
    final prefix = event.wasMissed ? '⚠️ Missed' : '✓ Took';
    final dayStr = '${event.date.day}/${event.date.month}';

    return Row(children: [
      SizedBox(
        width: 44,
        child: Text(dayStr, style: AppTextStyles.labelCaps()),
      ),
      Expanded(
        child: Text('$prefix ${event.medName}',
            style: AppTextStyles.bodySmall()
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      ),
      const Icon(Icons.arrow_forward, size: 12, color: AppColors.textMuted),
      const SizedBox(width: 4),
      _TierChip(score: event.nextDayScore),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. STRESS × PAIN BODY  —  scatter plot + stats
// ─────────────────────────────────────────────────────────────────────────────
class _StressBody extends StatelessWidget {
  final StressCorrelation data;
  const _StressBody({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.points.isEmpty) {
      return Text('Not enough data. Keep logging daily to unlock this insight.',
          style: AppTextStyles.bodySmall());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.bgSection,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Each dot below is one day — its horizontal position is your '
            'stress level (0–10) and its vertical position is your RAPID3 '
            'score. A cluster trending up-right means higher stress '
            'tends to coincide with higher pain.',
            style: AppTextStyles.bodySmall(),
          ),
        ),
        const SizedBox(height: 12),
        // Stats row
        Row(children: [
          _StatBox(
            value: data.avgPainLowStress.toStringAsFixed(1),
            label: 'Avg RAPID3 when stress ≤ 3',
            color: AppColors.tierRemission,
          ),
          const SizedBox(width: 8),
          _StatBox(
            value: data.avgPainHighStress.toStringAsFixed(1),
            label: 'Avg RAPID3 when stress ≥ 7',
            color: AppColors.tierHigh,
          ),
        ]),
        const SizedBox(height: 12),
        // Scatter chart
        SizedBox(
          height: 180,
          child: _StressScatter(points: data.points),
        ),
        const SizedBox(height: 10),
        // Pearson r interpretation
        if (!data.correlationCoeff.isNaN)
          _InsightChip(
            text: 'Pearson r = ${data.correlationCoeff.toStringAsFixed(2)} '
                  '(${data.strengthLabel} correlation). '
                  '${data.correlationCoeff > 0.3
                      ? "On high-stress days your disease activity tends to be higher — consider stress management techniques."
                      : "Stress and pain do not appear strongly linked in your data this period."}',
          ),
      ],
    );
  }
}

// ── Scatter plot painter ─────────────────────────────────────────────────────
class _StressScatter extends StatelessWidget {
  final List<StressPoint> points;
  const _StressScatter({required this.points});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScatterPainter(points: points),
      size: Size.infinite,
    );
  }
}

class _ScatterPainter extends CustomPainter {
  final List<StressPoint> points;
  const _ScatterPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final padL = 28.0;
    final padB = 22.0;
    final plotW = w - padL;
    final plotH = h - padB;

    // ── Grid ───────────────────────────────────────────────
    final gridPaint = Paint()
      ..color       = AppColors.border
      ..strokeWidth = 0.5;

    for (int gx = 0; gx <= 10; gx += 2) {
      final x = padL + gx / 10 * plotW;
      canvas.drawLine(Offset(x, 0), Offset(x, plotH), gridPaint);
      _label(canvas, gx.toString(), x - 6, plotH + 4, 8, AppColors.textMuted);
    }
    for (int gy = 0; gy <= 12; gy += 3) {
      final y = plotH - gy / 12 * plotH;
      canvas.drawLine(Offset(padL, y), Offset(w, y), gridPaint);
      _label(canvas, gy.toString(), 0, y - 5, 8, AppColors.textMuted);
    }

    // Axis labels
    _label(canvas, 'Stress →', w / 2 - 20, h - 10, 9, AppColors.textMuted);
    // RAPID3 label rotated: skip for simplicity, use text above

    // ── Regression line ────────────────────────────────────
    if (points.length >= 3) {
      final n     = points.length.toDouble();
      final meanX = points.fold(0.0, (a, p) => a + p.stressLevel) / n;
      final meanY = points.fold(0.0, (a, p) => a + p.painScore) / n;
      double covXY = 0, varX = 0;
      for (final p in points) {
        covXY += (p.stressLevel - meanX) * (p.painScore - meanY);
        varX  += (p.stressLevel - meanX) * (p.stressLevel - meanX);
      }
      if (varX > 0) {
        final m = covXY / varX;
        final b = meanY - m * meanX;
        final x0 = 0.0; final y0 = (m * x0 + b).clamp(0.0, 12.0);
        final x1 = 10.0; final y1 = (m * x1 + b).clamp(0.0, 12.0);
        canvas.drawLine(
          Offset(padL + x0 / 10 * plotW, plotH - y0 / 12 * plotH),
          Offset(padL + x1 / 10 * plotW, plotH - y1 / 12 * plotH),
          Paint()
            ..color       = AppColors.primary.withOpacity(0.4)
            ..strokeWidth = 1.5
            ..style       = PaintingStyle.stroke,
        );
      }
    }

    // ── Dots ───────────────────────────────────────────────
    for (final p in points) {
      final x = padL + p.stressLevel / 10 * plotW;
      final y = plotH - p.painScore.clamp(0, 12) / 12 * plotH;
      final color = _tierColor(p.tier);
      canvas.drawCircle(
          Offset(x, y), 4.5,
          Paint()..color = color.withOpacity(0.7));
      canvas.drawCircle(
          Offset(x, y), 4.5,
          Paint()
            ..color       = color
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'REMISSION': return AppColors.tierRemission;
      case 'LOW':       return AppColors.tierLow;
      case 'MODERATE':  return AppColors.tierModerate;
      default:          return AppColors.tierHigh;
    }
  }

  void _label(Canvas c, String text, double x, double y,
      double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(fontSize: fontSize, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, y));
  }

  @override
  bool shouldRepaint(_ScatterPainter old) => old.points != points;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. MORNING STIFFNESS BODY  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _StiffnessBody extends StatelessWidget {
  final ReportController controller;
  const _StiffnessBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final months  = controller.correlations?.stiffnessByMonth ?? [];
    final current = controller.currentStiffnessMonth;
    if (current == null) {
      return Text('No stiffness data logged yet.',
          style: AppTextStyles.caption());
    }

    return Column(
      children: [
        // Month navigator
        Row(children: [
          _NavBtn(
            icon:    Icons.chevron_left,
            enabled: controller.canGoPrevStiffMonth,
            onTap:   () => controller.changeStiffnessMonth(-1),
          ),
          Expanded(
            child: Center(
              child: Text(current.monthLabel,
                  style: AppTextStyles.cardTitle()),
            ),
          ),
          _NavBtn(
            icon:    Icons.chevron_right,
            enabled: controller.canGoNextStiffMonth,
            onTap:   () => controller.changeStiffnessMonth(1),
          ),
        ]),
        const SizedBox(height: 12),
        // KPI grid
        Row(children: [
          _StiffKPI(value: '${current.avgMinutes.round()}m',
              label: 'Monthly avg', color: _sc(current.avgMinutes)),
          const SizedBox(width: 8),
          _StiffKPI(value: '${current.daysAbove30}',
              label: 'Days >30 min', color: AppColors.tierHigh),
          const SizedBox(width: 8),
          _StiffKPI(value: '${current.bestMinutes}m',
              label: 'Best day', color: AppColors.tierRemission),
          const SizedBox(width: 8),
          _StiffKPI(value: '${current.worstMinutes}m',
              label: 'Worst day', color: AppColors.tierHigh),
        ]),
        const SizedBox(height: 12),
        Text('MONTH-OVER-MONTH', style: AppTextStyles.labelCaps()),
        const SizedBox(height: 8),
        // MoM bars — cap to 6
        ...months.reversed.take(6).toList().reversed.map((m) {
          final pct     = (m.avgMinutes / 60).clamp(0.0, 1.0);
          final col     = _sc(m.avgMinutes);
          final active  = m.monthLabel == current.monthLabel;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                width: 36,
                child: Text(
                  m.monthLabel.length >= 3 ? m.monthLabel.substring(0, 3) : m.monthLabel,
                  style: AppTextStyles.labelCaps().copyWith(
                      color: active ? AppColors.textPrimary : AppColors.textMuted),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value:           pct,
                    minHeight:       6,
                    backgroundColor: AppColors.bgSection,
                    valueColor:      AlwaysStoppedAnimation(col),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text('${m.avgMinutes.round()}m',
                    style: AppTextStyles.labelCaps().copyWith(color: col)),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
        _InsightChip(
          text: 'Stiffness >30 min often predicts a higher RAPID3 score the same day. '
                '${current.avgMinutes < 25 ? "You\'re trending down — keep going!" : "Focus on gentle morning warm-ups."}',
        ),
      ],
    );
  }

  Color _sc(double mins) {
    if (mins <= 15) return AppColors.tierRemission;
    if (mins <= 30) return AppColors.tierLow;
    if (mins <= 45) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color:        enabled ? AppColors.bgSection : AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border:       Border.all(color: AppColors.border),
      ),
      child: Icon(icon,
          size:  16,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted),
    ),
  );
}

class _StiffKPI extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  const _StiffKPI({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color:        AppColors.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(children: [
        Text(value,
            style: AppTextStyles.scoreMedium(color).copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption().copyWith(fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _InsightChip extends StatelessWidget {
  final String text;
  const _InsightChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm + 2),
    decoration: BoxDecoration(
      color:        AppColors.bgSection,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💡', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _TierChip extends StatelessWidget {
  final double score;
  const _TierChip({required this.score});

  Color get _color {
    if (score <= 1) return AppColors.tierRemission;
    if (score <= 2) return AppColors.tierLow;
    if (score <= 4) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Text(score.toStringAsFixed(1),
        style: AppTextStyles.labelCaps().copyWith(color: _color)),
  );
}