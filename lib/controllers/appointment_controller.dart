// lib/controllers/appointment_controller.dart

import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentController extends ChangeNotifier {
  late final AppointmentService _service;

  List<Appointment> _appointments = [];

  List<Appointment> get upcomingAppointments => _appointments
      .where((a) => !a.isCompleted)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Appointment> get historyAppointments => _appointments
      .where((a) => a.isCompleted)
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  /// [uid] — pass the patient's uid when a guardian is viewing.
  /// Leave null to use the signed-in user's own data.
  AppointmentController({String? uid}) {
    _service = AppointmentService(uid: uid);
    _listen();
  }

  void _listen() {
    _service.appointmentStream().listen((appts) {
      _appointments = appts;
      notifyListeners();
    });
  }

  Future<void> addAppointment({
    required String   title,
    required String   personInCharge,
    required String   location,
    required DateTime dateTime,
    String preNotes        = '',
    int    reminderMinutes = 60,
  }) async {
    final appt = Appointment(
      id:             '',
      title:          title,
      personInCharge: personInCharge,
      location:       location,
      dateTime:       dateTime,
      preNotes:       preNotes,
      createdAt:      DateTime.now(),
    );
    await _service.addAppointment(appt, reminderMinutes);
  }

  Future<void> updateAppointment(
      Appointment appt, int reminderMinutes) async {
    await _service.updateAppointment(appt, reminderMinutes);
  }

  Future<void> markAsDone(String id, {String postNotes = ''}) async {
    await _service.markAsDone(id, postNotes);
  }

  Future<void> deleteAppointment(String id) async {
    await _service.deleteAppointment(id);
  }
}