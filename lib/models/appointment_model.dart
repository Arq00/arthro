// lib/models/appointment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String   id;
  final String   title;
  final String   personInCharge;
  final String   location;
  final DateTime dateTime;
  final String   preNotes;
  final String   postNotes;
  final bool     isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Appointment({
    required this.id,
    required this.title,
    required this.personInCharge,
    required this.location,
    required this.dateTime,
    this.preNotes    = '',
    this.postNotes   = '',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Appointment(
      id:             doc.id,
      title:          d['title']          ?? '',
      personInCharge: d['personInCharge'] ?? '',
      location:       d['location']       ?? '',
      dateTime:       (d['dateTime']  as Timestamp).toDate(),
      preNotes:       d['preNotes']   ?? '',
      postNotes:      d['postNotes']  ?? '',
      isCompleted:    d['isCompleted'] ?? false,
      createdAt:      (d['createdAt'] as Timestamp).toDate(),
      completedAt:    d['completedAt'] != null
          ? (d['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':          title,
    'personInCharge': personInCharge,
    'location':       location,
    'dateTime':       Timestamp.fromDate(dateTime),
    'preNotes':       preNotes,
    'postNotes':      postNotes,
    'isCompleted':    isCompleted,
    'createdAt':      Timestamp.fromDate(createdAt),
  };

  Appointment copyWith({
    String?   title,
    String?   personInCharge,
    String?   location,
    DateTime? dateTime,
    String?   preNotes,
    String?   postNotes,
    bool?     isCompleted,
  }) => Appointment(
    id:             id,
    title:          title          ?? this.title,
    personInCharge: personInCharge ?? this.personInCharge,
    location:       location       ?? this.location,
    dateTime:       dateTime       ?? this.dateTime,
    preNotes:       preNotes       ?? this.preNotes,
    postNotes:      postNotes      ?? this.postNotes,
    isCompleted:    isCompleted    ?? this.isCompleted,
    createdAt:      createdAt,
    completedAt:    completedAt,
  );
}