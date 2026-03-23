// lib/views/health/symptom/morning_stiffness_view.dart
// Step 1c: Morning stiffness duration + weather integration.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import '../../../models/health_model.dart';

class MorningStiffnessView extends StatelessWidget {
  const MorningStiffnessView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.primary,
          onPressed: () => ctrl.goToStep(HealthStep.bodyHeatmap),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 3 OF 3', style: AppTextStyles.labelCaps()),
            Text('Morning Stiffness', style: AppTextStyles.sectionTitle()),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm,
            ),
            child: StepIndicator(total: 3, current: 2),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stiffness card ──
                  SectionHeader(
                    title: 'Morning Stiffness Duration',
                    subtitle: 'How long did stiffness last after waking up?',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StiffnessPicker(
                    value: ctrl.stiffnessMinutes,
                    onChanged: ctrl.setStiffnessMinutes,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Stress level card ──
                  SectionHeader(
                    title: 'Stress Level',
                    subtitle: 'How stressed do you feel in your overall life?',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StressSlider(
                    value: ctrl.stressLevel,
                    onChanged: ctrl.setStressLevel,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'Today\'s Weather',
                    subtitle: 'Weather affects joint stiffness risk',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeatherCard(weather: ctrl.weather, loading: ctrl.weatherLoading),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Summary preview ──
                  _SymptomSummaryCard(ctrl: ctrl),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          _BottomBar(
            onBack: () => ctrl.goToStep(HealthStep.bodyHeatmap),
            onCalculate: ctrl.calculateAndShowResult,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STIFFNESS DURATION PICKER
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// STIFFNESS DURATION PICKER  (Fix 1: custom input)
// ─────────────────────────────────────────────
class _StiffnessPicker extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _StiffnessPicker({required this.value, required this.onChanged});

  @override
  State<_StiffnessPicker> createState() => _StiffnessPickerState();
}

class _StiffnessPickerState extends State<_StiffnessPicker> {
  static const _options = [0, 10, 15, 20, 30, 45, 60, 90, 120];
  bool _showCustom = false;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  String _label(int v) {
    if (v == 0)  return 'None';
    if (v < 60)  return '$v min';
    if (v == 60) return '1 hour';
    return '${v ~/ 60}h ${v % 60 > 0 ? "${v % 60}m" : ""}';
  }

  Color _color(int v) {
    if (v == 0)   return AppColors.tierRemission;
    if (v <= 15)  return AppColors.tierLow;
    if (v <= 45)  return AppColors.tierModerate;
    return AppColors.tierHigh;
  }

  bool _isCustom(int v) => !_options.contains(v);

  @override
  Widget build(BuildContext context) {
    final col = _color(widget.value);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          // Current value display
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Text(_label(widget.value), style: AppTextStyles.scoreMedium(col)),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          // Preset chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              ..._options.map((opt) {
                final selected = opt == widget.value && !_showCustom;
                return GestureDetector(
                  onTap: () {
                    setState(() { _showCustom = false; });
                    widget.onChanged(opt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.bgSection,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      _label(opt),
                      style: AppTextStyles.label().copyWith(
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
              // ── Custom time chip ──
              GestureDetector(
                onTap: () => setState(() { _showCustom = !_showCustom; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: (_showCustom || _isCustom(widget.value))
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.bgSection,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: (_showCustom || _isCustom(widget.value))
                          ? AppColors.primary
                          : AppColors.border,
                      width: (_showCustom || _isCustom(widget.value)) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        _isCustom(widget.value) && !_showCustom
                            ? _label(widget.value)
                            : 'Custom',
                        style: AppTextStyles.label().copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Custom input row — shown when Custom chip tapped ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showCustom
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.cardTitle(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.bgSection,
                              hintText: 'e.g. 35',
                              hintStyle: AppTextStyles.caption(),
                              suffixText: 'min',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          label: 'Set',
                          onTap: () {
                            final mins = int.tryParse(_customCtrl.text.trim());
                            if (mins != null && mins > 0 && mins <= 480) {
                              widget.onChanged(mins);
                              setState(() { _showCustom = false; });
                              _customCtrl.clear();
                            }
                          },
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Risk indicator
          if (widget.value > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: col.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.value > 45
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: col, size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.value > 45
                          ? 'Prolonged stiffness may indicate active disease'
                          : 'Mild-moderate stiffness — monitor throughout the day',
                      style: AppTextStyles.caption().copyWith(color: col),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STRESS LEVEL SLIDER  (Fix 2)
// ─────────────────────────────────────────────
class _StressSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _StressSlider({required this.value, required this.onChanged});

  @override
  State<_StressSlider> createState() => _StressSliderState();
}

class _StressSliderState extends State<_StressSlider> {
  bool _showInfo = false;

  String _label(double v) {
    if (v < 4.0)  return 'Low Stress';
    if (v <= 7.5) return 'Average Stress';
    return 'High Stress';
  }

  Color _color(double v) {
    if (v < 4.0)  return AppColors.tierRemission;
    if (v <= 7.5) return AppColors.tierModerate;
    return AppColors.tierHigh;
  }

  String _emoji(double v) {
    if (v < 4.0)  return '😌';
    if (v <= 7.5) return '😐';
    return '😰';
  }

  @override
  Widget build(BuildContext context) {
    final col = _color(widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            children: [
              // Value display
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_emoji(widget.value),
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      widget.value.toStringAsFixed(1),
                      style: AppTextStyles.scoreMedium(col),
                    ),
                    const SizedBox(width: 8),
                    Text('/ 10', style: AppTextStyles.caption()),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              // Slider — 0 to 10 in steps of 0.5 (21 divisions)
              Slider(
                value: widget.value,
                min: 0,
                max: 10,
                divisions: 20,
                activeColor: col,
                inactiveColor: col.withOpacity(0.2),
                onChanged: widget.onChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 — None', style: AppTextStyles.labelCaps()),
                    Text('10 — Extreme', style: AppTextStyles.labelCaps()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Result badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: col.withOpacity(0.3)),
                ),
                child: Text(
                  _label(widget.value),
                  style: AppTextStyles.label().copyWith(
                    color: col, fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // ── Info toggle ──
        GestureDetector(
          onTap: () => setState(() { _showInfo = !_showInfo; }),
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm, left: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  _showInfo
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.info_outline_rounded,
                  size: 16, color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'How is this scale measured?',
                  style: AppTextStyles.label().copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showInfo
              ? Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: AppColors.bgSection,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is a 0–10 self-reported scale (steps of 0.5) based on '
                        'your overall perceived stress across work, relationships, '
                        'health, and daily life. It is not a clinical diagnosis.',
                        style: AppTextStyles.caption(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Scale bands
                      Row(
                        children: [
                          _BandChip(
                            label: '0 – 3.5', desc: 'Low',
                            color: AppColors.tierRemission,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _BandChip(
                            label: '4 – 7.5', desc: 'Average',
                            color: AppColors.tierModerate,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _BandChip(
                            label: '7.5 – 10', desc: 'High',
                            color: AppColors.tierHigh,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'High stress is associated with increased inflammation and '
                        'may worsen RA symptoms.',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _BandChip extends StatelessWidget {
  final String label;
  final String desc;
  final Color color;
  const _BandChip({
    required this.label, required this.desc, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.labelCaps().copyWith(color: color)),
            Text(desc,
                style: AppTextStyles.label().copyWith(
                  color: color, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEATHER CARD
// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// WEATHER CARD  (3 states: loading / unavailable+picker / data)
// ─────────────────────────────────────────────
class _WeatherCard extends StatefulWidget {
  final WeatherData? weather;
  final bool loading;
  const _WeatherCard({this.weather, required this.loading});

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  final _cityCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading ───────────────────────────────────────────────────────
    if (widget.loading || _submitting) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: Column(children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          if (_submitting) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Fetching weather for ${_cityCtrl.text}…',
                style: AppTextStyles.caption()),
          ],
        ])),
      );
    }

    // ── Unavailable → show city picker ───────────────────────────────
    if (widget.weather == null || widget.weather!.isUnavailable) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location not available',
                    style: AppTextStyles.label()),
                Text(
                  'Enter your city to get local weather data for your logs.',
                  style: AppTextStyles.caption(),
                ),
              ],
            )),
          ]),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppSpacing.md),
          // City input row
          Row(children: [
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                textCapitalization: TextCapitalization.words,
                style: AppTextStyles.cardTitle(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgSection,
                  hintText: 'e.g. Petaling Jaya',
                  hintStyle: AppTextStyles.caption(),
                  prefixIcon: const Icon(Icons.location_city_outlined,
                      color: AppColors.primary, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                onSubmitted: (_) => _submit(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: 'Set',
              onTap: () => _submit(context),
              color: AppColors.primary,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // Dismiss note — user can skip
          Text(
            'Tap "Set" once — your city is saved for future logs.',
            style: AppTextStyles.caption(),
          ),
        ]),
      );
    }

    // ── Data: render weather ──────────────────────────────────────────
    final w = widget.weather!;
    final riskColor = {
      'high':     AppColors.tierHigh,
      'moderate': AppColors.tierModerate,
      'low':      AppColors.tierRemission,
    }[w.stiffnessRisk] ?? AppColors.textMuted;

    final card = AppCard(
      color: AppColors.bgCard,
      shadow: AppShadows.card(),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                // Condition icon
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _conditionEmoji(w.condition),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${w.temperature.toStringAsFixed(0)}°C  •  ${w.condition}',
                        style: AppTextStyles.cardTitle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current location',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: [
                // Metrics row
                Row(
                  children: [
                    _WeatherMetric(
                      icon: Icons.water_drop_outlined,
                      label: 'Humidity',
                      value: '${w.humidity.toStringAsFixed(0)}%',
                      color: w.humidity > 75 ? AppColors.tierModerate : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _WeatherMetric(
                      icon: Icons.speed_outlined,
                      label: 'Pressure',
                      value: '${w.pressure.toStringAsFixed(0)} hPa',
                      color: w.pressure < 1005 ? AppColors.tierHigh : AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Risk banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: riskColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_riskIcon(w.stiffnessRisk), color: riskColor, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.riskLabel,
                              style: AppTextStyles.label().copyWith(color: riskColor),
                            ),
                            Text(
                              _riskDescription(w.stiffnessRisk, w.humidity),
                              style: AppTextStyles.caption().copyWith(color: riskColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // Wrap card + source badge together
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: _sourceBadge(w.source, w.cityName),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) return;
    setState(() => _submitting = true);
    // Delegate to controller — saves city + fetches weather
    await context.read<HealthController>().setCityAndRefetch(city);
    if (mounted) setState(() => _submitting = false);
  }

  String _conditionEmoji(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain'))  return '🌧️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('clear') || c.contains('sun')) return '☀️';
    if (c.contains('storm')) return '⛈️';
    if (c.contains('haze') || c.contains('fog')) return '🌫️';
    return '🌤️';
  }

  IconData _riskIcon(String risk) {
    switch (risk) {
      case 'high':     return Icons.warning_amber_rounded;
      case 'moderate': return Icons.info_outline_rounded;
      default:         return Icons.check_circle_outline_rounded;
    }
  }

  String _riskDescription(String risk, double humidity) {
    switch (risk) {
      case 'high':
        return 'High humidity (${humidity.toStringAsFixed(0)}%) — joints may be more stiff today';
      case 'moderate':
        return 'Moderate humidity — mild stiffness possible';
      default:
        return 'Conditions are favourable for joint comfort';
    }
  }

  /// Small badge shown below weather card indicating data source
  Widget _sourceBadge(WeatherSource source, String city) {
    switch (source) {
      case WeatherSource.gps:
        return Row(children: [
          const Icon(Icons.gps_fixed_rounded,
              size: 12, color: AppColors.tierRemission),
          const SizedBox(width: 4),
          Text('GPS location', style: AppTextStyles.labelCaps()
              .copyWith(color: AppColors.tierRemission)),
        ]);
      case WeatherSource.manualCity:
        return Row(children: [
          const Icon(Icons.location_city_outlined,
              size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(city, style: AppTextStyles.labelCaps()
              .copyWith(color: AppColors.primary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              // Clear weather → triggers unavailable state → shows picker again
              context.read<HealthController>().clearSavedCity();
            },
            child: Text('change',
                style: AppTextStyles.labelCaps().copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                )),
          ),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WeatherMetric({
    required this.icon, required this.label, required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSection,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelCaps()),
                Text(value, style: AppTextStyles.cardTitle().copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SYMPTOM SUMMARY (before final calculation)
// ─────────────────────────────────────────────
class _SymptomSummaryCard extends StatelessWidget {
  final HealthController ctrl;
  const _SymptomSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final score = SymptomLog.calculateRapid3(
      ctrl.painValue, ctrl.functionValue, ctrl.globalValue,
    );
    final tier = SymptomLog.tierFromScore(score);

    return AppCard(
      color: AppTierHelper.bgColor(tier),
      shadow: [],
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppTierHelper.emoji(tier), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to Calculate', style: AppTextStyles.cardTitle()),
                    Text('Based on your symptom inputs', style: AppTextStyles.caption()),
                  ],
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: AppTextStyles.scoreMedium(AppTierHelper.color(tier)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _SumItem('Pain', ctrl.painValue.toStringAsFixed(1)),
              _SumItem('Function', ctrl.functionValue.toStringAsFixed(1)),
              _SumItem('Global', ctrl.globalValue.toStringAsFixed(1)),
              _SumItem('Stiffness', '${ctrl.stiffnessMinutes}m'),
              _SumItem('Stress', ctrl.stressLevel.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label;
  final String value;
  const _SumItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.sectionTitle().copyWith(fontSize: 16)),
          Text(label, style: AppTextStyles.labelCaps()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCalculate;
  const _BottomBar({required this.onBack, required this.onCalculate});

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
          Expanded(
            flex: 3,
            child: AppButton(
              label: '🧮  Calculate RAPID3',
              onTap: onCalculate,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}