// lib/views/appointment/appointment_history_view.dart
//
// Past appointments — searchable, shows post-notes, colour-coded by how long ago.

import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment_model.dart';
import 'appointment_form_view.dart';

class AppointmentHistoryView extends StatefulWidget {
  const AppointmentHistoryView({super.key});

  @override
  State<AppointmentHistoryView> createState() => _AppointmentHistoryViewState();
}

class _AppointmentHistoryViewState extends State<AppointmentHistoryView> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppointmentController>().historyAppointments;
    final filtered = _search.isEmpty
        ? all
        : all.where((a) =>
            a.title.toLowerCase().contains(_search.toLowerCase()) ||
            a.personInCharge.toLowerCase().contains(_search.toLowerCase()) ||
            a.location.toLowerCase().contains(_search.toLowerCase())).toList();

    return Column(children: [

      // ── Search bar ──────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.base,
            AppSpacing.base, AppSpacing.sm),
        child: TextField(
          controller: _searchCtrl,
          style:      AppTextStyles.body(),
          onChanged:  (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText:  'Search by title, doctor or location...',
            hintStyle: AppTextStyles.caption(),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primary, size: 20),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon:      const Icon(Icons.clear_rounded, size: 18),
                    color:     AppColors.textMuted,
                    onPressed: () =>
                        setState(() {
                          _search = '';
                          _searchCtrl.clear();
                        }),
                  )
                : null,
            filled:    true,
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:   const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:   const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:   const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),

      // ── Summary strip ───────────────────────────────────────────
      if (all.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, 0, AppSpacing.base, AppSpacing.md),
          child: Row(children: [
            _StatChip(
              label: '${all.length} total',
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: '${all.where((a) => a.postNotes.isNotEmpty).length} with notes',
              color: AppColors.tierLow,
            ),
          ]),
        ),

      // ── List ────────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? _EmptyHistory(hasSearch: _search.isNotEmpty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, 0, AppSpacing.base, 100),
                itemCount:        filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) =>
                    _HistoryCard(appt: filtered[i]),
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Appointment appt;
  const _HistoryCard({required this.appt});

  // How long ago — colour hint
  Color get _ageColor {
    final days = DateTime.now().difference(appt.dateTime).inDays;
    if (days <= 7)  return AppColors.tierRemission;
    if (days <= 30) return AppColors.tierLow;
    return AppColors.textMuted;
  }

  String get _ageLabel {
    final days = DateTime.now().difference(appt.dateTime).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7)  return '$days days ago';
    if (days < 30) return '${(days / 7).floor()}w ago';
    if (days < 365) return '${(days / 30).floor()}mo ago';
    return '${(days / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [

        Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Completed icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        AppColors.tierRemission.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(
                  child: Icon(Icons.event_available_rounded,
                      size: 20, color: AppColors.tierRemission),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(appt.title,
                              style: AppTextStyles.cardTitle()),
                        ),
                        // Age badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _ageColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _ageLabel,
                            style: AppTextStyles.labelCaps().copyWith(
                                color: _ageColor, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (appt.personInCharge.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(appt.personInCharge,
                            style: AppTextStyles.caption()),
                      ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(_fmtDateTime(appt.dateTime),
                          style: AppTextStyles.caption()),
                    ]),
                    if (appt.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(appt.location,
                              style: AppTextStyles.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Post-notes block
        if (appt.postNotes.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:        AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    appt.postNotes,
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.primary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Divider(color: AppColors.divider, height: 1),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(children: [
            _CardAction(
              icon:  Icons.note_add_outlined,
              label: appt.postNotes.isNotEmpty ? 'Edit Notes' : 'Add Notes',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AppointmentController>(),
                    child: AppointmentFormView(
                        appointment: appt, isHistory: true),
                  ),
                ),
              ),
            ),
            _CardAction(
              icon:  Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.tierHigh,
              onTap: () => _showDeleteDialog(context, appt),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE DIALOG  — always reads controller fresh from context
// ─────────────────────────────────────────────────────────────────────────────
void _showDeleteDialog(BuildContext context, Appointment appt) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text('Delete appointment?',
          style: AppTextStyles.sectionTitle()),
      content: Text(
        'This will permanently remove "${appt.title}".',
        style: AppTextStyles.body(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tierHigh),
          onPressed: () {
            Navigator.pop(dialogCtx);
            context
                .read<AppointmentController>()
                .deleteAppointment(appt.id);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  final bool hasSearch;
  const _EmptyHistory({required this.hasSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: AppColors.bgSection, shape: BoxShape.circle),
          child: const Center(
              child: Icon(Icons.history_rounded,
                  size: 32, color: AppColors.textMuted)),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          hasSearch ? 'No results found' : 'No past appointments',
          style: AppTextStyles.sectionTitle(),
        ),
        const SizedBox(height: 4),
        Text(
          hasSearch
              ? 'Try a different search term.'
              : 'Completed appointments will appear here.',
          style: AppTextStyles.caption(),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(label,
        style: AppTextStyles.labelCaps()
            .copyWith(color: color, fontSize: 10)),
  );
}

class _CardAction extends StatelessWidget {
  final IconData icon; final String label;
  final Color color;   final VoidCallback onTap;
  const _CardAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      icon:  Icon(icon, size: 15, color: color),
      label: Text(label,
          style: AppTextStyles.label().copyWith(color: color)),
      style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
      onPressed: onTap,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtDateTime(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final h   = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final min = d.minute.toString().padLeft(2, '0');
  final per = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day} ${months[d.month - 1]} ${d.year}  ·  $h:$min $per';
}