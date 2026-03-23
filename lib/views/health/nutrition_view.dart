// lib/views/health/lifestyle/nutrition_log_view.dart
// User logs vegetables, fruits, water glasses, and custom food items
// against the day's nutrition recommendation.

import 'package:arthro/models/health_model.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';

class NutritionLogView extends StatefulWidget {
  final NutritionRecommendation nutrition;
  const NutritionLogView({Key? key, required this.nutrition}) : super(key: key);

  @override
  State<NutritionLogView> createState() => _NutritionLogViewState();
}

class _NutritionLogViewState extends State<NutritionLogView> {
  final TextEditingController _foodCtrl = TextEditingController();

  @override
  void dispose() {
    _foodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final n    = widget.nutrition;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LOG NUTRITION', style: AppTextStyles.labelCaps()),
            Text(n.name, style: AppTextStyles.sectionTitle()),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: Text(
              _todayDate(),
              style: AppTextStyles.label().copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _DailyProgressBar(ctrl: ctrl, n: n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target summary card
                  _TargetCard(n: n),
                  const SizedBox(height: AppSpacing.base),

                  // Serving counters
                  SectionHeader(
                    title: 'Track Servings',
                    subtitle: 'Tap + / − to update your counts',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ServingCounter(
                    icon: '🥦',
                    label: 'Vegetables',
                    current: ctrl.loggedVegetables,
                    target: n.vegetablesTarget,
                    onIncrement: ctrl.incrementVegetables,
                    onDecrement: ctrl.decrementVegetables,
                    color: AppColors.tierRemission,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ServingCounter(
                    icon: '🍎',
                    label: 'Fruits',
                    current: ctrl.loggedFruits,
                    target: n.fruitsTarget,
                    onIncrement: ctrl.incrementFruits,
                    onDecrement: ctrl.decrementFruits,
                    color: AppColors.tierModerate,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ServingCounter(
                    icon: '💧',
                    label: 'Water Glasses',
                    current: ctrl.loggedWater,
                    target: n.waterGlassesTarget,
                    onIncrement: ctrl.incrementWater,
                    onDecrement: ctrl.decrementWater,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Recommended food quick-add
                  SectionHeader(
                    title: 'Quick Add — Recommended Foods',
                    subtitle: 'Tap to add to your food log',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickFoodGrid(
                    examples: n.examples,
                    loggedFoods: ctrl.loggedFoods,
                    onAdd:    ctrl.addFoodItem,
                    onRemove: ctrl.removeFoodItem,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Custom food entry
                  SectionHeader(
                    title: 'Add Custom Food',
                    subtitle: 'Type anything you ate today',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CustomFoodInput(
                    controller: _foodCtrl,
                    onAdd: () {
                      final text = _foodCtrl.text.trim();
                      if (text.isNotEmpty) {
                        ctrl.addFoodItem(text);
                        _foodCtrl.clear();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Logged food chips
                  if (ctrl.loggedFoods.isNotEmpty) ...[
                    _LoggedFoodChips(
                      foods: ctrl.loggedFoods,
                      onRemove: ctrl.removeFoodItem,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Foods to avoid reminder
                  if (n.avoidFoods.isNotEmpty) ...[
                    _AvoidReminder(foods: n.avoidFoods),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Today's adherence summary
                  _AdherenceSummary(ctrl: ctrl, n: n),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          // Save bar
          _SaveBar(ctrl: ctrl),
        ],
      ),
    );
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

// ─────────────────────────────────────────────
// DAILY PROGRESS BAR (top strip)
// ─────────────────────────────────────────────
class _DailyProgressBar extends StatelessWidget {
  final HealthController ctrl;
  final NutritionRecommendation n;
  const _DailyProgressBar({required this.ctrl, required this.n});

  @override
  Widget build(BuildContext context) {
    final totalTarget = n.vegetablesTarget + n.fruitsTarget + n.waterGlassesTarget;
    final totalLogged = ctrl.loggedVegetables + ctrl.loggedFruits + ctrl.loggedWater;
    final pct = totalTarget > 0
        ? (totalLogged / totalTarget).clamp(0.0, 1.0)
        : 0.0;
    final color = pct >= 1.0
        ? AppColors.tierRemission
        : pct >= 0.6
            ? AppColors.tierLow
            : AppColors.tierModerate;

    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base, vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Progress', style: AppTextStyles.label()),
              Text(
                '${(pct * 100).round()}%',
                style: AppTextStyles.label().copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.bgSection,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARGET CARD
// ─────────────────────────────────────────────
class _TargetCard extends StatelessWidget {
  final NutritionRecommendation n;
  const _TargetCard({required this.n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primarySurface,
          AppColors.bgCard,
        ]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Goal", style: AppTextStyles.cardTitle()),
                Text(
                  n.dailyGoal,
                  style: AppTextStyles.sectionTitle()
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Focus: ${n.focusArea}',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SERVING COUNTER
// ─────────────────────────────────────────────
class _ServingCounter extends StatelessWidget {
  final String icon;
  final String label;
  final int current;
  final int target;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color color;

  const _ServingCounter({
    required this.icon,
    required this.label,
    required this.current,
    required this.target,
    required this.onIncrement,
    required this.onDecrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final done = current >= target;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      color: done ? color.withOpacity(0.05) : AppColors.bgCard,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.cardTitle()),
                Row(
                  children: [
                    Text(
                      '$current / $target servings',
                      style: AppTextStyles.label().copyWith(
                        color: done ? color : AppColors.textSecondary,
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // Progress dots
                Row(
                  children: List.generate(target, (i) => Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < current ? color : AppColors.bgSection,
                      border: Border.all(
                        color: i < current ? color : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                  )).take(10).toList(), // max 10 dots shown
                ),
              ],
            ),
          ),
          // Counter controls
          Row(
            children: [
              _CounterBtn(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
                enabled: current > 0,
              ),
              Container(
                width: 44, height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: done ? color.withOpacity(0.15) : AppColors.bgSection,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: done ? color.withOpacity(0.4) : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$current',
                    style: AppTextStyles.sectionTitle()
                        .copyWith(color: done ? color : AppColors.textPrimary),
                  ),
                ),
              ),
              _CounterBtn(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                enabled: true,
                active: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool active;

  const _CounterBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: !enabled
              ? AppColors.bgSection
              : active
                  ? AppColors.primary
                  : AppColors.bgSection,
          shape: BoxShape.circle,
          border: Border.all(
            color: !enabled
                ? AppColors.border
                : active
                    ? AppColors.primary
                    : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: !enabled
              ? AppColors.textMuted
              : active
                  ? Colors.white
                  : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// QUICK FOOD GRID
// ─────────────────────────────────────────────
class _QuickFoodGrid extends StatelessWidget {
  final List<String> examples;
  final List<String> loggedFoods;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const _QuickFoodGrid({
    required this.examples,
    required this.loggedFoods,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Flatten examples: each line like "Vegetables: Spinach, kale, ..."
    // → extract individual items
    final items = <_FoodItem>[];
    for (final line in examples) {
      final parts = line.split(':');
      if (parts.length == 2) {
        final category = parts[0].trim();
        final foods = parts[1].split(',').map((f) => f.trim()).toList();
        for (final food in foods) {
          if (food.isNotEmpty) items.add(_FoodItem(name: food, category: category));
        }
      } else {
        items.add(_FoodItem(name: line.trim(), category: ''));
      }
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final logged = loggedFoods.contains(item.name);
        return GestureDetector(
          onTap: () => logged ? onRemove(item.name) : onAdd(item.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: logged
                  ? AppColors.tierRemission.withOpacity(0.12)
                  : AppColors.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: logged
                    ? AppColors.tierRemission
                    : AppColors.border,
                width: logged ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logged)
                  const Icon(Icons.check_rounded,
                      size: 12, color: AppColors.tierRemission),
                if (logged) const SizedBox(width: 4),
                Text(
                  item.name,
                  style: AppTextStyles.caption().copyWith(
                    color: logged
                        ? AppColors.tierRemission
                        : AppColors.textPrimary,
                    fontWeight: logged ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FoodItem {
  final String name;
  final String category;
  const _FoodItem({required this.name, required this.category});
}

// ─────────────────────────────────────────────
// CUSTOM FOOD INPUT
// ─────────────────────────────────────────────
class _CustomFoodInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _CustomFoodInput({
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. Brown rice, grilled chicken...',
              prefixIcon: const Icon(
                Icons.restaurant_outlined,
                color: AppColors.primary, size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: 14),
            ),
            onSubmitted: (_) => onAdd(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// LOGGED FOOD CHIPS
// ─────────────────────────────────────────────
class _LoggedFoodChips extends StatelessWidget {
  final List<String> foods;
  final void Function(String) onRemove;

  const _LoggedFoodChips({required this.foods, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.tierRemission, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text('Logged Today (${foods.length})',
                  style: AppTextStyles.cardTitle()),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: foods
                .map((f) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tierRemission.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.tierRemission.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f,
                            style: AppTextStyles.caption().copyWith(
                              color: AppColors.tierRemission,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () => onRemove(f),
                            child: const Icon(Icons.close_rounded,
                                size: 12,
                                color: AppColors.tierRemission),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AVOID REMINDER
// ─────────────────────────────────────────────
class _AvoidReminder extends StatelessWidget {
  final List<String> foods;
  const _AvoidReminder({required this.foods});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tierHighBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.tierHigh.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.not_interested_rounded,
              color: AppColors.tierHigh, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avoid Today',
                  style: AppTextStyles.label()
                      .copyWith(color: AppColors.tierHigh),
                ),
                const SizedBox(height: 4),
                Text(
                  foods.join(' • '),
                  style: AppTextStyles.caption()
                      .copyWith(color: AppColors.tierHigh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ADHERENCE SUMMARY
// ─────────────────────────────────────────────
class _AdherenceSummary extends StatelessWidget {
  final HealthController ctrl;
  final NutritionRecommendation n;
  const _AdherenceSummary({required this.ctrl, required this.n});

  @override
  Widget build(BuildContext context) {
    final vegPct  = n.vegetablesTarget > 0
        ? (ctrl.loggedVegetables / n.vegetablesTarget).clamp(0.0, 1.0)
        : 0.0;
    final fruPct  = n.fruitsTarget > 0
        ? (ctrl.loggedFruits / n.fruitsTarget).clamp(0.0, 1.0)
        : 0.0;
    final watPct  = n.waterGlassesTarget > 0
        ? (ctrl.loggedWater / n.waterGlassesTarget).clamp(0.0, 1.0)
        : 0.0;
    final overall = ((vegPct + fruPct + watPct) / 3 * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Adherence", style: AppTextStyles.cardTitle()),
              Text(
                '$overall%',
                style: AppTextStyles.sectionTitle().copyWith(
                  color: overall >= 80
                      ? AppColors.tierRemission
                      : overall >= 50
                          ? AppColors.tierLow
                          : AppColors.tierModerate,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MiniBar('Vegetables', vegPct, AppColors.tierRemission),
          const SizedBox(height: AppSpacing.sm),
          _MiniBar('Fruits',     fruPct, AppColors.tierModerate),
          const SizedBox(height: AppSpacing.sm),
          _MiniBar('Water',      watPct, AppColors.info),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _MiniBar(this.label, this.pct, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.caption()),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.bgSection,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${(pct * 100).round()}%',
          style: AppTextStyles.label().copyWith(
            color: color, fontVariations: [],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SAVE BAR
// ─────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  final HealthController ctrl;
  const _SaveBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.md,
        AppSpacing.base, AppSpacing.base + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: AppShadows.subtle(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ctrl.nutritionDone &&
              ctrl.loggedVegetables == 0 &&
              ctrl.loggedFruits == 0 &&
              ctrl.loggedWater == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Add at least one item to save your log',
                style: AppTextStyles.caption(),
              ),
            ),
          AppButton(
            label: ctrl.saving
                ? 'Saving...'
                : ctrl.nutritionDone
                    ? '✓ Saved! Update Log'
                    : 'Save Nutrition Log',
            loading: ctrl.saving,
            color: ctrl.nutritionDone
                ? AppColors.tierRemission
                : AppColors.primary,
            icon: ctrl.nutritionDone
                ? null
                : Icons.save_alt_rounded,
            onTap: () => _save(context, ctrl),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, HealthController ctrl) async {
    await ctrl.saveNutritionLog();
    if (!context.mounted) return;

    if (ctrl.errorMsg != null) {
      // Show the actual error so developer/user can diagnose it
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
      return; // do NOT pop — let user retry
    }

    // Success
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('Nutrition log saved!',
            style: AppTextStyles.label().copyWith(color: Colors.white)),
      ]),
      backgroundColor: AppColors.tierRemission,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      duration: const Duration(seconds: 2),
    ));
    Navigator.of(context).pop();
  }
}