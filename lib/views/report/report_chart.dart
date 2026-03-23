// lib/views/report/widgets/report_chart.dart
// Interactive RAPID3 sparkline.
// — Tapping a dot shows a tooltip with date, score, tier, and interpretation.
// — Zone bands are labelled with tier names on the right.
// — X-axis shows date markers.
// — All dots visible; flare dots pulse red.

import 'package:flutter/material.dart';
import '../../../models/report_model.dart';
import 'package:arthro/widgets/app_theme.dart';

class ReportChart extends StatefulWidget {
  final List<ChartPoint> points;
  final double height;

  const ReportChart({
    super.key,
    required this.points,
    this.height = 160,
  });

  @override
  State<ReportChart> createState() => _ReportChartState();
}

class _ReportChartState extends State<ReportChart> {
  int? _selectedIndex;

  ChartPoint? get _selected =>
      _selectedIndex != null && _selectedIndex! < widget.points.length
          ? widget.points[_selectedIndex!]
          : null;

  void _onTap(TapDownDetails d, double chartWidth) {
    if (widget.points.isEmpty) return;
    final n = widget.points.length;
    double best = double.infinity;
    int    idx  = 0;
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? chartWidth / 2 : i / (n - 1) * chartWidth;
      final dist = (d.localPosition.dx - x).abs();
      if (dist < best) { best = dist; idx = i; }
    }
    setState(() {
      _selectedIndex = _selectedIndex == idx ? null : idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(child: Text('No data yet', style: AppTextStyles.caption())),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip / hint
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selected != null
              ? _TooltipCard(point: _selected!, key: ValueKey(_selectedIndex))
              : const _HintRow(key: ValueKey('hint')),
        ),
        const SizedBox(height: 10),
        // Chart
        LayoutBuilder(builder: (context, bc) {
          final chartW = bc.maxWidth;
          return GestureDetector(
            onTapDown: (d) => _onTap(d, chartW),
            child: SizedBox(
              width:  chartW,
              height: widget.height,
              child: CustomPaint(
                painter: _ChartPainter(
                  points:        widget.points,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        const _ZoneLegend(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TooltipCard extends StatelessWidget {
  final ChartPoint point;
  const _TooltipCard({required this.point, super.key});

  String get _tierLabel {
    switch (point.tier) {
      case 'REMISSION': return 'Remission';
      case 'LOW':       return 'Low Activity';
      case 'MODERATE':  return 'Moderate Activity';
      default:          return 'High Activity / Flare';
    }
  }

  String get _explanation {
    switch (point.tier) {
      case 'REMISSION':
        return 'Disease activity is minimal. Keep up your current routine.';
      case 'LOW':
        return 'Mild symptoms present. Monitor closely and maintain lifestyle plan.';
      case 'MODERATE':
        return 'Noticeable RA activity. Follow your exercise and nutrition plan closely.';
      default:
        return 'Active flare. Rest, take all medications on time, and contact your doctor if it persists.';
    }
  }

  Color get _color {
    switch (point.tier) {
      case 'REMISSION': return AppColors.tierRemission;
      case 'LOW':       return AppColors.tierLow;
      case 'MODERATE':  return AppColors.tierModerate;
      default:          return AppColors.tierHigh;
    }
  }

  String get _emoji {
    switch (point.tier) {
      case 'REMISSION': return '🟢';
      case 'LOW':       return '🟡';
      case 'MODERATE':  return '🟠';
      default:          return '🔴';
    }
  }

  String _mo(int m) => ['','Jan','Feb','Mar','Apr','May','Jun',
                         'Jul','Aug','Sep','Oct','Nov','Dec'][m];

  @override
  Widget build(BuildContext context) {
    final d = point.date;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color:        _color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:       Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(point.score.toStringAsFixed(1),
                      style: AppTextStyles.scoreMedium(_color)
                          .copyWith(fontSize: 22, letterSpacing: -0.5)),
                  const SizedBox(width: 5),
                  Text('/ 12 RAPID3',
                      style: AppTextStyles.caption()),
                  const Spacer(),
                  Text('${d.day} ${_mo(d.month)} ${d.year}',
                      style: AppTextStyles.labelCaps()),
                ]),
                const SizedBox(height: 2),
                Text(_tierLabel,
                    style: AppTextStyles.label()
                        .copyWith(color: _color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(_explanation,
                    style: AppTextStyles.bodySmall(), maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textMuted),
    const SizedBox(width: 5),
    Text('Tap any dot to see what this score means',
        style: AppTextStyles.caption()),
  ]);
}

class _ZoneLegend extends StatelessWidget {
  const _ZoneLegend();
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 4,
    children: const [
      _LegI(color: AppColors.tierRemission, label: 'Remission 0–1'),
      _LegI(color: AppColors.tierLow,       label: 'Low 1–2'),
      _LegI(color: AppColors.tierModerate,  label: 'Moderate 2–4'),
      _LegI(color: AppColors.tierHigh,      label: 'Flare >4'),
    ],
  );
}

class _LegI extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegI({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption().copyWith(fontSize: 9)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final int? selectedIndex;

  const _ChartPainter({required this.points, this.selectedIndex});

  static const double _yMin = 0;
  static const double _yMax = 12;
  // Padding so x-labels don't get clipped
  static const double _padBottom = 16;
  static const double _padTop    = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final w  = size.width;
    final h  = size.height - _padBottom;

    // ── Zone bands ───────────────────────────────────────────
    _zone(canvas, w, h, 0,   1.0,  AppColors.tierRemission.withOpacity(0.10));
    _zone(canvas, w, h, 1.0, 2.0,  AppColors.tierLow.withOpacity(0.10));
    _zone(canvas, w, h, 2.0, 4.0,  AppColors.tierModerate.withOpacity(0.10));
    _zone(canvas, w, h, 4.0, 12.0, AppColors.tierHigh.withOpacity(0.07));

    // ── Zone labels (right edge) ─────────────────────────────
    _zoneLabel(canvas, w, h, 0.5,  'REMISSION', AppColors.tierRemission);
    _zoneLabel(canvas, w, h, 1.5,  'LOW',       AppColors.tierLow);
    _zoneLabel(canvas, w, h, 3.0,  'MODERATE',  AppColors.tierModerate);
    _zoneLabel(canvas, w, h, 7.0,  'FLARE',     AppColors.tierHigh);

    // ── Flare threshold dashed line ──────────────────────────
    _hLine(canvas, w, h, 4.0,
        color: AppColors.tierHigh.withOpacity(0.4), dash: 5, gap: 4);

    // ── Y labels ─────────────────────────────────────────────
    for (final v in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0]) {
      _yLabel(canvas, h, v, v.toInt().toString());
    }

    // ── Gradient area ────────────────────────────────────────
    final area = Path();
    for (int i = 0; i < points.length; i++) {
      final x = _x(i, w); final y = _y(points[i].score, h);
      if (i == 0) area.moveTo(x, y); else area.lineTo(x, y);
    }
    area.lineTo(_x(points.length - 1, w), h);
    area.lineTo(_x(0, w), h);
    area.close();
    final grad = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [AppColors.info.withOpacity(0.18), AppColors.info.withOpacity(0)],
    );
    canvas.drawPath(area,
        Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, w, h))
                ..style  = PaintingStyle.fill);

    // ── Line ─────────────────────────────────────────────────
    final lp  = Path();
    for (int i = 0; i < points.length; i++) {
      final x = _x(i, w); final y = _y(points[i].score, h);
      if (i == 0) lp.moveTo(x, y); else lp.lineTo(x, y);
    }
    canvas.drawPath(lp,
        Paint()..color       = AppColors.info
               ..strokeWidth = 2
               ..style       = PaintingStyle.stroke
               ..strokeCap   = StrokeCap.round
               ..strokeJoin  = StrokeJoin.round);

    // ── Dots ─────────────────────────────────────────────────
    for (int i = 0; i < points.length; i++) {
      final p   = points[i];
      final x   = _x(i, w);
      final y   = _y(p.score, h);
      final sel = i == selectedIndex;

      if (p.isFlare) {
        canvas.drawCircle(Offset(x, y), sel ? 12 : 9,
            Paint()..color = AppColors.tierHigh.withOpacity(sel ? 0.35 : 0.20));
        canvas.drawCircle(Offset(x, y), sel ? 6 : 5,
            Paint()..color = AppColors.tierHigh);
      } else if (p.isToday) {
        canvas.drawCircle(Offset(x, y), sel ? 8 : 5,
            Paint()..color = AppColors.tierLow);
      } else if (sel) {
        canvas.drawCircle(Offset(x, y), 9,
            Paint()..color = AppColors.info.withOpacity(0.2));
        canvas.drawCircle(Offset(x, y), 5,
            Paint()..color = AppColors.info);
      } else {
        canvas.drawCircle(Offset(x, y), 3,
            Paint()..color = AppColors.info.withOpacity(0.5));
      }
    }

    // ── X labels ─────────────────────────────────────────────
    if (points.length >= 2) {
      final step = (points.length / 5).ceil().clamp(1, points.length);
      for (int i = 0; i < points.length; i += step) {
        final px = _x(i, w);
        final lbl = '${points[i].date.day}/${points[i].date.month}';
        final tp = TextPainter(
          text: TextSpan(text: lbl,
              style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.drawLine(Offset(px, h), Offset(px, h + 3),
            Paint()..color = AppColors.border..strokeWidth = 1);
        tp.paint(canvas,
            Offset((px - tp.width / 2).clamp(0, w - tp.width), h + 4));
      }
    }
  }

  void _zone(Canvas c, double w, double h,
      double s0, double s1, Color col) {
    c.drawRect(Rect.fromLTRB(0, _y(s1, h), w, _y(s0, h)),
        Paint()..color = col);
  }

  void _zoneLabel(Canvas c, double w, double h,
      double mid, String text, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(fontSize: 8, color: col.withOpacity(0.55),
              fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(w - tp.width - 4, _y(mid, h) - tp.height / 2));
  }

  void _hLine(Canvas c, double w, double h, double score,
      {required Color color, double dash = 0, double gap = 0}) {
    final y = _y(score, h);
    final p = Paint()..color = color..strokeWidth = 1;
    if (dash == 0) { c.drawLine(Offset(0, y), Offset(w, y), p); return; }
    double x = 0; bool on = true;
    while (x < w) {
      final e = (x + (on ? dash : gap)).clamp(0.0, w);
      if (on) c.drawLine(Offset(x, y), Offset(e, y), p);
      x += on ? dash : gap; on = !on;
    }
  }

  void _yLabel(Canvas c, double h, double score, String text) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(fontSize: 9, color: AppColors.textMuted,
              fontFamily: 'DMMono')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(2, _y(score, h) - tp.height));
  }

  double _x(int i, double w) =>
      points.length == 1 ? w / 2 : i / (points.length - 1) * w;

  double _y(double score, double h) {
    final usable = h - _padTop;
    return _padTop + (usable - (score.clamp(_yMin, _yMax) / (_yMax - _yMin)) * usable);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.selectedIndex != selectedIndex;
}