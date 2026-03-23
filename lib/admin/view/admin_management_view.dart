// lib/admin/views/admin_management_view.dart
//
// Combined "Management" page.
// ┌──────────────────────────────────────────────────────┐
// │  Management                                          │
// │  Users · Library                                     │
// │ ┌──────────────┬──────────────────────────────────┐  │
// │ │  👥 Users    │  📚 Library                      │  │
// │ └──────────────┴──────────────────────────────────┘  │
// │                                                      │
// │  [Users tab]  → full patient/guardian user table    │
// │                                                      │
// │  [Library tab] → sub-tabs: Exercise | Nutrition     │
// └──────────────────────────────────────────────────────┘
//
// The two sections are intentionally styled differently so
// neither the admin nor an examiner can confuse them:
//
//   • Users tab     → teal accent, group icon, patient data
//   • Library tab   → amber accent, book icon, content CRUD
//
// Each tab carries its own header strip with title, subtitle,
// and a coloured left-border banner so the context is always
// visible even after scrolling.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_user_controller.dart';
import '../controllers/admin_data_controller.dart';

// Re-export the individual tab bodies from their original files.
// This keeps each section's internal logic unchanged — only the
// navigation shell is combined here.
import 'admin_user_list_view.dart'  show AdminUserListView;
import 'admin_data_view.dart'       show AdminDataView;

// ── Accent colours for each section ──────────────────────────────────────────
const _kUsersAccent   = AdminTheme.primary;       // teal
const _kLibraryAccent = Color(0xFFB45309);         // amber-700

class AdminManagementView extends StatefulWidget {
  const AdminManagementView({super.key});
  @override State<AdminManagementView> createState() =>
      _AdminManagementViewState();
}

class _AdminManagementViewState extends State<AdminManagementView>
    with SingleTickerProviderStateMixin {

  late TabController _topTabs;
  int _activeTop = 0;

  @override
  void initState() {
    super.initState();
    _topTabs = TabController(length: 2, vsync: this);
    _topTabs.addListener(() {
      if (_topTabs.indexIsChanging) return;
      setState(() => _activeTop = _topTabs.index);
    });
  }

  @override
  void dispose() { _topTabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Shared page header ─────────────────────────────────────────────────
      _ManagementHeader(tabCtrl: _topTabs, activeIndex: _activeTop),
      const Divider(height: 1, color: AdminTheme.border),

      // ── Tab bodies ─────────────────────────────────────────────────────────
      Expanded(
        child: TabBarView(
          controller: _topTabs,
          // Disable swipe — the two sections contain their own scroll views
          // and accidental swipes between sections would be confusing.
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _UsersSection(),
            _LibrarySection(),
          ],
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HEADER WITH TOP-LEVEL TABS
// ─────────────────────────────────────────────────────────────────────────────
class _ManagementHeader extends StatelessWidget {
  final TabController tabCtrl;
  final int activeIndex;
  const _ManagementHeader({
    required this.tabCtrl, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final accent = activeIndex == 0 ? _kUsersAccent : _kLibraryAccent;
    final subtitle = activeIndex == 0
        ? 'Manage patient & guardian accounts'
        : 'Manage exercise & nutrition content library';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: AdminTheme.bgCard,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Page title row
        Row(children: [
          // Coloured section indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4, height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Management', style: AdminTheme.tsTitle),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(subtitle,
                  key: ValueKey(activeIndex),
                  style: AdminTheme.tsBody),
            ),
          ]),
        ]),

        const SizedBox(height: 16),

        // ── Top-level tab bar ──────────────────────────────────────────────
        TabBar(
          controller: tabCtrl,
          // Each tab is individually coloured to reinforce the separation
          labelColor:           accent,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor:       accent,
          indicatorWeight:      3,
          indicatorSize:        TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              fontFamily: AdminTheme.fontFamily),
          unselectedLabelStyle: const TextStyle(
              fontSize: 13, fontFamily: AdminTheme.fontFamily),
          tabs: const [
            Tab(
              icon: Icon(Icons.group_rounded, size: 16),
              text: 'Users',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.menu_book_rounded, size: 16),
              text: 'Library',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION A — USERS
// Wraps AdminUserListView with a visible section banner so the context
// is always clear even after the page header scrolls off.
// ─────────────────────────────────────────────────────────────────────────────
class _UsersSection extends StatelessWidget {
  const _UsersSection();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Section identity banner
      _SectionBanner(
        color:    _kUsersAccent,
        icon:     Icons.group_rounded,
        label:    'USERS',
        subtitle: 'Patient & guardian accounts',
      ),
      // Full user list (scroll, filter, search, sort all inside)
      const Expanded(child: AdminUserListView()),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION B — LIBRARY
// Wraps AdminDataView (which already has its own Exercise / Nutrition sub-tabs)
// with a visible amber section banner.
// ─────────────────────────────────────────────────────────────────────────────
class _LibrarySection extends StatelessWidget {
  const _LibrarySection();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Section identity banner
      _SectionBanner(
        color:    _kLibraryAccent,
        icon:     Icons.menu_book_rounded,
        label:    'LIBRARY',
        subtitle: 'Exercise & nutrition content — organised by disease tier',
      ),
      // Full library view with its own Exercise / Nutrition sub-tabs
      const Expanded(child: _LibraryBody()),
    ]);
  }
}

// ── Library body — strips AdminDataView's own header to avoid double titles ──
// AdminDataView renders its own "Library & Data" title + TabBar internally.
// Here we embed AdminDataView but override the top padding so it flows
// cleanly under our amber section banner.
class _LibraryBody extends StatefulWidget {
  const _LibraryBody();
  @override State<_LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends State<_LibraryBody>
    with SingleTickerProviderStateMixin {
  late TabController _libTabs;

  @override
  void initState() {
    super.initState();
    _libTabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDataController>().loadLibrary('exercise_library');
    });
  }

  @override
  void dispose() { _libTabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Sub-tab bar (Exercise | Nutrition) with amber accent
      Container(
        color: AdminTheme.bgCard,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: TabBar(
          controller: _libTabs,
          labelColor:           _kLibraryAccent,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor:       _kLibraryAccent,
          indicatorWeight:      2,
          indicatorSize:        TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              fontFamily: AdminTheme.fontFamily),
          unselectedLabelStyle: const TextStyle(
              fontSize: 13, fontFamily: AdminTheme.fontFamily),
          tabs: const [
            Tab(text: 'Exercise Library'),
            Tab(text: 'Nutrition Library'),
          ],
          onTap: (i) {
            final ctrl = context.read<AdminDataController>();
            if (i == 0) ctrl.loadLibrary('exercise_library');
            if (i == 1) ctrl.loadLibrary('nutrition_library');
          },
        ),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: TabBarView(
        controller: _libTabs,
        children: const [
          _LibraryTabContent(collection: 'exercise_library'),
          _LibraryTabContent(collection: 'nutrition_library'),
        ],
      )),
    ]);
  }
}

// ── Thin section identity banner (always visible, never scrolls away) ─────────
class _SectionBanner extends StatelessWidget {
  final Color    color;
  final IconData icon;
  final String   label;
  final String   subtitle;
  const _SectionBanner({
    required this.color, required this.icon,
    required this.label, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border(
          left:   BorderSide(color: color, width: 4),
          bottom: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: color, letterSpacing: 1.2,
                fontFamily: AdminTheme.fontFamily)),
        const SizedBox(width: 10),
        Text('—  $subtitle',
            style: const TextStyle(
                fontSize: 11, color: AdminTheme.textMuted,
                fontFamily: AdminTheme.fontFamily)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LibraryTabContent
// Inlined from admin_data_view.dart's _LibraryTab so we don't need to
// re-export that private class. Any future changes to _LibraryTab should
// be mirrored here (or refactored into a shared widget).
// ─────────────────────────────────────────────────────────────────────────────
class _LibraryTabContent extends StatelessWidget {
  final String collection;
  const _LibraryTabContent({required this.collection});

  bool get isExercise => collection == 'exercise_library';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDataController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.loading) {
          return const Center(child: CircularProgressIndicator(
              color: AdminTheme.primary));
        }

        final items = isExercise ? ctrl.exercises : ctrl.nutrition;

        return Column(children: [
          // Sub-section header with item count + add button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${items.length} items',
                    style: AdminTheme.tsSectionTitle),
                Text(
                  isExercise
                      ? 'Exercises shown to patients based on their disease tier'
                      : 'Nutrition plans assigned by disease tier',
                  style: AdminTheme.tsSmall),
              ]),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                    'Add ${isExercise ? "Exercise" : "Plan"}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        fontFamily: AdminTheme.fontFamily)),
                onPressed: () => _showDialog(ctx, ctrl, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(130, 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AdminTheme.border),

          if (items.isEmpty)
            Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isExercise
                    ? Icons.fitness_center_rounded
                    : Icons.restaurant_menu_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No ${isExercise ? "exercises" : "plans"} yet',
                    style: AdminTheme.tsCardTitle),
                const SizedBox(height: 6),
                Text('Tap "+ Add ${isExercise ? "Exercise" : "Plan"}" to create one',
                    style: AdminTheme.tsSmall),
              ],
            )))
          else
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (ctx, i) =>
                  _LibraryItemCard(
                    item:      items[i],
                    ctrl:      ctrl,
                    onEdit:    () => _showDialog(ctx, ctrl, items[i]),
                    onDelete:  () => _doDelete(ctx, ctrl, items[i]),
                  ),
            )),
        ]);
      },
    );
  }

  void _showDialog(BuildContext ctx, AdminDataController ctrl,
      dynamic existing) {
    // Delegate to the dialog defined in admin_data_view.dart
    // by re-importing or calling a shared method.
    // For simplicity, inline the dialog call here.
    showDialog(
      context: ctx,
      builder: (_) => _LibraryDialog(
          collection: collection,
          existing:   existing,
          ctrl:       ctrl),
    );
  }

  Future<void> _doDelete(BuildContext ctx, AdminDataController ctrl,
      dynamic item) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Delete item?',
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: AdminTheme.fontFamily)),
              const SizedBox(height: 8),
              const Text(
                  'This will permanently remove this item from the library.',
                  style: TextStyle(fontSize: 12,
                      color: AdminTheme.textSecondary,
                      fontFamily: AdminTheme.fontFamily)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                TextButton(
                    onPressed: () => Navigator.pop(dCtx, false),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: AdminTheme.fontFamily))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12,
                          fontFamily: AdminTheme.fontFamily)),
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: const Text('Delete'),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (ok == true && ctx.mounted) {
      await ctrl.deleteItem(collection, item.id);
    }
  }
}

// ── Library item card ──────────────────────────────────────────────────────────
class _LibraryItemCard extends StatefulWidget {
  final dynamic item;
  final AdminDataController ctrl;
  final VoidCallback onEdit, onDelete;
  const _LibraryItemCard({
    required this.item, required this.ctrl,
    required this.onEdit, required this.onDelete,
  });
  @override State<_LibraryItemCard> createState() => _LibraryItemCardState();
}

class _LibraryItemCardState extends State<_LibraryItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d      = widget.item.data as Map<String, dynamic>;
    final name   = d['name'] as String? ?? 'Unnamed';
    final tier   = (d['tierId'] ?? d['tier'] ?? '') as String;
    final detail = d['duration'] as String?
        ?? d['dailyGoal'] as String?
        ?? '';

    final tierColor = AdminTheme.tierColor(tier);
    final tierBg    = AdminTheme.tierBg(tier);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovered ? AdminTheme.bg : AdminTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Row(children: [
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: tierBg,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              tier.isEmpty ? '—'
                  : tier[0] + tier.substring(1).toLowerCase(),
              style: TextStyle(color: tierColor, fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: AdminTheme.fontFamily),
            ),
          ),
          const SizedBox(width: 14),
          // Name + detail
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AdminTheme.tsCardTitle,
                  overflow: TextOverflow.ellipsis),
              if (detail.isNotEmpty)
                Text(detail, style: AdminTheme.tsSmall,
                    overflow: TextOverflow.ellipsis),
            ],
          )),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: AdminTheme.primary),
            onPressed: widget.onEdit,
            tooltip: 'Edit',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 16, color: AdminTheme.red),
            onPressed: widget.onDelete,
            tooltip: 'Delete',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    );
  }
}

// ── Library add/edit dialog ────────────────────────────────────────────────────
class _LibraryDialog extends StatefulWidget {
  final String collection;
  final dynamic existing;
  final AdminDataController ctrl;
  const _LibraryDialog({
    required this.collection, required this.existing,
    required this.ctrl,
  });
  @override State<_LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<_LibraryDialog> {
  final _name    = TextEditingController();
  final _detail  = TextEditingController(); // duration or dailyGoal
  final _focus   = TextEditingController();
  String _tier   = 'HIGH';
  bool   _saving = false;

  bool get isExercise => widget.collection == 'exercise_library';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing.data as Map<String, dynamic>;
      _name.text   = d['name']      as String? ?? '';
      _detail.text = (isExercise ? d['duration'] : d['dailyGoal'])
                         as String? ?? '';
      _focus.text  = (isExercise ? d['type'] : d['focusArea'])
                         as String? ?? '';
      _tier        = (d['tierId'] ?? d['tier'] ?? 'HIGH') as String;
    }
  }

  @override
  void dispose() {
    _name.dispose(); _detail.dispose(); _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Dialog title
            Row(children: [
              Icon(isExercise
                  ? Icons.fitness_center_rounded
                  : Icons.restaurant_menu_rounded,
                  size: 18, color: _kLibraryAccent),
              const SizedBox(width: 8),
              Text(
                '${isEdit ? "Edit" : "Add"} '
                '${isExercise ? "Exercise" : "Nutrition Plan"}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    fontFamily: AdminTheme.fontFamily)),
            ]),
            const SizedBox(height: 20),

            _Fld('Name', _name),
            const SizedBox(height: 12),
            _Fld(isExercise ? 'Duration (e.g. 15-20 min)' : 'Daily Goal',
                _detail),
            const SizedBox(height: 12),
            _Fld(isExercise ? 'Type (e.g. Stretching)' : 'Focus Area',
                _focus),
            const SizedBox(height: 12),

            // Tier dropdown
            Text('Disease Tier',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textSecondary,
                    fontFamily: AdminTheme.fontFamily)),
            const SizedBox(height: 6),
            _TierDrop(value: _tier, onChanged: (v) =>
                setState(() => _tier = v ?? 'HIGH')),

            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 13,
                          fontFamily: AdminTheme.fontFamily))),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(90, 38),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: AdminTheme.fontFamily)),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final data = isExercise
        ? {
            'name':     _name.text.trim(),
            'duration': _detail.text.trim(),
            'type':     _focus.text.trim(),
            'tierId':   _tier,
          }
        : {
            'name':      _name.text.trim(),
            'dailyGoal': _detail.text.trim(),
            'focusArea': _focus.text.trim(),
            'tierId':    _tier,
          };

    if (widget.existing == null) {
      await widget.ctrl.createItem(widget.collection, data);
    } else {
      await widget.ctrl.updateItem(
          widget.collection, widget.existing.id, data);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }
}

// ── Field + dropdown helpers ──────────────────────────────────────────────────
class _Fld extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _Fld(this.label, this.ctrl);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AdminTheme.textSecondary,
          fontFamily: AdminTheme.fontFamily)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13,
            fontFamily: AdminTheme.fontFamily),
        decoration: AdminTheme.inputDeco(label),
      ),
    ],
  );
}

class _TierDrop extends StatefulWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _TierDrop({required this.value, required this.onChanged});
  @override State<_TierDrop> createState() => _TierDropState();
}

class _TierDropState extends State<_TierDrop> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: widget.value,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13,
          color: AdminTheme.textPrimary,
          fontFamily: AdminTheme.fontFamily),
      decoration: AdminTheme.inputDeco('Tier'),
      items: const [
        DropdownMenuItem(value: 'REMISSION', child: Text('REMISSION')),
        DropdownMenuItem(value: 'LOW',       child: Text('LOW')),
        DropdownMenuItem(value: 'MODERATE',  child: Text('MODERATE')),
        DropdownMenuItem(value: 'HIGH',      child: Text('HIGH')),
      ],
    );
  }
}