// lib/views/health/lifestyle/exercise_session_view.dart
// Exercise session: painBefore → active timer (pause/resume/stop) → painAfter → done
// PAUSE: saves elapsed time to DB immediately.
// User can close and resume; if not resumed by next day, time is final.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import '../../../models/health_model.dart';

class ExerciseSessionView extends StatefulWidget {
  final ExerciseRecommendation exercise;
  /// If true: skip painBefore phase, restore elapsed from DB-saved pause
  final bool resumeFromPause;
  const ExerciseSessionView({Key? key, required this.exercise, this.resumeFromPause = false}) : super(key: key);
  @override
  State<ExerciseSessionView> createState() => _ExerciseSessionViewState();
}

class _ExerciseSessionViewState extends State<ExerciseSessionView> {
  // 0=painBefore  1=active  2=painAfter  3=done
  late int _phase;

  @override
  void initState() {
    super.initState();
    if (widget.resumeFromPause) {
      // Skip painBefore — already have it — go straight to active timer
      _phase = 1;
      // Start timer immediately, restoring saved elapsed time
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctrl = context.read<HealthController>();
        ctrl.startExerciseSession(widget.exercise, resumeFromPause: true);
      });
    } else {
      _phase = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textSecondary,
          onPressed: () async {
            if (_phase == 1) {
              if (ctrl.sessionActive) {
                // Running → pause first, then show exit dialog
                await ctrl.pauseExerciseSession();
              }
              // Always show dialog in phase 1 so user knows time is saved
              if (mounted) _showExitDialog(context, ctrl);
            } else {
              if (mounted) Navigator.of(context).pop();
            }
          },
        ),
        title: Text(widget.exercise.name, style: AppTextStyles.sectionTitle()),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.base),
            child: _PhaseIndicator(current: _phase),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: _buildPhase(ctrl),
      ),
    );
  }

  void _showExitDialog(BuildContext context, HealthController ctrl) {
    final saved = ctrl.pausedAtSec;
    final mins  = saved ~/ 60;
    final secs  = saved % 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Exercise Paused'),
        content: Text(
          'Your progress (${mins}m ${secs}s) has been saved.\n\n'
          'You can resume this exercise anytime today from the activity list.',
        ),
        actions: [
          // ── Stay and resume now ──
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              ctrl.resumeExerciseSession();
            },
            child: const Text('Resume Now'),
          ),
          // ── Exit — time is saved ──
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.of(context).pop(); // close session screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Exit & Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(HealthController ctrl) {
    switch (_phase) {
      case 0: return _PainBeforePhase(
        key: const ValueKey(0),
        exercise: widget.exercise,
        value: ctrl.painBeforeExercise,
        onChanged: ctrl.setPainBefore,
        onStart: () { ctrl.startExerciseSession(widget.exercise); setState(() => _phase = 1); },
      );
      case 1: return _ActivePhase(
        key: const ValueKey(1),
        ctrl: ctrl,
        exercise: widget.exercise,
        onPause: () async { await ctrl.pauseExerciseSession(); },
        onResume: () { ctrl.resumeExerciseSession(); },
        onStop: () { ctrl.stopExerciseSession(); setState(() => _phase = 2); },
      );
      case 2: return _PainAfterPhase(
        key: const ValueKey(2),
        exercise: widget.exercise,
        elapsed: ctrl.sessionElapsedSec,
        painBefore: ctrl.painBeforeExercise,
        value: ctrl.painAfterExercise,
        onChanged: ctrl.setPainAfter,
        onSave: () async {
          await ctrl.saveExerciseLog();
          if (!mounted) return;
          if (ctrl.errorMsg != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Save failed: ${ctrl.errorMsg}',
                    style: const TextStyle(color: Colors.white, fontSize: 12))),
              ]),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ));
          } else {
            setState(() => _phase = 3);
          }
        },
      );
      default: return _DonePhase(
        key: const ValueKey(3),
        exercise: widget.exercise,
        elapsed: ctrl.sessionElapsedSec,
        onClose: () {
          // Ensure marked complete before leaving
          if (!ctrl.isExerciseCompleted(widget.exercise.id)) {
            ctrl.markExerciseCompleted(widget.exercise.id);
          }
          Navigator.of(context).pop();
        },
      );
    }
  }
}

// ─────────────────────────────────────────────
// PHASE 0 — PAIN BEFORE
// ─────────────────────────────────────────────
class _PainBeforePhase extends StatelessWidget {
  final ExerciseRecommendation exercise;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onStart;
  const _PainBeforePhase({Key? key, required this.exercise, required this.value, required this.onChanged, required this.onStart}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ExerciseSummaryCard(exercise: exercise),
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(title: 'Pain Level Before Exercise', subtitle: 'Rate 0 = no pain, 10 = severe'),
      const SizedBox(height: AppSpacing.base),
      _PainRatingCard(value: value, onChanged: onChanged),
      const SizedBox(height: AppSpacing.xl),
      AppButton(label: 'Start Exercise  ▶', icon: Icons.play_circle_outline_rounded, onTap: onStart),
      const SizedBox(height: AppSpacing.xxl),
    ]),
  );
}

// ─────────────────────────────────────────────
// PHASE 1 — ACTIVE TIMER WITH PAUSE/RESUME
// ─────────────────────────────────────────────
class _ActivePhase extends StatelessWidget {
  final HealthController ctrl;
  final ExerciseRecommendation exercise;
  final AsyncCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  const _ActivePhase({Key? key, required this.ctrl, required this.exercise, required this.onPause, required this.onResume, required this.onStop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final elapsed  = ctrl.sessionElapsedSec;
    final paused   = ctrl.sessionPaused;
    final target   = exercise.maxMinutes * 60;
    final progress = (elapsed / target).clamp(0.0, 1.0);
    final color    = _timerColor(progress);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(children: [
        const SizedBox(height: AppSpacing.base),
        // ── Circular timer ──
        SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(size: const Size(220, 220), painter: _ArcPainter(progress, color)),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(ctrl.formattedSessionTime,
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: color, letterSpacing: -1)),
              Text(exercise.duration.isNotEmpty ? 'Target: ${exercise.duration}' : 'Keep going!',
                  style: AppTextStyles.caption()),
              if (paused) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.tierLow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text('PAUSED — saved', style: AppTextStyles.labelCaps().copyWith(color: AppColors.tierLow)),
                ),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Control buttons ──
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // PAUSE / RESUME
          _CircleBtn(
            icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: paused ? 'Resume' : 'Pause',
            color: AppColors.tierLow,
            onTap: paused ? onResume : () => onPause(),
          ),
          const SizedBox(width: AppSpacing.xl),
          // STOP (finish)
          _CircleBtn(
            icon: Icons.stop_rounded,
            label: 'Finish',
            color: AppColors.tierHigh,
            onTap: () => _confirmStop(context),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        // Info / exit-while-paused card
        if (paused) ...[
          // When paused: show exit option explicitly
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.tierLow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.tierLow.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.save_rounded, color: AppColors.tierLow, size: 16),
                const SizedBox(width: 6),
                Text('Progress saved', style: AppTextStyles.label().copyWith(color: AppColors.tierLow)),
              ]),
              const SizedBox(height: 6),
              Text('Your time is saved. You can resume from the activity list.', style: AppTextStyles.caption()),
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                  label: const Text('Exit & Resume Later'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tierLow,
                    side: const BorderSide(color: AppColors.tierLow),
                  ),
                  onPressed: () {
                    // Pop dialog + screen — time already saved in DB
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(
                'Tap Pause to save progress and exit. Resume anytime today.',
                style: AppTextStyles.caption(),
              )),
            ]),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ]),
    );
  }

  void _confirmStop(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Finish Exercise?'),
      content: Text('You\'ve done ${ctrl.formattedSessionTime}. Finish and log your pain level after?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Going')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); onStop(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Yes, Finish'),
        ),
      ],
    ));
  }

  Color _timerColor(double p) {
    if (p >= 1.0) return AppColors.tierRemission;
    if (p >= 0.6) return AppColors.tierLow;
    return AppColors.primary;
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12), border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 28),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppTextStyles.caption().copyWith(color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ─────────────────────────────────────────────
// PHASE 2 — PAIN AFTER
// ─────────────────────────────────────────────
class _PainAfterPhase extends StatelessWidget {
  final ExerciseRecommendation exercise;
  final int elapsed;
  final double painBefore, value;
  final ValueChanged<double> onChanged;
  final AsyncCallback onSave;
  const _PainAfterPhase({Key? key, required this.exercise, required this.elapsed, required this.painBefore, required this.value, required this.onChanged, required this.onSave}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final mins = elapsed ~/ 60;
    final secs = elapsed % 60;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary card
        AppCard(padding: const EdgeInsets.all(AppSpacing.base), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _SummaryTile('Duration', '${mins}m ${secs}s', AppColors.primary),
            _SummaryTile('Before', painBefore.toStringAsFixed(1), _painColor(painBefore)),
            _SummaryTile('Exercise', exercise.name.split(' ').first, AppColors.textSecondary),
          ]),
        ])),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: 'Pain Level After Exercise', subtitle: 'How do you feel now?'),
        const SizedBox(height: AppSpacing.base),
        _PainRatingCard(value: value, onChanged: onChanged),
        const SizedBox(height: AppSpacing.xl),
        // Comparison
        _PainComparisonCard(before: painBefore, after: value),
        const SizedBox(height: AppSpacing.xl),
        if (ctrl.errorMsg != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.tierHigh.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.tierHigh.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.tierHigh, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(ctrl.errorMsg!, style: AppTextStyles.caption().copyWith(color: AppColors.tierHigh))),
            ]),
          ),
        ctrl.saving
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : AppButton(label: 'Save & Complete ✓', icon: Icons.save_rounded, onTap: onSave),
        const SizedBox(height: AppSpacing.xxl),
      ]),
    );
  }

  Color _painColor(double v) {
    if (v <= 2) return AppColors.tierRemission;
    if (v <= 4) return AppColors.tierLow;
    if (v <= 7) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value; final Color color;
  const _SummaryTile(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: AppTextStyles.caption()),
  ]);
}

class _PainComparisonCard extends StatelessWidget {
  final double before, after;
  const _PainComparisonCard({required this.before, required this.after});
  @override
  Widget build(BuildContext context) {
    final delta = after - before;
    final improved = delta < 0;
    final same = delta == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: improved ? AppColors.tierRemission.withValues(alpha: 0.08) : same ? AppColors.primarySurface : AppColors.tierHighBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(children: [
        Text(improved ? '📈' : same ? '➡️' : '⚠️', style: const TextStyle(fontSize: 24)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(
          improved
              ? 'Pain improved by ${delta.abs().toStringAsFixed(1)} points. Great work!'
              : same
                  ? 'Pain unchanged. Rest and monitor.'
                  : 'Pain increased by ${delta.toStringAsFixed(1)} points. Rest if needed.',
          style: AppTextStyles.bodySmall(),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// PHASE 3 — DONE
// ─────────────────────────────────────────────
class _DonePhase extends StatelessWidget {
  final ExerciseRecommendation exercise;
  final int elapsed;
  final VoidCallback onClose;
  const _DonePhase({Key? key, required this.exercise, required this.elapsed, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mins = elapsed ~/ 60;
    return Center(child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.tierRemission.withValues(alpha: 0.12), border: Border.all(color: AppColors.tierRemission, width: 3)),
          child: const Icon(Icons.check_rounded, size: 50, color: AppColors.tierRemission),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Exercise Complete!', style: AppTextStyles.sectionTitle().copyWith(color: AppColors.tierRemission)),
        const SizedBox(height: AppSpacing.sm),
        Text('${exercise.name} — ${mins}m logged and saved', style: AppTextStyles.bodySmall(), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(label: 'Back to Activities', icon: Icons.arrow_back_rounded, onTap: onClose),
      ]),
    ));
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _ExerciseSummaryCard extends StatelessWidget {
  final ExerciseRecommendation exercise;
  const _ExerciseSummaryCard({required this.exercise});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
          child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name, style: AppTextStyles.cardTitle()),
          Text('${exercise.type}  •  ${exercise.duration}  •  ${exercise.intensity}',
              style: AppTextStyles.caption()),
        ])),
      ]),
      if (exercise.benefits.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: 6, runSpacing: 4, children: exercise.benefits
          .map((b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(b, style: AppTextStyles.caption().copyWith(color: AppColors.primary)),
          )).toList()),
      ],
    ]),
  );
}

class _PainRatingCard extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _PainRatingCard({required this.value, required this.onChanged});

  Color _color(double v) {
    if (v <= 2) return AppColors.tierRemission;
    if (v <= 4) return AppColors.tierLow;
    if (v <= 7) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(children: [
      Center(child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 90, height: 90,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _color(value).withValues(alpha: 0.1), border: Border.all(color: _color(value), width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toStringAsFixed(1),
              style: AppTextStyles.heroScore(_color(value)),
            ),
          ),
        ),
      )),
      const SizedBox(height: AppSpacing.md),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('No pain', style: AppTextStyles.caption()),
        Text('Severe pain', style: AppTextStyles.caption()),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: _color(value), thumbColor: _color(value), overlayColor: _color(value).withValues(alpha: 0.15)),
        child: Slider(value: value, min: 0, max: 10, divisions: 20, label: value.toStringAsFixed(1), onChanged: onChanged),
      ),
    ]),
  );
}

class _PhaseIndicator extends StatelessWidget {
  final int current;
  const _PhaseIndicator({required this.current});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(4, (i) {
    final done   = i < current;
    final active = i == current;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 24 : 8, height: 8,
      decoration: BoxDecoration(
        color: done ? AppColors.tierRemission : active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }));
}

// Circular arc progress painter
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ArcPainter(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    final bg = Paint()..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * progress, false, fg);
  }
  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress || old.color != color;
}