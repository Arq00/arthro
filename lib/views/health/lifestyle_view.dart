// lib/views/health/lifestyle/lifestyle_view.dart
// Lifestyle Plan — Exercise multi-select (min 2) + Nutrition log
// Exercise: user selects ≥2 activities, starts each with a timer.
// Nutrition: user can log and update until end of day.

import 'package:arthro/models/health_model.dart';
import 'package:arthro/views/health/nutrition_view.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';
import 'exercise_session_view.dart';


class LifestyleView extends StatefulWidget {
  const LifestyleView({Key? key}) : super(key: key);
  @override
  State<LifestyleView> createState() => _LifestyleViewState();
}

class _LifestyleViewState extends State<LifestyleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: _buildAppBar(ctrl),
      body: ctrl.lifestyleLoading
          ? const _LoadingState()
          : Column(children: [
              _TierStrip(tier: ctrl.rapid3Tier, score: ctrl.rapid3Score),
              _TabBar(ctrl: ctrl, tabCtrl: _tabCtrl),
              Expanded(child: TabBarView(controller: _tabCtrl, children: [
                _ExerciseTab(ctrl: ctrl),
                _NutritionTab(nutrition: ctrl.nutrition),
              ])),
            ]),
    );
  }

  AppBar _buildAppBar(HealthController ctrl) => AppBar(
    backgroundColor: AppColors.bgCard, elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      color: AppColors.primary,
      onPressed: () => ctrl.goToStep(HealthStep.result),
    ),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LIFESTYLE PLAN', style: AppTextStyles.labelCaps()),
      Text('Today\'s Activities', style: AppTextStyles.sectionTitle()),
    ]),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: AppSpacing.base),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(_todayDate(), style: AppTextStyles.labelCaps().copyWith(color: AppColors.primary)),
      ),
    ],
  );

  String _todayDate() { final n = DateTime.now(); return '${n.day}/${n.month}/${n.year}'; }
}

// ─────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final HealthController ctrl;
  final TabController tabCtrl;
  const _TabBar({required this.ctrl, required this.tabCtrl});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgCard,
    child: TabBar(
      controller: tabCtrl,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      labelStyle: AppTextStyles.label(),
      tabs: [
        Tab(
          icon: ctrl.completedExerciseCount > 0
              ? Badge(label: Text('${ctrl.completedExerciseCount}'), child: const Icon(Icons.fitness_center_rounded, size: 18))
              : const Icon(Icons.fitness_center_rounded, size: 18),
          text: 'Exercise',
        ),
        Tab(
          icon: Icon(ctrl.nutritionDone ? Icons.check_circle_rounded : Icons.restaurant_rounded,
              size: 18, color: ctrl.nutritionDone ? AppColors.tierRemission : null),
          text: ctrl.nutritionDone ? 'Nutrition ✓' : 'Nutrition',
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
class _TierStrip extends StatelessWidget {
  final String tier; final double score;
  const _TierStrip({required this.tier, required this.score});
  @override
  Widget build(BuildContext context) {
    final color = AppTierHelper.color(tier);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      color: AppTierHelper.bgColor(tier),
      child: Row(children: [
        Text(AppTierHelper.emoji(tier), style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Plan for ${AppTierHelper.label(tier)}', style: AppTextStyles.label().copyWith(color: color)),
          Text('RAPID3 score: ${score.toStringAsFixed(1)}', style: AppTextStyles.labelCaps()),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// EXERCISE TAB
// ─────────────────────────────────────────────
class _ExerciseTab extends StatelessWidget {
  final HealthController ctrl;
  const _ExerciseTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.exercises.isEmpty) return const _EmptyState(icon: Icons.fitness_center_rounded, message: 'No exercise recommendations available');
    return ListView(padding: const EdgeInsets.all(AppSpacing.base), children: [
      _SelectionBanner(ctrl: ctrl),
      const SizedBox(height: AppSpacing.base),
      ...ctrl.exercises.map((ex) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _ExerciseCard(exercise: ex, ctrl: ctrl),
      )),
      if (ctrl.allSelectedExercisesDone) ...[
        const SizedBox(height: AppSpacing.sm),
        _AllDoneBanner(ctrl: ctrl),
      ] else if (ctrl.hasMinimumExercisesSelected) ...[
        const SizedBox(height: AppSpacing.sm),
        _StartSelectedBtn(ctrl: ctrl),
      ],
      const SizedBox(height: AppSpacing.xxl),
    ]);
  }
}

class _SelectionBanner extends StatelessWidget {
  final HealthController ctrl;
  const _SelectionBanner({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final n     = ctrl.selectedExerciseIds.length;
    final ready = ctrl.hasMinimumExercisesSelected;
    final color = ready ? AppColors.tierRemission : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ready ? AppColors.tierRemission.withValues(alpha: 0.08) : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ready ? AppColors.tierRemission.withValues(alpha: 0.3) : AppColors.primaryBorder),
      ),
      child: Row(children: [
        Icon(ready ? Icons.check_circle_rounded : Icons.touch_app_rounded, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ready ? '$n activities selected — ready to start!' : 'Select at least 2 activities', style: AppTextStyles.label().copyWith(color: color)),
          Text('Tap a card to select. Each has its own timer.', style: AppTextStyles.caption()),
        ])),
      ]),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseRecommendation exercise;
  final HealthController ctrl;
  const _ExerciseCard({required this.exercise, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final selected  = ctrl.isExerciseSelected(exercise.id);
    final completed = ctrl.isExerciseCompleted(exercise.id);
    final borderColor = completed ? AppColors.tierRemission : selected ? AppColors.primary : AppColors.border;
    final bgColor     = completed
        ? AppColors.tierRemission.withValues(alpha: 0.06)
        : selected ? AppColors.primarySurface : AppColors.bgCard;

    return GestureDetector(
      onTap: completed ? null : () => ctrl.toggleExerciseSelection(exercise.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: selected || completed ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(children: [
              // Select circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? AppColors.tierRemission : selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: completed ? AppColors.tierRemission : selected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: (completed || selected) ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(exercise.name, style: AppTextStyles.cardTitle()),
                const SizedBox(height: 3),
                Row(children: [
                  _SmallChip(exercise.type, AppColors.primary),
                  if (exercise.duration.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _SmallChip(exercise.duration, AppColors.textSecondary),
                  ],
                ]),
              ])),
              if (completed)
                _DoneTag()
              else if (selected)
                _StartBtn(exercise: exercise, ctrl: ctrl),
            ]),
          ),
          // Benefits
          if (exercise.benefits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Wrap(spacing: 6, runSpacing: 4, children: exercise.benefits.map((b) => _BenefitTag(b)).toList()),
            ),
          // Footer: intensity + joint
          if (exercise.intensity.isNotEmpty || exercise.jointImpact.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgSection,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppRadius.lg), bottomRight: Radius.circular(AppRadius.lg)),
              ),
              child: Row(children: [
                if (exercise.intensity.isNotEmpty) ...[
                  const Icon(Icons.speed_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(exercise.intensity, style: AppTextStyles.caption()),
                  const SizedBox(width: AppSpacing.md),
                ],
                if (exercise.jointImpact.isNotEmpty) ...[
                  const Icon(Icons.accessibility_new_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${exercise.jointImpact} impact', style: AppTextStyles.caption()),
                ],
              ]),
            ),
        ]),
      ),
    );
  }
}

class _StartBtn extends StatelessWidget {
  final ExerciseRecommendation exercise;
  final HealthController ctrl;
  const _StartBtn({required this.exercise, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isPaused   = ctrl.isExercisePaused(exercise.id);
    final pausedSec  = ctrl.exercisePausedSec(exercise.id);
    final pausedMin  = pausedSec ~/ 60;
    final pausedSecR = pausedSec % 60;
    final label      = isPaused
        ? 'Resume (${pausedMin}m ${pausedSecR}s saved)'
        : 'Start';
    final btnColor   = isPaused ? AppColors.tierLow : AppColors.primary;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctrl,
          child: ExerciseSessionView(
            exercise: exercise,
            resumeFromPause: isPaused,
          ),
        ),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isPaused ? Icons.play_circle_filled_rounded : Icons.play_arrow_rounded,
              size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.label().copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}

class _DoneTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.tierRemission.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text('Done ✓', style: AppTextStyles.labelCaps().copyWith(color: AppColors.tierRemission)),
  );
}

class _StartSelectedBtn extends StatelessWidget {
  final HealthController ctrl;
  const _StartSelectedBtn({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    // Prefer a paused exercise for resume, else pick first unfinished
    final pending = ctrl.selectedExercises.where((e) => !ctrl.isExerciseCompleted(e.id)).toList();
    final first   = pending.firstWhere(
      (e) => ctrl.isExercisePaused(e.id),
      orElse: () => pending.isNotEmpty ? pending.first : ctrl.selectedExercises.first,
    );
    final isPaused = ctrl.isExercisePaused(first.id);
    return AppButton(
      label: isPaused
          ? 'Resume ${first.name}'
          : 'Start Activities (${ctrl.selectedExerciseIds.length} selected)',
      icon: isPaused ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctrl,
          child: ExerciseSessionView(exercise: first, resumeFromPause: isPaused),
        ),
      )),
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  final HealthController ctrl;
  const _AllDoneBanner({required this.ctrl});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color: AppColors.tierRemission.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.tierRemission.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Text('🎉', style: TextStyle(fontSize: 28)),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('All exercises completed!', style: AppTextStyles.cardTitle().copyWith(color: AppColors.tierRemission)),
        Text('${ctrl.completedExerciseCount} / ${ctrl.selectedExerciseIds.length} done today.', style: AppTextStyles.caption()),
      ])),
    ]),
  );
}

// ─────────────────────────────────────────────
// NUTRITION TAB
// ─────────────────────────────────────────────
class _NutritionTab extends StatelessWidget {
  final NutritionRecommendation? nutrition;
  const _NutritionTab({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final n = nutrition;
    if (n == null) return const _EmptyState(icon: Icons.restaurant_rounded, message: 'No nutrition plan available');

    return ListView(padding: const EdgeInsets.all(AppSpacing.base), children: [
      // Plan summary
      _NutritionPlanCard(n: n),
      const SizedBox(height: AppSpacing.base),
      // Lifestyle tips
      if (n.tips.isNotEmpty) ...[
        _TipsCard(tips: n.tips),
        const SizedBox(height: AppSpacing.base),
      ],
      // Progress if already logged
      if (ctrl.nutritionDone) ...[
        _NutritionProgressSummary(ctrl: ctrl, n: n),
        const SizedBox(height: AppSpacing.base),
      ],
      // Log / Update button — always available
      AppButton(
        label: ctrl.nutritionDone ? '✏️  Update Today\'s Nutrition' : '🥗  Log Today\'s Nutrition',
        color: ctrl.nutritionDone ? AppColors.tierLow : AppColors.primary,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(value: ctrl, child: NutritionLogView(nutrition: n)),
        )),
      ),
      const SizedBox(height: AppSpacing.xxl),
    ]);
  }
}

class _NutritionPlanCard extends StatelessWidget {
  final NutritionRecommendation n;
  const _NutritionPlanCard({required this.n});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(n.name, style: AppTextStyles.cardTitle())),
      ]),
      if (n.description.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(n.description, style: AppTextStyles.bodySmall()),
      ],
      const Divider(height: AppSpacing.xl, color: AppColors.divider),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _TargetTile('🥦', '${n.vegetablesTarget}+', 'Veg'),
        _TargetTile('🍎', '${n.fruitsTarget}', 'Fruits'),
        _TargetTile('💧', '${n.waterGlassesTarget}', 'Glasses'),
      ]),
      if (n.focusArea.isNotEmpty) ...[
        const Divider(height: AppSpacing.xl, color: AppColors.divider),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.center_focus_strong_rounded, size: 15, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(n.focusArea, style: AppTextStyles.bodySmall())),
        ]),
      ],
    ]),
  );
}

class _TargetTile extends StatelessWidget {
  final String emoji, value, label;
  const _TargetTile(this.emoji, this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    Text(value, style: AppTextStyles.scoreMedium(AppColors.primary)),
    Text(label, style: AppTextStyles.caption()),
  ]);
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  const _TipsCard({required this.tips});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.tierLow, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text('Lifestyle Guidance', style: AppTextStyles.cardTitle()),
      ]),
      const SizedBox(height: AppSpacing.md),
      ...tips.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.bodySmall()),
      )),
    ]),
  );
}

class _NutritionProgressSummary extends StatelessWidget {
  final HealthController ctrl;
  final NutritionRecommendation n;
  const _NutritionProgressSummary({required this.ctrl, required this.n});
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.tierRemission.withValues(alpha: 0.06),
    padding: const EdgeInsets.all(AppSpacing.base),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.tierRemission, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text("Today's Log", style: AppTextStyles.cardTitle().copyWith(color: AppColors.tierRemission)),
      ]),
      const SizedBox(height: AppSpacing.md),
      _ProgressBar('🥦', 'Vegetables', ctrl.loggedVegetables, n.vegetablesTarget),
      _ProgressBar('🍎', 'Fruits', ctrl.loggedFruits, n.fruitsTarget),
      _ProgressBar('💧', 'Water', ctrl.loggedWater, n.waterGlassesTarget),
      if (ctrl.loggedFoods.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: 6, runSpacing: 4, children: ctrl.loggedFoods.map((f) => _BenefitTag(f)).toList()),
      ],
    ]),
  );
}

class _ProgressBar extends StatelessWidget {
  final String emoji, label;
  final int current, target;
  const _ProgressBar(this.emoji, this.label, this.current, this.target);
  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AppTextStyles.caption()),
            Text('$current / $target', style: AppTextStyles.caption().copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            color: pct >= 1.0 ? AppColors.tierRemission : AppColors.primary,
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ])),
      ]),
    );
  }
}

// Tiny shared chips
class _SmallChip extends StatelessWidget {
  final String label; final Color color;
  const _SmallChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(label, style: AppTextStyles.caption().copyWith(color: color, fontWeight: FontWeight.w600)),
  );
}

class _BenefitTag extends StatelessWidget {
  final String label;
  const _BenefitTag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppRadius.pill)),
    child: Text(label, style: AppTextStyles.caption().copyWith(color: AppColors.primary)),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const CircularProgressIndicator(color: AppColors.primary),
    const SizedBox(height: AppSpacing.base),
    Text('Loading your plan...', style: AppTextStyles.bodySmall()),
  ]));
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 48, color: AppColors.textMuted),
    const SizedBox(height: AppSpacing.base),
    Text(message, style: AppTextStyles.bodySmall()),
  ]));
}