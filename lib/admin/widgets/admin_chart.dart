// lib/admin/widgets/admin_charts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_dashboard_controller.dart';

// ── RAPID3 7-day trend ────────────────────────────────────────────────────────
class Rapid3TrendChart extends StatelessWidget {
  final List<Rapid3DayPoint> points;
  const Rapid3TrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return _empty('No trend data');

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      if (points[i].count > 0) {
        spots.add(FlSpot(i.toDouble(), points[i].avgScore));
      }
    }

    return LineChart(LineChartData(
      minY: 0, maxY: 10,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AdminTheme.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 32, interval: 2,
          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
              style: AdminTheme.tsSmall),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= points.length) return const SizedBox();
            final d = points[i].date;
            return Padding(padding: const EdgeInsets.only(top: 6),
                child: Text('${d.day}/${d.month}',
                    style: AdminTheme.tsSmall));
          },
        )),
        topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(y1: 0, y2: 1,
              color: AdminTheme.green.withOpacity(0.07)),
          HorizontalRangeAnnotation(y1: 1, y2: 2,
              color: AdminTheme.amber.withOpacity(0.07)),
          HorizontalRangeAnnotation(y1: 2, y2: 4,
              color: AdminTheme.orange.withOpacity(0.07)),
          HorizontalRangeAnnotation(y1: 4, y2: 10,
              color: AdminTheme.red.withOpacity(0.07)),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, curveSmoothness: 0.35,
          color: AdminTheme.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: AdminTheme.primary,
                  strokeWidth: 2, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true,
              gradient: LinearGradient(colors: [
                AdminTheme.primary.withOpacity(0.15),
                AdminTheme.primary.withOpacity(0.0),
              ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AdminTheme.navBg,
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) => spots.map((s) {
            final i   = s.x.toInt();
            final cnt = i < points.length ? points[i].count : 0;
            return LineTooltipItem(
              'Avg: ${s.y.toStringAsFixed(1)}\n$cnt logs',
              const TextStyle(color: Colors.white, fontSize: 11,
                  fontFamily: AdminTheme.fontFamily),
            );
          }).toList(),
        ),
      ),
    ));
  }
}

// ── Tier pie ──────────────────────────────────────────────────────────────────
class TierPieChart extends StatefulWidget {
  final TierDistribution dist;
  const TierPieChart({super.key, required this.dist});
  @override State<TierPieChart> createState() => _TierPieState();
}

class _TierPieState extends State<TierPieChart> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    final d = widget.dist;
    if (d.total == 0) return _empty('No tier data');

    final slices = <_Slice>[
      _Slice('Remission', d.remission, AdminTheme.green),
      _Slice('Low',       d.low,       AdminTheme.amber),
      _Slice('Moderate',  d.moderate,  AdminTheme.orange),
      _Slice('High',      d.high,      AdminTheme.red),
    ].where((s) => s.value > 0).toList();

    return Row(children: [
      Expanded(flex: 3, child: PieChart(PieChartData(
        pieTouchData: PieTouchData(touchCallback: (e, r) {
          setState(() {
            _touched = (!e.isInterestedForInteractions || r?.touchedSection==null)
                ? -1 : r!.touchedSection!.touchedSectionIndex;
          });
        }),
        sectionsSpace: 3,
        centerSpaceRadius: 36,
        sections: slices.asMap().entries.map((e) {
          final isTouched = e.key == _touched;
          final pct = e.value.value / d.total * 100;
          return PieChartSectionData(
            value: e.value.value.toDouble(),
            color: e.value.color,
            radius: isTouched ? 72 : 60,
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: TextStyle(
              color: Colors.white, fontSize: isTouched ? 14 : 11,
              fontWeight: FontWeight.bold,
              fontFamily: AdminTheme.fontFamily),
          );
        }).toList(),
      ))),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: slices.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(
                    color: s.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text('${s.label}', style: AdminTheme.tsBody)),
            Text('${s.value}',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textPrimary,
                    fontFamily: AdminTheme.fontFamily)),
          ]),
        )).toList(),
      )),
    ]);
  }
}

class _Slice {
  final String label; final int value; final Color color;
  const _Slice(this.label, this.value, this.color);
}

// ── User activity bar chart ───────────────────────────────────────────────────
class UserActivityBarChart extends StatelessWidget {
  final int active, inactive, terminated;
  const UserActivityBarChart({super.key,
      required this.active, required this.inactive,
      required this.terminated});

  @override
  Widget build(BuildContext context) {
    final maxY = [active, inactive, terminated]
        .fold(0, (a, b) => a > b ? a : b).toDouble();
    if (maxY == 0) return _empty('No activity data');

    return BarChart(BarChartData(
      maxY: (maxY * 1.35).ceilToDouble(),
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AdminTheme.border, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (v, _) {
            const l = ['Active', 'Inactive', 'Terminated'];
            final i = v.toInt();
            return i >= 0 && i < l.length
                ? Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(l[i], style: AdminTheme.tsSmall))
                : const SizedBox();
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 30,
          getTitlesWidget: (v, _) =>
              Text(v.toInt().toString(), style: AdminTheme.tsSmall),
        )),
        topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: [
        _grp(0, active.toDouble(),     AdminTheme.green),
        _grp(1, inactive.toDouble(),   AdminTheme.amber),
        _grp(2, terminated.toDouble(), AdminTheme.red),
      ],
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AdminTheme.navBg,
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) {
            const l = ['Active','Inactive','Terminated'];
            return BarTooltipItem(
              '${l[g.x]}: ${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontSize: 11,
                  fontFamily: AdminTheme.fontFamily));
          },
        ),
      ),
    ));
  }

  BarChartGroupData _grp(int x, double y, Color c) =>
      BarChartGroupData(x: x, barRods: [BarChartRodData(
        toY: y, width: 40, color: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: 0, color: Colors.transparent),
      )]);
}

// ── Correlation scatter ───────────────────────────────────────────────────────
class CorrelationChart extends StatelessWidget {
  final List<CorrelationPoint> points;
  const CorrelationChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return _empty('No correlation data available');

    return ScatterChart(ScatterChartData(
      minX: 0, maxX: 10, minY: 0, maxY: 100,
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AdminTheme.border, strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            FlLine(color: AdminTheme.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: AdminTheme.border)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          axisNameWidget: const Text('Lifestyle Adherence %',
              style: AdminTheme.tsSmall),
          axisNameSize: 18,
          sideTitles: SideTitles(showTitles: true, reservedSize: 36,
              getTitlesWidget: (v, _) =>
                  Text('${v.toInt()}', style: AdminTheme.tsSmall)),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Text('RAPID3 Score',
              style: AdminTheme.tsSmall),
          axisNameSize: 18,
          sideTitles: SideTitles(showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) =>
                  Text(v.toStringAsFixed(0), style: AdminTheme.tsSmall)),
        ),
        topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      scatterSpots: points.map((p) => ScatterSpot(
        p.rapid3Score, p.lifestyleScore,
        dotPainter: FlDotCirclePainter(
          radius: 6,
          color: AdminTheme.tierColor(p.tier).withOpacity(0.75),
          strokeColor: Colors.white, strokeWidth: 1.5,
        ),
      )).toList(),
      scatterTouchData: ScatterTouchData(
        touchTooltipData: ScatterTouchTooltipData(
          getTooltipColor: (_) => AdminTheme.navBg,
          getTooltipItems: (s) => ScatterTooltipItem(
            'RAPID3: ${s.x.toStringAsFixed(1)}\n'
            'Adherence: ${s.y.toStringAsFixed(0)}%',
            textStyle: const TextStyle(color: Colors.white,
                fontSize: 11, fontFamily: AdminTheme.fontFamily),
          ),
        ),
      ),
    ));
  }
}

// ── EULAR pie ─────────────────────────────────────────────────────────────────
class EularPieChart extends StatefulWidget {
  final EularSummary data;
  const EularPieChart({super.key, required this.data});
  @override State<EularPieChart> createState() => _EularPieState();
}

class _EularPieState extends State<EularPieChart> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    if (d.total == 0) return _empty('No EULAR data');

    final slices = [
      _Slice('Good',     d.good,     AdminTheme.green),
      _Slice('Moderate', d.moderate, AdminTheme.amber),
      _Slice('None',     d.none,     AdminTheme.red),
    ].where((s) => s.value > 0).toList();

    return Row(children: [
      Expanded(flex: 3, child: PieChart(PieChartData(
        pieTouchData: PieTouchData(touchCallback: (e, r) {
          setState(() {
            _touched = (!e.isInterestedForInteractions || r?.touchedSection==null)
                ? -1 : r!.touchedSection!.touchedSectionIndex;
          });
        }),
        sectionsSpace: 3, centerSpaceRadius: 40,
        sections: slices.asMap().entries.map((e) {
          final isTouched = e.key == _touched;
          return PieChartSectionData(
            value: e.value.value.toDouble(), color: e.value.color,
            radius: isTouched ? 72 : 60,
            title: '${(e.value.value / d.total * 100).toStringAsFixed(0)}%',
            titleStyle: TextStyle(color: Colors.white,
                fontSize: isTouched ? 14 : 11, fontWeight: FontWeight.bold,
                fontFamily: AdminTheme.fontFamily),
          );
        }).toList(),
      ))),
      const SizedBox(width: 16),
      Expanded(flex: 2, child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EularLegendRow('Good Response',     d.good,     AdminTheme.green),
          _EularLegendRow('Moderate Response', d.moderate, AdminTheme.amber),
          _EularLegendRow('No Response',       d.none,     AdminTheme.red),
          const SizedBox(height: 8),
          Text('Total: ${d.total} patients', style: AdminTheme.tsSmall),
        ],
      )),
    ]);
  }
}

class _EularLegendRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _EularLegendRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: AdminTheme.tsBody)),
      Text('$value', style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: AdminTheme.textPrimary,
          fontFamily: AdminTheme.fontFamily)),
    ]),
  );
}

Widget _empty(String msg) => Center(
    child: Text(msg,
        style: AdminTheme.tsBody,
        textAlign: TextAlign.center));