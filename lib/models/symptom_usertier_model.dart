// lib/models/symptom_usertier_model.dart
// Lightweight snapshot of a user's current RAPID3 tier.
// Written by SymptomService.saveLog() into users/{uid}.
// Read by:
//   - HealthController  → drive lifestyle recommendations
//   - HomeView          → show today's tier card
//   - GuardianView      → show patient's current tier
//   - LifestyleController (if standalone lifestyle module exists)
//
// This is NOT a Firestore collection — it is a sub-object
// stored directly on the UserModel document (users/{uid}).

class UserTierStatus {
  /// "REMISSION" | "LOW" | "MODERATE" | "HIGH" | null (never logged)
  final String? tier;

  /// The calculated RAPID3 score, e.g. 3.2
  final double? rapid3Score;

  /// When this tier was last written (from Timestamp in Firestore)
  final DateTime? updatedAt;

  /// ISO date string of the log that produced this tier, e.g. "2026-02-25"
  final String? logDate;

  const UserTierStatus({
    this.tier,
    this.rapid3Score,
    this.updatedAt,
    this.logDate,
  });

  // ─── Convenience getters ───────────────────────────────

  /// True if the user has ever completed a RAPID3 assessment
  bool get hasTier => tier != null;

  /// True if the tier was logged today
  bool get isToday {
    if (logDate == null) return false;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return logDate == today;
  }

  /// Human-readable tier label
  String get tierLabel {
    switch (tier) {
      case 'REMISSION': return 'Remission';
      case 'LOW':       return 'Low Activity';
      case 'MODERATE':  return 'Moderate Activity';
      case 'HIGH':      return 'High Activity / Flare';
      default:          return 'Not assessed';
    }
  }

  /// Tier emoji matching rapid3TierDefinitions in Firestore
  String get tierEmoji {
    switch (tier) {
      case 'REMISSION': return '🟢';
      case 'LOW':       return '🟡';
      case 'MODERATE':  return '🟠';
      case 'HIGH':      return '🔴';
      default:          return '⚪';
    }
  }

  /// Hex colour matching rapid3TierDefinitions.colorHex in Firestore
  String get colorHex {
    switch (tier) {
      case 'REMISSION': return '#10B981';
      case 'LOW':       return '#F59E0B';
      case 'MODERATE':  return '#F97316';
      case 'HIGH':      return '#EF4444';
      default:          return '#6B7280';
    }
  }

  /// How long ago the tier was updated, for display
  String get updatedAgoLabel {
    if (updatedAt == null) return 'Never';
    final diff = DateTime.now().difference(updatedAt!);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// Serialise to map — written into users/{uid} by SymptomService
  Map<String, dynamic> toFirestoreFields() => {
    'activeRapid3Tier':  tier,
    'activeRapid3Score': rapid3Score,
    'tierUpdatedAt':     updatedAt != null
        ? updatedAt!.millisecondsSinceEpoch
        : null,
    'tierLogDate':       logDate,
  };

  @override
  String toString() =>
      'UserTierStatus(tier: $tier, score: $rapid3Score, logDate: $logDate)';
}