// lib/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { guardianRequest, guardianApproved, guardianRevoked, general }

class AppNotification {
  final String           id;
  final NotificationType type;
  final String           title;
  final String           body;
  final bool             isRead;
  final DateTime         createdAt;
  final Map<String, dynamic> metadata; // e.g. guardianId, guardianName

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.metadata = const {},
  });

  factory AppNotification.fromMap(Map<String, dynamic> m, String id) =>
      AppNotification(
        id:        id,
        type:      _typeFromString(m['type'] as String? ?? 'general'),
        title:     m['title']  as String? ?? '',
        body:      m['body']   as String? ?? '',
        isRead:    m['isRead'] as bool?   ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        metadata:  Map<String, dynamic>.from(m['metadata'] as Map? ?? {}),
      );

  Map<String, dynamic> toMap() => {
    'type':      _typeToString(type),
    'title':     title,
    'body':      body,
    'isRead':    isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'metadata':  metadata,
  };

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id:        id,
    type:      type,
    title:     title,
    body:      body,
    isRead:    isRead ?? this.isRead,
    createdAt: createdAt,
    metadata:  metadata,
  );

  static NotificationType _typeFromString(String s) {
    switch (s) {
      case 'guardianRequest':  return NotificationType.guardianRequest;
      case 'guardianApproved': return NotificationType.guardianApproved;
      case 'guardianRevoked':  return NotificationType.guardianRevoked;
      default:                 return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType t) {
    switch (t) {
      case NotificationType.guardianRequest:  return 'guardianRequest';
      case NotificationType.guardianApproved: return 'guardianApproved';
      case NotificationType.guardianRevoked:  return 'guardianRevoked';
      case NotificationType.general:          return 'general';
    }
  }
}