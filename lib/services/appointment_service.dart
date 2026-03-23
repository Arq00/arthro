// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import 'notification_service.dart';

class AppointmentService {
  final _db = FirebaseFirestore.instance;

  /// If a uid is supplied (guardian viewing patient), use it.
  /// Otherwise fall back to the signed-in user's own uid.
  final String? _overrideUid;
  AppointmentService({String? uid}) : _overrideUid = uid;

  String get _uid =>
      _overrideUid ?? FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _apptRef =>
      _db.collection('users').doc(_uid).collection('appointments');

  // ─── Stream ───────────────────────────────────────────────────────────────

  Stream<List<Appointment>> appointmentStream() {
    return _apptRef
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromFirestore(d))
            .toList());
  }

  // ─── Add ──────────────────────────────────────────────────────────────────

  Future<void> addAppointment(
      Appointment appt, int reminderMinutes) async {
    final doc = await _apptRef.add(appt.toFirestore());
    await NotificationService.scheduleAppointment(
      apptId:          doc.id,
      title:           appt.title,
      personInCharge:  appt.personInCharge,
      dateTime:        appt.dateTime,
      reminderMinutes: reminderMinutes,
    );
    debugPrint('[AppointmentService] Added: ${appt.title}');
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateAppointment(
      Appointment appt, int reminderMinutes) async {
    await _apptRef.doc(appt.id).update(appt.toFirestore());
    await NotificationService.scheduleAppointment(
      apptId:          appt.id,
      title:           appt.title,
      personInCharge:  appt.personInCharge,
      dateTime:        appt.dateTime,
      reminderMinutes: reminderMinutes,
    );
    debugPrint('[AppointmentService] Updated: ${appt.title}');
  }

  // ─── Mark done ────────────────────────────────────────────────────────────

  Future<void> markAsDone(String id, String postNotes) async {
    await NotificationService.cancelAppointment(id);
    await _apptRef.doc(id).update({
      'isCompleted': true,
      'postNotes':   postNotes,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteAppointment(String id) async {
    await NotificationService.cancelAppointment(id);
    await _apptRef.doc(id).delete();
    debugPrint('[AppointmentService] Deleted appointment $id');
  }
}