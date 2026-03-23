// lib/views/report/widgets/day_detail_sheet.dart
// Bottom sheet shown when user taps a row in the daily log table.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/report_model.dart';
import 'package:arthro/widgets/app_theme.dart';

class DayDetailSheet extends StatelessWidget {
  final DailyLogRow row;

  const DayDetailSheet({super.key, required this.row});

  static void show(BuildContext context, DailyLogRow row) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:       (_) => DayDetailSheet(row: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTierHelper.color(row.tier);
    final tierEmoji = AppTierHelper.emoji(row.tier);
    final tierLabel = AppTierHelper.label(row.tier);
    final dateStr   = _fmtDate(row.date);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize:     0.92,
      minChildSize:     0.5,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 0),
              decoration: BoxDecoration(
                color:        AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: AppTextStyles.sectionTitle()),
                        const SizedBox(height: 2),
                        Text('Daily Clinical Summary',
                            style: AppTextStyles.caption()),
                      ],
                    ),
                  ),
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        AppTierHelper.bgColor(row.tier),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border:       Border.all(
                          color: tierColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$tierEmoji ${row.rapid3Score.toStringAsFixed(1)} $tierLabel',
                      style: AppTextStyles.label()
                          .copyWith(color: tierColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color:        AppColors.bgSection,
                        shape:        BoxShape.circle,
                        border:       Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable body
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  _Section(
                    label: 'SYMPTOM BREAKDOWN',
                    children: [
                      _InfoRow('RAPID3 Score',
                          row.rapid3Score.toStringAsFixed(1),
                          valueColor: tierColor),
                      _InfoRow('Pain VAS',
                          '${row.pain.toStringAsFixed(1)}/10'),
                      _InfoRow('Physical Function',
                          '${row.function.toStringAsFixed(1)}/3 avg'),
                      _InfoRow('Patient Global',
                          '${row.globalAssessment.toStringAsFixed(1)}/10'),
                      _InfoRow('Morning Stiffness',
                          row.stiffnessMin == 0
                              ? 'None'
                              : '${row.stiffnessMin} min'),
                      _InfoRow('Stress Level',
                          row.stressLevel == 0
                              ? '—'
                              : '${row.stressLevel.toStringAsFixed(1)}/10'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (row.affectedJoints.isNotEmpty) ...[
                    _Section(
                      label: 'AFFECTED JOINTS',
                      children: [
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: row.affectedJoints
                              .map((j) => _JointChip(joint: j))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  _Section(
                    label: 'MEDICATIONS',
                    children: [
                      _InfoRow('Logged doses', row.medsStatus),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Section(
                    label: 'LIFESTYLE',
                    children: [
                      _InfoRow(
                        row.exerciseName.isEmpty
                            ? '🛏️ Rest day'
                            : '🏃 ${row.exerciseName}',
                        row.exerciseDone ? 'Completed ✓' : 'Not completed',
                        valueColor: row.exerciseDone
                            ? AppColors.tierRemission
                            : AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Actions
                  Row(
                    children: [
                      _ActionBtn(
                        label: 'Copy',
                        icon:  Icons.copy,
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: _buildCopyText()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Share',
                        icon:  Icons.share,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:  AppColors.bgSection,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text('Close',
                                style: AppTextStyles.label()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _buildCopyText() {
    return 'ArthroCare Report — ${_fmtDate(row.date)}\n'
        'RAPID3: ${row.rapid3Score.toStringAsFixed(1)} (${AppTierHelper.label(row.tier)})\n'
        'Pain: ${row.pain.toStringAsFixed(1)}/10  '
        'Function: ${row.function.toStringAsFixed(1)}/3  '
        'Global: ${row.globalAssessment.toStringAsFixed(1)}/10\n'
        'Morning stiffness: ${row.stiffnessMin} min\n'
        'Medications: ${row.medsStatus}\n'
        'Exercise: ${row.exerciseName.isEmpty ? "Rest day" : row.exerciseName}';
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String        label;
  final List<Widget>  children;
  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.labelCaps()),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color:        AppColors.bgSection,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:       Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        child: Column(children: children),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final String  label;
  final String  value;
  final Color?  valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.caption())),
        Text(
          value,
          style: AppTextStyles.cardTitle().copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}

class _JointChip extends StatelessWidget {
  final String joint;
  const _JointChip({required this.joint});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        AppColors.tierHighBg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(
          color: AppColors.tierHigh.withOpacity(0.3)),
    ),
    child: Text(
      _prettyJoint(joint),
      style: AppTextStyles.caption().copyWith(
        color: AppColors.tierHigh,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  String _prettyJoint(String j) {
    return j
        .replaceAll(RegExp(r'([A-Z])'), ' \$1')
        .replaceFirst(' ', '')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _ActionBtn extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:        AppColors.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.label()),
        ],
      ),
    ),
  );
}