// lib/views/profile/account_settings_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'security_view.dart';
import '../../widgets/app_theme.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: context.read<AuthController>().currentUser?.username ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // ── Change password dialog ────────────────────────────────────────────────
  void _showChangePasswordDialog(BuildContext context) {
    final passCont    = TextEditingController();
    final confirmCont = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Change Password', style: AppTextStyles.sectionTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passCont,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCont,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                    AppTextStyles.buttonSecondary().copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () async {
              if (passCont.text != confirmCont.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              await context
                  .read<AuthController>()
                  .changePassword(passCont.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ── Copy code to clipboard ────────────────────────────────────────────────
  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied!',
            style: AppTextStyles.bodySmall()
                .copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user = auth.currentUser;

        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.bgPage,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final initials = user.fullName.trim().isNotEmpty
            ? user.fullName.trim()[0].toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor:        AppColors.bgCard,
            elevation:              0,
            scrolledUnderElevation: 1,
            shadowColor:            AppColors.border,
            centerTitle:            true,
            title: Text('Account Settings',
                style: AppTextStyles.sectionTitle()),
            iconTheme:
                const IconThemeData(color: AppColors.primary),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Avatar card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color:        AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border:       Border.all(color: AppColors.border),
                    boxShadow:    AppShadows.card(),
                  ),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color:  AppColors.primary,
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryBorder, width: 3),
                        boxShadow: AppShadows.elevated(),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   28,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(user.fullName, style: AppTextStyles.sectionTitle()),
                    const SizedBox(height: 4),
                    Text('@${user.username}',
                        style: AppTextStyles.bodySmall()
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.sm),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border:       Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: AppTextStyles.labelCaps()
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Profile info ─────────────────────────────────────────
                _SectionLabel('Profile Information'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color:        AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border:       Border.all(color: AppColors.border),
                    boxShadow:    AppShadows.subtle(),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(children: [
                    _ReadOnlyField(label: 'Full Name', value: user.fullName),
                    const SizedBox(height: AppSpacing.md),
                    _ReadOnlyField(label: 'Email', value: user.email),
                    const SizedBox(height: AppSpacing.md),
                    // Editable username
                    TextFormField(
                      controller: _usernameController,
                      style: AppTextStyles.body(),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: AppTextStyles.caption(),
                        prefixIcon: const Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.primary),
                        filled:     true,
                        fillColor:  AppColors.bgSection,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide:
                                const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                          elevation: 0,
                        ),
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (_usernameController.text.trim().isEmpty)
                                  return;
                                await auth.changeUsername(
                                    _usernameController.text.trim());
                              },
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Update Username',
                                style: AppTextStyles.buttonPrimary()),
                      ),
                    ),
                    // Status message
                    if (auth.status.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _StatusBox(
                        msg: auth.status,
                        isError: auth.status.toLowerCase().contains('fail') ||
                            auth.status.toLowerCase().contains('error'),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: AppSpacing.lg),

                /*// ── Guardian & Security (moved to Security tab) ──────────
                _SectionLabel('Guardian & Security'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color:        AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border:       Border.all(color: AppColors.border),
                    boxShadow:    AppShadows.subtle(),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical:   AppSpacing.xs),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text('Security Settings',
                        style: AppTextStyles.cardTitle()),
                    subtitle: Text(
                        'Guardian pairing, access control & password',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textMuted),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const SecurityView())),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Security ─────────────────────────────────────────────
                _SectionLabel('Security'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color:        AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border:       Border.all(color: AppColors.border),
                    boxShadow:    AppShadows.subtle(),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical:   AppSpacing.xs),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    title: Text('Change Password',
                        style: AppTextStyles.cardTitle()),
                    subtitle: Text('Update your login password',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textMuted),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ),*/

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text, style: AppTextStyles.labelCaps()),
      );
}

// ── Read-only field ───────────────────────────────────────────────────────────
class _ReadOnlyField extends StatelessWidget {
  final String label, value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => TextFormField(
        readOnly: true,
        initialValue: value,
        style: AppTextStyles.body(),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: AppTextStyles.caption(),
          filled:     true,
          fillColor:  AppColors.bgSection,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
      );
}

// ── Info banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String   title, message;
  final Color    color;
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:       Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:  color.withOpacity(0.15),
                shape:  BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.cardTitle()
                          .copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: AppTextStyles.bodySmall()
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Status box ────────────────────────────────────────────────────────────────
class _StatusBox extends StatelessWidget {
  final String msg;
  final bool   isError;
  const _StatusBox({required this.msg, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.tierRemission;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style:
                  AppTextStyles.bodySmall().copyWith(color: color)),
        ),
      ]),
    );
  }
}