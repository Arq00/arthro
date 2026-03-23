// lib/admin/widgets/admin_nav_rail.dart
import 'package:flutter/material.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';

enum AdminPage { dashboard, management, analytics, profile }

class AdminNavRail extends StatelessWidget {
  final AdminPage selected;
  final ValueChanged<AdminPage> onSelect;
  final String adminName;
  final VoidCallback onLogout;
  final bool collapsed;

  final VoidCallback onProfile;
  const AdminNavRail({super.key, required this.selected,
      required this.onSelect, required this.adminName,
      required this.onLogout, required this.onProfile,
      this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 68.0 : 224.0,
      decoration: const BoxDecoration(
        color: AdminTheme.navBg,
        boxShadow: [BoxShadow(
            color: Colors.black26, blurRadius: 16, offset: Offset(2, 0))],
      ),
      child: Column(children: [
        // ── Logo ────────────────────────────────────────────────────────────
        SizedBox(
          height: 72,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 16 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AdminTheme.accent, AdminTheme.primaryLight],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 20),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ArthroCare', style: TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: AdminTheme.fontFamily)),
                      Text('Admin Panel', style: TextStyle(
                          color: Colors.white38, fontSize: 11,
                          fontFamily: AdminTheme.fontFamily)),
                    ])),
                ],
              ]),
          ),
        ),

        Container(height: 1, color: Colors.white10),
        const SizedBox(height: 8),

        // ── Nav items ────────────────────────────────────────────────────────
        _NavItem(Icons.dashboard_rounded,        'Dashboard',
            AdminPage.dashboard,  selected, onSelect, collapsed),
        _NavItem(Icons.manage_search_rounded,    'Management',
            AdminPage.management, selected, onSelect, collapsed),
        _NavItem(Icons.analytics_rounded,        'Analytics',
            AdminPage.analytics,  selected, onSelect, collapsed),
        _NavItem(Icons.manage_accounts_rounded,  'Profile',
            AdminPage.profile,    selected, onSelect, collapsed),

        const Spacer(),
        Container(height: 1, color: Colors.white10),

        // ── Admin profile ────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 16, vertical: 14),
          child: collapsed
              ? Tooltip(
                  message: 'Logout',
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.logout_rounded,
                          color: Colors.white54, size: 18)),
                  ))
              : Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AdminTheme.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(
                      adminName.isNotEmpty
                          ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                          color: AdminTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(adminName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const Text('Administrator',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  )),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white38, size: 16),
                    onPressed: onLogout,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Logout',
                  ),
                ]),
        ),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final AdminPage page, selected;
  final ValueChanged<AdminPage> onTap;
  final bool collapsed;
  const _NavItem(this.icon, this.label, this.page,
      this.selected, this.onTap, this.collapsed);
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.page == widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? AdminTheme.accent.withOpacity(0.15)
                : _hovered ? Colors.white.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AdminTheme.accent.withOpacity(0.3))
                : null,
          ),
          child: widget.collapsed
              ? Tooltip(
                  message: widget.label,
                  preferBelow: false,
                  child: Center(child: Icon(widget.icon,
                      color: isSelected
                          ? AdminTheme.accent : Colors.white54,
                      size: 20)))
              : Row(children: [
                  Icon(widget.icon,
                      color: isSelected
                          ? AdminTheme.accent : Colors.white54,
                      size: 18),
                  const SizedBox(width: 12),
                  Text(widget.label, style: TextStyle(
                    color: isSelected ? AdminTheme.accent : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600 : FontWeight.normal,
                    fontFamily: AdminTheme.fontFamily,
                  )),
                  if (isSelected) ...[
                    const Spacer(),
                    Container(width: 4, height: 4,
                        decoration: const BoxDecoration(
                            color: AdminTheme.accent,
                            shape: BoxShape.circle)),
                  ],
                ]),
        ),
      ),
    );
  }
}