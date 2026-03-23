// lib/views/home/home_view.dart
// CHANGE from original: _HomeAppBar now reads the user's role.
// - Patient  → "Good morning, Jane ☀️"  (unchanged)
// - Guardian → "Helping John ☀️" with an orange guardian badge

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/controllers/auth_controller.dart';
import 'package:arthro/controllers/home_controller.dart';
import 'package:arthro/services/home_service.dart';
import 'package:arthro/views/navigation/global_navigation.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/views/profile/profile_sheet.dart';
import 'package:arthro/views/home/notification_view.dart';
import 'package:arthro/services/app_noti_services.dart';
import 'package:arthro/views/home/progress_card.dart';

const _kTabHealth = 1;
const _kTabMeds   = 2;
const _kTabAppt   = 3;
const _kTabReport = 4;

// ─────────────────────────────────────────────────────────────────────────────
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return ChangeNotifierProvider(
      create: (_) => HomeController(auth),
      child: const _HomeBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, ctrl, _) {
        if (ctrl.state == HomeState.loading ||
            ctrl.state == HomeState.idle) {
          return const _HomeSkeleton();
        }
        if (ctrl.state == HomeState.error) {
          return _ErrorScreen(message: ctrl.error, onRetry: ctrl.load);
        }

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: RefreshIndicator(
            color:     AppColors.primary,
            onRefresh: ctrl.load,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _HomeAppBar(ctrl: ctrl),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base, AppSpacing.sm,
                        AppSpacing.base, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ctrl.hasLoggedToday
                            ? _TodaySymptomCard(symptom: ctrl.todaySymptom!)
                            : const _LogNudgeCard(),
                      
                        // My Progress card — hidden until user has at least 1 symptom log
                        if (ctrl.hasProgress) ...[
                          const SizedBox(height: AppSpacing.sm),
                          MyProgressCard(progress: ctrl.progressSummary!),
                        ],
                      
                        const SizedBox(height: AppSpacing.sm),
                      
                        _WellnessBanner(
                            hasLogged: ctrl.hasLoggedToday,
                            tier:      ctrl.tier),
                      
                        const SizedBox(height: AppSpacing.lg),
                      
                        Text('Quick Access',
                            style: AppTextStyles.sectionTitle()),
                        const SizedBox(height: AppSpacing.sm),
                        _QuickNavGrid(
                          onTab: (i) =>
                              globalNavKey.currentState?.switchTab(i),
                        ),
                      
                        const SizedBox(height: AppSpacing.lg),
                      
                        Text('Your Care Today',
                            style: AppTextStyles.sectionTitle()),
                        const SizedBox(height: AppSpacing.sm),
                        Row(children: [
                          Expanded(
                              child: _MedCard(summary: ctrl.medSummary)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: _ApptCard(appt: ctrl.nextAppt)),
                        ]),
                      
                        const SizedBox(height: AppSpacing.lg),
                      
                        Text('Daily RA Tips',
                            style: AppTextStyles.sectionTitle()),
                        const SizedBox(height: AppSpacing.sm),
                        const _GuidanceSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR  ← ONLY THIS WIDGET CHANGED vs original
// ─────────────────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final HomeController ctrl;
  const _HomeAppBar({required this.ctrl});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _greetEmoji() {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '🌤️';
    return '🌙';
  }

  static String _date() {
    final d = DateTime.now();
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    const dy = ['Monday','Tuesday','Wednesday','Thursday',
                 'Friday','Saturday','Sunday'];
    return '${dy[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.read<AuthController>();
    final user      = auth.currentUser;
    final isGuardian = user?.role == 'guardian';

    // For guardians we try to show the patient's first name in the greeting.
    // ctrl.userName is already resolved to the effective (patient) name.
    final greetingText = isGuardian
        ? 'Helping ${ctrl.userName} ${_greetEmoji()}'
        : '${_greeting()}, ${ctrl.userName} ${_greetEmoji()}';

    final initials = (user?.fullName.trim().isNotEmpty == true)
        ? user!.fullName.trim()[0].toUpperCase()
        : '?';

    // Guardian uses an orange accent on the avatar border
    final avatarBorder = isGuardian
        ? const Color(0xFFFF8C00)   // orange
        : AppColors.primaryBorder;

    return SliverAppBar(
      floating:               true,
      snap:                   true,
      backgroundColor:        AppColors.bgCard,
      surfaceTintColor:       Colors.transparent,
      shadowColor:            AppColors.border,
      scrolledUnderElevation: 1,
      elevation:              0,
      expandedHeight:         isGuardian ? 100 : 88,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand icon
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Center(
                          child: Text('🦴',
                              style: TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),

                    // Greeting text
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingText,
                            style: AppTextStyles.sectionTitle()
                                .copyWith(fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(_date(), style: AppTextStyles.caption()),
                        ],
                      ),
                    ),

                    // Notification bell
                    _NotificationBell(),
                    const SizedBox(width: 8),

                    // Profile avatar
                    GestureDetector(
                      onTap: () => showProfileSheet(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isGuardian
                              ? const Color(0xFFFF8C00)
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: avatarBorder, width: 2),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Guardian context badge (only shown for guardians)
                if (isGuardian) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: const Color(0xFFFF8C00).withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.shield_outlined,
                          size: 12, color: Color(0xFFFF8C00)),
                      const SizedBox(width: 4),
                      Text(
                        'Viewing as Guardian',
                        style: AppTextStyles.labelCaps()
                            .copyWith(color: const Color(0xFFFF8C00)),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Everything below is IDENTICAL to the original home_view.dart
// ─────────────────────────────────────────────────────────────────────────────

class _QuickNavGrid extends StatelessWidget {
  final void Function(int) onTab;
  const _QuickNavGrid({required this.onTab});

  static const _items = [
    _NavItem(Icons.show_chart_rounded,     'Health',      Color(0xFF009688), Color(0xFFE0F2F1), _kTabHealth),
    _NavItem(Icons.medication_rounded,     'Medication',  Color(0xFF4A90E2), Color(0xFFEBF2FC), _kTabMeds),
    _NavItem(Icons.calendar_month_rounded, 'Appointment', Color(0xFF8B6BAE), Color(0xFFF2EDF8), _kTabAppt),
    _NavItem(Icons.bar_chart_rounded,      'Report',      Color(0xFF1B5F5F), Color(0xFFE8F5F5), _kTabReport),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: _items.asMap().entries.map((e) {
      final i    = e.key;
      final item = e.value;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
              right: i < _items.length - 1 ? AppSpacing.sm : 0),
          child: GestureDetector(
            onTap: () => onTab(item.tab),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color:        item.bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border:       Border.all(color: item.color.withOpacity(0.2)),
                boxShadow:    AppShadows.subtle(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(item.label,
                      style: AppTextStyles.caption().copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.color),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _NavItem {
  final IconData icon;
  final String   label;
  final Color    color, bg;
  final int      tab;
  const _NavItem(this.icon, this.label, this.color, this.bg, this.tab);
}

class _TodaySymptomCard extends StatelessWidget {
  final HomeTodaySymptom symptom;
  const _TodaySymptomCard({required this.symptom});

  @override
  Widget build(BuildContext context) {
    final c = AppTierHelper.color(symptom.rapid3Tier);
    final l = AppTierHelper.label(symptom.rapid3Tier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [c.withOpacity(0.08), c.withOpacity(0.03), AppColors.bgCard],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border:       Border.all(color: c.withOpacity(0.25), width: 1.5),
        boxShadow:    AppShadows.card(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _TierBadge(tier: symptom.rapid3Tier, color: c, label: l),
              const Spacer(),
              Text("Today's Check-in", style: AppTextStyles.caption()),
            ]),
            const SizedBox(height: AppSpacing.base),
            Row(children: [
              SizedBox(
                width: 88, height: 88,
                child: Stack(alignment: Alignment.center, children: [
                  CustomPaint(
                    size: const Size(88, 88),
                    painter: _RingPainter(
                      value:       symptom.rapid3Score,
                      maxValue:    30,
                      color:       c,
                      trackColor:  c.withOpacity(0.10),
                      strokeWidth: 8,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(symptom.rapid3Score.toStringAsFixed(1),
                        style: AppTextStyles.scoreMedium(c)
                            .copyWith(fontSize: 22, height: 1)),
                    Text('/30',
                        style: AppTextStyles.caption()
                            .copyWith(fontSize: 9)),
                  ]),
                ]),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(children: [
                  _SubScoreRow(label: 'Pain',     value: symptom.pain,             max: 10),
                  const SizedBox(height: 6),
                  _SubScoreRow(label: 'Function', value: symptom.function,         max: 10),
                  const SizedBox(height: 6),
                  _SubScoreRow(label: 'Global',   value: symptom.globalAssessment, max: 10),
                ]),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _StatPill(
                icon:  Icons.wb_sunny_outlined,
                label: 'Stiffness',
                value: '${symptom.morningStiffnessMinutes}m',
                color: symptom.morningStiffnessMinutes > 60
                    ? AppColors.tierHigh : AppColors.tierLow,
              ),
              _StatPill(
                icon:  Icons.psychology_outlined,
                label: 'Stress',
                value: '${symptom.stressLevel.toStringAsFixed(1)}/10',
                color: symptom.stressLevel >= 7.5 ? AppColors.tierHigh
                     : symptom.stressLevel >= 4.0 ? AppColors.warning
                                                  : AppColors.tierRemission,
              ),
              if (symptom.affectedJoints.isNotEmpty)
                _StatPill(
                  icon:  Icons.location_on_outlined,
                  label: 'Joints',
                  value: '${symptom.affectedJoints.length}',
                  color: AppColors.tierModerate,
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LogNudgeCard extends StatelessWidget {
  const _LogNudgeCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.primarySurface,
                 AppColors.primary.withOpacity(0.03),
                 AppColors.bgCard],
      ),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border:       Border.all(
          color: AppColors.primary.withOpacity(0.18), width: 1.5),
      boxShadow: AppShadows.card(),
    ),
    child: Row(children: [
      Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
            color: AppColors.primarySurface, shape: BoxShape.circle),
        child: const Center(
            child: Text('📋', style: TextStyle(fontSize: 28))),
      ),
      const SizedBox(width: AppSpacing.base),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No check-in yet today', style: AppTextStyles.cardTitle()),
            const SizedBox(height: 4),
            Text(
              "Take 2 minutes to log how you're feeling.",
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  globalNavKey.currentState?.switchTab(_kTabHealth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('Log Symptoms',
                    style: AppTextStyles.labelCaps()
                        .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ]),
  );
}

class _WellnessBanner extends StatelessWidget {
  final bool   hasLogged;
  final String tier;
  const _WellnessBanner({required this.hasLogged, required this.tier});

  @override
  Widget build(BuildContext context) {
    final t = hasLogged ? tier : 'UNKNOWN';
    final c = _col(t);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color:        c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(_emj(t), style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_ttl(t),
                  style: AppTextStyles.cardTitle().copyWith(color: c)),
              const SizedBox(height: 3),
              Text(_bdy(t),
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: AppColors.textMuted),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  static Color  _col(String t) {
    switch (t) {
      case 'REMISSION': return AppColors.tierRemission;
      case 'LOW':       return AppColors.tierLow;
      case 'MODERATE':  return AppColors.tierModerate;
      case 'HIGH':      return AppColors.tierHigh;
      default:          return AppColors.primary;
    }
  }
  static String _emj(String t) {
    switch (t) {
      case 'REMISSION': return '🌟';
      case 'LOW':       return '💪';
      case 'MODERATE':  return '🌿';
      case 'HIGH':      return '❤️';
      default:          return '✨';
    }
  }
  static String _ttl(String t) {
    switch (t) {
      case 'REMISSION': return "You're in remission — keep it up!";
      case 'LOW':       return 'Mild activity today';
      case 'MODERATE':  return 'Listen to your body today';
      case 'HIGH':      return 'Take it easy today';
      default:          return 'Welcome back!';
    }
  }
  static String _bdy(String t) {
    switch (t) {
      case 'REMISSION': return 'Stay consistent with meds and gentle exercise.';
      case 'LOW':       return 'Light stretching and hydration help ease stiffness.';
      case 'MODERATE':  return "Pace yourself and don't skip your meds.";
      case 'HIGH':      return 'Rest and stay warm. Contact your rheumatologist if pain persists.';
      default:          return "Log today's symptoms to see personalised guidance.";
    }
  }
}

class _MedCard extends StatelessWidget {
  final HomeMedSummary? summary;
  const _MedCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final empty = summary == null;
    final taken = summary?.takenToday ?? 0;
    final total = summary?.totalDoses ?? 0;
    final pct   = total > 0 ? taken / total : 0.0;

    final Color pillColor = empty
        ? AppColors.textMuted
        : pct >= 1.0 ? AppColors.tierRemission
        : pct >  0.0 ? AppColors.tierLow
                     : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(color: AppColors.border),
        boxShadow:    AppShadows.subtle(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color:        AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.medication_rounded,
                  size: 15, color: AppColors.primary),
            ),
            const Spacer(),
            Text('Medication',
                style: AppTextStyles.caption().copyWith(fontSize: 9)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (!empty && total > 0) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$taken',
                  style: AppTextStyles.scoreMedium(pillColor)
                      .copyWith(fontSize: 28, height: 1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(' / $total',
                    style: AppTextStyles.bodySmall().copyWith(
                        color:      AppColors.textMuted,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            Text('doses taken today',
                style: AppTextStyles.caption()
                    .copyWith(fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value:           pct,
                minHeight:       6,
                color:           pillColor,
                backgroundColor: pillColor.withOpacity(0.12),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${summary!.name}'
              '${summary!.dosage.isNotEmpty ? ' · ${summary!.dosage}' : ''}'
              '${summary!.displayTime != '—' ? '  🕐 ${summary!.displayTime}' : ''}',
              style: AppTextStyles.caption()
                  .copyWith(fontSize: 10, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Text(
              empty ? 'No meds added' : 'All done for today!',
              style: AppTextStyles.cardTitle()
                  .copyWith(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 3),
            Text(
              empty ? 'Add meds in the Meds tab' : '✓ All doses taken',
              style: AppTextStyles.caption().copyWith(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final HomeAppt? appt;
  const _ApptCard({required this.appt});

  static String _fmtDate(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    final diff = dt.difference(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${dt.day} ${mo[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final empty = appt == null;
    const iconColor = Color(0xFF6C8FBF);
    const iconBg    = Color(0xFFEBF0F8);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:       Border.all(
            color: empty
                ? AppColors.border.withOpacity(0.5)
                : AppColors.border),
        boxShadow: AppShadows.subtle(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Icon(Icons.calendar_today_rounded,
                  size: 15, color: iconColor),
            ),
            const Spacer(),
            Text('Next Appointment',
                style: AppTextStyles.caption().copyWith(fontSize: 9)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (!empty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(_fmtDate(appt!.dateTime),
                  style: AppTextStyles.labelCaps()
                      .copyWith(color: iconColor, fontSize: 10)),
            ),
            const SizedBox(height: 6),
            Text(appt!.title,
                style: AppTextStyles.cardTitle().copyWith(fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            if (appt!.personInCharge.isNotEmpty)
              Text(appt!.personInCharge,
                  style: AppTextStyles.caption().copyWith(fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (appt!.location.isNotEmpty)
              Text(appt!.location,
                  style: AppTextStyles.caption()
                      .copyWith(fontSize: 10, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ] else ...[
            Text('No upcoming appt',
                style: AppTextStyles.cardTitle()
                    .copyWith(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 3),
            Text('Book in Appointment tab',
                style: AppTextStyles.caption().copyWith(fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection();

  static const _items = [
    _GItem('💧', 'Stay Hydrated',
        '8 glasses of water daily helps reduce joint inflammation.',
        Color(0xFF4A9EDB), Color(0xFFEAF4FB)),
    _GItem('💊', 'Never Skip Meds',
        'DMARDs and biologics need consistent dosing to control inflammation.',
        AppColors.primary, AppColors.primarySurface),
    _GItem('🧘', 'Gentle Movement',
        'Low-impact exercise like walking keeps joints flexible and reduces stiffness.',
        Color(0xFF6BAE75), Color(0xFFEDF6EE)),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: _items.map((i) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:        i.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:       Border.all(color: i.color.withOpacity(0.18)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: i.color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
                child: Text(i.emoji,
                    style: const TextStyle(fontSize: 19))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title,
                    style: AppTextStyles.cardTitle()
                        .copyWith(color: i.color, fontSize: 13)),
                const SizedBox(height: 3),
                Text(i.body,
                    style: AppTextStyles.bodySmall()
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ]),
      ),
    )).toList(),
  );
}

class _GItem {
  final String emoji, title, body;
  final Color  color, bg;
  const _GItem(this.emoji, this.title, this.body, this.color, this.bg);
}

class _TierBadge extends StatelessWidget {
  final String tier, label;
  final Color  color;
  const _TierBadge({required this.tier, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(AppTierHelper.emoji(tier), style: const TextStyle(fontSize: 11)),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.labelCaps()
              .copyWith(color: color, fontSize: 10)),
    ]),
  );
}

class _SubScoreRow extends StatelessWidget {
  final String label;
  final double value, max;
  const _SubScoreRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct   = (value / max).clamp(0.0, 1.0);
    final color = pct >= 0.7 ? AppColors.tierHigh
                : pct >= 0.4 ? AppColors.tierModerate
                             : AppColors.tierRemission;
    return Row(children: [
      SizedBox(width: 54,
          child: Text(label,
              style: AppTextStyles.caption().copyWith(fontSize: 10))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: pct, minHeight: 5,
            color: color, backgroundColor: color.withOpacity(0.12),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(value.toStringAsFixed(1),
          style: AppTextStyles.caption().copyWith(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;
  const _StatPill({required this.icon, required this.label,
                   required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border:       Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text('$label $value',
          style: AppTextStyles.caption().copyWith(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _RingPainter extends CustomPainter {
  final double value, maxValue, strokeWidth;
  final Color  color, trackColor;
  const _RingPainter({required this.value, required this.maxValue,
                      required this.color, required this.trackColor,
                      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - strokeWidth) / 2;
    final p = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = trackColor);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        (value / maxValue).clamp(0.0, 1.0) * 2 * math.pi,
        false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.value != value || o.color != color;
}

class _ErrorScreen extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppTextStyles.sectionTitle()),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall()
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text('Try Again',
                    style: AppTextStyles.labelCaps()
                        .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();
  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    body: AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final col = Color.lerp(AppColors.bgSection, AppColors.border, _a.value)!;
        return SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.lg, AppSpacing.base, 0),
            child: Column(children: [
              _B(56,  col, AppRadius.lg),
              const SizedBox(height: AppSpacing.lg),
              _B(170, col, AppRadius.xl),
              const SizedBox(height: AppSpacing.sm),
              _B(58,  col, AppRadius.lg),
              const SizedBox(height: AppSpacing.lg),
              Row(children: List.generate(4, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? AppSpacing.sm : 0),
                  child: _B(72, col, AppRadius.lg),
                ),
              ))),
              const SizedBox(height: AppSpacing.lg),
              Row(children: [
                Expanded(child: _B(110, col, AppRadius.lg)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _B(110, col, AppRadius.lg)),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _B(72, col, AppRadius.lg),
              const SizedBox(height: AppSpacing.sm),
              _B(72, col, AppRadius.lg),
              const SizedBox(height: AppSpacing.sm),
              _B(72, col, AppRadius.lg),
            ]),
          ),
        );
      },
    ),
  );
}


// ── Notification Bell with unread badge ──────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().currentUser?.uid ?? '';
    return StreamBuilder<int>(
      stream: AppNotificationService.instance.streamUnreadCount(uid),
      builder: (context, snap) {
        final unread = snap.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationView())),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:  AppColors.bgSection,
                  shape:  BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  unread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  size: 18,
                  color: unread > 0
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: -2, right: -2,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   8,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _B extends StatelessWidget {
  final double h, r;
  final Color  c;
  const _B(this.h, this.c, this.r);
  @override
  Widget build(BuildContext context) => Container(
    height: h,
    decoration: BoxDecoration(
        color: c, borderRadius: BorderRadius.circular(r)),
  );
}