// lib/admin/views/admin_management_view.dart
//
// Combined "Management" page — Users + Library in one nav entry.
//
// Layout:
//   Top tabs:  [👥 Users]  [📚 Library]
//   Users  → full patient/guardian user table (teal accent)
//   Library → [Exercise Library] [Nutrition Library] sub-tabs (amber accent)
//
// Bug fix: Firestore fields like 'dailyGoal', 'duration', 'description'
// may be stored as List<dynamic> or String depending on how they were
// originally seeded. All field reads use _str() / _list() helpers that
// handle both types safely — no more TypeError cast crashes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_user_controller.dart';
import '../controllers/admin_data_controller.dart';
import 'admin_user_list_view.dart';

// ── Section accent colours ─────────────────────────────────────────────────────
const _kUsersAccent   = AdminTheme.primary;
const _kLibraryAccent = Color(0xFFB45309); // amber-700

// ── Safe field-read helpers ────────────────────────────────────────────────────
// Firestore fields can be String OR List<dynamic> depending on seed/version.
// These helpers never throw.

String _str(dynamic v, [String fallback = '']) {
  if (v == null)   return fallback;
  if (v is String) return v;
  if (v is List)   return v.map((e) => e.toString()).join(', ');
  return v.toString();
}

List<String> _list(dynamic v) {
  if (v == null)   return [];
  if (v is List)   return v.map((e) => e.toString()).toList();
  if (v is String) return v.isEmpty ? [] : [v];
  return [];
}

// ══════════════════════════════════════════════════════════════════════════════
// ROOT WIDGET
// ══════════════════════════════════════════════════════════════════════════════
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
    final accent = _activeTop == 0 ? _kUsersAccent : _kLibraryAccent;
    return Column(children: [
      _PageHeader(tabCtrl: _topTabs, activeIndex: _activeTop, accent: accent),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: TabBarView(
        controller: _topTabs,
        physics: const NeverScrollableScrollPhysics(),
        children: const [_UsersSection(), _LibrarySection()],
      )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  final TabController tabCtrl;
  final int   activeIndex;
  final Color accent;
  const _PageHeader({required this.tabCtrl,
      required this.activeIndex, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.bgCard,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4, height: 38,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Management', style: AdminTheme.tsTitle),
            const SizedBox(height: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                key: ValueKey(activeIndex),
                activeIndex == 0
                    ? 'Patient & guardian accounts'
                    : 'Exercise & nutrition content library',
                style: AdminTheme.tsBody),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        TabBar(
          controller: tabCtrl,
          labelColor:           accent,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor:       accent,
          indicatorWeight:      3,
          indicatorSize:        TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: AdminTheme.fontFamily),
          unselectedLabelStyle: const TextStyle(fontSize: 13,
              fontFamily: AdminTheme.fontFamily),
          tabs: const [
            Tab(icon: Icon(Icons.group_rounded, size: 16),
                text: 'Users', iconMargin: EdgeInsets.only(bottom: 2)),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 16),
                text: 'Library', iconMargin: EdgeInsets.only(bottom: 2)),
          ],
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION A — USERS
// ══════════════════════════════════════════════════════════════════════════════
class _UsersSection extends StatelessWidget {
  const _UsersSection();
  @override
  Widget build(BuildContext context) => Column(children: [
    _SectionBanner(color: _kUsersAccent, icon: Icons.group_rounded,
        label: 'USERS', subtitle: 'Manage patient & guardian accounts'),
    const Expanded(child: AdminUserListView()),
  ]);
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION B — LIBRARY
// ══════════════════════════════════════════════════════════════════════════════
class _LibrarySection extends StatelessWidget {
  const _LibrarySection();
  @override
  Widget build(BuildContext context) => Column(children: [
    _SectionBanner(color: _kLibraryAccent, icon: Icons.menu_book_rounded,
        label: 'LIBRARY',
        subtitle: 'Content shown to patients based on disease tier'),
    const Expanded(child: _LibraryBody()),
  ]);
}

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
      Container(
        color: AdminTheme.bgCard,
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
        child: TabBar(
          controller: _libTabs,
          labelColor:           _kLibraryAccent,
          unselectedLabelColor: AdminTheme.textSecondary,
          indicatorColor:       _kLibraryAccent,
          indicatorWeight:      2,
          indicatorSize:        TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              fontFamily: AdminTheme.fontFamily),
          unselectedLabelStyle: const TextStyle(fontSize: 13,
              fontFamily: AdminTheme.fontFamily),
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
          _LibraryGrid(collection: 'exercise_library'),
          _LibraryGrid(collection: 'nutrition_library'),
        ],
      )),
    ]);
  }
}

// ── Thin coloured section identity banner ─────────────────────────────────────
class _SectionBanner extends StatelessWidget {
  final Color color; final IconData icon;
  final String label, subtitle;
  const _SectionBanner({required this.color, required this.icon,
      required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      border: Border(
        left:   BorderSide(color: color, width: 4),
        bottom: BorderSide(color: color.withOpacity(0.18), width: 1),
      ),
    ),
    child: Row(children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
          color: color, letterSpacing: 1.4,
          fontFamily: AdminTheme.fontFamily)),
      const SizedBox(width: 10),
      Text('—  $subtitle', style: const TextStyle(fontSize: 11,
          color: AdminTheme.textMuted, fontFamily: AdminTheme.fontFamily)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// LIBRARY GRID — responsive card grid with safe Firestore reads
// ══════════════════════════════════════════════════════════════════════════════
class _LibraryGrid extends StatelessWidget {
  final String collection;
  const _LibraryGrid({required this.collection});
  bool get isExercise => collection == 'exercise_library';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDataController>(
      builder: (ctx, ctrl, _) {
        if (ctrl.loading) return const Center(
            child: CircularProgressIndicator(color: AdminTheme.primary));

        final items = isExercise ? ctrl.exercises : ctrl.nutrition;

        return Column(children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
            color: AdminTheme.bgCard,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _kLibraryAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kLibraryAccent.withOpacity(0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isExercise
                      ? Icons.fitness_center_rounded
                      : Icons.restaurant_menu_rounded,
                      size: 13, color: _kLibraryAccent),
                  const SizedBox(width: 6),
                  Text('${items.length} '
                      '${isExercise ? "exercises" : "plans"}',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kLibraryAccent,
                          fontFamily: AdminTheme.fontFamily)),
                ]),
              ),
              const SizedBox(width: 10),
              Text(
                isExercise
                    ? 'Shown to patients based on disease tier'
                    : 'Nutrition plans assigned by disease tier',
                style: AdminTheme.tsSmall),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text('Add ${isExercise ? "Exercise" : "Plan"}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: AdminTheme.fontFamily)),
                onPressed: () => _showDialog(ctx, ctrl, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white, elevation: 0,
                  minimumSize: const Size(130, 40),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: AdminTheme.border),

          if (items.isEmpty)
            Expanded(child: Center(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
              Icon(isExercise
                  ? Icons.fitness_center_rounded
                  : Icons.restaurant_menu_rounded,
                  size: 52, color: Colors.grey.shade200),
              const SizedBox(height: 14),
              Text('No ${isExercise ? "exercises" : "plans"} yet',
                  style: AdminTheme.tsCardTitle),
              const SizedBox(height: 6),
              const Text('Tap the button above to add one',
                  style: AdminTheme.tsSmall),
            ])))
          else
            Expanded(child: LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth < 700 ? 1
                         : c.maxWidth < 1100 ? 2 : 3;
              return GridView.builder(
                padding: const EdgeInsets.all(28),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:   cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing:  16,
                  childAspectRatio: isExercise ? 1.55 : 1.45,
                ),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _LibraryCard(
                  item:       items[i],
                  isExercise: isExercise,
                  onEdit:     () => _showDialog(ctx, ctrl, items[i]),
                  onDelete:   () => _doDelete(ctx, ctrl, items[i]),
                ),
              );
            })),
        ]);
      },
    );
  }

  void _showDialog(BuildContext ctx, AdminDataController ctrl, dynamic ex) {
    showDialog(context: ctx, builder: (_) =>
        _LibraryDialog(collection: collection, existing: ex, ctrl: ctrl));
  }

  Future<void> _doDelete(BuildContext ctx, AdminDataController ctrl,
      dynamic item) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AdminTheme.redBg,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: AdminTheme.red),
                ),
                const SizedBox(width: 10),
                const Text('Delete item?', style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: AdminTheme.fontFamily)),
              ]),
              const SizedBox(height: 12),
              const Text(
                  'This item will be permanently removed from the library '
                  'and will no longer be shown to patients.',
                  style: TextStyle(fontSize: 12,
                      color: AdminTheme.textSecondary,
                      fontFamily: AdminTheme.fontFamily)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed: () => Navigator.pop(dCtx, false),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12,
                        fontFamily: AdminTheme.fontFamily))),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.red,
                      foregroundColor: Colors.white, elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    if (ok == true && ctx.mounted) await ctrl.deleteItem(collection, item.id);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LIBRARY CARD — rich grid card, all fields read safely via _str()/_list()
// ══════════════════════════════════════════════════════════════════════════════
class _LibraryCard extends StatefulWidget {
  final dynamic item;
  final bool isExercise;
  final VoidCallback onEdit, onDelete;
  const _LibraryCard({required this.item, required this.isExercise,
      required this.onEdit, required this.onDelete});
  @override State<_LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<_LibraryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.item.data as Map<String, dynamic>;

    final name      = _str(d['name'], 'Unnamed');
    final tier      = _str(d['tierId'] ?? d['tier']);
    final tierColor = AdminTheme.tierColor(tier);
    final tierBg    = AdminTheme.tierBg(tier);
    final tierLabel = tier.isEmpty ? '—'
        : tier[0] + tier.substring(1).toLowerCase();

    // Exercise
    final duration   = _str(d['duration']);
    final type       = _str(d['type']);
    final intensity  = _str(d['intensity']);
    final difficulty = _str(d['difficulty']);
    final benefits   = _list(d['benefits']);

    // Nutrition
    final dailyGoal = _str(d['dailyGoal']);
    final focusArea = _str(d['focusArea']);
    final examples  = _list(d['examples']);

    final subtitle = widget.isExercise
        ? [if (type.isNotEmpty) type, if (duration.isNotEmpty) duration]
              .join(' · ')
        : focusArea.isNotEmpty ? focusArea : _str(d['description']);

    final chips = widget.isExercise
        ? benefits.take(3).toList()
        : examples.take(3).toList();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? AdminTheme.bg : AdminTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _hovered
                  ? tierColor.withOpacity(0.4) : AdminTheme.border),
          boxShadow: _hovered ? [BoxShadow(
              color: tierColor.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Card header with tier badge + action buttons
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              border: Border(bottom: BorderSide(
                  color: tierColor.withOpacity(0.15))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: tierBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tierLabel, style: TextStyle(
                    color: tierColor, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.3,
                    fontFamily: AdminTheme.fontFamily)),
              ),
              const Spacer(),
              _IconBtn(icon: Icons.edit_outlined,
                  color: AdminTheme.primary,
                  tooltip: 'Edit', onTap: widget.onEdit),
              const SizedBox(width: 2),
              _IconBtn(icon: Icons.delete_outline_rounded,
                  color: AdminTheme.red,
                  tooltip: 'Delete', onTap: widget.onDelete),
            ]),
          ),

          // Card body
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: AdminTheme.textPrimary,
                  fontFamily: AdminTheme.fontFamily),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(
                    fontSize: 11, color: AdminTheme.textSecondary,
                    fontFamily: AdminTheme.fontFamily),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],

              // Exercise: intensity + difficulty chips
              if (widget.isExercise &&
                  (intensity.isNotEmpty || difficulty.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if (intensity.isNotEmpty)
                    _MetaChip(icon: Icons.bolt_rounded,
                        label: intensity, color: AdminTheme.amber),
                  if (intensity.isNotEmpty && difficulty.isNotEmpty)
                    const SizedBox(width: 6),
                  if (difficulty.isNotEmpty)
                    _MetaChip(icon: Icons.bar_chart_rounded,
                        label: difficulty, color: AdminTheme.primary),
                ]),
              ],

              // Nutrition: daily goal
              if (!widget.isExercise && dailyGoal.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.flag_rounded,
                      size: 11, color: AdminTheme.primary),
                  const SizedBox(width: 4),
                  Expanded(child: Text(dailyGoal,
                      style: const TextStyle(fontSize: 11,
                          color: AdminTheme.textSecondary,
                          fontFamily: AdminTheme.fontFamily),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ],

              const Spacer(),

              // Benefit / example chips
              if (chips.isNotEmpty)
                Wrap(spacing: 5, runSpacing: 5,
                    children: chips.map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminTheme.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: Text(c, style: const TextStyle(
                          fontSize: 10, color: AdminTheme.textSecondary,
                          fontFamily: AdminTheme.fontFamily)),
                    )).toList()),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final String tooltip; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color,
      required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 15, color: color))),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _MetaChip({required this.icon, required this.label,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w600, color: color,
          fontFamily: AdminTheme.fontFamily)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD / EDIT DIALOG
// ══════════════════════════════════════════════════════════════════════════════
class _LibraryDialog extends StatefulWidget {
  final String collection;
  final dynamic existing;
  final AdminDataController ctrl;
  const _LibraryDialog({required this.collection,
      required this.existing, required this.ctrl});
  @override State<_LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<_LibraryDialog> {
  final _name   = TextEditingController();
  final _detail = TextEditingController();
  final _focus  = TextEditingController();
  String _tier  = 'HIGH';
  bool _saving  = false;

  bool get isExercise => widget.collection == 'exercise_library';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing.data as Map<String, dynamic>;
      // _str() handles List or String safely — this was the crash source
      _name.text   = _str(d['name']);
      _detail.text = isExercise ? _str(d['duration']) : _str(d['dailyGoal']);
      _focus.text  = isExercise ? _str(d['type'])     : _str(d['focusArea']);
      final t = _str(d['tierId'] ?? d['tier'], 'HIGH');
      _tier = t.isEmpty ? 'HIGH' : t;
    }
  }

  @override
  void dispose() { _name.dispose(); _detail.dispose();
      _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Dialog header
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kLibraryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(isExercise
                    ? Icons.fitness_center_rounded
                    : Icons.restaurant_menu_rounded,
                    size: 18, color: _kLibraryAccent)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${isEdit ? "Edit" : "Add"} '
                    '${isExercise ? "Exercise" : "Nutrition Plan"}',
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: AdminTheme.fontFamily)),
                Text(isExercise
                    ? 'Shown to patients matching the selected tier'
                    : 'Assigned to patients matching the selected tier',
                    style: AdminTheme.tsSmall),
              ]),
            ]),

            const SizedBox(height: 20),
            const Divider(height: 1, color: AdminTheme.border),
            const SizedBox(height: 16),

            _Fld('Name *', _name),
            const SizedBox(height: 14),
            _Fld(isExercise
                ? 'Duration  (e.g. 15–20 min)'
                : 'Daily Goal', _detail),
            const SizedBox(height: 14),
            _Fld(isExercise
                ? 'Type  (e.g. Stretching, Aerobic)'
                : 'Focus Area', _focus),
            const SizedBox(height: 14),

            const Text('Disease Tier', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AdminTheme.textSecondary,
                fontFamily: AdminTheme.fontFamily)),
            const SizedBox(height: 8),
            _TierPicker(value: _tier,
                onChanged: (v) => setState(() => _tier = v)),

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(
                      fontSize: 13, fontFamily: AdminTheme.fontFamily))),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white, elevation: 0,
                    minimumSize: const Size(100, 40),
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
                    : Text(isEdit ? 'Save Changes' : 'Add Item'),
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
        ? {'name': _name.text.trim(), 'duration': _detail.text.trim(),
           'type': _focus.text.trim(), 'tierId': _tier}
        : {'name': _name.text.trim(), 'dailyGoal': _detail.text.trim(),
           'focusArea': _focus.text.trim(), 'tierId': _tier};

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

// ── Tier segmented picker (replaces ugly dropdown) ─────────────────────────────
class _TierPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TierPicker({required this.value, required this.onChanged});

  static const _tiers = ['REMISSION', 'LOW', 'MODERATE', 'HIGH'];

  @override
  Widget build(BuildContext context) {
    return Row(children: _tiers.map((t) {
      final sel = t == value;
      final c   = AdminTheme.tierColor(t);
      final bg  = AdminTheme.tierBg(t);
      return Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? bg : AdminTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel ? c : AdminTheme.border,
                  width: sel ? 1.5 : 1),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: sel ? c : AdminTheme.border,
                      shape: BoxShape.circle)),
              const SizedBox(height: 4),
              Text(t[0] + t.substring(1).toLowerCase(),
                  style: TextStyle(fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      color: sel ? c : AdminTheme.textSecondary,
                      fontFamily: AdminTheme.fontFamily),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      ));
    }).toList());
  }
}

// ── Text field helper ──────────────────────────────────────────────────────────
class _Fld extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _Fld(this.label, this.ctrl);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AdminTheme.textSecondary,
          fontFamily: AdminTheme.fontFamily)),
      const SizedBox(height: 6),
      TextField(controller: ctrl,
          style: const TextStyle(fontSize: 13,
              fontFamily: AdminTheme.fontFamily),
          decoration: AdminTheme.inputDeco(label)),
    ],
  );
}