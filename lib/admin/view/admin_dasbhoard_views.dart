// lib/admin/views/admin_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_user_controller.dart';
import '../controllers/admin_data_controller.dart';
import '../widgets/admin_navi.dart';
import '../widgets/admin_chart.dart';
import 'admin_management_view.dart';

import 'admin_analytics_view.dart';
import 'admin_profile_view.dart';
import 'admin_profile_view.dart';
import 'admin_login_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});
  @override State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  AdminPage _page      = AdminPage.dashboard;
  bool      _collapsed = false;

  late final AdminAuthController      _auth;
  late final AdminDashboardController _dash;
  late final AdminUserController      _users;
  late final AdminDataController      _data;

  @override
  void initState() {
    super.initState();
    _auth  = AdminAuthController()..checkSession();
    _dash  = AdminDashboardController()..init();
    _users = AdminUserController()..init();
    _data  = AdminDataController();
  }

  @override
  void dispose() { _dash.dispose(); _users.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _dash),
        ChangeNotifierProvider.value(value: _users),
        ChangeNotifierProvider.value(value: _data),
      ],
      child: Consumer<AdminAuthController>(
        builder: (ctx, auth, _) {
          if (!auth.isAuthenticated && auth.state != AdminAuthState.loading) {
            return const AdminLoginView();
          }

          return Scaffold(
            backgroundColor: AdminTheme.bg,
            body: Row(children: [
              AdminNavRail(
                selected:  _page,
                collapsed: _collapsed,
                adminName: auth.adminName,
                onSelect:  (p) => setState(() => _page = p),
                onLogout:  () async { await auth.logout(); setState(() {}); },
                onProfile: () => setState(() => _page = AdminPage.profile),
              ),
              // Collapse toggle strip
              GestureDetector(
                onTap: () => setState(() => _collapsed = !_collapsed),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 16, color: AdminTheme.navBg,
                    alignment: Alignment.center,
                    child: Icon(
                      _collapsed
                          ? Icons.chevron_right : Icons.chevron_left,
                      color: Colors.white24, size: 14),
                  ),
                ),
              ),
              Expanded(child: _buildPage()),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case AdminPage.dashboard:  return const _DashboardBody();
      case AdminPage.management: return const AdminManagementView();
      case AdminPage.analytics:  return const AdminAnalyticsView();
      case AdminPage.profile:    return const AdminProfileView();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDashboardController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.loading) {
          return const Center(child: CircularProgressIndicator(
              color: AdminTheme.primary));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Dashboard', style: AdminTheme.tsTitle),
                  const SizedBox(height: 2),
                  Text(_nowLabel(), style: AdminTheme.tsBody),
                ]),
                const Spacer(),
                _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  onTap: ctrl.refresh,
                ),
              ]),
              const SizedBox(height: 24),

              // ── KPI grid ─────────────────────────────────────────────────
              LayoutBuilder(builder: (_, c) {
                final cols = c.maxWidth > 900 ? 4 : c.maxWidth > 600 ? 2 : 1;
                return _KpiGrid(ctrl: ctrl, cols: cols);
              }),
              const SizedBox(height: 24),

              // ── Charts row ────────────────────────────────────────────────
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 860) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _ChartCard(
                        title: 'RAPID3 — 7-Day Community Trend',
                        subtitle: 'Average score across active patients',
                        height: 260,
                        child: Rapid3TrendChart(points: ctrl.trend),
                      )),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _ChartCard(
                        title: 'Tier Distribution',
                        subtitle: 'Active patients by disease tier',
                        height: 260,
                        child: TierPieChart(dist: ctrl.tierDist),
                      )),
                    ],
                  );
                }
                return Column(children: [
                  _ChartCard(title: 'RAPID3 — 7-Day Trend',
                      subtitle: 'Average score across active patients',
                      height: 260,
                      child: Rapid3TrendChart(points: ctrl.trend)),
                  const SizedBox(height: 16),
                  _ChartCard(title: 'Tier Distribution',
                      subtitle: 'Active patients by disease tier',
                      height: 260,
                      child: TierPieChart(dist: ctrl.tierDist)),
                ]);
              }),
              const SizedBox(height: 16),

              // ── Bottom row ────────────────────────────────────────────────
              LayoutBuilder(builder: (_, c) {
                if (c.maxWidth > 860) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ChartCard(
                        title: 'User Activity Status',
                        subtitle: 'Active vs Inactive vs Terminated',
                        height: 220,
                        child: UserActivityBarChart(
                          active:     ctrl.activity.activeUsers,
                          inactive:   ctrl.activity.inactiveUsers,
                          terminated: ctrl.activity.terminatedUsers,
                        ),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _ChartCard(
                        title: 'EULAR Response Overview',
                        subtitle: 'Clinical improvement from baseline',
                        height: 220,
                        child: EularPieChart(data: ctrl.eular),
                      )),
                    ],
                  );
                }
                return Column(children: [
                  _ChartCard(title: 'User Activity',
                      subtitle: '',  height: 220,
                      child: UserActivityBarChart(
                        active: ctrl.activity.activeUsers,
                        inactive: ctrl.activity.inactiveUsers,
                        terminated: ctrl.activity.terminatedUsers,
                      )),
                  const SizedBox(height: 16),
                  _ChartCard(title: 'EULAR Response',
                      subtitle: '', height: 220,
                      child: EularPieChart(data: ctrl.eular)),
                ]);
              }),
            ],
          ),
        );
      },
    );
  }

  String _nowLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday-1]}, ${now.day} ${months[now.month-1]} ${now.year}';
  }
}

// ── KPI grid ──────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final AdminDashboardController ctrl;
  final int cols;
  const _KpiGrid({required this.ctrl, required this.cols});

  @override
  Widget build(BuildContext context) {
    final tier = ctrl.avgRapid3 <= 1 ? 'REMISSION'
        : ctrl.avgRapid3 <= 2 ? 'LOW'
        : ctrl.avgRapid3 <= 4 ? 'MODERATE' : 'HIGH';

    final items = [
      _KpiItem('Total Patients', ctrl.activity.totalUsers.toString(),
          Icons.group_rounded, AdminTheme.primary,
          [AdminTheme.primary, AdminTheme.primaryLight], null),
      _KpiItem('Active Today', ctrl.activity.activeUsers.toString(),
          Icons.check_circle_rounded, AdminTheme.green,
          [AdminTheme.green, const Color(0xFF059669)], null),
      _KpiItem('Avg RAPID3 Score', ctrl.avgRapid3.toStringAsFixed(1),
          Icons.monitor_heart_rounded, AdminTheme.tierColor(tier),
          [AdminTheme.tierColor(tier),
           AdminTheme.tierColor(tier).withOpacity(0.7)],
          tier),
      _KpiItem('New This Week', '+${ctrl.activity.newThisWeek}',
          Icons.person_add_alt_1_rounded, AdminTheme.accent,
          [AdminTheme.accent, AdminTheme.primaryLight], null),
      _KpiItem('In HIGH Flare', ctrl.tierDist.high.toString(),
          Icons.warning_rounded, AdminTheme.red,
          [AdminTheme.red, const Color(0xFFDC2626)], null),
      _KpiItem('In Remission', ctrl.tierDist.remission.toString(),
          Icons.spa_rounded, AdminTheme.green,
          [AdminTheme.green, const Color(0xFF059669)], null),
      _KpiItem('Inactive (>6mo)', ctrl.activity.inactiveUsers.toString(),
          Icons.access_time_rounded, AdminTheme.amber,
          [AdminTheme.amber, const Color(0xFFD97706)], null),
      _KpiItem('7-Day Log Count', ctrl.totalLogs.toString(),
          Icons.edit_note_rounded, AdminTheme.primaryLight,
          [AdminTheme.primaryLight, AdminTheme.primary], null),
    ];

    // Use fixed-height rows instead of GridView to avoid overflow
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += cols) {
      final rowItems = items.skip(i).take(cols).toList();
      rows.add(Row(children: [
        for (int j = 0; j < rowItems.length; j++) ...[
          if (j > 0) const SizedBox(width: 12),
          Expanded(child: _KpiCard(item: rowItems[j])),
        ],
        // Fill empty slots in last row
        for (int k = rowItems.length; k < cols; k++) ...[
          const SizedBox(width: 12),
          const Expanded(child: SizedBox()),
        ],
      ]));
      if (i + cols < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _KpiItem {
  final String label, value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String? badge;
  const _KpiItem(this.label, this.value, this.icon,
      this.color, this.gradient, this.badge);
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AdminTheme.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: item.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: Colors.white, size: 15),
              ),
              if (item.badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdminTheme.tierBg(item.badge!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.badge!,
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: AdminTheme.tierColor(item.badge!),
                          fontFamily: AdminTheme.fontFamily)),
                ),
              ],
            ]),
            const SizedBox(height: 8),
            Text(item.value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AdminTheme.textPrimary,
                    fontFamily: AdminTheme.fontFamily,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(item.label,
                style: AdminTheme.tsBody,
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title, subtitle;
  final double height;
  final Widget child;
  final Widget? action;
  const _ChartCard({required this.title, required this.subtitle,
      required this.height, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTheme.tsSectionTitle),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: AdminTheme.tsSmall),
              ],
            ],
          )),
          if (action != null) action!,
        ]),
        const SizedBox(height: 20),
        SizedBox(height: height, child: child),
      ]),
    );
  }
}

// ── Generic action button ─────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionButton({required this.icon, required this.label,
      required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 15),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? AdminTheme.primary,
        side: BorderSide(color: color ?? AdminTheme.primary),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: AdminTheme.fontFamily),
      ),
    );
  }
}