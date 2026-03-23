// lib/admin/views/admin_analytics_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/admin_theme.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_chart.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AdminTheme.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Analytics', style: AdminTheme.tsTitle),
                  SizedBox(height: 2),
                  Text('Clinical outcomes & lifestyle correlation',
                      style: AdminTheme.tsBody),
                ]),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Refresh'),
                  onPressed: ctrl.refresh,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.primary,
                    side: const BorderSide(color: AdminTheme.primary),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontFamily: AdminTheme.fontFamily),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Explanation banner ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AdminTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AdminTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AdminTheme.primary),
                    const SizedBox(width: 8),
                    const Text('How to read this page',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.primary,
                            fontFamily: AdminTheme.fontFamily)),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    '• EULAR Response measures whether a patients disease has improved over time based on their RAPID3 score change (Δ).'

                    '• Good Response = RAPID3 dropped by >1.2 points (significant improvement).'

                    '• Moderate = dropped 0.6–1.2 points. No Response = little or no change.'

                    '• The correlation chart shows whether patients who stick to their lifestyle plans tend to have lower RAPID3 scores.',
                    style: TextStyle(fontSize: 11,
                        color: AdminTheme.textSecondary,
                        height: 1.6,
                        fontFamily: AdminTheme.fontFamily)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── EULAR summary KPIs ────────────────────────────────────────
              const Text('EULAR Clinical Response',
                  style: AdminTheme.tsSectionTitle),
              const SizedBox(height: 4),
              const Text(
                  'Measures disease improvement: Δ RAPID3 (baseline → current)',
                  style: AdminTheme.tsBody),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (_, c) {
                final cols = c.maxWidth > 700 ? 3 : 1;
                return _EularKpis(eular: ctrl.eular, cols: cols);
              }),
              const SizedBox(height: 20),

              // ── Charts row ────────────────────────────────────────────────
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 860) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Expanded(child: _Card(
                      title: 'EULAR Response Distribution',
                      subtitle: 'Based on RAPID3 change from first log',
                      height: 240,
                      child: EularPieChart(data: ctrl.eular),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _Card(
                      title: 'RAPID3 vs Lifestyle Adherence',
                      subtitle:
                          'Correlation: higher adherence → lower disease score',
                      height: 240,
                      child: CorrelationChart(points: ctrl.correlation),
                    )),
                  ]);
                }
                return Column(children: [
                  _Card(
                    title: 'EULAR Response Distribution',
                    subtitle: 'Based on RAPID3 change from first log',
                    height: 240,
                    child: EularPieChart(data: ctrl.eular),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'RAPID3 vs Lifestyle Adherence',
                    subtitle:
                        'Correlation: higher adherence → lower disease score',
                    height: 240,
                    child: CorrelationChart(points: ctrl.correlation),
                  ),
                ]);
              }),
              const SizedBox(height: 24),

              // ── EULAR patient table ───────────────────────────────────────
              Row(children: [
                const Expanded(
                    child: Text('Patient Improvement Table',
                        style: AdminTheme.tsSectionTitle)),
                _LegendDot(AdminTheme.green,  'Good (Δ>1.2)'),
                const SizedBox(width: 14),
                _LegendDot(AdminTheme.amber,  'Moderate (Δ0.6-1.2)'),
                const SizedBox(width: 14),
                _LegendDot(AdminTheme.red,    'No Response'),
              ]),
              const SizedBox(height: 12),
              _EularTable(patients: ctrl.eularList),
            ],
          ),
        );
      },
    );
  }
}

// ── EULAR KPI strip ───────────────────────────────────────────────────────────
class _EularKpis extends StatelessWidget {
  final EularSummary eular;
  final int cols;
  const _EularKpis({required this.eular, required this.cols});

  @override
  Widget build(BuildContext context) {
    final items = [
      _EularKpi('Good Response', eular.good,
          '${eular.goodPct.toStringAsFixed(0)}%',
          AdminTheme.green, AdminTheme.greenBg,
          Icons.trending_down_rounded,
          'RAPID3 improved by > 1.2 points'),
      _EularKpi('Moderate Response', eular.moderate,
          '${eular.moderatePct.toStringAsFixed(0)}%',
          AdminTheme.amber, AdminTheme.amberBg,
          Icons.remove_rounded,
          'RAPID3 improved by 0.6 – 1.2 points'),
      _EularKpi('No Response', eular.none,
          '${eular.nonePct.toStringAsFixed(0)}%',
          AdminTheme.red, AdminTheme.redBg,
          Icons.trending_up_rounded,
          'RAPID3 unchanged or worsened'),
    ];

    return Row(children: [
      for (int j = 0; j < items.length; j++) ...[
        if (j > 0) const SizedBox(width: 12),
        Expanded(child: _EularKpiCard(item: items[j])),
      ],
    ]);
  }
}

class _EularKpi {
  final String label, percent, description;
  final int count;
  final Color color, bg;
  final IconData icon;
  const _EularKpi(this.label, this.count, this.percent,
      this.color, this.bg, this.icon, this.description);
}

class _EularKpiCard extends StatelessWidget {
  final _EularKpi item;
  const _EularKpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: AdminTheme.card(),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: item.bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, color: item.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.count.toString(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: item.color, fontFamily: AdminTheme.fontFamily,
                    letterSpacing: -0.5)),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(item.percent,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: item.color.withOpacity(0.7),
                      fontFamily: AdminTheme.fontFamily)),
            ),
          ]),
          Text(item.label, style: AdminTheme.tsCardTitle),
          const SizedBox(height: 2),
          Text(item.description, style: AdminTheme.tsSmall,
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ));
  }
}

// ── EULAR patient table ───────────────────────────────────────────────────────
class _EularTable extends StatelessWidget {
  final List<EularPatient> patients;
  const _EularTable({required this.patients});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AdminTheme.card(),
        child: const Center(child: Text(
            'No EULAR data available. '
            'Patients need at least 2 symptom logs.',
            style: AdminTheme.tsBody, textAlign: TextAlign.center)),
      );
    }

    return Container(
      decoration: AdminTheme.card(),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AdminTheme.bg),
          headingTextStyle: AdminTheme.tsLabel,
          dataTextStyle: const TextStyle(fontSize: 12,
              color: AdminTheme.textPrimary,
              fontFamily: AdminTheme.fontFamily),
          columns: const [
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Baseline RAPID3')),
            DataColumn(label: Text('Current RAPID3')),
            DataColumn(label: Text('Δ Change')),
            DataColumn(label: Text('Response')),
          ],
          rows: patients.take(20).map((p) {
            final c = p.response == 'good' ? AdminTheme.green
                : p.response == 'moderate' ? AdminTheme.amber
                : AdminTheme.red;
            final bg = p.response == 'good' ? AdminTheme.greenBg
                : p.response == 'moderate' ? AdminTheme.amberBg
                : AdminTheme.redBg;
            final lbl = p.response == 'good' ? 'Good'
                : p.response == 'moderate' ? 'Moderate' : 'No Response';
            return DataRow(cells: [
              DataCell(Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(p.startScore.toStringAsFixed(1))),
              DataCell(Text(p.currentScore.toStringAsFixed(1))),
              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(p.delta > 0
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                    size: 13,
                    color: p.delta > 0 ? AdminTheme.green : AdminTheme.red),
                const SizedBox(width: 4),
                Text(p.delta.abs().toStringAsFixed(1),
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: p.delta > 0 ? AdminTheme.green : AdminTheme.red)),
              ])),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(lbl, style: TextStyle(
                    color: c, fontSize: 11, fontWeight: FontWeight.w600,
                    fontFamily: AdminTheme.fontFamily)),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title, subtitle;
  final double height;
  final Widget child;
  const _Card({required this.title, required this.subtitle,
      required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AdminTheme.tsSectionTitle),
        const SizedBox(height: 2),
        Text(subtitle, style: AdminTheme.tsSmall),
        const SizedBox(height: 20),
        SizedBox(height: height, child: child),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: AdminTheme.tsSmall),
    ],
  );
}