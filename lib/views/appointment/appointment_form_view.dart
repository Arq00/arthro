// lib/views/appointment/appointment_form_view.dart
//
// Add / Edit appointment form.
// isHistory=true → shows only post-notes field (mark done flow).

import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/appointment_controller.dart';
import '../../models/appointment_model.dart';

class AppointmentFormView extends StatefulWidget {
  final Appointment? appointment;
  final bool isHistory;
  const AppointmentFormView(
      {super.key, this.appointment, this.isHistory = false});

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _personCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _preNotesCtrl;
  late TextEditingController _postNotesCtrl;

  DateTime _selectedDateTime =
      DateTime.now().add(const Duration(hours: 1));
  int  _reminderMinutes = 60;
  bool _saving          = false;
  bool _submitAttempted = false;

  static const _reminderOptions = [
    {'label': '5 minutes before',  'value': 5},
    {'label': '15 minutes before', 'value': 15},
    {'label': '30 minutes before', 'value': 30},
    {'label': '1 hour before',     'value': 60},
    {'label': '1 day before',      'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _titleCtrl    = TextEditingController(text: a?.title           ?? '');
    _personCtrl   = TextEditingController(text: a?.personInCharge  ?? '');
    _locationCtrl = TextEditingController(text: a?.location        ?? '');
    _preNotesCtrl = TextEditingController(text: a?.preNotes        ?? '');
    _postNotesCtrl= TextEditingController(text: a?.postNotes       ?? '');
    if (a != null) _selectedDateTime = a.dateTime;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _personCtrl.dispose();
    _locationCtrl.dispose(); _preNotesCtrl.dispose();
    _postNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context:     context,
      initialDate: _selectedDateTime,
      firstDate:   DateTime.now(),
      lastDate:    DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    setState(() => _submitAttempted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ctrl = context.read<AppointmentController>();

      if (widget.isHistory) {
        await ctrl.markAsDone(widget.appointment!.id,
            postNotes: _postNotesCtrl.text.trim());
      } else if (widget.appointment != null) {
        // Edit existing
        await ctrl.updateAppointment(
          widget.appointment!.copyWith(
            title:          _titleCtrl.text.trim(),
            personInCharge: _personCtrl.text.trim(),
            location:       _locationCtrl.text.trim(),
            dateTime:       _selectedDateTime,
            preNotes:       _preNotesCtrl.text.trim(),
          ),
          _reminderMinutes,
        );
      } else {
        // Add new
        await ctrl.addAppointment(
          title:           _titleCtrl.text.trim(),
          personInCharge:  _personCtrl.text.trim(),
          location:        _locationCtrl.text.trim(),
          dateTime:        _selectedDateTime,
          preNotes:        _preNotesCtrl.text.trim(),
          reminderMinutes: _reminderMinutes,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final isEdit    = widget.appointment != null && !widget.isHistory;
    final isHistory = widget.isHistory;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon:  const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHistory
                  ? 'POST NOTES'
                  : isEdit
                      ? 'EDIT APPOINTMENT'
                      : 'NEW APPOINTMENT',
              style: AppTextStyles.labelCaps(),
            ),
            Text(
              isHistory
                  ? widget.appointment!.title
                  : isEdit
                      ? 'Update details'
                      : 'Schedule a visit',
              style: AppTextStyles.sectionTitle(),
            ),
          ],
        ),
      ),
      body: Form(
        key:              _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [

            // ════════════════════════════════════
            // POST-NOTES ONLY (history mode)
            // ════════════════════════════════════
            if (isHistory) ...[
              SectionHeader(
                title:    'Post-Appointment Notes',
                subtitle: 'How did it go? Any follow-ups or changes?',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: TextFormField(
                  controller: _postNotesCtrl,
                  minLines:   5,
                  maxLines:   10,
                  style:      AppTextStyles.body(),
                  decoration: const InputDecoration(
                    hintText:           'e.g. Doctor adjusted MTX dose. Next visit in 3 months.',
                    alignLabelWithHint: true,
                    border:             InputBorder.none,
                  ),
                ),
              ),
            ],

            // ════════════════════════════════════
            // FULL FORM (add / edit)
            // ════════════════════════════════════
            if (!isHistory) ...[

              // ── 1. Details ──
              SectionHeader(
                  title: 'Appointment Details',
                  subtitle: '* Required'),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(children: [

                  // Title *
                  TextFormField(
                    controller:         _titleCtrl,
                    textCapitalization: TextCapitalization.words,
                    style:              AppTextStyles.cardTitle(),
                    decoration: const InputDecoration(
                      labelText:  'Appointment title *',
                      prefixIcon: Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Doctor / specialist
                  TextFormField(
                    controller:         _personCtrl,
                    textCapitalization: TextCapitalization.words,
                    style:              AppTextStyles.cardTitle(),
                    decoration: const InputDecoration(
                      labelText:  'Doctor / Specialist (optional)',
                      hintText:   'e.g. Dr. Sarah Lee, Rheumatologist',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location
                  TextFormField(
                    controller:         _locationCtrl,
                    textCapitalization: TextCapitalization.words,
                    style:              AppTextStyles.cardTitle(),
                    decoration: const InputDecoration(
                      labelText:  'Location (optional)',
                      hintText:   'e.g. Hospital Kuala Lumpur, Ward 5',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── 2. Schedule ──
              SectionHeader(
                  title:    'Schedule *',
                  subtitle: 'Date, time and reminder'),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(children: [

                  // Date & time picker tile
                  InkWell(
                    onTap:        _pickDateTime,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      child: Row(children: [
                        const Icon(Icons.event_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date & Time *',
                                  style: AppTextStyles.cardTitle()),
                              const SizedBox(height: 2),
                              Text(_fmtDateTime(_selectedDateTime),
                                  style: AppTextStyles.caption()
                                      .copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textMuted),
                      ]),
                    ),
                  ),

                  const Divider(color: AppColors.divider, height: 1),

                  // Reminder dropdown
                  DropdownButtonFormField<int>(
                    value: _reminderMinutes,
                    style: AppTextStyles.cardTitle(),
                    decoration: const InputDecoration(
                      labelText:  'Reminder',
                      prefixIcon: Icon(Icons.notifications_outlined,
                          color: AppColors.primary, size: 20),
                      border:     InputBorder.none,
                    ),
                    items: _reminderOptions
                        .map((e) => DropdownMenuItem<int>(
                              value: e['value'] as int,
                              child: Text(e['label'] as String,
                                  style: AppTextStyles.body()),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _reminderMinutes = v!),
                  ),
                ]),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── 3. Pre-appointment notes ──
              SectionHeader(
                title:    'Before Appointment',
                subtitle: 'Things to tell your doctor, questions to ask',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: TextFormField(
                  controller: _preNotesCtrl,
                  minLines:   3,
                  maxLines:   6,
                  style:      AppTextStyles.body(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ask about adjusting MTX dose, '
                        'report increased morning stiffness...',
                    alignLabelWithHint: true,
                    border:             InputBorder.none,
                  ),
                ),
              ),

              // ── RA tip box ──
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip for RA patients: Note your pain level, '
                        'morning stiffness duration, and any new swollen '
                        'joints before your visit. This helps your doctor '
                        'track disease activity accurately.',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            AppButton(
              label: isHistory
                  ? '💾  Save Notes'
                  : isEdit
                      ? '💾  Save Changes'
                      : '📅  Schedule Appointment',
              loading: _saving,
              onTap:   _save,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}