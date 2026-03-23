// lib/admin/views/admin_user_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_user_controller.dart';

class AdminUserListView extends StatelessWidget {
  const AdminUserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminUserController>(
      builder: (ctx, ctrl, _) => Column(children: [
        _TopBar(ctrl: ctrl),
        _FilterBar(ctrl: ctrl),

        Expanded(child: _UserTable(ctrl: ctrl)),
      ]),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AdminUserController ctrl;
  const _TopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      color: AdminTheme.bgCard,
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('User Management', style: AdminTheme.tsTitle),
          const SizedBox(height: 2),
          Text(
            '${ctrl.totalCount} total  ·  '
            '${ctrl.activeCount} active  ·  '
            '${ctrl.inactiveCount} inactive',
            style: AdminTheme.tsBody),
          const SizedBox(height: 4),
          const Text(
            'Manage patient & guardian accounts · View details · Bulk selection',
            style: TextStyle(fontSize: 11, color: AdminTheme.textMuted,
                fontFamily: AdminTheme.fontFamily)),
        ]),
      ]),
    );
  }
}

// ── Filter + search bar ───────────────────────────────────────────────────────
class _FilterBar extends StatefulWidget {
  final AdminUserController ctrl;
  const _FilterBar({required this.ctrl});
  @override State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _search = TextEditingController();
  @override void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return Container(
      color: AdminTheme.bgCard,
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
      child: Row(children: [
        // Status chips
        ...[UserFilter.all, UserFilter.active,
            UserFilter.inactive]
            .map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _lbl(f, ctrl), selected: ctrl.filter == f,
                onTap: () => ctrl.setFilter(f),
              ),
            )),
        const Spacer(),
        SizedBox(
          width: 240,
          child: TextField(
            controller: _search,
            onChanged: ctrl.setSearch,
            style: const TextStyle(fontSize: 13,
                fontFamily: AdminTheme.fontFamily),
            decoration: AdminTheme.inputDeco(
                'Search name or email…',
                icon: Icons.search_rounded),
          ),
        ),
      ]),
    );
  }

  String _lbl(UserFilter f, AdminUserController c) {
    switch (f) {
      case UserFilter.all:       return 'All (${c.totalCount})';
      case UserFilter.active:    return 'Active (${c.activeCount})';
      case UserFilter.inactive:  return 'Inactive (${c.inactiveCount})';
      default:                   return '';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AdminTheme.primary : AdminTheme.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AdminTheme.primary : AdminTheme.border),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontFamily: AdminTheme.fontFamily,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? Colors.white : AdminTheme.textSecondary,
        )),
      ),
    );
  }
}



// ── User table ────────────────────────────────────────────────────────────────
class _UserTable extends StatelessWidget {
  final AdminUserController ctrl;
  const _UserTable({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.loading) return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary));

    if (ctrl.users.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_accounts_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No users match this filter',
              style: AdminTheme.tsCardTitle),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: AdminTheme.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              color: AdminTheme.bg,
              child: Row(children: [
                // Select all — only visible when something is selected
                SizedBox(width: 36,
                  child: ctrl.hasSelection
                    ? Checkbox(
                        value: ctrl.users.isNotEmpty &&
                            ctrl.users.every((u) =>
                                ctrl.selected.contains(u.uid)),
                        onChanged: (_) {
                          ctrl.users.every((u) =>
                              ctrl.selected.contains(u.uid))
                              ? ctrl.clearSelect()
                              : ctrl.selectAll();
                        },
                        activeColor: AdminTheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : const SizedBox()),
                _Th('Name',        flex: 4, field: SortField.name, ctrl: ctrl),
                _Th('Role',        flex: 1),
                _Th('Last Active', flex: 2, field: SortField.lastActive,
                    ctrl: ctrl),
                _Th('Status',      flex: 1),
                _Th('Activity',    flex: 2, field: SortField.activity,
                    ctrl: ctrl),

              ]),
            ),
            const Divider(height: 1, color: AdminTheme.border),
            // Rows
            ...ctrl.users.map((u) => _UserRow(
              user: u, ctrl: ctrl,
            )),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  final int flex;
  final SortField? field;
  final AdminUserController? ctrl;
  const _Th(this.label,
      {this.flex = 1, this.field, this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: field != null && ctrl != null
          ? InkWell(
              onTap: () => ctrl!.setSort(field!),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: AdminTheme.tsLabel),
                const SizedBox(width: 4),
                Icon(
                  ctrl!.sortField == field
                      ? (ctrl!.sortAsc
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                      : Icons.unfold_more_rounded,
                  size: 12, color: AdminTheme.textMuted),
              ]),
            )
          : Text(label, style: AdminTheme.tsLabel),
    );
  }
}

class _UserRow extends StatefulWidget {
  final AdminUserModel user;
  final AdminUserController ctrl;
  const _UserRow({required this.user, required this.ctrl});
  @override State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u          = widget.user;
    final isSelected = widget.ctrl.selected.contains(u.uid);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: isSelected
            ? AdminTheme.primary.withOpacity(0.06)
            : _hovered ? AdminTheme.bg : Colors.white,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(children: [
              // Checkbox — only visible on hover or when selected
              SizedBox(width: 36,
                child: AnimatedOpacity(
                  opacity: (isSelected || _hovered || widget.ctrl.hasSelection) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => widget.ctrl.toggleSelect(u.uid),
                    activeColor: AdminTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )),

              // Name + email + link info (no avatar letter)
              Expanded(flex: 4, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Flexible(child: Text(u.fullName, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AdminTheme.textPrimary,
                        fontFamily: AdminTheme.fontFamily),
                        overflow: TextOverflow.ellipsis)),
                    if (u.tier != null) ...[
                      const SizedBox(width: 6),
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(
                              color: AdminTheme.tierColor(u.tier!),
                              shape: BoxShape.circle)),
                    ],
                  ]),
                  Text(u.email, style: AdminTheme.tsSmall,
                      overflow: TextOverflow.ellipsis),
                  // Show guardian/patient link
                  if (u.role == 'patient' && u.guardianId != null)
                    _LinkLabel(
                        prefix: 'Guardian:',
                        uid: u.guardianId!,
                        allUsers: widget.ctrl.users)
                  else if (u.role == 'guardian' && u.patientId != null)
                    _LinkLabel(
                        prefix: 'Patient:',
                        uid: u.patientId!,
                        allUsers: widget.ctrl.users),
                ],
              )),

              // Role
              Expanded(flex: 1, child: _RoleBadge(role: u.displayRole)),

              // Last active
              Expanded(flex: 2, child: Text(
                  _fmt(u.lastActive), style: AdminTheme.tsBody)),

              // Status
              Expanded(flex: 1, child: _StatusPill(status: u.status)),

              // Activity — compact: just % + small bar
              Expanded(flex: 2, child: _ActivityBar(
                  count: u.logCount30d,
                  pct:   u.activityPct,
                  label: u.activityLabel,
                  color: u.activityColor,
                )),


            ]),
          ),
          const Divider(height: 1, color: AdminTheme.border),
        ]),
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'Today';
    if (d == 1) return 'Yesterday';
    if (d < 30) return '${d}d ago';
    if (d < 365) return '${(d/30).round()}mo ago';
    return '${(d/365).round()}y ago';
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────
// Shows linked user name (guardian for a patient, or patient for a guardian)
class _LinkLabel extends StatelessWidget {
  final String prefix, uid;
  final List<AdminUserModel> allUsers;
  const _LinkLabel({required this.prefix, required this.uid,
      required this.allUsers});

  @override
  Widget build(BuildContext context) {
    final linked = allUsers.where((u) => u.uid == uid).firstOrNull;
    final name   = linked?.fullName ?? 'Linked';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.link_rounded, size: 10, color: AdminTheme.textMuted),
      const SizedBox(width: 3),
      Flexible(child: Text('$prefix $name',
          style: const TextStyle(
              fontSize: 10, color: AdminTheme.textMuted,
              fontFamily: AdminTheme.fontFamily),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) {
    final c = role == 'Guardian' ? AdminTheme.primaryLight : AdminTheme.accent;
    final icon = role == 'Guardian'
        ? Icons.shield_outlined : Icons.person_outline_rounded;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: c),
      const SizedBox(width: 4),
      Text(role, style: TextStyle(color: c, fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: AdminTheme.fontFamily)),
    ]);
  }
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});
  @override
  Widget build(BuildContext context) {
    final c = AdminTheme.tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AdminTheme.tierBg(tier),
          borderRadius: BorderRadius.circular(20)),
      child: Text(tier.length > 1
          ? tier[0] + tier.substring(1).toLowerCase() : tier,
          style: TextStyle(color: c, fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: AdminTheme.fontFamily)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final c = status == 'active' ? AdminTheme.green
        : status == 'inactive' ? AdminTheme.amber : AdminTheme.red;
    final lbl = status[0].toUpperCase() + status.substring(1);
    // Compact: dot + short text, no background pill box
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(lbl, style: TextStyle(color: c, fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: AdminTheme.fontFamily)),
    ]);
  }
}

class _ActivityBar extends StatelessWidget {
  final int count;
  final double pct;
  final String label;
  final Color color;
  const _ActivityBar({required this.count, required this.pct,
      required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(children: [
          Container(height: 5, color: AdminTheme.bg),
          FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(height: 5,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3))),
          ),
        ]),
      )),
      const SizedBox(width: 6),
      Text('${(pct*100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: color, fontFamily: AdminTheme.fontFamily)),
    ]);
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
Future<bool?> _confirm(BuildContext ctx,
    {required String title,
     required String body,
     required String danger}) {
  return showDialog<bool>(
    context: ctx,
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                fontFamily: AdminTheme.fontFamily)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(
                fontSize: 12, color: AdminTheme.textSecondary,
                fontFamily: AdminTheme.fontFamily)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7)),
              child: const Text('Cancel', style: TextStyle(
                  fontSize: 12, fontFamily: AdminTheme.fontFamily))),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.red,
                  foregroundColor: Colors.white, elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12,
                      fontFamily: AdminTheme.fontFamily)),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(danger)),
          ]),
        ]),
      ),
    )),
  );
}

void _snack(BuildContext ctx, String msg, Color color) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(
        fontSize: 12, fontFamily: AdminTheme.fontFamily)),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ));
}