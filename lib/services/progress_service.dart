// lib/services/progress_service.dart
// Fetches a user's very first symptomLog and compares to their current score.
// Used by HomeController to populate the My Progress card.

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ProgressSummary {
  // First-ever log
  final double firstScore;
  final String firstTier;
  final DateTime firstDate;

  // Current (from UserModel.activeRapid3Score / activeRapid3Tier)
  final double currentScore;
  final String currentTier;
  final DateTime? currentDate; // tierUpdatedAt

  // Total logs recorded
  final int totalLogs;

  const ProgressSummary({
    required this.firstScore,
    required this.firstTier,
    required this.firstDate,
    required this.currentScore,
    required this.currentTier,
    this.currentDate,
    required this.totalLogs,
  });

  // Positive = improvement (score went down)
  double get delta => firstScore - currentScore;

  bool get isImproved  => delta > 0.5;
  bool get isWorsened  => delta < -0.5;
  bool get isStable    => !isImproved && !isWorsened;

  // EULAR-style response label
  String get responseLabel {
    if (delta >= 1.2) return 'Good Response';
    if (delta >= 0.6) return 'Moderate Response';
    if (delta <= -0.6) return 'Worsening';
    return 'No Change';
  }

  String get responseEmoji {
    if (delta >= 1.2)  return '✅';
    if (delta >= 0.6)  return '🟡';
    if (delta <= -0.6) return '⚠️';
    return '➡️';
  }

  Duration get trackingDuration => currentDate != null
      ? currentDate!.difference(firstDate)
      : DateTime.now().difference(firstDate);

  String get durationLabel {
    final days = trackingDuration.inDays;
    if (days < 7)   return '$days days';
    if (days < 30)  return '${(days / 7).round()} weeks';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()}yr ${((days % 365) / 30).round()}mo';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final _db = FirebaseFirestore.instance;

  /// Fetches the first symptomLog doc (doc IDs are log_YYYYMMDD so
  /// alphabetical order == chronological order).
  /// Also reads the total count of logs for "X logs recorded" display.
  Future<ProgressSummary?> fetchProgress({
    required String uid,
    required double currentScore,
    required String currentTier,
    required DateTime? currentDate,
  }) async {
    try {
      final col = _db.collection('users').doc(uid).collection('symptomLogs');

      // First log — oldest doc ID ascending
      final firstSnap = await col
          .orderBy(FieldPath.documentId)
          .limit(1)
          .get();

      if (firstSnap.docs.isEmpty) {
        dev.log('[ProgressService] no symptomLogs found for uid=$uid');
        return null;
      }

      final firstDoc  = firstSnap.docs.first;
      final firstData = firstDoc.data();

      final firstScore = (firstData['rapid3Score'] as num?)?.toDouble();
      final firstTier  = firstData['rapid3Tier'] as String?;

      // createdAt is stored as millisecondsSinceEpoch (int) per SymptomLog.toMap()
      final createdAtMs = firstData['createdAt'] as int?;
      DateTime? firstDate;
      if (createdAtMs != null) {
        firstDate = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
      } else {
        // Fallback: parse from doc ID "log_YYYYMMDD"
        firstDate = _parseDateFromDocId(firstDoc.id);
      }

      if (firstScore == null || firstTier == null || firstDate == null) {
        dev.log('[ProgressService] missing fields in first log: ${firstDoc.id}');
        return null;
      }

      // Total log count
      final countSnap = await col.count().get();
      final totalLogs = countSnap.count ?? 0;

      dev.log('[ProgressService] first=$firstScore/$firstTier '
          'current=$currentScore/$currentTier '
          'total=$totalLogs');

      return ProgressSummary(
        firstScore:   firstScore,
        firstTier:    firstTier,
        firstDate:    firstDate,
        currentScore: currentScore,
        currentTier:  currentTier,
        currentDate:  currentDate,
        totalLogs:    totalLogs,
      );
    } catch (e) {
      dev.log('[ProgressService] error: $e');
      return null;
    }
  }

  /// Parses "log_20250115" → DateTime(2025, 1, 15)
  static DateTime? _parseDateFromDocId(String docId) {
    try {
      // docId format: log_YYYYMMDD
      final digits = docId.replaceAll('log_', '');
      if (digits.length != 8) return null;
      final y = int.parse(digits.substring(0, 4));
      final m = int.parse(digits.substring(4, 6));
      final d = int.parse(digits.substring(6, 8));
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }
}