// lib/views/home/progress_card.dart
// "My Progress" card shown on the Home page below today's symptom card.
// Compares user's first-ever RAPID3 log to their current score.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/services/progress_service.dart';

class MyProgressCard extends StatelessWidget {
  final ProgressSummary progress;
  const MyProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final delta       = progress.delta;
    final isImproved  = progress.isImproved;
    final isWorsened  = progress.isWorsened;

    final firstColor   = AppTierHelper.color(progress.firstTier);
    final currentColor = AppTierHelper.color(progress.currentTier);

    // Arrow/trend color
    final trendColor = isImproved
        ? AppColors.tierRemission
        : isWorsened
            ? AppColors.tierHigh
            : AppColors.tierModerate;

    final trendIcon = isImproved
        ? Icons.trending_down_rounded
        : isWorsened
            ? Icons.trending_up_rounded
            : Icons.trending_flat_rounded;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border:       Border.all(
            color: trendColor.withOpacity(0.25), width: 1.5),
        boxShadow: AppShadows.card(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color:        trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.show_chart_rounded,
                    size: 16, color: trendColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Progress',
                        style: AppTextStyles.cardTitle()),
                    Text('Since ${_fmtDate(progress.firstDate)}',
                        style: AppTextStyles.caption()
                            .copyWith(fontSize: 10)),
                  ],
                ),
              ),
              // Response badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                      color: trendColor.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(progress.responseEmoji,
                      style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(progress.responseLabel,
                      style: AppTextStyles.labelCaps().copyWith(
                          color: trendColor, fontSize: 9)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.base),

          // ── Score comparison row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base),
            child: Row(
              children: [
                // First score
                Expanded(child: _ScoreBlock(
                  label:  'First Entry',
                  date:   _fmtDate(progress.firstDate),
                  score:  progress.firstScore,
                  tier:   progress.firstTier,
                  color:  firstColor,
                  isFirst: true,
                )),

                // Arrow + delta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 28),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: trendColor.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          delta >= 0
                              ? '−${delta.abs().toStringAsFixed(1)}'
                              : '+${delta.abs().toStringAsFixed(1)}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: trendColor,
                              fontFamily: 'Roboto'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Current score
                Expanded(child: _ScoreBlock(
                  label:   'Today',
                  date:    progress.currentDate != null
                      ? _fmtDate(progress.currentDate!)
                      : 'Latest',
                  score:   progress.currentScore,
                  tier:    progress.currentTier,
                  color:   currentColor,
                  isFirst: false,
                )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base),
            child: _ProgressBar(
              firstScore:   progress.firstScore,
              currentScore: progress.currentScore,
              firstColor:   firstColor,
              currentColor: currentColor,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Stats strip ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0,
                AppSpacing.base, AppSpacing.base),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color:        AppColors.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon:  Icons.calendar_today_rounded,
                  label: 'Tracking',
                  value: progress.durationLabel,
                ),
                _Divider(),
                _StatItem(
                  icon:  Icons.edit_note_rounded,
                  label: 'Logs',
                  value: '${progress.totalLogs}',
                ),
                _Divider(),
                _StatItem(
                  icon:  trendIcon,
                  label: 'Change',
                  value: delta >= 0
                      ? '−${delta.abs().toStringAsFixed(1)}'
                      : '+${delta.abs().toStringAsFixed(1)}',
                  valueColor: trendColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${mo[dt.month - 1]} ${dt.year}';
  }
}

// ── Score block (left = first, right = current) ───────────────────────────────
class _ScoreBlock extends StatelessWidget {
  final String label, date, tier;
  final double score;
  final Color  color;
  final bool   isFirst;
  const _ScoreBlock({
    required this.label, required this.date,
    required this.score, required this.tier,
    required this.color, required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: isFirst
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(label,
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(date,
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(score.toStringAsFixed(1),
              style: AppTextStyles.scoreMedium(color)
                  .copyWith(fontSize: 26, height: 1)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              tier[0] + tier.substring(1).toLowerCase(),
              style: TextStyle(
                  color: color, fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dual progress bar showing first vs current position ──────────────────────
class _ProgressBar extends StatelessWidget {
  final double firstScore, currentScore;
  final Color  firstColor, currentColor;
  const _ProgressBar({
    required this.firstScore, required this.currentScore,
    required this.firstColor, required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    const maxScore = 30.0; // RAPID3 max
    final firstPct   = (firstScore   / maxScore).clamp(0.0, 1.0);
    final currentPct = (currentScore / maxScore).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('0',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
          const Spacer(),
          Text('RAPID3 Score (max 30)',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
          const Spacer(),
          Text('30',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth;
          return Stack(children: [
            // Track
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.bgSection,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            // First score marker (faded)
            Positioned(
              left: (firstPct * w).clamp(0.0, w - 12),
              child: Container(
                width: 12, height: 10,
                decoration: BoxDecoration(
                  color: firstColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            // Current score fill
            FractionallySizedBox(
              widthFactor: currentPct,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    currentColor.withOpacity(0.5),
                    currentColor,
                  ]),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ]);
        }),
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: firstColor.withOpacity(0.4),
                  shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('First: ${firstScore.toStringAsFixed(1)}',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: currentColor, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('Now: ${currentScore.toStringAsFixed(1)}',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
        ]),
      ],
    );
  }
}

// ── Stat item in the bottom strip ────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color?   valueColor;
  const _StatItem({
    required this.icon, required this.label,
    required this.value, this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.textMuted),
      const SizedBox(height: 3),
      Text(value,
          style: AppTextStyles.cardTitle().copyWith(
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary)),
      Text(label,
          style: AppTextStyles.caption()
              .copyWith(fontSize: 9, color: AppColors.textMuted)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32, color: AppColors.border);
}