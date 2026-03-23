// lib/views/medication/medication_add_view.dart
//
// Required: name *, per dose *, frequency *, start date *
// Optional: dosage, notes, end date, evening time, side effects
// Reminder OFF → "Anytime Today" behaviour explained inline.

import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/medication_controller.dart';
import '../../models/medication_model.dart';

class MedicationAddView extends StatefulWidget {
  final Medication? medicationToEdit;
  const MedicationAddView({super.key, this.medicationToEdit});

  @override
  State<MedicationAddView> createState() => _MedicationAddViewState();
}

class _MedicationAddViewState extends State<MedicationAddView> {
  // ── IMPORTANT: single GlobalKey — never recreate it ──
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _dosageCtrl;   // optional
  late TextEditingController _stockCtrl;
  late TextEditingController _maxStockCtrl;
  late TextEditingController _descCtrl;
  final TextEditingController _customSideEffectCtrl = TextEditingController();

  late String       _frequency;
  late String       _medType;
  late String       _mealTiming;
  late bool         _reminderOn;
  late TimeOfDay    _reminderTime;
  TimeOfDay?        _eveningReminderTime;
  late int          _perDose;       // required — validated via dropdown (always has a value)
  late List<int>    _weeklyDays;
  late List<String> _sideEffects;

  late DateTime _startDate;
  DateTime?     _endDate;
  bool          _noEndDate = true;
  bool          _saving    = false;

  // Track whether user attempted to submit — shows weekly-day inline error
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    final m = widget.medicationToEdit;
    _nameCtrl     = TextEditingController(text: m?.name ?? '');
    _dosageCtrl   = TextEditingController(text: m?.dosage ?? '');
    _stockCtrl    = TextEditingController(text: (m?.stockCurrent ?? 0).toString());
    _maxStockCtrl = TextEditingController(text: (m?.stockMax ?? 30).toString());
    _descCtrl     = TextEditingController(text: m?.description ?? '');

    _frequency           = m?.frequency      ?? 'Daily';
    _medType             = m?.medicationType ?? 'Tablet';
    _mealTiming          = m?.mealTiming     ?? 'Any Time';
    _reminderOn          = m?.isReminderOn   ?? true;
    _reminderTime        = m?.reminderTime   ?? const TimeOfDay(hour: 9, minute: 0);
    _eveningReminderTime = m?.eveningReminderTime;
    _perDose             = m?.perDose        ?? 1;
    _weeklyDays          = List<int>.from(m?.weeklyDays         ?? []);
    _sideEffects         = List<String>.from(m?.knownSideEffects ?? []);
    _startDate           = m?.startDate      ?? DateTime.now();
    _endDate             = m?.endDate;
    _noEndDate           = m?.endDate == null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _dosageCtrl.dispose();
    _stockCtrl.dispose(); _maxStockCtrl.dispose();
    _descCtrl.dispose(); _customSideEffectCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final per = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$min $per';
  }

  Future<void> _save() async {
  setState(() => _submitAttempted = true);
  final formValid = _formKey.currentState!.validate();
  final weeklyValid = _frequency != 'Weekly' || _weeklyDays.isNotEmpty;
  if (!formValid || !weeklyValid) {
    if (!weeklyValid && formValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select at least one day for Weekly.'),
        backgroundColor: AppColors.tierHigh,
        behavior: SnackBarBehavior.floating,
      ));
    }
    return;
  }

  setState(() => _saving = true);

  try {
    final ctrl = context.read<MedicationController>();
    final med = Medication(
      id: widget.medicationToEdit?.id ?? '',
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      frequency: _frequency,
      medicationType: _medType,
      mealTiming: _mealTiming,
      stockCurrent: int.tryParse(_stockCtrl.text) ?? 0,
      stockMax: int.tryParse(_maxStockCtrl.text) ?? 30,
      perDose: _perDose,
      isReminderOn: _reminderOn,
      reminderTime: _reminderTime,
      eveningReminderTime: _frequency == 'Twice Daily' ? _eveningReminderTime : null,
      weeklyDays: _frequency == 'Weekly' ? _weeklyDays : [],
      knownSideEffects: _sideEffects,
      description: _descCtrl.text.trim(),
      startDate: _startDate,
      endDate: _noEndDate ? null : _endDate,
      firstTaken: widget.medicationToEdit?.firstTaken,
      lastTaken: widget.medicationToEdit?.lastTaken,
    );

    if (widget.medicationToEdit != null) {
      await ctrl.updateMedication(med);
    } else {
      await ctrl.addMedication(med);
    }

    if (mounted) Navigator.pop(context);
  } catch (e) {
    debugPrint('[MedicationAddView] Save error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving: $e'),
        backgroundColor: AppColors.tierHigh,
        behavior: SnackBarBehavior.floating,
      ));
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicationToEdit != null;

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
            Text(isEdit ? 'EDIT MEDICATION' : 'NEW MEDICATION',
                style: AppTextStyles.labelCaps()),
            Text(isEdit ? 'Update details' : 'Add to your schedule',
                style: AppTextStyles.sectionTitle()),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        // autovalidateMode: disabled by default — only validate on submit tap
        // (individual fields use validator functions that run on _formKey.currentState!.validate())
        autovalidateMode: AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [

            // ══════════════════════════════════════════
            // 1. MEDICATION INFO
            // ══════════════════════════════════════════
            SectionHeader(
              title:    'Medication Info',
              subtitle: '* Required fields',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(children: [

                // ── Medicine name * ──
                TextFormField(
                  controller:         _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style:              AppTextStyles.cardTitle(),
                  decoration: InputDecoration(
                    labelText: 'Medicine name *',
                    prefixIcon: const Icon(Icons.medication_outlined,
                        color: AppColors.primary, size: 20),
                    // Show error styling even before first tap
                    errorStyle: TextStyle(color: AppColors.tierHigh),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Medicine name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Dosage (optional) ──
                TextFormField(
                  controller: _dosageCtrl,
                  style:      AppTextStyles.cardTitle(),
                  decoration: const InputDecoration(
                    labelText:  'Dosage (optional — e.g. 500mg)',
                    prefixIcon: Icon(Icons.scale_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                  // No validator — optional
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Type + Per dose * ──
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value:      _medType,
                      style:      AppTextStyles.cardTitle(),
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['Tablet', 'Capsule', 'Liquid', 'Injection']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _medType = v!),
                      // No validator — always has a value
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Per dose * — required, but dropdown always has a value (1-10)
                  // Label shows * to signal importance
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value:      _perDose,
                      style:      AppTextStyles.cardTitle(),
                      decoration: const InputDecoration(
                        labelText: 'Per dose *',
                        helperText: 'Units per intake',
                        helperStyle: TextStyle(fontSize: 10),
                      ),
                      items: List.generate(10, (i) => i + 1)
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e unit${e > 1 ? 's' : ''}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _perDose = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),

                // ── Notes (optional) ──
                TextFormField(
                  controller: _descCtrl,
                  minLines: 2, maxLines: 4,
                  style: AppTextStyles.body(),
                  decoration: const InputDecoration(
                    labelText:          'Notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ══════════════════════════════════════════
            // 2. TREATMENT SCHEDULE *
            // ══════════════════════════════════════════
            SectionHeader(
              title:    'Treatment Schedule *',
              subtitle: 'How often and from when?',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Frequency *
                  DropdownButtonFormField<String>(
                    value:      _frequency,
                    style:      AppTextStyles.cardTitle(),
                    decoration: const InputDecoration(labelText: 'Frequency *'),
                    items: ['Daily', 'Twice Daily', 'Weekly']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _frequency = v!;
                      _weeklyDays.clear(); // reset days on frequency change
                    }),
                    validator: (v) =>
                        v == null ? 'Please select a frequency' : null,
                  ),

                  // Weekly day picker (shown only for Weekly)
                  if (_frequency == 'Weekly') ...[
                    const SizedBox(height: AppSpacing.base),
                    Row(
                      children: [
                        Text('Which days? *', style: AppTextStyles.cardTitle()),
                        const SizedBox(width: 8),
                        // Inline error shown after submit attempted
                        if (_submitAttempted && _weeklyDays.isEmpty)
                          Text(
                            'Select at least one day',
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.tierHigh),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DayOfWeekPicker(
                      selected:  _weeklyDays,
                      hasError:  _submitAttempted && _weeklyDays.isEmpty,
                      onChanged: (days) => setState(() => _weeklyDays = days),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // Start date *
                  _DateTile(
                    label: 'Start date *',
                    icon:  Icons.calendar_today_outlined,
                    value: _fmtDate(_startDate),
                    onTap: () async {
                      final d = await showDatePicker(
                        context:     context,
                        initialDate: _startDate,
                        firstDate:   DateTime(2020),
                        lastDate:    DateTime(2100),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                  ),
                  const Divider(color: AppColors.divider, height: 1),

                  // Ongoing toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                        child: Text('Ongoing treatment',
                            style: AppTextStyles.cardTitle()),
                      ),
                      Switch(
                        value:       _noEndDate,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() {
                          _noEndDate = v;
                          if (v) _endDate = null;
                        }),
                      ),
                    ]),
                  ),

                  if (!_noEndDate) ...[
                    const Divider(color: AppColors.divider, height: 1),
                    _DateTile(
                      label:     'End date',
                      icon:      Icons.event_busy_outlined,
                      iconColor: AppColors.tierHigh,
                      value: _endDate != null
                          ? _fmtDate(_endDate!)
                          : 'Tap to select',
                      onTap: () async {
                        final d = await showDatePicker(
                          context:     context,
                          initialDate: _endDate ?? _startDate,
                          firstDate:   _startDate,
                          lastDate:    DateTime(2100),
                        );
                        if (d != null) setState(() => _endDate = d);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ══════════════════════════════════════════
            // 3. REMINDER & TIME
            // ══════════════════════════════════════════
            SectionHeader(
              title:    'Reminder & Time',
              subtitle: _reminderOn
                  ? 'Notification fires at the set time. Window is ±30 min.'
                  : 'No reminder — dose shows as "Anytime Today" all day.',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(children: [

                Row(children: [
                  const Icon(Icons.notifications_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminder notification',
                            style: AppTextStyles.cardTitle()),
                        Text(
                          _reminderOn
                              ? 'Fires at set time'
                              : 'Appears as "Anytime Today" all day',
                          style: AppTextStyles.caption(),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value:       _reminderOn,
                    activeColor: AppColors.primary,
                    onChanged:   (v) => setState(() => _reminderOn = v),
                  ),
                ]),

                if (_reminderOn) ...[
                  const Divider(color: AppColors.divider, height: 1),
                  _DateTile(
                    label: _frequency == 'Twice Daily'
                        ? 'Morning reminder time'
                        : 'Reminder time',
                    icon:  Icons.alarm_outlined,
                    value: _fmtTime(_reminderTime),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: context, initialTime: _reminderTime);
                      if (t != null) setState(() => _reminderTime = t);
                    },
                  ),
                  if (_frequency == 'Twice Daily') ...[
                    const Divider(color: AppColors.divider, height: 1),
                    _DateTile(
                      label: 'Evening reminder time',
                      icon:  Icons.nightlight_outlined,
                      value: _eveningReminderTime != null
                          ? _fmtTime(_eveningReminderTime!)
                          : 'Default: ${_fmtTime(TimeOfDay(
                              hour:   (_reminderTime.hour + 8).clamp(0, 23),
                              minute: _reminderTime.minute))}',
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _eveningReminderTime ??
                              TimeOfDay(
                                hour:   (_reminderTime.hour + 8).clamp(0, 23),
                                minute: _reminderTime.minute,
                              ),
                        );
                        if (t != null)
                          setState(() => _eveningReminderTime = t);
                      },
                    ),
                  ],
                ],

                if (!_reminderOn) ...[
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Without a reminder this dose appears in '
                            '"Due Anytime" from midnight of each scheduled day. '
                            'It will not be marked missed until the day ends '
                            'without being logged.',
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ]),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ══════════════════════════════════════════
            // 4. MEAL TIMING
            // ══════════════════════════════════════════
            SectionHeader(
                title: 'Meal Timing',
                subtitle: 'When to take relative to meals'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: _SegmentedPicker(
                options:   const ['Before Meal', 'With Meal', 'After Meal', 'Any Time'],
                selected:  _mealTiming,
                onChanged: (v) => setState(() => _mealTiming = v),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ══════════════════════════════════════════
            // 5. STOCK
            // ══════════════════════════════════════════
            SectionHeader(title: 'Stock', subtitle: 'Units currently on hand'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(children: [
                Expanded(
                  child: TextFormField(
                    controller:   _stockCtrl,
                    keyboardType: TextInputType.number,
                    style:        AppTextStyles.cardTitle(),
                    decoration:   const InputDecoration(
                      labelText:  'Current stock',
                      prefixIcon: Icon(Icons.inventory_2_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Enter a number' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller:   _maxStockCtrl,
                    keyboardType: TextInputType.number,
                    style:        AppTextStyles.cardTitle(),
                    decoration:   const InputDecoration(
                      labelText:  'Max stock',
                      prefixIcon: Icon(Icons.all_inbox_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Enter a number' : null,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ══════════════════════════════════════════
            // 6. SIDE EFFECTS TO WATCH
            // ══════════════════════════════════════════
            SectionHeader(
                title: 'Side Effects to Watch',
                subtitle: 'You\'ll be prompted after each dose.'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: Medication.commonSideEffects.map((effect) {
                      final active = _sideEffects.contains(effect);
                      return GestureDetector(
                        onTap: () => setState(() => active
                            ? _sideEffects.remove(effect)
                            : _sideEffects.add(effect)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.tierHigh.withOpacity(0.12)
                                : AppColors.bgSection,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: active
                                  ? AppColors.tierHigh.withOpacity(0.5)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(effect,
                              style: AppTextStyles.label().copyWith(
                                  color: active
                                      ? AppColors.tierHigh
                                      : AppColors.textSecondary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller:         _customSideEffectCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        style:              AppTextStyles.body(),
                        decoration: const InputDecoration(
                          hintText: 'Add custom side effect...',
                          prefixIcon: Icon(Icons.add_circle_outline_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        onSubmitted: _addCustom,
                      ),
                    ),
                    IconButton(
                      icon:      const Icon(Icons.add_rounded),
                      color:     AppColors.primary,
                      onPressed: () => _addCustom(_customSideEffectCtrl.text),
                    ),
                  ]),
                  if (_sideEffects
                      .any((e) => !Medication.commonSideEffects.contains(e))) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: _sideEffects
                          .where((e) =>
                              !Medication.commonSideEffects.contains(e))
                          .map((effect) => Chip(
                                label:           Text(effect),
                                backgroundColor: AppColors.tierHighBg,
                                side: BorderSide(
                                    color: AppColors.tierHigh.withOpacity(0.3)),
                                deleteIconColor: AppColors.tierHigh,
                                onDeleted: () =>
                                    setState(() => _sideEffects.remove(effect)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Save button ──
            AppButton(
              label:   isEdit ? '💾  Save Changes' : '➕  Add Medication',
              loading: _saving,
              onTap:   _save,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _addCustom(String value) {
    final t = value.trim();
    if (t.isNotEmpty && !_sideEffects.contains(t)) {
      setState(() {
        _sideEffects.add(t);
        _customSideEffectCtrl.clear();
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentedPicker(
      {required this.options, required this.selected, required this.onChanged});

  String _icon(String o) {
    switch (o) {
      case 'Before Meal': return '🍽️';
      case 'With Meal':   return '🥘';
      case 'After Meal':  return '🍵';
      default:            return '⏱️';
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: options.map((opt) {
      final active = opt == selected;
      return GestureDetector(
        onTap: () => onChanged(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.bgSection,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_icon(opt), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(opt,
                style: AppTextStyles.label().copyWith(
                    color: active ? Colors.white : AppColors.textSecondary)),
          ]),
        ),
      );
    }).toList(),
  );
}

class _DayOfWeekPicker extends StatelessWidget {
  final List<int>               selected;
  final bool                    hasError;
  final ValueChanged<List<int>> onChanged;
  const _DayOfWeekPicker(
      {required this.selected, required this.hasError, required this.onChanged});

  static const _short = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _full  = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (i) {
      final day    = i + 1;
      final active = selected.contains(day);
      return Tooltip(
        message: _full[i],
        child: GestureDetector(
          onTap: () {
            final next = List<int>.from(selected);
            active ? next.remove(day) : next.add(day);
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.bgSection,
              shape: BoxShape.circle,
              border: Border.all(
                // Red ring when error state and not yet selected
                color: (!active && hasError)
                    ? AppColors.tierHigh
                    : active
                        ? AppColors.primary
                        : AppColors.border,
                width: (!active && hasError) ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(_short[i],
                  style: AppTextStyles.label().copyWith(
                    color: active
                        ? Colors.white
                        : (!active && hasError)
                            ? AppColors.tierHigh
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                  )),
            ),
          ),
        ),
      );
    }),
  );
}

class _DateTile extends StatelessWidget {
  final String    label, value;
  final IconData  icon;
  final Color     iconColor;
  final VoidCallback onTap;
  const _DateTile({
    required this.label, required this.value,
    required this.icon,  this.iconColor = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap:        onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.cardTitle())),
        Text(value,
            style: AppTextStyles.label().copyWith(color: AppColors.primary)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded,
            size: 16, color: AppColors.textMuted),
      ]),
    ),
  );
}