// lib/models/connection_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequest {
  final String requestId;
  final String guardianId;
  final String guardianName;
  final String patientId;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  const ConnectionRequest({
    required this.requestId,
    required this.guardianId,
    required this.guardianName,
    required this.patientId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'requestId':    requestId,
        'guardianId':   guardianId,
        'guardianName': guardianName,
        'patientId':    patientId,
        'status':       status,
        'createdAt':    Timestamp.fromDate(createdAt),
      };

  factory ConnectionRequest.fromMap(Map<String, dynamic> map) =>
      ConnectionRequest(
        requestId:    map['requestId']    ?? '',
        guardianId:   map['guardianId']   ?? '',
        guardianName: map['guardianName'] ?? '',
        patientId:    map['patientId']    ?? '',
        status:       map['status']       ?? 'pending',
        createdAt: map['createdAt'] != null
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}