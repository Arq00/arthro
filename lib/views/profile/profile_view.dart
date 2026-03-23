// lib/views/profile/profile_view.dart

import 'package:arthro/views/profile/account_settings_view.dart';
import 'package:arthro/views/profile/security_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/controllers/auth_controller.dart';
import 'package:arthro/widgets/app_theme.dart';

class ProfileView extends StatelessWidget {
  final VoidCallback? onLogout;
  const ProfileView({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user     = auth.currentUser;
        final initials = (user?.fullName.trim().isNotEmpty == true)
            ? user!.fullName.trim()[0].toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor:        AppColors.bgCard,
            elevation:              0,
            scrolledUnderElevation: 1,
            shadowColor:            AppColors.border,
            centerTitle:            true,
            automaticallyImplyLeading: true,
            title: Text('Profile', style: AppTextStyles.sectionTitle()),
            iconTheme: const IconThemeData(color: AppColors.primary),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [

                // ── Hero ──────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:  AppColors.bgCard,
                    border: Border(
                        bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.xl,
                      AppSpacing.base, AppSpacing.xl),
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color:  AppColors.primary,
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryBorder, width: 3),
                        boxShadow: AppShadows.elevated(),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(user?.fullName ?? 'User',
                        style: AppTextStyles.pageTitle()),
                    const SizedBox(height: 4),
                    Text('@${user?.username ?? ''}',
                        style: AppTextStyles.bodySmall()
                            .copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color:        AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Text(
                        (user?.role ?? '').toUpperCase(),
                        style: AppTextStyles.labelCaps()
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (user?.email.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.mail_outline_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 5),
                        Text(user!.email,
                            style: AppTextStyles.caption()
                                .copyWith(color: AppColors.textMuted)),
                      ]),
                    ],
                  ]),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Menu ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 4, bottom: AppSpacing.sm),
                        child: Text('Account',
                            style: AppTextStyles.labelCaps()),
                      ),

                      _MenuItem(
                        icon:     Icons.person_outline_rounded,
                        title:    'Account Settings',
                        subtitle: 'Manage your name and details',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AccountSettingsView())),
                      ),

                      // ← Security tab now enabled
                      _MenuItem(
                        icon:     Icons.shield_outlined,
                        title:    'Security',
                        subtitle: 'Password, guardian pairing & access control',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const SecurityView())),
                      ),

                      /*_MenuItem(
                        icon:     Icons.settings_outlined,
                        title:    'Settings',
                        subtitle: 'App preferences and configurations',
                      ),*/

                      const SizedBox(height: AppSpacing.xl),
                      
                      // ADD THIS IMPORT at top of file
                      /*const SizedBox(height: AppSpacing.lg),

                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Icon(Icons.access_time_outlined, 
                                      size: 20, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Activity Status', 
                                    style: AppTextStyles.labelCaps()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Consumer<AuthController>(
                                builder: (context, auth, _) {
                                  final user = auth.currentUser;
                                  final lastLogin = user?.lastLogin;
                                  
                                  if (lastLogin == null) {
                                    return Text('Never logged in', 
                                      style: AppTextStyles.caption()
                                        .copyWith(color: AppColors.textMuted));
                                  }
                                  
                                  final daysAgo = DateTime.now().difference(lastLogin).inDays;
                                  String status;
                                  Color color;
                                  
                                  if (daysAgo == 0) {
                                    status = 'Active today';
                                    color = Colors.green;
                                  } else if (daysAgo <= 7) {
                                    status = 'Active ${daysAgo} days ago';
                                    color = Colors.orange;
                                  } else {
                                    status = 'Inactive (${daysAgo} days ago)';
                                    color = Colors.red;
                                  } 
                                  return Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: color),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(status, 
                                        style: AppTextStyles.caption()
                                          .copyWith(color: color)),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh, size: 14),
                                        label: const Text('Update'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                          textStyle: AppTextStyles.caption(),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                        ),
                                        onPressed: () async {
                                          // Call your AuthController method
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(FirebaseAuth.instance.currentUser!.uid)
                                              .set({
                                                'lastLogin': FieldValue.serverTimestamp(),
                                                'active': true,
                                              }, SetOptions(merge: true));
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('✅ Activity updated!'),
                                              backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),*/

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                                color: AppColors.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppRadius.lg)),
                          ),
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (onLogout != null) onLogout!();
                                  await auth.logout(context);
                                },
                          icon: auth.isLoading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error))
                              : const Icon(Icons.logout_rounded, size: 18),
                          label: Text('Log Out',
                              style: AppTextStyles.buttonPrimary()
                                  .copyWith(color: AppColors.error)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
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

class _MenuItem extends StatelessWidget {
  final IconData      icon;
  final String        title;
  final String?       subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: BoxDecoration(
      color:        AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border:       Border.all(color: AppColors.border),
      boxShadow:    AppShadows.subtle(),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.xs),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color:        AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(title, style: AppTextStyles.cardTitle()),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.textMuted))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 13, color: AppColors.textMuted),
      onTap: onTap,
    ),
  );
}