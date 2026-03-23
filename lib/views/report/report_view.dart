// lib/views/report/report_view.dart
// Main Report/Trend page.
// Changes vs v1:
//   1. Export section: Doctor Report only (email + CSV removed)
//   2. RAPID3 chart: tappable dots with tooltip + zone labels
//   3. Daily log: month-based calendar; tap a date cell to open detail
//   4. Correlations: removed humidity + exercise; added stress × pain scatter
//   5. Doctor report: single scrollable page with joint pie chart

import 'package:arthro/models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../controllers/report_controller.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'report_chart.dart';
import 'correlation_card.dart';
import 'day_detail.dart';
import 'pdf_preview.dart';

class ReportView extends StatelessWidget {
  /// Pass the patient's uid when a guardian is viewing; null = own data.
  final String? uid;
  const ReportView({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportController(uid: uid)..load(),
      child: const _ReportBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ReportBody extends StatelessWidget {
  const _ReportBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Consumer<ReportController>(
        builder: (context, ctrl, _) {
          if (ctrl.state == ReportState.loading ||
              ctrl.state == ReportState.idle) {
            return const _LoadingSkeleton();
          }
          if (ctrl.state == ReportState.error) {
            return _ErrorState(message: ctrl.error, onRetry: ctrl.load);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ReportAppBar(ctrl: ctrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, 0,
                      AppSpacing.base, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ctrl.flareAlert?.isActive == true) ...[
                        _FlareAlertBanner(alert: ctrl.flareAlert!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _PeriodToggle(ctrl: ctrl),
                      const SizedBox(height: AppSpacing.base),
                      if (ctrl.summary != null)
                        _SummaryKPIRow(summary: ctrl.summary!),
                      const SizedBox(height: AppSpacing.lg),
                      _ChartSection(ctrl: ctrl),
                      const SizedBox(height: AppSpacing.lg),
                      _CalendarLogSection(ctrl: ctrl),
                      const SizedBox(height: AppSpacing.lg),
                      _CorrelationSection(ctrl: ctrl),
                      const SizedBox(height: AppSpacing.lg),
                      _ReportSection(ctrl: ctrl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ReportAppBar extends StatelessWidget {
  final ReportController ctrl;
  const _ReportAppBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating:                true,
      snap:                    true,
      backgroundColor:         AppColors.bgCard,
      surfaceTintColor:        Colors.transparent,
      elevation:               0,
      scrolledUnderElevation:  1,
      shadowColor:             AppColors.border,
      title: Text('Trends & Reports', style: AppTextStyles.sectionTitle()),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.primary, size: 20),
          onPressed: ctrl.load,
          tooltip: 'Refresh',
        ),
        if (ctrl.pdfData != null)
          IconButton(
            icon: const Icon(Icons.description_outlined,
                color: AppColors.primary, size: 20),
            onPressed: () => DoctorReportSheet.show(context, ctrl.pdfData!),
            tooltip: 'Doctor Report',
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLARE ALERT BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _FlareAlertBanner extends StatelessWidget {
  final dynamic alert;
  const _FlareAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color:        AppColors.tierHighBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(color: AppColors.tierHigh.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.tierHigh.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔴', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppTextStyles.cardTitle()
                        .copyWith(color: AppColors.tierHigh)),
                const SizedBox(height: 3),
                Text(alert.body,
                    style: AppTextStyles.bodySmall(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD SELECTOR  — 7D / 30D / 90D presets  +  Custom date range picker
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodToggle extends StatelessWidget {
  final ReportController ctrl;
  const _PeriodToggle({required this.ctrl});

  static const _presets = [
    (label: '7D',  days: 7),
    (label: '30D', days: 30),
    (label: '90D', days: 90),
  ];

  Future<void> _pickCustomRange(BuildContext context) async {
    final now   = DateTime.now();
    final range = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(now.year - 2),
      lastDate:         now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end:   now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary:    AppColors.primary,
            onPrimary:  Colors.white,
            surface:    AppColors.bgCard,
            onSurface:  AppColors.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      await ctrl.setCustomRange(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          ..._presets.map((p) {
            final selected = !ctrl.isCustomRange && ctrl.periodDays == p.days;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _PBtn(
                label:    p.label,
                selected: selected,
                onTap:    () => ctrl.switchPeriod(p.days),
              ),
            );
          }),
          _PBtn(
            label:    'Custom',
            selected: ctrl.isCustomRange,
            icon:     Icons.calendar_today_rounded,
            onTap:    () => _pickCustomRange(context),
          ),
        ]),
        if (ctrl.dateRangeLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.date_range_rounded,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              ctrl.dateRangeLabel,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.textMuted),
            ),
          ]),
        ],
      ],
    );
  }
}

class _PBtn extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;
  final IconData?    icon;
  const _PBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color:        selected ? AppColors.primary : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border:       Border.all(
            color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11,
              color: selected ? Colors.white : AppColors.textMuted),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: AppTextStyles.labelCaps().copyWith(
                color: selected ? Colors.white : AppColors.textMuted)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY KPI ROW
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryKPIRow extends StatelessWidget {
  final dynamic summary;
  const _SummaryKPIRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTierHelper.color(summary.avgTier);
    return Row(children: [
      _KpiCard(
        value: summary.avgRapid3.toStringAsFixed(1),
        label: 'Avg RAPID3',
        color: tierColor,
        emoji: AppTierHelper.emoji(summary.avgTier),
      ),
      const SizedBox(width: 8),
      _KpiCard(
        value: '${summary.flareCount}',
        label: 'Flare Days',
        color: AppColors.tierHigh,
        emoji: '🔴',
      ),
      const SizedBox(width: 8),
      _KpiCard(
        value: '${summary.medAdherence.round()}%',
        label: 'Adherence',
        color: AppColors.tierRemission,
        emoji: '💊',
      ),
      const SizedBox(width: 8),
      _KpiCard(
        value: '${summary.logStreakDays}d',
        label: 'Log Streak',
        color: AppColors.info,
        emoji: '🔥',
      ),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final Color  color;
  final String emoji;
  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:       Border.all(color: AppColors.border),
        boxShadow:    AppShadows.subtle(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.scoreMedium(color)
                  .copyWith(fontSize: 22, letterSpacing: -0.5)),
          Text(label,
              style: AppTextStyles.caption().copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RAPID3 CHART SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ChartSection extends StatelessWidget {
  final ReportController ctrl;
  const _ChartSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title:    'RAPID3 Trend',
            subtitle: ctrl.dateRangeLabel,
          ),
          const SizedBox(height: 14),
          ReportChart(points: ctrl.chartPoints),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR-BASED DAILY LOG
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarLogSection extends StatelessWidget {
  final ReportController ctrl;
  const _CalendarLogSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final allRows    = ctrl.allDailyRows;
    final monthRows  = ctrl.calendarMonthRows;
    final totalAll   = allRows.length;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppSpacing.sm),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Log', style: AppTextStyles.sectionTitle()),
                    const SizedBox(height: 2),
                    Text('$totalAll total entries  ·  tap a date for details',
                        style: AppTextStyles.caption()),
                  ],
                ),
              ),
              if (ctrl.availableMonths.isNotEmpty)
                GestureDetector(
                  onTap: () => _showMonthPicker(context, ctrl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:        AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border:       Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Jump to month',
                          style: AppTextStyles.labelCaps()
                              .copyWith(color: AppColors.primary)),
                    ]),
                  ),
                ),
            ]),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: 10),
            child: Row(children: [
              _CalNavBtn(
                icon:    Icons.chevron_left,
                enabled: ctrl.calCanGoPrev,
                onTap:   ctrl.calGoToPrev,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthPicker(context, ctrl),
                  child: Center(
                    child: Text(
                      _monthName(ctrl.calMonth, ctrl.calYear),
                      style: AppTextStyles.cardTitle(),
                    ),
                  ),
                ),
              ),
              _CalNavBtn(
                icon:    Icons.chevron_right,
                enabled: ctrl.calCanGoNext,
                onTap:   ctrl.calGoToNext,
              ),
            ]),
          ),
          if (monthRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
              child: _MonthSummaryStrip(rows: monthRows),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: _CalendarGrid(
              year:  ctrl.calYear,
              month: ctrl.calMonth,
              rows:  monthRows,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
            child: Wrap(
              spacing: 12, runSpacing: 4,
              children: const [
                _CalLegItem(color: AppColors.tierRemission, label: 'Remission'),
                _CalLegItem(color: AppColors.tierLow,       label: 'Low'),
                _CalLegItem(color: AppColors.tierModerate,  label: 'Moderate'),
                _CalLegItem(color: AppColors.tierHigh,      label: 'Flare'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m, int y) {
    const names = ['', 'January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${names[m]} $y';
  }

  static void _showMonthPicker(BuildContext context, ReportController ctrl) {
    final months = ctrl.availableMonths;
    if (months.isEmpty) return;
    showModalBottomSheet(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MonthPickerSheet(
        months:        months,
        selectedYear:  ctrl.calYear,
        selectedMonth: ctrl.calMonth,
        onPick: (y, m) {
          ctrl.calJumpToMonth(y, m);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MonthSummaryStrip extends StatelessWidget {
  final List<DailyLogRow> rows;
  const _MonthSummaryStrip({required this.rows});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'REMISSION': 0, 'LOW': 0, 'MODERATE': 0, 'HIGH': 0,
    };
    for (final r in rows) {
      counts[r.tier] = (counts[r.tier] ?? 0) + 1;
    }
    return Row(children: [
      _SChip(count: counts['REMISSION']!, label: 'Remission', color: AppColors.tierRemission),
      const SizedBox(width: 6),
      _SChip(count: counts['LOW']!,       label: 'Low',       color: AppColors.tierLow),
      const SizedBox(width: 6),
      _SChip(count: counts['MODERATE']!,  label: 'Moderate',  color: AppColors.tierModerate),
      const SizedBox(width: 6),
      _SChip(count: counts['HIGH']!,      label: 'Flare',     color: AppColors.tierHigh),
      const Spacer(),
      Text('${rows.length} days logged', style: AppTextStyles.caption()),
    ]);
  }
}

class _SChip extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;
  const _SChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text('$count $label',
        style: AppTextStyles.caption().copyWith(color: color, fontSize: 10)),
  );
}

class _CalendarGrid extends StatelessWidget {
  final int  year;
  final int  month;
  final List<DailyLogRow> rows;
  const _CalendarGrid({required this.year, required this.month, required this.rows});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Map<int, DailyLogRow> get _dayMap {
    final m = <int, DailyLogRow>{};
    for (final r in rows) { m[r.date.day] = r; }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final dayMap      = _dayMap;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWd     = DateTime(year, month, 1).weekday;
    final lead        = firstWd - 1;
    final totalCells  = lead + daysInMonth;
    final numRows     = (totalCells / 7).ceil();
    final now         = DateTime.now();

    return Column(
      children: [
        Row(
          children: _dayNames.map((d) => Expanded(
            child: Center(
              child: Text(d, style: AppTextStyles.caption()
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(numRows, (row) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final day = idx - lead + 1;
              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final r       = dayMap[day];
              final color   = r != null ? AppTierHelper.color(r.tier) : null;
              final isToday = year == now.year && month == now.month && day == now.day;
              final isFuture = DateTime(year, month, day)
                  .isAfter(DateTime(now.year, now.month, now.day));

              return Expanded(
                child: GestureDetector(
                  onTap: r != null ? () => DayDetailSheet.show(context, r) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary.withOpacity(0.12)
                          : color != null
                              ? color.withOpacity(0.14)
                              : isFuture
                                  ? Colors.transparent
                                  : AppColors.bgSection.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : color != null
                              ? Border.all(color: color.withOpacity(0.4))
                              : isFuture
                                  ? null
                                  : Border.all(color: AppColors.border.withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day', style: TextStyle(
                          fontSize: 13,
                          fontWeight: r != null || isToday ? FontWeight.w700 : FontWeight.w400,
                          color: isToday
                              ? AppColors.primary
                              : color ?? (isFuture
                                  ? AppColors.textMuted.withOpacity(0.25)
                                  : AppColors.textMuted.withOpacity(0.5)),
                        )),
                        if (r != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 5, height: 5,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                              const SizedBox(width: 2),
                              Text(r.rapid3Score.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 8, color: color,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        )),
      ],
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final List<DateTime> months;
  final int selectedYear;
  final int selectedMonth;
  final void Function(int year, int month) onPick;
  const _MonthPickerSheet({
    required this.months,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onPick,
  });

  static const _mo = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final byYear = <int, List<DateTime>>{};
    for (final m in months) { byYear.putIfAbsent(m.year, () => []).add(m); }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(children: [
              Text('Jump to Month', style: AppTextStyles.sectionTitle()),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
              ),
            ]),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: years.map((y) {
                final yMonths = byYear[y]!..sort((a, b) => b.month.compareTo(a.month));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('$y', style: AppTextStyles.labelCaps()
                          .copyWith(color: AppColors.textMuted)),
                    ),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: yMonths.map((m) {
                        final selected = m.year == selectedYear && m.month == selectedMonth;
                        return GestureDetector(
                          onTap: () => onPick(m.year, m.month),
                          child: Container(
                            width: 68,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.bgSection,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(_mo[m.month], style: AppTextStyles.label().copyWith(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalNavBtn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;
  const _CalNavBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color:        enabled ? AppColors.bgSection : AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border:       Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 20,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted),
    ),
  );
}

class _CalLegItem extends StatelessWidget {
  final Color  color;
  final String label;
  const _CalLegItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 3),
      Text(label, style: AppTextStyles.caption().copyWith(fontSize: 9)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CORRELATION SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CorrelationSection extends StatelessWidget {
  final ReportController ctrl;
  const _CorrelationSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title:    'Correlations & Insights',
          subtitle: 'Tap a card to expand its analysis',
        ),
        const SizedBox(height: AppSpacing.md),
        CorrelationSection(controller: ctrl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOCTOR REPORT SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ReportSection extends StatelessWidget {
  final ReportController ctrl;
  const _ReportSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title:    'Doctor Report',
          subtitle: 'A summary report to share with your rheumatologist',
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: ctrl.pdfData == null
              ? null
              : () => DoctorReportSheet.show(context, ctrl.pdfData!),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.primary.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              boxShadow: AppShadows.subtle(),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color:        AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(child: Text('📄', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('View Clinical Report',
                        style: AppTextStyles.cardTitle()
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 3),
                    Text(
                      'Covers RAPID3 trend, joint distribution, '
                      'medication adherence, and next-visit action plan.',
                      style: AppTextStyles.bodySmall(),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Icon(
                ctrl.pdfData == null
                    ? Icons.hourglass_top_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();
  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fade = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: 16),
          _Bone(height: 20, width: 160),
          const SizedBox(height: 14),
          Row(children: [
            for (int i = 0; i < 4; i++) ...[
              Expanded(child: _Bone(height: 72)),
              if (i < 3) const SizedBox(width: 8),
            ]
          ]),
          const SizedBox(height: 14),
          _Bone(height: 130),
          const SizedBox(height: 14),
          _Bone(height: 160),
          const SizedBox(height: 14),
          _Bone(height: 52),
          const SizedBox(height: 8),
          _Bone(height: 52),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double  height;
  final double? width;
  const _Bone({required this.height, this.width});

  @override
  Widget build(BuildContext context) => Container(
    width:  width,
    height: height,
    decoration: BoxDecoration(
      color:        AppColors.border,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Could not load report', style: AppTextStyles.sectionTitle()),
            const SizedBox(height: 6),
            Text(message, style: AppTextStyles.caption(), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            AppButton(
              label: 'Try again',
              icon:  Icons.refresh,
              onTap: onRetry,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}