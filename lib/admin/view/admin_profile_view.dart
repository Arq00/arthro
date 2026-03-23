// lib/admin/views/admin_profile_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_auth_controller.dart';

class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});
  @override State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool             _loadingAdmins = true;
  List<_AdminInfo> _admins        = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final snap = await _db.collection('users')
          .where('role', isEqualTo: 'admin').get();
      _admins = snap.docs.map((d) => _AdminInfo(
        uid:      d.id,
        name:     d.data()['fullName'] ?? 'Admin',
        email:    d.data()['email']    ?? '',
        isMe:     d.id == _auth.currentUser?.uid,
      )).toList();
    } catch (_) {}
    setState(() => _loadingAdmins = false);
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AdminAuthController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          const Text('Admin Profile', style: AdminTheme.tsTitle),
          const SizedBox(height: 2),
          const Text('Manage your account',
              style: AdminTheme.tsBody),
          const SizedBox(height: 24),

          _MyProfileCard(authCtrl: authCtrl),

          const SizedBox(height: 28),

          // ── Admin accounts list ──────────────────────────────────────────
          Row(children: [
            const Text('All Admin Accounts', style: AdminTheme.tsSectionTitle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_admins.length}',
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.primary,
                      fontFamily: AdminTheme.fontFamily)),
            ),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Refresh'),
              onPressed: _loadAdmins,
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTheme.primary,
                side: const BorderSide(color: AdminTheme.primary),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12,
                    fontFamily: AdminTheme.fontFamily),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          _loadingAdmins
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: AdminTheme.primary)))
              : _AdminTable(admins: _admins, onRefresh: _loadAdmins),
        ],
      ),
    );
  }
}

// ── My profile card ───────────────────────────────────────────────────────────
class _MyProfileCard extends StatefulWidget {
  final AdminAuthController authCtrl;
  const _MyProfileCard({required this.authCtrl});
  @override State<_MyProfileCard> createState() => _MyProfileCardState();
}

class _MyProfileCardState extends State<_MyProfileCard> {
  final _nameCtrl = TextEditingController();
  bool _editing   = false;
  bool _saving    = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.authCtrl.adminName;
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final name  = widget.authCtrl.adminName;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminTheme.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('My Account', style: AdminTheme.tsSectionTitle),
        const SizedBox(height: 20),

        // Avatar
        Center(child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AdminTheme.primary, AdminTheme.primaryLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                    color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: AdminTheme.fontFamily))),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.accentLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Administrator',
                style: TextStyle(color: AdminTheme.accent,
                    fontSize: 11, fontWeight: FontWeight.w600,
                    fontFamily: AdminTheme.fontFamily)),
          ),
        ])),

        const SizedBox(height: 20),
        const Divider(color: AdminTheme.border),
        const SizedBox(height: 16),

        // Name field
        const Text('Display Name',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AdminTheme.textPrimary,
                fontFamily: AdminTheme.fontFamily)),
        const SizedBox(height: 6),
        _editing
            ? TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 13,
                    fontFamily: AdminTheme.fontFamily),
                decoration: AdminTheme.inputDeco('Enter name'))
            : Text(name, style: const TextStyle(
                fontSize: 13, color: AdminTheme.textPrimary,
                fontFamily: AdminTheme.fontFamily)),

        const SizedBox(height: 14),

        // Email (read-only)
        const Text('Email',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AdminTheme.textPrimary,
                fontFamily: AdminTheme.fontFamily)),
        const SizedBox(height: 6),
        Text(email, style: AdminTheme.tsBody),

        const SizedBox(height: 20),

        // Actions
        Row(children: [
          if (_editing) ...[
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() { _editing = false;
                  _nameCtrl.text = widget.authCtrl.adminName; }),
              style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: AdminTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9))),
              child: const Text('Cancel', style: TextStyle(
                  fontSize: 13, fontFamily: AdminTheme.fontFamily,
                  color: AdminTheme.textSecondary)),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton(
              onPressed: _saving ? null : _saveName,
              style: AdminTheme.primaryBtn(),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(
                      fontSize: 13, fontFamily: AdminTheme.fontFamily)),
            )),
          ] else
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Edit Name'),
              onPressed: () => setState(() => _editing = true),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.primary,
                  side: const BorderSide(color: AdminTheme.primary),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                  textStyle: const TextStyle(fontSize: 13,
                      fontFamily: AdminTheme.fontFamily)),
            )),
        ]),
      ]),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .update({'fullName': name});
      }
      setState(() { _editing = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Name updated',
              style: TextStyle(fontSize: 12,
                  fontFamily: AdminTheme.fontFamily)),
          backgroundColor: AdminTheme.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }
}



// ── Admin accounts table ──────────────────────────────────────────────────────
class _AdminTable extends StatelessWidget {
  final List<_AdminInfo> admins;
  final VoidCallback onRefresh;
  const _AdminTable({required this.admins, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (admins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AdminTheme.card(),
        child: const Center(child: Text('No admin accounts found.',
            style: AdminTheme.tsBody)),
      );
    }
    return Container(
      decoration: AdminTheme.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          color: AdminTheme.bg,
          child: const Row(children: [
            Expanded(flex: 3, child: Text('NAME',
                style: AdminTheme.tsLabel)),
            Expanded(flex: 3, child: Text('EMAIL',
                style: AdminTheme.tsLabel)),
            Expanded(flex: 2, child: Text('ROLE',
                style: AdminTheme.tsLabel)),
          ]),
        ),
        const Divider(height: 1, color: AdminTheme.border),
        ...admins.map((a) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(flex: 3, child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AdminTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(
                      a.name.isNotEmpty
                          ? a.name[0].toUpperCase() : 'A',
                      style: const TextStyle(
                          color: AdminTheme.primary, fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: AdminTheme.fontFamily))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(a.name, style: AdminTheme.tsCardTitle,
                          overflow: TextOverflow.ellipsis),
                      if (a.isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AdminTheme.accentLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('You',
                              style: TextStyle(
                                  color: AdminTheme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AdminTheme.fontFamily)),
                        ),
                      ],
                    ]),
                  ],
                )),
              ])),
              Expanded(flex: 3, child: Text(a.email,
                  style: AdminTheme.tsBody,
                  overflow: TextOverflow.ellipsis)),
              Expanded(flex: 2, child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminTheme.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Admin',
                    style: TextStyle(
                        color: AdminTheme.accent, fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: AdminTheme.fontFamily)),
              )),
            ]),
          ),
          const Divider(height: 1, color: AdminTheme.border),
        ])),
      ]),
    );
  }
}

class _AdminInfo {
  final String uid, name, email;
  final bool isMe;
  const _AdminInfo({required this.uid, required this.name,
      required this.email, required this.isMe});
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AdminTheme.textPrimary,
          fontFamily: AdminTheme.fontFamily));
}