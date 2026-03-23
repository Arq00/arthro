// ============================================================
// models/user_model.dart
// ADDED: activeRapid3Tier, activeRapid3Score, tierUpdatedAt,
//        tierLogDate — written by SymptomService, read by
//        Lifestyle module via AuthController.currentUser
// ============================================================

import 'package:arthro/models/symptom_usertier_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String role;
  final String? patientId;
  final String? guardianId;
  final String? linkCode;
  final DateTime? linkCodeCreatedAt;
  final DateTime? createdAt;

  // ── RAPID3 tier (written by SymptomService.saveLog) ──────
  final String? activeRapid3Tier;    // "REMISSION"|"LOW"|"MODERATE"|"HIGH"
  final double? activeRapid3Score;
  final DateTime? tierUpdatedAt;
  final String? tierLogDate;         // "2026-02-25"

  final DateTime? lastLogin;
  final bool? active;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    this.patientId,
    this.guardianId,
    this.linkCode,
    this.linkCodeCreatedAt,
    this.createdAt,
    this.activeRapid3Tier,
    this.activeRapid3Score,
    this.tierUpdatedAt,
    this.tierLogDate,
    this.lastLogin,
    this.active,
  });

  /// Convenience getter used by LifestyleController
  UserTierStatus get tierStatus => UserTierStatus(
    tier:        activeRapid3Tier,
    rapid3Score: activeRapid3Score,
    updatedAt:   tierUpdatedAt,
    logDate:     tierLogDate,
  );

  Map<String, dynamic> toMap() {
    return {
      'uid':               uid,
      'email':             email,
      'fullName':          fullName,
      'username':          username,
      'role':              role,
      'patientId':         patientId,
      'guardianId':        guardianId,
      'linkCode':          linkCode,
      'linkCodeCreatedAt': linkCodeCreatedAt != null
          ? Timestamp.fromDate(linkCodeCreatedAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'active': active,
      // Tier fields are written by SymptomService, not here
      // toMap() is used for registration — new users have no tier yet
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid:               map['uid']         ?? '',
      email:             map['email']       ?? '',
      fullName:          map['fullName']    ?? '',
      username:          map['username']    ?? '',
      role:              map['role']        ?? '',
      patientId:         map['patientId'],
      guardianId:        map['guardianId'],
      linkCode:          map['linkCode'],
      linkCodeCreatedAt: map['linkCodeCreatedAt'] != null
          ? (map['linkCodeCreatedAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      // Tier fields — null-safe, absent on new accounts
      activeRapid3Tier:  map['activeRapid3Tier']  as String?,
      activeRapid3Score: (map['activeRapid3Score'] as num?)?.toDouble(),
      tierUpdatedAt: map['tierUpdatedAt'] != null
          ? (map['tierUpdatedAt'] as Timestamp).toDate()
          : null,
      tierLogDate: map['tierLogDate'] as String?,
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
      active: map['active'] as bool?,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? role,
    String? patientId,
    String? guardianId,
    String? linkCode,
    DateTime? linkCodeCreatedAt,
    DateTime? createdAt,
    String? activeRapid3Tier,
    double? activeRapid3Score,
    DateTime? tierUpdatedAt,
    String? tierLogDate,
    DateTime? lastLogin,
    bool? active,
  }) {
    return UserModel(
      uid:               uid               ?? this.uid,
      email:             email             ?? this.email,
      fullName:          fullName          ?? this.fullName,
      username:          username          ?? this.username,
      role:              role              ?? this.role,
      patientId:         patientId         ?? this.patientId,
      guardianId:        guardianId        ?? this.guardianId,
      linkCode:          linkCode          ?? this.linkCode,
      linkCodeCreatedAt: linkCodeCreatedAt ?? this.linkCodeCreatedAt,
      createdAt:         createdAt         ?? this.createdAt,
      activeRapid3Tier:  activeRapid3Tier  ?? this.activeRapid3Tier,
      activeRapid3Score: activeRapid3Score ?? this.activeRapid3Score,
      tierUpdatedAt:     tierUpdatedAt     ?? this.tierUpdatedAt,
      tierLogDate:       tierLogDate       ?? this.tierLogDate,
      lastLogin:         lastLogin         ?? this.lastLogin,
      active:            active            ?? this.active,
    );
  }
}