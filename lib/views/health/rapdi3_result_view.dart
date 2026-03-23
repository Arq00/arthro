// lib/views/health/symptom/rapid3_result_view.dart
// Shows the calculated RAPID3 score, tier badge, tier description,
// joint summary, and a CTA to view lifestyle recommendations.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import '../../../models/health_model.dart';

class Rapid3ResultView extends StatefulWidget {
  const Rapid3ResultView({Key? key}) : super(key: key);

  @override
  State<Rapid3ResultView> createState() => _Rapid3ResultViewState();
}

class _Rapid3ResultViewState extends State<Rapid3ResultView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    // Slight delay so the page transition settles first
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();
    final tier = ctrl.rapid3Tier;
    final def  = ctrl.tierDef;

    final tierColor = AppTierHelper.color(tier);
    final tierBg    = AppTierHelper.bgColor(tier);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          // ── Gradient header ──
          _ResultHeader(
            tier:       tier,
            score:      ctrl.rapid3Score,
            tierColor:  tierColor,
            tierBg:     tierBg,
            scaleAnim:  _scaleAnim,
            fadeAnim:   _fadeAnim,
          ),
          // ── Scrollable details ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    if (def != null) ...[
                      _StatusCard(def: def, tierColor: tierColor),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Alert banner for HIGH tier
                    if (tier == 'HIGH' && def?.alert == true) ...[
                      _AlertBanner(message: def!.alertMessage),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Score breakdown
                    _ScoreBreakdown(ctrl: ctrl),
                    const SizedBox(height: AppSpacing.base),

                    // Affected joints summary
                    if (ctrl.selectedJoints.isNotEmpty) ...[
                      _JointSummary(joints: ctrl.bodyJoints
                          .where((j) => j.isSelected)
                          .toList()),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Morning stiffness + weather
                    _ContextCard(ctrl: ctrl),
                    const SizedBox(height: AppSpacing.base),

                    // What this tier means
                    _TierGuideCard(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
          // ── Bottom CTA ──
          _ResultBottomBar(
            onViewLifestyle: ctrl.goToLifestyle,
            onRetake: ctrl.reset,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GRADIENT HEADER WITH ANIMATED SCORE
// ─────────────────────────────────────────────
class _ResultHeader extends StatelessWidget {
  final String tier;
  final double score;
  final Color tierColor;
  final Color tierBg;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;

  const _ResultHeader({
    required this.tier,
    required this.score,
    required this.tierColor,
    required this.tierBg,
    required this.scaleAnim,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      // Compact header: tight padding, horizontal layout
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, topPad + AppSpacing.sm,
        AppSpacing.base, AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tierColor.withValues(alpha: 0.12), tierBg],
        ),
        border: Border(
          bottom: BorderSide(color: tierColor.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: FadeTransition(
        opacity: fadeAnim,
        child: Row(
          children: [
            // Small animated score circle
            ScaleTransition(
              scale: scaleAnim,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierBg,
                  border: Border.all(color: tierColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.25),
                      blurRadius: 12, spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(score.toStringAsFixed(1),
                        style: AppTextStyles.scoreMedium(tierColor)),
                    Text('/10', style: AppTextStyles.caption()),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + tier badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR RAPID3 RESULT',
                      style: AppTextStyles.labelCaps()
                          .copyWith(color: tierColor, fontSize: 10)),
                  const SizedBox(height: 4),
                  TierBadge(tier: tier, large: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATUS CARD
// ─────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final Rapid3TierDefinition def;
  final Color tierColor;

  const _StatusCard({required this.def, required this.tierColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Text(def.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.statusText, style: AppTextStyles.sectionTitle()),
                const SizedBox(height: 4),
                Text(def.statusDescription, style: AppTextStyles.bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ALERT BANNER (HIGH tier)
// ─────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final String message;
  const _AlertBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.tierHighBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.tierHigh.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.tierHigh.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.tierHigh, size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Alert',
                  style: AppTextStyles.cardTitle()
                      .copyWith(color: AppColors.tierHigh),
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: AppTextStyles.bodySmall()
                        .copyWith(color: AppColors.tierHigh)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SCORE BREAKDOWN
// ─────────────────────────────────────────────
class _ScoreBreakdown extends StatelessWidget {
  final HealthController ctrl;
  const _ScoreBreakdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score Breakdown', style: AppTextStyles.cardTitle()),
          const SizedBox(height: AppSpacing.md),
          _ScoreBar(
            label: 'Pain',
            sublabel: 'How much pain in the past week',
            value: ctrl.painValue,
            max: 10,
            color: _barColor(ctrl.painValue, 10),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreBar(
            label: 'Physical Function',
            sublabel: 'Average difficulty with daily tasks',
            value: ctrl.functionValue,
            max: 3,
            color: _barColor(ctrl.functionValue, 3),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreBar(
            label: 'Global Health',
            sublabel: 'Overall wellbeing this week',
            value: ctrl.globalValue,
            max: 10,
            color: _barColor(ctrl.globalValue, 10),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreBar(
            label: 'Stress Level',
            sublabel: 'Self-reported overall stress (tracked separately)',
            value: ctrl.stressLevel,
            max: 10,
            color: ctrl.stressLevel < 4 ? AppColors.tierRemission
                   : ctrl.stressLevel <= 7.5 ? AppColors.tierModerate
                   : AppColors.tierHigh,
          ),
          const Divider(color: AppColors.divider, height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RAPID3 Score', style: AppTextStyles.cardTitle()),
              Text(
                ctrl.rapid3Score.toStringAsFixed(1),
                style: AppTextStyles.sectionTitle().copyWith(
                  color: AppTierHelper.color(ctrl.rapid3Tier),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Formula: (Pain + Function×(10/3) + Global) ÷ 3',
            style: AppTextStyles.labelCaps(),
          ),
        ],
      ),
    );
  }

  Color _barColor(double val, double max) {
    final pct = val / max;
    if (pct <= 0.25) return AppColors.tierRemission;
    if (pct <= 0.50) return AppColors.tierLow;
    if (pct <= 0.75) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final double max;
  final Color color;
  const _ScoreBar({
    required this.label, required this.sublabel,
    required this.value, required this.max, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Value never truncates — shrinks label instead
            Text(
              '${value.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
              style: AppTextStyles.label().copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(sublabel, style: AppTextStyles.labelCaps()),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.bgSection,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// JOINT SUMMARY
// ─────────────────────────────────────────────
class _JointSummary extends StatelessWidget {
  final List<BodyJoint> joints;
  const _JointSummary({required this.joints});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility_new_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Affected Joints (${joints.length})',
                  style: AppTextStyles.cardTitle()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: joints.map((j) {
              final color = j.severity == 'severe'
                  ? AppColors.tierHigh
                  : AppColors.tierLow;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 5),
                    Text(j.label,
                        style: AppTextStyles.caption()
                            .copyWith(color: color, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text(j.severity,
                        style: AppTextStyles.labelCaps()
                            .copyWith(color: color.withOpacity(0.7))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONTEXT CARD (stiffness + weather)
// ─────────────────────────────────────────────
class _ContextCard extends StatelessWidget {
  final HealthController ctrl;
  const _ContextCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final w = ctrl.weather;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Context', style: AppTextStyles.cardTitle()),
          const SizedBox(height: AppSpacing.md),
          // Morning stiffness
          InfoRow(
            label: 'Morning Stiffness',
            value: ctrl.stiffnessMinutes == 0
                ? 'None'
                : '${ctrl.stiffnessMinutes} min',
            valueColor: ctrl.stiffnessMinutes > 45
                ? AppColors.tierHigh
                : ctrl.stiffnessMinutes > 15
                    ? AppColors.tierModerate
                    : AppColors.tierRemission,
          ),
          const Divider(color: AppColors.divider, height: 1),
          if (w != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoRow(
              label: 'Humidity',
              value: '${w.humidity.toStringAsFixed(0)}%',
              valueColor: w.humidity > 75 ? AppColors.tierModerate : AppColors.primary,
            ),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stiffness Risk', style: AppTextStyles.caption()),
                WeatherRiskChip(
                  label: w.riskLabel,
                  riskLevel: w.stiffnessRisk,
                  icon: Icons.water_drop_outlined,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TIER GUIDE (score ranges reference)
// ─────────────────────────────────────────────
class _TierGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiers = [
      ('REMISSION', '0 – 1.0',  '🟢'),
      ('LOW',       '1.0 – 2.0','🟡'),
      ('MODERATE',  '2.0 – 4.0','🟠'),
      ('HIGH',      '4.0 – 10', '🔴'),
    ];
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RAPID3 Score Guide', style: AppTextStyles.cardTitle()),
          const SizedBox(height: AppSpacing.md),
          ...tiers.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Text(t.$3, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(
                  AppTierHelper.label(t.$1),
                  style: AppTextStyles.bodySmall(),
                )),
                Text(t.$2,
                  style: AppTextStyles.label().copyWith(
                    color: AppTierHelper.color(t.$1),
                    fontFamily: 'DMMono',
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────
class _ResultBottomBar extends StatelessWidget {
  final VoidCallback onViewLifestyle;
  final VoidCallback onRetake;

  const _ResultBottomBar({
    required this.onViewLifestyle,
    required this.onRetake,
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
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retake'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'View Lifestyle Plan',
              onTap: onViewLifestyle,
              icon: Icons.fitness_center_rounded,
            ),
          ),
        ],
      ),
    );
  }
}