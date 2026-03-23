// lib/views/notifications/notification_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/auth_controller.dart';
import 'package:arthro/models/notification_model.dart';
import 'package:arthro/services/app_noti_services.dart';
import '../../widgets/app_theme.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor:        AppColors.bgCard,
        elevation:              0,
        scrolledUnderElevation: 1,
        shadowColor:            AppColors.border,
        centerTitle:            true,
        title: Text('Notifications', style: AppTextStyles.sectionTitle()),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          TextButton(
            onPressed: () =>
                AppNotificationService.instance.markAllRead(uid),
            child: Text('Mark all read',
                style: AppTextStyles.bodySmall()
                    .copyWith(color: AppColors.primary)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted),
            onSelected: (v) {
              if (v == 'clear_all') _confirmClearAll(context, uid);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(children: [
                  Icon(Icons.delete_sweep_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 10),
                  Text('Clear all'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: AppNotificationService.instance.streamNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary));
          }

          final notifications = snap.data ?? [];
          if (notifications.isEmpty) return const _EmptyState();

          // Separate unread and read
          final unread = notifications.where((n) => !n.isRead).toList();
          final read   = notifications.where((n) => n.isRead).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              if (unread.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm),
                  child: Text('NEW',
                      style: AppTextStyles.labelCaps()),
                ),
                ...unread.map((n) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm),
                      child: _NotificationCard(
                          notif: n, uid: uid),
                    )),
                if (read.isNotEmpty)
                  const Divider(
                      color: AppColors.divider, height: 24),
              ],
              if (read.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm),
                  child: Text('EARLIER',
                      style: AppTextStyles.labelCaps()),
                ),
                ...read.map((n) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.sm),
                      child: _NotificationCard(
                          notif: n, uid: uid),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title:   Text('Clear All',
            style: AppTextStyles.sectionTitle()),
        content: Text(
            'Remove all notifications? This cannot be undone.',
            style: AppTextStyles.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.bodySmall()
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              AppNotificationService.instance.deleteAll(uid);
              Navigator.pop(context);
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final String          uid;
  const _NotificationCard({required this.notif, required this.uid});

  // Derive icon + colour from type AND metadata category
  _IconColor get _iconColor {
    final category = notif.metadata['category'] as String? ?? '';

    // Medication
    if (category.startsWith('medication') ||
        category.startsWith('stock')) {
      if (category == 'stock_out') {
        return _IconColor(
            Icons.medication_outlined, AppColors.tierHigh);
      }
      if (category == 'stock_low') {
        return _IconColor(
            Icons.medication_outlined, AppColors.tierLow);
      }
      return _IconColor(
          Icons.medication_rounded, AppColors.primary);
    }

    // Appointment
    if (category.startsWith('appointment')) {
      return _IconColor(
          Icons.calendar_today_rounded, const Color(0xFF8B6BAE));
    }

    // Guardian / general
    switch (notif.type) {
      case NotificationType.guardianRequest:
        return _IconColor(
            Icons.people_outline_rounded, AppColors.primary);
      case NotificationType.guardianApproved:
        return _IconColor(
            Icons.verified_user_rounded, AppColors.tierRemission);
      case NotificationType.guardianRevoked:
        return _IconColor(
            Icons.person_remove_outlined, AppColors.error);
      case NotificationType.general:
        return _IconColor(
            Icons.notifications_outlined, AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = AppNotificationService.instance;
    final ic  = _iconColor;

    return Dismissible(
      key:       Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.base),
        decoration: BoxDecoration(
          color:        AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      onDismissed: (_) =>
          svc.deleteNotification(uid, notif.id),
      child: GestureDetector(
        onTap: () {
          if (!notif.isRead) svc.markRead(uid, notif.id);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: notif.isRead
                ? AppColors.bgCard
                : ic.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: notif.isRead
                  ? AppColors.border
                  : ic.color.withOpacity(0.25),
            ),
            boxShadow: AppShadows.subtle(),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: ic.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ic.icon, color: ic.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTextStyles.cardTitle().copyWith(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: ic.color,
                              shape: BoxShape.circle),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.bodySmall()
                          .copyWith(
                              color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeago.format(notif.createdAt),
                      style: AppTextStyles.caption()
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textMuted),
                onPressed: () =>
                    svc.deleteNotification(uid, notif.id),
                padding:     EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconColor {
  final IconData icon;
  final Color    color;
  const _IconColor(this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No notifications yet',
                style: AppTextStyles.sectionTitle()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Medication reminders, appointment alerts\nand guardian updates will appear here.',
              style: AppTextStyles.bodySmall()
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}