// lib/views/profile/security_view.dart
// Security tab: password change + guardian list (revoke) + pairing code (patients only)

import 'package:arthro/views/navigation/global_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_theme.dart';

class SecurityView extends StatelessWidget {
  const SecurityView({super.key});

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

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor:        AppColors.bgCard,
            elevation:              0,
            scrolledUnderElevation: 1,
            shadowColor:            AppColors.border,
            centerTitle:            true,
            title: Text('Security', style: AppTextStyles.sectionTitle()),
            iconTheme: const IconThemeData(color: AppColors.primary),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Password ─────────────────────────────────────────────
                _SectionLabel('Password'),
                const SizedBox(height: AppSpacing.sm),
                _Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical:   AppSpacing.xs),
                    leading: _IconBox(
                        Icons.lock_outline_rounded, AppColors.primary),
                    title: Text('Change Password',
                        style: AppTextStyles.cardTitle()),
                    subtitle: Text('Update your login password',
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textMuted),
                    onTap: () => _showChangePasswordDialog(context, auth),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Pairing Code (patients only) ─────────────────────────
                if (user.role == 'patient') ...[
                  _SectionLabel('Guardian Pairing Code'),
                  const SizedBox(height: AppSpacing.sm),
                  _PairingCodeSection(auth: auth),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Guardian list (patients only) ────────────────────────
                if (user.role == 'patient') ...[
                  _SectionLabel('Linked Guardian'),
                  const SizedBox(height: AppSpacing.sm),
                  _GuardianListSection(auth: auth),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Patient info (guardians only) ────────────────────────
                if (user.role == 'guardian') ...[
                  _SectionLabel('Linked Patient'),
                  const SizedBox(height: AppSpacing.sm),
                  _LinkedPatientSection(auth: auth),
                  const SizedBox(height: AppSpacing.lg),
                ],

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AuthController auth) {
    final passCont    = TextEditingController();
    final confirmCont = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Change Password',
            style: AppTextStyles.sectionTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passCont,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'New Password'),
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
                style: AppTextStyles.buttonSecondary()
                    .copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () async {
              if (passCont.text != confirmCont.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Passwords do not match')),
                );
                return;
              }
              await auth.changePassword(passCont.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
/*Future<void> _handleRevoke(AuthController auth) async {
  try {
    await auth.revokeGuardian();
    // Show snackbar using root navigator (SAFE)
    if (mounted) {
      ScaffoldMessenger.of(GlobalNavigation.navigatorKey.currentContext!).showSnackBar(
        SnackBar(content: Text(auth.status.isNotEmpty ? auth.status : 'Guardian removed')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(GlobalNavigation.globalNavKey.currentContext!).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}*/

// ── Pairing code section ──────────────────────────────────────────────────────
class _PairingCodeSection extends StatelessWidget {
  final AuthController auth;
  const _PairingCodeSection({required this.auth});

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied!',
            style: AppTextStyles.bodySmall()
                .copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    // Already has guardian
    if (user.guardianId != null) {
      return _InfoBanner(
        icon:    Icons.verified_user_rounded,
        title:   'Guardian Already Linked',
        message: 'You already have a linked guardian. Remove them first to generate a new code.',
        color:   AppColors.tierRemission,
      );
    }

    // Has a code
    if (user.linkCode != null) {
      return _Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(children: [
            const Icon(Icons.qr_code_rounded,
                size: 36, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Share with your Guardian',
                style: AppTextStyles.cardTitle(),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color:        AppColors.bgPage,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border:
                    Border.all(color: AppColors.primary, width: 2),
              ),
              child: Text(
                user.linkCode!,
                style: const TextStyle(
                  fontSize:      32,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: 8,
                  color:         AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text('Copy Code',
                    style: AppTextStyles.buttonPrimary()),
                onPressed: () => _copyCode(context, user.linkCode!),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed:
                  auth.isLoading ? null : () => auth.generateGuardianCode(),
              child: Text('Generate New Code',
                  style: AppTextStyles.bodySmall()
                      .copyWith(color: AppColors.textMuted)),
            ),
            Text('Code expires 30 minutes after generation',
                style: AppTextStyles.caption()
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    // No code yet
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.link_rounded,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Link a Guardian', style: AppTextStyles.sectionTitle()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Generate a pairing code and share it with your guardian.',
            style: AppTextStyles.bodySmall()
                .copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.md)),
                elevation: 0,
              ),
              icon: const Icon(Icons.qr_code_rounded, size: 20),
              label: Text('Generate Pairing Code',
                  style: AppTextStyles.buttonPrimary()),
              onPressed: auth.isLoading
                  ? null
                  : () => auth.generateGuardianCode(),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Guardian list section (patient sees their guardian) ───────────────────────
class _GuardianListSection extends StatelessWidget {
  final AuthController auth;
  const _GuardianListSection({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    if (user.guardianId == null) {
      return _InfoBanner(
        icon:    Icons.shield_outlined,
        title:   'No Guardian Linked',
        message: 'Generate a pairing code above and share it with your guardian.',
        color:   AppColors.textMuted,
      );
    }

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _IconBox(Icons.shield_rounded, AppColors.tierRemission),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guardian Linked',
                        style: AppTextStyles.cardTitle()),
                    const SizedBox(height: 2),
                    Text(
                      'Your guardian can view your health data.',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.base),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.base),

            // Revoke button
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                      color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md)),
                ),
                icon: const Icon(Icons.person_remove_outlined,
                    size: 18),
                label: Text('Remove Guardian',
                    style: AppTextStyles.buttonPrimary()
                        .copyWith(color: AppColors.error)),
                onPressed: () => _confirmRevoke(context, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle
            ),
            child: const Icon(Icons.person_remove_outlined,
              color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Remove Guardian',
            style: AppTextStyles.sectionTitle()
          ),
        ]),
        content: Text(
          'This will remove your guardian\'s access to your health data. '
          'They will need to send a new request to reconnect.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // ✅ Safe
            child: Text('Cancel', style: AppTextStyles.buttonSecondary()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop(); // ✅ Pop FIRST
              await auth.revokeGuardian(); // Then unlink
            },
            child: Text('Remove', style: AppTextStyles.buttonPrimary()),
          ),
        ],
      ),
    );
  }
}

// ── Linked patient section (guardian sees their patient) ──────────────────────
class _LinkedPatientSection extends StatelessWidget {
  final AuthController auth;
  const _LinkedPatientSection({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser!;

    if (user.patientId == null || user.patientId!.isEmpty) {
      return _InfoBanner(
        icon:    Icons.person_search_outlined,
        title:   'No Patient Linked',
        message: 'Go to the Home tab to link a patient using their pairing code.',
        color:   AppColors.warning,
      );
    }

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _IconBox(Icons.favorite_rounded,
                  const Color(0xFF92400E)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Linked',
                        style: AppTextStyles.cardTitle()),
                    const SizedBox(height: 2),
                    Text(
                      'You are monitoring a linked patient.',
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.base),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                      color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md)),
                ),
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: Text('Unlink Patient',
                    style: AppTextStyles.buttonPrimary()
                        .copyWith(color: AppColors.error)),
                onPressed: () => _confirmUnlink(context, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnlink(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)
        ),
        title: Text('Unlink Patient',
          style: AppTextStyles.sectionTitle()
        ),
        content: Text(
          'This will remove your access to the patient\'s health data.',
          style: AppTextStyles.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // ✅ Safe
            child: Text('Cancel', style: AppTextStyles.buttonSecondary()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop(); // ✅ Pop FIRST
              await auth.revokeGuardian(); // Then unlink (same method!)
            },
            child: Text('Unlink', style: AppTextStyles.buttonPrimary()),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text, style: AppTextStyles.labelCaps()),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:       Border.all(color: AppColors.border),
          boxShadow:    AppShadows.subtle(),
        ),
        child: child,
      );
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _IconBox(this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: color, size: 18),
      );
}

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
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:       Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.cardTitle().copyWith(color: color)),
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