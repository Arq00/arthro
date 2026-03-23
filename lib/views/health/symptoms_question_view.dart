// lib/views/health/symptom/symptom_questions_view.dart
// Step 1a: RAPID3 Symptom Questions
// Shows pain slider, functional ability (10 sub-questions), global slider.

import 'package:arthro/models/health_model.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';

class SymptomQuestionsView extends StatefulWidget {
  const SymptomQuestionsView({Key? key}) : super(key: key);
  @override
  State<SymptomQuestionsView> createState() => _SymptomQuestionsViewState();
}

class _SymptomQuestionsViewState extends State<SymptomQuestionsView> {
  final PageController _pageCtrl = PageController();
  int _page = 0; // 0=pain, 1=function, 2=global

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage(HealthController ctrl) {
    if (_page < 2) {
      setState(() => _page++);
      _pageCtrl.animateToPage(
        _page, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut,
      );
    } else {
      ctrl.nextToHeatmap();
    }
  }

  void _prevPage() {
    if (_page > 0) {
      setState(() => _page--);
      _pageCtrl.animateToPage(
        _page, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    if (ctrl.questionsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: _buildAppBar(ctrl),
      body: Column(
        children: [
          // ─── Progress bar ───
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm,
            ),
            child: StepIndicator(total: 3, current: _page),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PainPage(onNext: () => _nextPage(ctrl)),
                _FunctionPage(onNext: () => _nextPage(ctrl), onBack: _prevPage),
                _GlobalPage(onNext: () => _nextPage(ctrl), onBack: _prevPage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(HealthController ctrl) => AppBar(
    backgroundColor: AppColors.bgCard,
    elevation: 0,
    leading: _page > 0
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _prevPage,
            color: AppColors.primary,
          )
        : null,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STEP 1 OF 3', style: AppTextStyles.labelCaps()),
        Text('Symptom Assessment', style: AppTextStyles.sectionTitle()),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// PAGE 1 — PAIN SLIDER
// ─────────────────────────────────────────────
class _PainPage extends StatelessWidget {
  final VoidCallback onNext;
  const _PainPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final pain = ctrl.painValue;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionHeader(
            number: 1,
            title: 'How much pain did you have in the past week?',
            subtitle: 'Rate your pain on a scale of 0–10',
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Big score display ──
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _painColor(pain).withOpacity(0.1),
                border: Border.all(color: _painColor(pain), width: 3),
              ),
              child: Center(
                child: Text(
                  pain.toStringAsFixed(1),
                  style: AppTextStyles.heroScore(_painColor(pain)),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Slider ──
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('No pain', style: AppTextStyles.caption()),
                    Text('Severe pain', style: AppTextStyles.caption()),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _painColor(pain),
                    thumbColor: _painColor(pain),
                    overlayColor: _painColor(pain).withOpacity(0.15),
                    valueIndicatorColor: _painColor(pain),
                  ),
                  child: Slider(
                    value: pain,
                    min: 0, max: 10, divisions: 20,
                    label: pain.toStringAsFixed(1),
                    onChanged: ctrl.setPain,
                  ),
                ),
                // ── Emoji guide ──
                const _PainEmojiGuide(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: AppButton(label: 'Next →', onTap: onNext, icon: Icons.arrow_forward_rounded),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Color _painColor(double v) {
    if (v <= 2) return AppColors.tierRemission;
    if (v <= 4) return AppColors.tierLow;
    if (v <= 7) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }
}

class _PainEmojiGuide extends StatelessWidget {
  const _PainEmojiGuide();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('0-2', '😊', 'Mild'),
      ('3-4', '😐', 'Low'),
      ('5-7', '😟', 'Mod'),
      ('8-10', '😣', 'Severe'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((e) => Column(
          children: [
            Text(e.$2, style: const TextStyle(fontSize: 22)),
            Text(e.$1, style: AppTextStyles.labelCaps()),
            Text(e.$3, style: AppTextStyles.caption()),
          ],
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE 2 — FUNCTION (10 sub-questions)
// ─────────────────────────────────────────────
class _FunctionPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _FunctionPage({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final options = ['No difficulty', 'Some difficulty', 'Much difficulty', 'Unable to do'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionHeader(
                  number: 2,
                  title: 'How much difficulty did you have with daily activities?',
                  subtitle: 'Rate each activity',
                ),
                const SizedBox(height: AppSpacing.base),
                ...List.generate(ctrl.functionSubQuestions.length, (i) {
                  final q = ctrl.functionSubQuestions[i];
                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: AppColors.bgCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q, style: AppTextStyles.cardTitle()),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: List.generate(4, (j) {
                            final selected = ctrl.functionAnswers[i] == j.toDouble();
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ctrl.setFunctionAnswer(i, j.toDouble()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected ? AppColors.primary : AppColors.bgSection,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(
                                      color: selected ? AppColors.primary : AppColors.border,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$j',
                                        style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w700,
                                          color: selected ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        options[j].split(' ').first,
                                        style: TextStyle(
                                          fontSize: 9, fontWeight: FontWeight.w600,
                                          color: selected ? Colors.white70 : AppColors.textMuted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }).expand((w) => [w, const SizedBox(height: AppSpacing.sm)]).toList(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        _BottomNavBar(onNext: onNext, onBack: onBack),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PAGE 3 — GLOBAL SLIDER
// ─────────────────────────────────────────────
class _GlobalPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const _GlobalPage({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final val  = ctrl.globalValue;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionHeader(
                  number: 3,
                  title: 'How well did you feel overall in the past week?',
                  subtitle: 'Rate your overall health status',
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _color(val).withOpacity(0.1),
                      border: Border.all(color: _color(val), width: 3),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(val.toStringAsFixed(1), style: AppTextStyles.heroScore(_color(val))),
                          Text('/10', style: AppTextStyles.caption()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Very well', style: AppTextStyles.caption()),
                          Text('Very poor', style: AppTextStyles.caption()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Slider(
                        value: val, min: 0, max: 10, divisions: 20,
                        label: val.toStringAsFixed(1),
                        onChanged: ctrl.setGlobal,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Wellness emoji row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _WellnessChip('😄', 'Excellent', val <= 2),
                          _WellnessChip('🙂', 'Good',      val > 2 && val <= 4),
                          _WellnessChip('😐', 'Fair',      val > 4 && val <= 7),
                          _WellnessChip('😔', 'Poor',      val > 7),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Preview RAPID3
                _Rapid3Preview(
                  pain:     ctrl.painValue,
                  function: ctrl.functionValue,
                  global:   val,
                ),
              ],
            ),
          ),
        ),
        _BottomNavBar(
          onNext: onNext,
          onBack: onBack,
          nextLabel: 'Continue to Joint Map',
        ),
      ],
    );
  }

  Color _color(double v) {
    if (v <= 2) return AppColors.tierRemission;
    if (v <= 4) return AppColors.tierLow;
    if (v <= 7) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }
}

class _WellnessChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool active;
  const _WellnessChip(this.emoji, this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: active ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            label,
            style: AppTextStyles.labelCaps().copyWith(
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rapid3Preview extends StatelessWidget {
  final double pain, function, global;
  const _Rapid3Preview({
    required this.pain, required this.function, required this.global,
  });

  @override
  Widget build(BuildContext context) {
    final score = SymptomLog.calculateRapid3(pain, function, global);
    final tier  = SymptomLog.tierFromScore(score);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppTierHelper.bgColor(tier),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppTierHelper.color(tier).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            AppTierHelper.emoji(tier),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estimated RAPID3', style: AppTextStyles.labelCaps()),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: AppTextStyles.scoreMedium(AppTierHelper.color(tier)),
                    ),
                    const SizedBox(width: 8),
                    TierBadge(tier: tier),
                  ],
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
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _QuestionHeader extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  const _QuestionHeader({
    required this.number, required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'Question $number of 3',
            style: AppTextStyles.labelCaps().copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.sectionTitle()),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.caption()),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  const _BottomNavBar({
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Next →',
  });

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
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: 3,
            child: AppButton(label: nextLabel, onTap: onNext),
          ),
        ],
      ),
    );
  }
}