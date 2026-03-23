// lib/views/medication/medication_today_view.dart
//
// Sections: Due Anytime | Due Now | Forgot to Take | Upcoming | Taken
// Bottom:   7-day heatmap — tap any circle → bottom sheet with that day's detail

import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/medication_controller.dart';
import '../../models/medication_model.dart';
import '../../models/scheduled_dose.dart';

class MedicationTodayView extends StatelessWidget {
  const MedicationTodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl     = context.watch<MedicationController>();
    final anytime  = ctrl.dosesAnytime;
    final dueSoon  = ctrl.dosesDueSoon;
    final missed   = ctrl.dosesMissed;
    final upcoming = ctrl.dosesUpcoming;
    final taken    = ctrl.dosesTaken;
    final summary  = ctrl.todaySummary;
    final allEmpty = anytime.isEmpty && dueSoon.isEmpty &&
        missed.isEmpty && upcoming.isEmpty && taken.isEmpty;

    return ListView(
      padding: EdgeInsets.zero,
      children: [

        // ── Today summary bar ──────────────────────────────────────────
        _TodaySummaryBar(done: summary.$1, total: summary.$2, ctrl: ctrl),

        // ── Stock banners ──────────────────────────────────────────────
        if (ctrl.hasOutOfStock)
          _StockBanner(meds: ctrl.outOfStockMedications, isEmpty: true),
        if (ctrl.hasLowStock && !ctrl.hasOutOfStock)
          _StockBanner(meds: ctrl.lowStockMedications, isEmpty: false),

        // ── Empty state ────────────────────────────────────────────────
        if (allEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _EmptySchedule(),
        ],

        // ── 🕐 Due Anytime ──────────────────────────────────────────
        if (anytime.isNotEmpty) ...[
          _SectionLabel(icon: '🕐', title: 'DUE ANYTIME', color: AppColors.primary),
          _DoseList(doses: anytime, ctrl: ctrl),
        ],

        // ── ⏰ Due Now ──────────────────────────────────────────────
        if (dueSoon.isNotEmpty) ...[
          _SectionLabel(icon: '⏰', title: 'DUE NOW', color: AppColors.tierLow),
          _DoseList(doses: dueSoon, ctrl: ctrl),
        ],

        // ── 🔴 Forgot to Take ──────────────────────────────────────
        if (missed.isNotEmpty) ...[
          _SectionLabel(icon: '🔴', title: 'FORGOT TO TAKE', color: AppColors.tierHigh),
          _DoseList(doses: missed, ctrl: ctrl, isMissed: true),
        ],

        // ── 🕘 Upcoming ────────────────────────────────────────────
        if (upcoming.isNotEmpty) ...[
          _SectionLabel(icon: '🕘', title: 'UPCOMING TODAY', color: AppColors.textMuted),
          _DoseList(doses: upcoming, ctrl: ctrl),
        ],

        // ── ✅ Taken ───────────────────────────────────────────────
        if (taken.isNotEmpty) ...[
          _SectionLabel(icon: '✅', title: 'TAKEN', color: AppColors.tierRemission),
          _DoseList(doses: taken, ctrl: ctrl),
        ],

        // ── 7-day heatmap ──────────────────────────────────────────
        if (ctrl.medications.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.sm),
            child: Row(children: [
              Text('THIS WEEK', style: AppTextStyles.labelCaps()),
              const SizedBox(width: 6),
              Text('Tap a day to see details',
                  style: AppTextStyles.caption()),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: _WeeklyHeatmap(ctrl: ctrl),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TODAY SUMMARY BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TodaySummaryBar extends StatelessWidget {
  final int done, total;
  final MedicationController ctrl;
  const _TodaySummaryBar(
      {required this.done, required this.total, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final pct    = total > 0 ? done / total : 0.0;
    final streak = ctrl.adherenceStreak;
    final allDone = done == total && total > 0;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F2D), Color(0xFF1B3A4B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevated(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Date + streak badge
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_todayLabel(), style: TextStyle(
              fontSize: 12, color: Colors.white.withOpacity(0.5),
              fontFamily: 'DM Mono', letterSpacing: 0.5,
            )),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tierRemission.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.tierRemission.withOpacity(0.4)),
                ),
                child: Text('🔥 $streak-day streak', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.tierRemission, fontFamily: 'PlusJakartaSans',
                )),
              ),
          ]),

          const SizedBox(height: AppSpacing.sm),

          // Headline
          Text(
            total == 0
                ? 'No medications today'
                : allDone
                    ? '🎉 All done for today!'
                    : '$done of $total doses taken',
            style: const TextStyle(
              fontFamily: 'Syne', fontSize: 22,
              fontWeight: FontWeight.w800, color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          if (total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value:          pct.clamp(0.0, 1.0),
                minHeight:      6,
                backgroundColor: Colors.white12,
                valueColor:      AlwaysStoppedAnimation<Color>(
                  allDone ? AppColors.tierRemission : AppColors.tierLow,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              total - done == 0
                  ? 'All medications logged ✓'
                  : '${total - done} remaining'
                    '${ctrl.dosesMissed.isNotEmpty ? " · ${ctrl.dosesMissed.length} missed" : ""}',
              style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.55),
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC'];
    const days   = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    return '${days[now.weekday - 1]}  ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-DAY HEATMAP  — tap any circle to see that day's medication detail
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyHeatmap extends StatelessWidget {
  final MedicationController ctrl;
  const _WeeklyHeatmap({required this.ctrl});

  Color _color(HeatmapStatus s) {
    switch (s) {
      case HeatmapStatus.taken:   return AppColors.tierRemission;
      case HeatmapStatus.partial: return AppColors.tierLow;
      case HeatmapStatus.missed:  return AppColors.tierHigh;
      case HeatmapStatus.pending: return AppColors.primary.withOpacity(0.55);
      case HeatmapStatus.none:    return AppColors.bgSection;
    }
  }

  String _symbol(HeatmapStatus s) {
    switch (s) {
      case HeatmapStatus.taken:   return '✓';
      case HeatmapStatus.partial: return '~';
      case HeatmapStatus.missed:  return '✗';
      case HeatmapStatus.pending: return '·';
      case HeatmapStatus.none:    return '';
    }
  }

  void _onTapDay(BuildContext context, HeatmapDay day) {
    // Don't open sheet for days with no medications
    if (day.status == HeatmapStatus.none) return;

    final details = ctrl.getDayDetail(day.date);
    if (details.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _DayDetailSheet(day: day, details: details),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ctrl.weeklyHeatmap;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            final color    = _color(day.status);
            final isToday  = day.isToday;
            final tappable = day.status != HeatmapStatus.none;

            return Expanded(
              child: GestureDetector(
                onTap: tappable ? () => _onTapDay(context, day) : null,
                child: Column(children: [
                  Text(
                    day.dayLabel,
                    style: AppTextStyles.labelCaps().copyWith(
                      color:      isToday ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(
                          day.status == HeatmapStatus.none ? 0.4 : 1),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : tappable
                              ? Border.all(
                                  color: color.withOpacity(0.4), width: 1)
                              : null,
                      boxShadow: day.status == HeatmapStatus.taken
                          ? [BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8, spreadRadius: 1,
                            )]
                          : null,
                    ),
                    child: Center(
                      child: Text(_symbol(day.status), style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w800,
                        color: day.status == HeatmapStatus.none
                            ? AppColors.textMuted
                            : Colors.white,
                      )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(day.dayNum,
                    style: AppTextStyles.caption().copyWith(
                      color:      isToday ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.sm),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _LegendItem(color: AppColors.tierRemission, label: 'All taken'),
          const SizedBox(width: 14),
          _LegendItem(color: AppColors.tierLow,       label: 'Partial'),
          const SizedBox(width: 14),
          _LegendItem(color: AppColors.tierHigh,      label: 'Missed'),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY DETAIL BOTTOM SHEET
// Shows each medication scheduled for the tapped day with taken/missed status
// ─────────────────────────────────────────────────────────────────────────────
class _DayDetailSheet extends StatelessWidget {
  final HeatmapDay         day;
  final List<DayMedDetail> details;
  const _DayDetailSheet({required this.day, required this.details});

  Color _statusColor(DayMedStatus s) {
    switch (s) {
      case DayMedStatus.taken:   return AppColors.tierRemission;
      case DayMedStatus.partial: return AppColors.tierLow;
      case DayMedStatus.missed:  return AppColors.tierHigh;
      case DayMedStatus.pending: return AppColors.primary;
    }
  }

  String _statusLabel(DayMedStatus s) {
    switch (s) {
      case DayMedStatus.taken:   return 'Taken';
      case DayMedStatus.partial: return 'Partial';
      case DayMedStatus.missed:  return 'Missed';
      case DayMedStatus.pending: return 'Pending';
    }
  }

  IconData _statusIcon(DayMedStatus s) {
    switch (s) {
      case DayMedStatus.taken:   return Icons.check_circle_rounded;
      case DayMedStatus.partial: return Icons.remove_circle_outline_rounded;
      case DayMedStatus.missed:  return Icons.cancel_rounded;
      case DayMedStatus.pending: return Icons.radio_button_unchecked_rounded;
    }
  }

  String _medEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':    return '💊';
      case 'capsule':   return '💊';
      case 'liquid':    return '🧴';
      case 'injection': return '💉';
      default:          return '💊';
    }
  }

  String _dateLabel() {
    final d = day.date;
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    // Summary counts
    final takenCount   = details.where((d) => d.status == DayMedStatus.taken).length;
    final missedCount  = details.where((d) => d.status == DayMedStatus.missed).length;
    final partialCount = details.where((d) => d.status == DayMedStatus.partial).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize:     0.4,
      maxChildSize:     0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Handle ──
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dateLabel(), style: AppTextStyles.sectionTitle()),
                      const SizedBox(height: 4),
                      // Summary chips
                      Row(children: [
                        if (takenCount > 0)
                          _SummaryChip('$takenCount taken', AppColors.tierRemission),
                        if (partialCount > 0) ...[
                          const SizedBox(width: 6),
                          _SummaryChip('$partialCount partial', AppColors.tierLow),
                        ],
                        if (missedCount > 0) ...[
                          const SizedBox(width: 6),
                          _SummaryChip('$missedCount missed', AppColors.tierHigh),
                        ],
                      ]),
                    ],
                  ),
                ),
                // Overall day dot (large)
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _dayColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_daySymbol(), style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),

          // ── Medication list ──
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: details.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final d   = details[i];
                final col = _statusColor(d.status);
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Emoji icon
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(_medEmoji(d.medication.medicationType),
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name + dose info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.medication.name,
                                style: AppTextStyles.cardTitle()),
                            const SizedBox(height: 2),
                            Text(
                              '${d.medication.dosage.isNotEmpty ? d.medication.dosage + " · " : ""}'
                              '${d.medication.perDose} ${d.medication.medicationType.toLowerCase()} · '
                              '${d.medication.mealTiming}',
                              style: AppTextStyles.caption(),
                            ),
                            const SizedBox(height: 4),
                            // Doses count
                            Text(d.takenLabel,
                                style: AppTextStyles.caption()
                                    .copyWith(color: col, fontWeight: FontWeight.w600)),
                            // Logged times
                            if (d.loggedTimes.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.access_time_rounded,
                                    size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text('Logged at ${d.timeLabel}',
                                    style: AppTextStyles.caption()),
                              ]),
                            ],
                            // Missed reason
                            if (d.status == DayMedStatus.missed) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 11, color: AppColors.tierHigh),
                                const SizedBox(width: 4),
                                Text('Not taken this day',
                                    style: AppTextStyles.caption()
                                        .copyWith(color: AppColors.tierHigh)),
                              ]),
                            ],
                          ],
                        ),
                      ),

                      // Status icon + label
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(d.status), size: 22, color: col),
                          const SizedBox(height: 3),
                          Text(_statusLabel(d.status),
                              style: AppTextStyles.labelCaps()
                                  .copyWith(color: col, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _dayColor() {
    switch (day.status) {
      case HeatmapStatus.taken:   return AppColors.tierRemission;
      case HeatmapStatus.partial: return AppColors.tierLow;
      case HeatmapStatus.missed:  return AppColors.tierHigh;
      case HeatmapStatus.pending: return AppColors.primary;
      case HeatmapStatus.none:    return AppColors.bgSection;
    }
  }

  String _daySymbol() {
    switch (day.status) {
      case HeatmapStatus.taken:   return '✓';
      case HeatmapStatus.partial: return '~';
      case HeatmapStatus.missed:  return '✗';
      default:                    return '·';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String text;
  final Color  color;
  const _SummaryChip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text,
        style: AppTextStyles.labelCaps().copyWith(color: color, fontSize: 9)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String icon, title;
  final Color  color;
  const _SectionLabel(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.xl, AppSpacing.base, AppSpacing.sm),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 6),
      Text(title,
          style: AppTextStyles.labelCaps()
              .copyWith(color: color, letterSpacing: 0.8)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DOSE LIST
// ─────────────────────────────────────────────────────────────────────────────
class _DoseList extends StatelessWidget {
  final List<ScheduledDose>  doses;
  final MedicationController ctrl;
  final bool                 isMissed;
  const _DoseList(
      {required this.doses, required this.ctrl, this.isMissed = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
    child: AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: doses.asMap().entries.map((e) => _DoseRow(
          dose:        e.value,
          ctrl:        ctrl,
          isMissed:    isMissed,
          showDivider: e.key < doses.length - 1,
        )).toList(),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DOSE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _DoseRow extends StatelessWidget {
  final ScheduledDose          dose;
  final MedicationController   ctrl;
  final bool                   isMissed;
  final bool                   showDivider;
  const _DoseRow({
    required this.dose, required this.ctrl,
    required this.isMissed, required this.showDivider,
  });

  Color get _statusColor {
    switch (dose.status) {
      case DoseStatus.taken:    return AppColors.tierRemission;
      case DoseStatus.missed:   return AppColors.tierHigh;
      case DoseStatus.dueSoon:  return AppColors.tierLow;
      case DoseStatus.anytime:  return AppColors.primary;
      case DoseStatus.upcoming: return AppColors.border;
    }
  }

  String get _medEmoji {
    switch (dose.medication.medicationType.toLowerCase()) {
      case 'tablet':    return '💊';
      case 'capsule':   return '💊';
      case 'liquid':    return '🧴';
      case 'injection': return '💉';
      default:          return '💊';
    }
  }

  void _handleLog(BuildContext context) async {
    final med = dose.medication;
    if (med.isOutOfStock) {
      final proceed = await _outOfStockDialog(context, med);
      if (!proceed) return;
    }
    await ctrl.markDoseTaken(dose);
    if (context.mounted && med.knownSideEffects.isNotEmpty) {
      _showSideEffectSheet(context, dose, ctrl);
    }
  }

  Future<bool> _outOfStockDialog(BuildContext ctx, Medication med) async =>
      await showDialog<bool>(
            context: ctx,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text('⚠️ Out of Stock', style: AppTextStyles.sectionTitle()),
              content: Text(
                '${med.name} shows 0 units. Log anyway or update stock first.',
                style: AppTextStyles.body(),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondary))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Log Anyway')),
              ],
            ),
          ) ??
          false;

  @override
  Widget build(BuildContext context) {
    final isTaken    = dose.status == DoseStatus.taken;
    final isUpcoming = dose.status == DoseStatus.upcoming;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.md),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

          // Status dot
          Container(
            width: 9, height: 9,
            decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isTaken
                  ? AppColors.tierRemission.withOpacity(0.1)
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
                child: Text(_medEmoji, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dose.medication.name,
                  style: AppTextStyles.cardTitle().copyWith(
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                    color: isTaken ? AppColors.textMuted : AppColors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Row(children: [
                Text(dose.doseSubtitle, style: AppTextStyles.caption()),
                const SizedBox(width: 5),
                Text('· ${dose.timeLabel}',
                    style: AppTextStyles.caption().copyWith(
                        color: _statusColor, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                if (dose.medication.mealTiming != 'Any Time')
                  _Badge(dose.medication.mealTiming, AppColors.primary),
                const SizedBox(width: 5),
                if (dose.medication.isOutOfStock)
                  _Badge('Out of stock', AppColors.tierHigh)
                else if (dose.medication.isLowStock)
                  _Badge('${dose.medication.stockCurrent} left', AppColors.tierLow)
                else
                  _Badge('${dose.medication.stockCurrent} left', AppColors.textMuted),
              ]),
              if (isMissed) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 12, color: AppColors.tierHigh),
                  const SizedBox(width: 4),
                  Text('You forgot to take this medicine',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.tierHigh)),
                ]),
              ],
              if (dose.isAnytime && !isTaken) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_outlined,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Take anytime today',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.primary)),
                ]),
              ],
              if (dose.status == DoseStatus.dueSoon && !isTaken) ...[
                const SizedBox(height: 4),
                Builder(builder: (ctx) {
                  final diff =
                      dose.scheduledTime.difference(DateTime.now()).inMinutes;
                  return Row(children: [
                    const Icon(Icons.timer_outlined,
                        size: 12, color: AppColors.tierLow),
                    const SizedBox(width: 4),
                    Text(diff <= 0 ? 'Due now' : '$diff min left',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.tierLow)),
                  ]);
                }),
              ],
            ]),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Action
          if (isTaken)
            _DoneChip()
          else if (!isUpcoming)
            _LogButton(
                isMissed: isMissed,
                onTap:    () => _handleLog(context))
          else
            SizedBox(
              width: 52,
              child: Text(dose.timeLabel,
                  style: AppTextStyles.caption(), textAlign: TextAlign.right),
            ),
        ]),
      ),
      if (showDivider)
        const Divider(color: AppColors.divider, height: 1, indent: 24),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDE EFFECT SHEET
// ─────────────────────────────────────────────────────────────────────────────
void _showSideEffectSheet(
    BuildContext context, ScheduledDose dose, MedicationController ctrl) {
  final selected  = <String>{};
  final notesCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base, right: AppSpacing.base,
          top: AppSpacing.base,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xxl,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.base),
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          )),
          Text('Any side effects?', style: AppTextStyles.sectionTitle()),
          const SizedBox(height: 4),
          Text('After taking ${dose.medication.name}',
              style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: dose.medication.knownSideEffects.map((effect) {
              final active = selected.contains(effect);
              return GestureDetector(
                onTap: () => setState(() =>
                    active ? selected.remove(effect) : selected.add(effect)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.tierHigh.withOpacity(0.12)
                        : AppColors.bgSection,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active
                          ? AppColors.tierHigh.withOpacity(0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(effect,
                      style: AppTextStyles.label().copyWith(
                          color: active
                              ? AppColors.tierHigh
                              : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
                hintText: 'Additional notes (optional)...'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.base),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No side effects'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (selected.isNotEmpty || notesCtrl.text.isNotEmpty) {
                    await ctrl.markDoseTaken(dose,
                        sideEffects: selected.toList(),
                        notes:       notesCtrl.text.trim());
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color; final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: AppTextStyles.caption()),
  ]);
}

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
        color: AppColors.tierRemission.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_rounded, size: 14, color: AppColors.tierRemission),
      const SizedBox(width: 4),
      Text('Done', style: AppTextStyles.label()
          .copyWith(color: AppColors.tierRemission)),
    ]),
  );
}

class _LogButton extends StatelessWidget {
  final bool isMissed;
  final VoidCallback onTap;
  const _LogButton({required this.isMissed, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = isMissed ? AppColors.tierHigh : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border:       Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(isMissed ? 'Log Late' : 'Log',
            style: AppTextStyles.label().copyWith(color: color)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border:       Border.all(color: color.withOpacity(0.2))),
    child: Text(text, style: AppTextStyles.labelCaps()
        .copyWith(color: color, fontSize: 9)),
  );
}

class _StockBanner extends StatelessWidget {
  final List<Medication> meds; final bool isEmpty;
  const _StockBanner({required this.meds, required this.isEmpty});
  @override
  Widget build(BuildContext context) {
    final color  = isEmpty ? AppColors.tierHigh : AppColors.tierLow;
    final names  = meds
        .map((m) => '${m.name.split(' ').first} '
            '(${isEmpty ? 'out of stock' : '~${m.stockCurrent} left'})')
        .join(', ');
    return Container(
      margin:  const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:       Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Text(isEmpty ? '⛔' : '⚠️', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${isEmpty ? 'Out of stock' : 'Low stock'}: $names — '
            '${isEmpty ? 'reminders still active, please refill.' : 'consider refilling soon.'}',
            style: AppTextStyles.caption().copyWith(color: color),
          ),
        ),
      ]),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base, vertical: AppSpacing.xl),
    child: Center(child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: AppColors.tierRemission.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline_rounded,
            size: 32, color: AppColors.tierRemission),
      ),
      const SizedBox(height: AppSpacing.md),
      Text('No medications today', style: AppTextStyles.sectionTitle()),
      const SizedBox(height: 4),
      Text('Add medications in the Medications tab.',
          style: AppTextStyles.caption(), textAlign: TextAlign.center),
    ])),
  );
}