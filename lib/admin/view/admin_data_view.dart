// lib/admin/views/admin_data_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_user_controller.dart';
import '../controllers/admin_data_controller.dart';

class AdminDataView extends StatefulWidget {
  const AdminDataView({super.key});
  @override State<AdminDataView> createState() => _AdminDataViewState();
}

class _AdminDataViewState extends State<AdminDataView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDataController>().loadLibrary('exercise_library');
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header + tabs ──────────────────────────────────────────────────────
      Container(
        color: AdminTheme.bgCard,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Library & Data', style: AdminTheme.tsTitle),
              SizedBox(height: 2),
              Text('Exercise & nutrition content library', style: AdminTheme.tsBody),
            ]),
          ]),
          const SizedBox(height: 14),
          TabBar(
            controller: _tabs,
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textSecondary,
            indicatorColor: AdminTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600,
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
        ]),
      ),
      const Divider(height: 1, color: AdminTheme.border),
      Expanded(child: TabBarView(controller: _tabs, children: const [
        _LibraryTab(collection: 'exercise_library'),
        _LibraryTab(collection: 'nutrition_library'),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIBRARY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _LibraryTab extends StatelessWidget {
  final String collection;
  const _LibraryTab({required this.collection});
  bool get isExercise => collection == 'exercise_library';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminDataController>(
      builder: (ctx, ctrl, _) {
        final items = isExercise ? ctrl.exercises : ctrl.nutrition;
        if (ctrl.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator(
              color: AdminTheme.primary));
        }
        return Column(children: [
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
                label: Text('Add ${isExercise ? "Exercise" : "Plan"}',
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
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
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => _LibraryCard(
              item: items[i], isExercise: isExercise,
              onEdit:   () => _showDialog(ctx, ctrl, items[i]),
              onDelete: () => _doDelete(ctx, ctrl, items[i]),
            ),
          )),
        ]);
      },
    );
  }

  Future<void> _showDialog(BuildContext ctx,
      AdminDataController ctrl, AdminCrudItem? item) async {
    final nameCtrl = TextEditingController(text: item?.data['name'] ?? '');
    final tierCtrl = TextEditingController(
        text: item?.data['tierId'] ?? 'MODERATE');
    final durCtrl  = TextEditingController(
        text: item?.data['duration'] ?? item?.data['dailyGoal'] ?? '');
    final descCtrl = TextEditingController(
        text: (item?.data['benefits'] as List?)?.join('\n')
            ?? item?.data['description'] ?? '');

    await showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        title: Text(
          item == null
              ? 'Add ${isExercise ? "Exercise" : "Nutrition Plan"}'
              : 'Edit ${item.data['name'] ?? "Item"}',
          style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: AdminTheme.fontFamily)),
        content: SizedBox(width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Fld('Name', nameCtrl),
            const SizedBox(height: 10),
            _TierDrop(ctrl: tierCtrl),
            const SizedBox(height: 10),
            _Fld(isExercise
                ? 'Duration (e.g. 20-30 min)' : 'Daily Goal', durCtrl),
            const SizedBox(height: 10),
            _Fld(isExercise
                ? 'Benefits (one per line)' : 'Description',
                descCtrl, maxLines: 3),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7)),
            child: const Text('Cancel', style: TextStyle(
                fontSize: 13, fontFamily: AdminTheme.fontFamily))),
          ElevatedButton(
            style: AdminTheme.primaryBtn(),
            onPressed: () async {
              final data = {
                'name':   nameCtrl.text.trim(),
                'tierId': tierCtrl.text.trim().toUpperCase(),
                if (isExercise) ...{
                  'duration': durCtrl.text.trim(),
                  'benefits': descCtrl.text.trim()
                      .split('\n').where((l) => l.isNotEmpty).toList(),
                } else ...{
                  'dailyGoal':   durCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                },
              };
              Navigator.pop(dialogCtx);
              item == null
                  ? await ctrl.createItem(collection, data)
                  : await ctrl.updateItem(collection, item.id, data);
            },
            child: Text(item == null ? 'Add' : 'Save',
                style: const TextStyle(fontSize: 13,
                    fontFamily: AdminTheme.fontFamily)),
          ),
        ],
      ),
    );
  }

  Future<void> _doDelete(BuildContext ctx,
      AdminDataController ctrl, AdminCrudItem item) async {
    final ok = await _miniConfirm(ctx,
        title: 'Delete "${item.data['name']}"?',
        danger: 'Delete');
    if (ok == true) await ctrl.deleteItem(collection, item.id);
  }
}

class _LibraryCard extends StatelessWidget {
  final AdminCrudItem item;
  final bool isExercise;
  final VoidCallback onEdit, onDelete;
  const _LibraryCard({required this.item, required this.isExercise,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d    = item.data;
    final tier = (d['tierId'] ?? '').toString().toUpperCase();
    final c    = AdminTheme.tierColor(tier);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AdminTheme.card(radius: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: AdminTheme.tierBg(tier),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(isExercise
              ? Icons.fitness_center_rounded
              : Icons.restaurant_rounded, color: c, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(d['name'] ?? '—', style: AdminTheme.tsCardTitle),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AdminTheme.tierBg(tier),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tier, style: TextStyle(
                    color: c, fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: AdminTheme.fontFamily)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(isExercise
                ? 'Duration: ${d['duration'] ?? '—'}'
                : d['dailyGoal'] ?? '—',
                style: AdminTheme.tsSmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 15, color: AdminTheme.primary),
            onPressed: onEdit, tooltip: 'Edit',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints()),
        const SizedBox(width: 4),
        IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 15, color: AdminTheme.red),
            onPressed: onDelete, tooltip: 'Delete',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints()),
      ]),
    );
  }
}

// ── Field + dropdown helpers ──────────────────────────────────────────────────
class _Fld extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int maxLines;
  const _Fld(this.label, this.ctrl, {this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AdminTheme.textPrimary,
          fontFamily: AdminTheme.fontFamily)),
      const SizedBox(height: 4),
      TextField(controller: ctrl, maxLines: maxLines,
          style: const TextStyle(fontSize: 13,
              fontFamily: AdminTheme.fontFamily),
          decoration: AdminTheme.inputDeco('')),
    ],
  );
}

class _TierDrop extends StatefulWidget {
  final TextEditingController ctrl;
  const _TierDrop({required this.ctrl});
  @override State<_TierDrop> createState() => _TierDropState();
}

class _TierDropState extends State<_TierDrop> {
  static const tiers = ['REMISSION','LOW','MODERATE','HIGH'];
  @override
  Widget build(BuildContext context) {
    final val = tiers.contains(widget.ctrl.text.toUpperCase())
        ? widget.ctrl.text.toUpperCase() : 'MODERATE';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tier', style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AdminTheme.textPrimary,
          fontFamily: AdminTheme.fontFamily)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: val,
        decoration: AdminTheme.inputDeco(''),
        style: const TextStyle(fontSize: 13,
            color: AdminTheme.textPrimary,
            fontFamily: AdminTheme.fontFamily),
        items: tiers.map((t) => DropdownMenuItem(value: t,
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: AdminTheme.tierColor(t),
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(t),
          ]),
        )).toList(),
        onChanged: (v) { if (v != null) widget.ctrl.text = v; },
      ),
    ]);
  }
}

// ── Mini confirm dialog (smaller than full confirm) ───────────────────────────
Future<bool?> _miniConfirm(BuildContext ctx,
    {required String title, required String danger}) {
  return showDialog<bool>(
    context: ctx,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      title: Text(title, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: AdminTheme.fontFamily)),
      content: const Text('This cannot be undone.',
          style: TextStyle(fontSize: 12,
              color: AdminTheme.textSecondary,
              fontFamily: AdminTheme.fontFamily)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7)),
          child: const Text('Cancel', style: TextStyle(
              fontSize: 12, fontFamily: AdminTheme.fontFamily))),
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
      ],
    ),
  );
}