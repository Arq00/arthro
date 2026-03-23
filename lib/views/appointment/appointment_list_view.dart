// lib/views/appointment/appointment_list_view.dart
//
// Upcoming appointments tab.
// RA-focused: shows doctor/specialist name prominently, countdown to appointment,
// pre-notes, quick "Mark Done" action.

import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment_model.dart';
import 'appointment_form_view.dart';

class AppointmentListView extends StatelessWidget {
  const AppointmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appts = context.watch<AppointmentController>().upcomingAppointments;

    if (appts.isEmpty) return _EmptyUpcoming();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.base, AppSpacing.base, 100),
      children: [

        // ── Next appointment hero ──────────────────────────────────
        _NextAppointmentCard(appt: appts.first),

        if (appts.length > 1) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                0, AppSpacing.xl, 0, AppSpacing.sm),
            child: Text('COMING UP', style: AppTextStyles.labelCaps()),
          ),
          ...appts.skip(1).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AppointmentCard(appt: a),
              )),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXT APPOINTMENT HERO CARD  (first / most urgent)
// ─────────────────────────────────────────────────────────────────────────────
class _NextAppointmentCard extends StatelessWidget {
  final Appointment appt;
  const _NextAppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final countdown = _countdownLabel(appt.dateTime);
    final isToday   = _isToday(appt.dateTime);
    final isTomorrow = _isTomorrow(appt.dateTime);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F2D), Color(0xFF1B3A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.elevated(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Top row: label + countdown badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday
                      ? '📅 TODAY'
                      : isTomorrow
                          ? '📅 TOMORROW'
                          : '📅 NEXT APPOINTMENT',
                  style: TextStyle(
                    fontFamily:    'PlusJakartaSans',
                    fontSize:      11,
                    fontWeight:    FontWeight.w700,
                    color:         Colors.white.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isToday ? AppColors.tierHigh : AppColors.tierLow)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color:
                          (isToday ? AppColors.tierHigh : AppColors.tierLow)
                              .withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    countdown,
                    style: TextStyle(
                      fontFamily:  'PlusJakartaSans',
                      fontSize:    11,
                      fontWeight:  FontWeight.w700,
                      color: isToday
                          ? AppColors.tierHigh
                          : AppColors.tierLow,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              appt.title,
              style: const TextStyle(
                fontFamily:    'Syne',
                fontSize:      20,
                fontWeight:    FontWeight.w800,
                color:         Colors.white,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 6),

            // Doctor / specialist
            if (appt.personInCharge.isNotEmpty)
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 5),
                Text(
                  appt.personInCharge,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize:   13,
                    color:      Colors.white.withOpacity(0.7),
                  ),
                ),
              ]),

            const SizedBox(height: 4),

            // Date + time
            Row(children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: Colors.white54),
              const SizedBox(width: 5),
              Text(
                _fmtDateTime(appt.dateTime),
                style: TextStyle(
                  fontFamily:  'PlusJakartaSans',
                  fontSize:    13,
                  color:       Colors.white.withOpacity(0.7),
                ),
              ),
            ]),

            // Location
            if (appt.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    appt.location,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize:   13,
                      color:      Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],

            // Pre-notes
            if (appt.preNotes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appt.preNotes,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize:   12,
                          color:      Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.base),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Actions
            Row(children: [
              _HeroAction(
                icon:  Icons.edit_outlined,
                label: 'Edit',
                onTap: () => _goEdit(context, appt),
              ),
              _HeroAction(
                icon:  Icons.check_circle_outline_rounded,
                label: 'Mark Done',
                color: AppColors.tierRemission,
                onTap: () => _markDoneSheet(context, appt),
              ),
              _HeroAction(
                icon:  Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.tierHigh,
                onTap: () => _deleteDialog(context, appt),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _goEdit(BuildContext context, Appointment appt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AppointmentController>(),
          child: AppointmentFormView(appointment: appt),
        ),
      ),
    );
  }

  void _markDoneSheet(BuildContext context, Appointment appt) {
    _showMarkDoneSheet(context, appt);
  }

  void _deleteDialog(BuildContext context, Appointment appt) {
    _showDeleteDialog(context, appt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPCOMING APPOINTMENT CARD  (subsequent items)
// ─────────────────────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  const _AppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final daysAway = appt.dateTime.difference(DateTime.now()).inDays;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: [

        Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Date block
              Container(
                width: 48, height: 54,
                decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appt.dateTime.day.toString(),
                      style: AppTextStyles.sectionTitle().copyWith(
                          color: AppColors.primary, height: 1),
                    ),
                    Text(
                      _monthShort(appt.dateTime.month),
                      style: AppTextStyles.labelCaps()
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.title, style: AppTextStyles.cardTitle()),
                    const SizedBox(height: 3),
                    if (appt.personInCharge.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(appt.personInCharge,
                            style: AppTextStyles.caption()),
                      ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(_fmtTime(appt.dateTime),
                          style: AppTextStyles.caption()),
                      if (appt.location.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(appt.location,
                              style: AppTextStyles.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ]),
                    if (appt.preNotes.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        appt.preNotes,
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Days away badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  daysAway == 0
                      ? 'Today'
                      : daysAway == 1
                          ? 'Tomorrow'
                          : 'In $daysAway days',
                  style: AppTextStyles.labelCaps()
                      .copyWith(color: AppColors.primary, fontSize: 9),
                ),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.divider, height: 1),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(children: [
            _CardAction(
              icon:  Icons.edit_outlined,
              label: 'Edit',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<AppointmentController>(),
                    child: AppointmentFormView(appointment: appt),
                  ),
                ),
              ),
            ),
            _CardAction(
              icon:  Icons.check_circle_outline_rounded,
              label: 'Mark Done',
              color: AppColors.tierRemission,
              onTap: () => _showMarkDoneSheet(context, appt),
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
// MARK DONE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
void _showMarkDoneSheet(BuildContext context, Appointment appt) {
  final notesCtrl = TextEditingController(text: appt.postNotes);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left:   AppSpacing.base,
        right:  AppSpacing.base,
        top:    AppSpacing.base,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              decoration: BoxDecoration(
                  color:        AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Mark as Done', style: AppTextStyles.sectionTitle()),
          const SizedBox(height: 4),
          Text(appt.title,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.base),
          Text('Post-appointment notes (optional)',
              style: AppTextStyles.label()),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller:  notesCtrl,
            maxLines:    4,
            style:       AppTextStyles.body(),
            decoration: InputDecoration(
              hintText:    'How did it go? Any follow-ups?',
              hintStyle:   AppTextStyles.caption(),
              filled:      true,
              fillColor:   AppColors.bgSection,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide:   BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tierRemission),
                onPressed: () async {
                  Navigator.pop(ctx);
                  context
                      .read<AppointmentController>()
                      .markAsDone(appt.id,
                          postNotes: notesCtrl.text.trim());
                },
                child: const Text('Confirm Done'),
              ),
            ),
          ]),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE DIALOG  — reads controller fresh from context, never stale
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
class _EmptyUpcoming extends StatelessWidget {
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
              child: Text('📅', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('No upcoming appointments',
            style: AppTextStyles.sectionTitle()),
        const SizedBox(height: 4),
        Text('Tap + to schedule one.',
            style: AppTextStyles.caption()),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _HeroAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _HeroAction({
    required this.icon, required this.label,
    this.color = Colors.white70, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      icon:  Icon(icon, size: 15, color: color),
      label: Text(label,
          style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize:   12,
              color:      color)),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6)),
      onPressed: onTap,
    ),
  );
}

class _CardAction extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
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
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
      onPressed: onTap,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

bool _isTomorrow(DateTime d) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return d.year == tomorrow.year &&
      d.month == tomorrow.month &&
      d.day == tomorrow.day;
}

String _countdownLabel(DateTime d) {
  if (_isToday(d)) {
    final diff = d.difference(DateTime.now());
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    return 'In ${diff.inHours}h';
  }
  if (_isTomorrow(d)) return 'Tomorrow';
  final days = d.difference(DateTime.now()).inDays;
  return 'In $days days';
}

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

String _fmtTime(DateTime d) {
  final h   = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final min = d.minute.toString().padLeft(2, '0');
  final per = d.hour < 12 ? 'AM' : 'PM';
  return '$h:$min $per';
}

String _monthShort(int m) {
  const months = [
    'JAN','FEB','MAR','APR','MAY','JUN',
    'JUL','AUG','SEP','OCT','NOV','DEC'
  ];
  return months[m - 1];
}