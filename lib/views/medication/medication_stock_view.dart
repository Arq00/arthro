// lib/views/medication/medication_list_view.dart

import 'package:arthro/views/medication/medication_add_form.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/medication_controller.dart';
import '../../models/medication_model.dart';

class MedicationListView extends StatelessWidget {
  const MedicationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationController>().medications;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicationAddView()),
        ),
      ),
      body: meds.isEmpty
          ? _EmptyMedList()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.base, AppSpacing.base, 100),
              itemCount: meds.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              // Pass only the medication — controller is read inside the card
              itemBuilder: (_, i) => _MedicationCard(med: meds[i]),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDICATION CARD
// No stored controller reference — always reads fresh from context.read<>()
// ─────────────────────────────────────────────────────────────────────────────
class _MedicationCard extends StatelessWidget {
  final Medication med;
  const _MedicationCard({required this.med});

  double get _stockPct => med.stockMax > 0 ? med.stockCurrent / med.stockMax : 0;

  Color get _stockColor {
    if (med.isOutOfStock) return AppColors.tierHigh;
    if (med.isLowStock)   return AppColors.tierLow;
    return AppColors.tierRemission;
  }

  String get _endDateLabel {
    if (med.endDate == null) return 'Ongoing';
    final d = med.endDate!;
    return '${d.day}/${d.month}/${d.year}';
  }

  String _medEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':    return '💊';
      case 'capsule':   return '💊';
      case 'liquid':    return '🧴';
      case 'injection': return '💉';
      default:          return '💊';
    }
  }

  String _frequencyLabel() {
    if (med.frequency == 'Weekly' && med.weeklyDays.isNotEmpty) {
      const short = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      final days = (List<int>.from(med.weeklyDays)..sort())
          .map((d) => short[d - 1])
          .join(' ');
      return 'Weekly ($days)';
    }
    return med.frequency;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      color: med.isOutOfStock
          ? AppColors.tierHighBg.withOpacity(0.5)
          : med.isLowStock
              ? AppColors.tierHighBg.withOpacity(0.3)
              : AppColors.bgCard,
      child: Column(children: [

        // ── Main info ──
        Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: med.isLowStock || med.isOutOfStock
                    ? AppColors.tierHighBg
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(_medEmoji(med.medicationType),
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(med.name, style: AppTextStyles.cardTitle()),
                const SizedBox(height: 3),
                Text(
                  '${med.dosage.isNotEmpty ? med.dosage + "  ·  " : ""}${med.medicationType}',
                  style: AppTextStyles.caption(),
                ),
                const SizedBox(height: 7),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _Chip(_frequencyLabel(), AppColors.primary),
                  if (med.mealTiming != 'Any Time')
                    _Chip(med.mealTiming, AppColors.textSecondary),
                  _Chip(_endDateLabel, AppColors.textMuted),
                  if (med.perDose > 1)
                    _Chip('${med.perDose}×/dose', AppColors.textSecondary),
                  if (med.knownSideEffects.isNotEmpty)
                    _Chip('${med.knownSideEffects.length} side effects tracked',
                        AppColors.tierLow),
                ]),
              ]),
            ),
          ]),
        ),

        const Divider(color: AppColors.divider, height: 1),

        // ── Stock bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.sm),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('STOCK', style: AppTextStyles.labelCaps()),
              Text('${med.stockCurrent} / ${med.stockMax}',
                  style: AppTextStyles.label().copyWith(
                      color: _stockColor, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value:           _stockPct.clamp(0.0, 1.0),
                minHeight:       6,
                backgroundColor: AppColors.bgSection,
                valueColor:      AlwaysStoppedAnimation<Color>(_stockColor),
              ),
            ),
            if (med.isOutOfStock) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.block_rounded, size: 13, color: AppColors.tierHigh),
                const SizedBox(width: 4),
                Text('Out of stock — reminders still active',
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.tierHigh)),
              ]),
            ] else if (med.isLowStock) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 13, color: AppColors.tierLow),
                const SizedBox(width: 4),
                Text('Low stock — consider refilling soon',
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.tierLow)),
              ]),
            ],
          ]),
        ),

        const Divider(color: AppColors.divider, height: 1),

        // ── Actions ──
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(children: [
            _TextAction(
              icon:  Icons.info_outline_rounded,
              label: 'Info',
              color: AppColors.primary,
              onTap: () => _showInfoSheet(context),
            ),
            _TextAction(
              icon:  Icons.edit_outlined,
              label: 'Edit',
              color: AppColors.tierLow,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MedicationAddView(medicationToEdit: med)),
              ),
            ),
            _TextAction(
              icon:  Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.tierHigh,
              onTap: () => _showDeleteDialog(context),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Info sheet ─────────────────────────────────────────────────────────────
  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.base),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(med.name, style: AppTextStyles.sectionTitle()),
              const SizedBox(height: AppSpacing.base),
              const Divider(color: AppColors.divider),
              if (med.dosage.isNotEmpty)
                InfoRow(label: 'Dosage', value: med.dosage),
              InfoRow(label: 'Type',        value: med.medicationType),
              InfoRow(label: 'Frequency',   value: _frequencyLabel()),
              InfoRow(label: 'Meal Timing', value: med.mealTiming),
              InfoRow(label: 'Per dose',    value: '${med.perDose} unit(s)'),
              InfoRow(
                label: 'Stock',
                value: '${med.stockCurrent} / ${med.stockMax}',
                valueColor: med.isLowStock
                    ? AppColors.tierHigh
                    : AppColors.textPrimary,
              ),
              InfoRow(
                label: 'Start date',
                value:
                    '${med.startDate.day}/${med.startDate.month}/${med.startDate.year}',
              ),
              InfoRow(
                label: 'End date',
                value: med.endDate != null
                    ? '${med.endDate!.day}/${med.endDate!.month}/${med.endDate!.year}'
                    : 'Ongoing',
              ),
              if (med.knownSideEffects.isNotEmpty) ...[
                const Divider(color: AppColors.divider),
                Text('Side Effects to Watch', style: AppTextStyles.label()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: med.knownSideEffects
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tierHighBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(e,
                                style: AppTextStyles.caption()
                                    .copyWith(color: AppColors.tierHigh)),
                          ))
                      .toList(),
                ),
              ],
              if (med.description.isNotEmpty) ...[
                const Divider(color: AppColors.divider),
                Text('Notes', style: AppTextStyles.label()),
                const SizedBox(height: 4),
                Text(med.description, style: AppTextStyles.caption()),
              ],
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete dialog ──────────────────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete medication?', style: AppTextStyles.sectionTitle()),
        content: Text(
          'This will permanently remove ${med.name} and all its logs.',
          style: AppTextStyles.bodySmall(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppTextStyles.buttonSecondary()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tierHigh,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              // Close dialog immediately
              Navigator.pop(dialogCtx);
              // Read controller fresh from the list view's context — never stale
              context.read<MedicationController>().deleteMedication(med.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(label,
        style: AppTextStyles.labelCaps().copyWith(color: color)),
  );
}

class _TextAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _TextAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      icon:  Icon(icon, size: 16, color: color),
      label: Text(label,
          style: AppTextStyles.label().copyWith(color: color)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      onPressed: onTap,
    ),
  );
}

class _EmptyMedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: AppColors.primarySurface, shape: BoxShape.circle),
          child: const Center(
              child: Text('💊', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('No medications added', style: AppTextStyles.sectionTitle()),
        const SizedBox(height: 4),
        Text('Tap + to add your first medication.',
            style: AppTextStyles.caption()),
      ],
    ),
  );
}