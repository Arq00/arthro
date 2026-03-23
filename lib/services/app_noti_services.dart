// lib/services/app_notification_service.dart
// Firestore-based in-app notification service.
// Separate from notification_service.dart (which handles local push notifications).

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  // ── Stream all notifications (real-time) ──────────────────────────────────
  Stream<List<AppNotification>> streamNotifications(String uid) =>
      _col(uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs
              .map((d) => AppNotification.fromMap(d.data(), d.id))
              .toList());

  // ── Unread count stream ───────────────────────────────────────────────────
  Stream<int> streamUnreadCount(String uid) =>
      _col(uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length);

  // ── Add notification ──────────────────────────────────────────────────────
  Future<void> addNotification(String uid, AppNotification notif) async {
    await _col(uid).add(notif.toMap());
  }

  // ── Mark as read ──────────────────────────────────────────────────────────
  Future<void> markRead(String uid, String notifId) async {
    await _col(uid).doc(notifId).update({'isRead': true});
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<void> markAllRead(String uid) async {
    final snap = await _col(uid).where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Delete notification ───────────────────────────────────────────────────
  Future<void> deleteNotification(String uid, String notifId) async {
    await _col(uid).doc(notifId).delete();
  }

  // ── Delete all notifications ──────────────────────────────────────────────
  Future<void> deleteAll(String uid) async {
    final snap = await _col(uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Convenience: write guardian request notification to patient ───────────
  Future<void> notifyPatientOfRequest({
    required String patientUid,
    required String guardianId,
    required String guardianName,
  }) async {
    final notif = AppNotification(
      id:        '',
      type:      NotificationType.guardianRequest,
      title:     'New Guardian Request',
      body:      '$guardianName wants to become your guardian.',
      isRead:    false,
      createdAt: DateTime.now(),
      metadata:  {'guardianId': guardianId, 'guardianName': guardianName},
    );
    await addNotification(patientUid, notif);
  }

  // ── Convenience: write approval notification to guardian ─────────────────
  Future<void> notifyGuardianOfApproval({
    required String guardianUid,
    required String patientName,
  }) async {
    final notif = AppNotification(
      id:        '',
      type:      NotificationType.guardianApproved,
      title:     'Request Approved',
      body:      '$patientName approved your guardian request.',
      isRead:    false,
      createdAt: DateTime.now(),
      metadata:  {'patientName': patientName},
    );
    await addNotification(guardianUid, notif);
  }

  // ── Convenience: write revoke notification ────────────────────────────────
  Future<void> notifyRevoked({
    required String targetUid,
    required String message,
  }) async {
    final notif = AppNotification(
      id:        '',
      type:      NotificationType.guardianRevoked,
      title:     'Guardian Access Removed',
      body:      message,
      isRead:    false,
      createdAt: DateTime.now(),
      metadata:  {},
    );
    await addNotification(targetUid, notif);
  }
}