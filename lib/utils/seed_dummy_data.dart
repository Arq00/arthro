// lib/utils/seed_multi_user.dart
//
// Seeds dummy data for up to 10 Firebase Auth users.
//
// USAGE:
//   1. Create 10 accounts in Firebase Console → Authentication → Add User
//   2. Copy each UID into the list inside SeedMultiUserButton
//   3. Drop <SeedMultiUserButton /> into any dev screen, tap the button
//   4. Remove before shipping to production
//
// Each user has a unique RA story arc from Dec 2024 → Mar 2026.
// Logging frequency is intentionally inconsistent (sparse, dense, or gapped).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER PROFILE  — defines each user's unique story
// ─────────────────────────────────────────────────────────────────────────────
class _UserProfile {
  final String name;
  final String gender;
  final int    age;
  final String doctorName;
  final String city;

  // Symptom arc: list of [year, month, day, pain, func, global, stiffMin, stress, joints]
  final List<List<dynamic>> symptomRows;

  // Med adherence multipliers (0.0–1.0) applied on top of base rates
  final double mtxAdherence;    // weekly
  final double hcqAdherence;    // twice daily
  final double folicAdherence;  // daily
  final double nsaidAdherence;  // as-needed

  const _UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.doctorName,
    required this.city,
    required this.symptomRows,
    required this.mtxAdherence,
    required this.hcqAdherence,
    required this.folicAdherence,
    required this.nsaidAdherence,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SEEDER
// ─────────────────────────────────────────────────────────────────────────────
class SeedMultiUser {
  static final _db = FirebaseFirestore.instance;

  /// Seeds all UIDs. Skips null/empty entries gracefully.
  static Future<void> seedAll(List<String> uids) async {
    // Seed global collections once
    try {
      await _seedGlobalCollections();
    } catch (e) {
      print('[Seed] ⚠️  Global collections skipped: $e');
    }

    final profiles = _buildProfiles();
    for (int i = 0; i < uids.length && i < profiles.length; i++) {
      final uid = uids[i].trim();
      if (uid.isEmpty) continue;
      print('[Seed] ── User ${i + 1}: ${profiles[i].name} (uid=$uid)');
      await _seedUser(uid, profiles[i]);
    }
    print('[Seed] ✅ All users seeded.');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BUILD 10 USER PROFILES
  // ───────────────────────────────────────────────────────────────────────────
  static List<_UserProfile> _buildProfiles() => [

    // ── USER 1: Farah — steady improver, high adherence ─────────────────────
    // Arc: starts HIGH (Dec 24), gradual improvement, reaches REMISSION
    //      by mid-2025, stays LOW–REMISSION through Mar 2026.
    // Logs: near-daily Dec–Feb, then every 2–3 days.
    _UserProfile(
      name: 'Farah Izzati', gender: 'Female', age: 34,
      doctorName: 'Dr. Aisha Rahman', city: 'Kuala Lumpur',
      mtxAdherence: 1.0, hcqAdherence: 0.95,
      folicAdherence: 0.90, nsaidAdherence: 0.70,
      symptomRows: [
        // Dec 2024 — HIGH flare
        [2024,12, 1, 7.5,2.1,7.0, 90,8.0,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 3, 8.0,2.3,7.5,100,8.5,['leftKnee','rightKnee','rightWrist','leftWrist']],
        [2024,12, 5, 7.0,2.0,6.5, 75,7.5,['leftKnee','rightKnee']],
        [2024,12, 7, 6.5,1.9,6.0, 60,7.0,['leftKnee','leftWrist']],
        [2024,12, 9, 6.0,1.8,5.5, 60,6.5,['leftKnee']],
        [2024,12,11, 5.5,1.6,5.0, 45,6.0,['leftKnee','leftWrist']],
        [2024,12,13, 5.0,1.5,4.5, 30,5.5,['leftKnee']],
        [2024,12,15, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        [2024,12,18, 4.0,1.2,3.5, 20,4.5,['leftWrist']],
        [2024,12,21, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2024,12,24, 3.0,0.9,2.5, 10,3.5,<String>[]],
        [2024,12,27, 2.5,0.8,2.0, 10,3.0,<String>[]],
        [2024,12,30, 2.0,0.7,1.5,  0,2.5,['leftWrist']],
        // Jan 2025 — LOW, improving
        [2025, 1, 2, 1.5,0.5,1.0,  0,2.0,<String>[]],
        [2025, 1, 5, 2.0,0.6,1.5,  0,2.5,['leftKnee']],
        [2025, 1, 8, 1.5,0.5,1.0,  0,2.0,<String>[]],
        [2025, 1,12, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1,16, 1.5,0.4,1.0,  0,1.5,<String>[]],
        [2025, 1,20, 1.0,0.3,0.5,  0,1.0,<String>[]],
        [2025, 1,25, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 1,30, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Feb 2025 — REMISSION
        [2025, 2, 4, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 2,10, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 2,18, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 2,25, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Mar–May 2025 — REMISSION / LOW
        [2025, 3, 5, 1.0,0.3,1.0,  0,1.0,['leftWrist']],
        [2025, 3,15, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 3,28, 1.5,0.4,1.5,  0,1.5,<String>[]],
        [2025, 4, 8, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 4,20, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 5, 5, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 5,20, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Jun–Aug 2025 — stable LOW
        [2025, 6,10, 1.5,0.4,1.5,  0,1.5,['leftKnee']],
        [2025, 6,25, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 7,12, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 7,28, 1.5,0.4,1.5,  0,1.5,<String>[]],
        [2025, 8,10, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 8,25, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Sep–Nov 2025 — small blip then back
        [2025, 9, 5, 2.0,0.6,2.0, 10,2.0,['leftKnee']],
        [2025, 9,20, 2.5,0.7,2.5, 10,2.5,['leftKnee','leftWrist']],
        [2025,10, 5, 2.0,0.6,2.0, 10,2.0,['leftKnee']],
        [2025,10,20, 1.5,0.5,1.5,  0,1.5,<String>[]],
        [2025,11, 5, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025,11,20, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Dec 2025–Mar 2026 — REMISSION maintained
        [2025,12,10, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025,12,25, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2026, 1,10, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2026, 1,25, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2026, 2,10, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2026, 2,25, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2026, 3, 5, 1.0,0.3,1.0,  0,1.0,<String>[]],
      ],
    ),

    // ── USER 2: Amir — chronic moderate, repeated flares ────────────────────
    // Arc: never fully remits, oscillates MODERATE↔HIGH.
    // Logs: every 3–5 days. Skips January 2025 entirely.
    _UserProfile(
      name: 'Amir Zulkifli', gender: 'Male', age: 45,
      doctorName: 'Dr. Farid Harun', city: 'Petaling Jaya',
      mtxAdherence: 0.80, hcqAdherence: 0.70,
      folicAdherence: 0.75, nsaidAdherence: 0.85,
      symptomRows: [
        // Dec 2024 — HIGH
        [2024,12, 2, 6.5,1.9,6.0, 75,7.0,['leftKnee','rightKnee']],
        [2024,12, 6, 7.0,2.0,6.5, 90,7.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12,10, 6.0,1.8,5.5, 60,6.5,['leftKnee','rightKnee']],
        [2024,12,14, 5.5,1.7,5.0, 45,6.0,['leftKnee']],
        [2024,12,18, 5.0,1.5,4.5, 45,5.5,['leftKnee','rightKnee']],
        [2024,12,22, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        [2024,12,27, 5.0,1.5,4.5, 45,5.5,['leftKnee','rightKnee']],
        // Jan 2025 — SKIPPED (no logs at all)
        // Feb 2025 — comes back, still MODERATE/HIGH
        [2025, 2, 3, 5.5,1.6,5.0, 60,6.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 2, 8, 6.0,1.8,5.5, 75,6.5,['leftKnee','rightKnee']],
        [2025, 2,13, 5.5,1.6,5.0, 60,6.0,['leftKnee']],
        [2025, 2,18, 4.5,1.4,4.0, 30,5.0,['leftKnee','leftWrist']],
        [2025, 2,23, 5.0,1.5,4.5, 45,5.5,['leftKnee']],
        [2025, 2,28, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        // Mar–Apr 2025 — MODERATE
        [2025, 3, 5, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        [2025, 3,12, 3.5,1.0,3.0, 20,4.0,['leftWrist']],
        [2025, 3,20, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        [2025, 3,28, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025, 4, 5, 4.5,1.4,4.0, 30,5.0,['leftKnee','rightKnee']],
        [2025, 4,15, 5.0,1.5,4.5, 45,5.5,['leftKnee','rightKnee']],
        [2025, 4,25, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        // May–Jun 2025 — brief LOW then back up
        [2025, 5, 5, 3.0,0.9,3.0, 15,3.5,['leftKnee']],
        [2025, 5,18, 2.5,0.8,2.5, 10,3.0,<String>[]],
        [2025, 6, 2, 3.5,1.0,3.5, 20,4.0,['leftKnee']],
        [2025, 6,15, 4.5,1.4,4.0, 30,5.0,['leftKnee','leftWrist']],
        [2025, 6,28, 5.0,1.5,5.0, 45,5.5,['leftKnee','rightKnee']],
        // Jul–Aug 2025 — HIGH flare
        [2025, 7, 5, 6.0,1.8,5.5, 75,6.5,['leftKnee','rightKnee','leftWrist']],
        [2025, 7,15, 7.0,2.0,6.5, 90,7.0,['leftKnee','rightKnee','rightWrist']],
        [2025, 7,25, 6.5,1.9,6.0, 75,6.5,['leftKnee','rightKnee']],
        [2025, 8, 5, 5.5,1.7,5.0, 60,6.0,['leftKnee']],
        [2025, 8,18, 5.0,1.5,4.5, 45,5.5,['leftKnee','rightKnee']],
        // Sep–Oct 2025 — settling MODERATE
        [2025, 9, 3, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        [2025, 9,18, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        [2025,10, 5, 4.5,1.4,4.0, 30,5.0,['leftKnee','leftWrist']],
        [2025,10,20, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        // Nov–Dec 2025 — SKIPPED (busy, no logs)
        // Jan–Mar 2026 — returns logging, still MODERATE
        [2026, 1, 8, 4.5,1.4,4.0, 30,5.0,['leftKnee','rightKnee']],
        [2026, 1,22, 5.0,1.5,4.5, 45,5.5,['leftKnee']],
        [2026, 2, 8, 4.5,1.4,4.0, 30,5.0,['leftKnee']],
        [2026, 2,22, 4.0,1.2,3.5, 20,4.5,<String>[]],
        [2026, 3, 5, 4.5,1.4,4.0, 30,5.0,['leftKnee','leftWrist']],
      ],
    ),

    // ── USER 3: Priya — mostly remission, one dramatic flare ────────────────
    // Arc: LOW/REMISSION most of the time. Sudden HIGH flare Sep 2025
    //      (stress event). Recovers quickly.
    // Logs: sparse — logs once a week or less.
    _UserProfile(
      name: 'Priya Nair', gender: 'Female', age: 29,
      doctorName: 'Dr. Suman Pillai', city: 'Subang Jaya',
      mtxAdherence: 0.95, hcqAdherence: 0.90,
      folicAdherence: 0.85, nsaidAdherence: 0.40,
      symptomRows: [
        [2024,12, 7, 1.5,0.4,1.5,  0,1.5,<String>[]],
        [2024,12,14, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2024,12,21, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2024,12,28, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 1, 6, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 1,13, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 1,20, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 1,27, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 2, 5, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 2,17, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Mar–Jul 2025 — very sparse
        [2025, 3,10, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 4,14, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 5,20, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 6,15, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025, 7,20, 1.0,0.3,1.0,  0,1.0,<String>[]],
        // Aug–Sep 2025 — sudden flare
        [2025, 8,28, 2.5,0.7,2.5, 10,3.0,['leftKnee']],
        [2025, 9, 3, 4.5,1.4,4.5, 30,5.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 9, 8, 6.5,1.9,6.0, 75,7.0,['leftKnee','rightKnee','leftWrist','rightWrist']],
        [2025, 9,13, 7.0,2.0,6.5, 90,7.5,['leftKnee','rightKnee','rightWrist']],
        [2025, 9,18, 6.0,1.8,5.5, 60,6.5,['leftKnee','rightKnee']],
        [2025, 9,23, 5.0,1.5,4.5, 45,5.5,['leftKnee']],
        [2025, 9,28, 3.5,1.0,3.5, 20,4.0,['leftKnee']],
        // Oct–Dec 2025 — recovery
        [2025,10, 7, 2.0,0.6,2.0, 10,2.5,<String>[]],
        [2025,10,20, 1.5,0.4,1.5,  0,2.0,<String>[]],
        [2025,11, 5, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025,11,25, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2025,12,15, 0.5,0.2,0.5,  0,0.5,<String>[]],
        // Jan–Mar 2026 — REMISSION
        [2026, 1,12, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2026, 2, 8, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2026, 3, 1, 0.5,0.2,0.5,  0,0.5,<String>[]],
      ],
    ),

    // ── USER 4: David — poor adherence, worsening trend ─────────────────────
    // Arc: starts MODERATE Dec 2024, slowly worsens to HIGH by mid-2025,
    //      never fully recovers. Skips 2 full months.
    // Logs: erratic — sometimes daily, then disappears for 6+ weeks.
    _UserProfile(
      name: 'David Tan', gender: 'Male', age: 52,
      doctorName: 'Dr. Chen Wei Ming', city: 'Ipoh',
      mtxAdherence: 0.50, hcqAdherence: 0.45,
      folicAdherence: 0.55, nsaidAdherence: 0.60,
      symptomRows: [
        [2024,12, 3, 4.0,1.2,3.5, 20,4.0,['leftKnee']],
        [2024,12, 7, 4.5,1.4,4.0, 30,4.5,['leftKnee','leftWrist']],
        [2024,12,11, 5.0,1.5,4.5, 45,5.0,['leftKnee','rightKnee']],
        [2024,12,15, 4.5,1.4,4.0, 30,4.5,['leftKnee']],
        [2024,12,19, 5.0,1.5,4.5, 45,5.5,['leftKnee','rightKnee']],
        [2024,12,23, 5.5,1.6,5.0, 45,5.5,['leftKnee','rightKnee']],
        [2024,12,28, 5.0,1.5,4.5, 45,5.0,['leftKnee']],
        // Jan 2025 — near daily then stops
        [2025, 1, 2, 5.5,1.7,5.0, 60,5.5,['leftKnee','rightKnee']],
        [2025, 1, 5, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee']],
        [2025, 1, 8, 5.5,1.7,5.0, 45,5.5,['leftKnee']],
        [2025, 1,11, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee']],
        // Feb–Mar 2025 — SKIPPED entirely
        // Apr 2025 — returns, worse
        [2025, 4, 5, 6.5,1.9,6.0, 75,6.5,['leftKnee','rightKnee','leftWrist']],
        [2025, 4,14, 7.0,2.0,6.5, 90,7.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 4,23, 6.5,1.9,6.0, 75,6.5,['leftKnee','rightKnee']],
        // May–Jun 2025 — HIGH
        [2025, 5, 5, 7.0,2.0,6.5, 90,7.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 5,20, 7.5,2.2,7.0,100,7.5,['leftKnee','rightKnee','rightWrist']],
        [2025, 6, 8, 7.0,2.0,6.5, 90,7.0,['leftKnee','rightKnee']],
        [2025, 6,22, 6.5,1.9,6.0, 75,6.5,['leftKnee','leftWrist']],
        // Jul 2025 — SKIPPED
        // Aug 2025 — comes back, still HIGH
        [2025, 8, 3, 7.0,2.0,6.5, 90,7.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 8,18, 6.5,1.9,6.0, 75,6.5,['leftKnee','rightKnee']],
        // Sep–Nov 2025 — slowly settling to MODERATE
        [2025, 9,10, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee']],
        [2025, 9,28, 5.5,1.7,5.0, 60,5.5,['leftKnee']],
        [2025,10,15, 5.0,1.5,4.5, 45,5.0,['leftKnee']],
        [2025,11, 3, 5.5,1.6,5.0, 45,5.5,['leftKnee','rightKnee']],
        [2025,11,25, 5.0,1.5,4.5, 45,5.0,['leftKnee']],
        // Dec 2025–Mar 2026 — still HIGH/MODERATE, not improving
        [2025,12, 8, 5.5,1.7,5.0, 60,5.5,['leftKnee','rightKnee']],
        [2025,12,22, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee','leftWrist']],
        [2026, 1, 7, 5.5,1.7,5.0, 60,5.5,['leftKnee']],
        [2026, 1,25, 6.0,1.8,5.5, 75,6.0,['leftKnee','rightKnee']],
        [2026, 2,10, 5.5,1.7,5.0, 60,5.5,['leftKnee','rightKnee']],
        [2026, 2,25, 6.0,1.8,5.5, 75,6.0,['leftKnee','leftWrist']],
        [2026, 3, 5, 5.5,1.7,5.0, 60,5.5,['leftKnee','rightKnee']],
      ],
    ),

    // ── USER 5: Nurul — newly diagnosed, erratic early logs ─────────────────
    // Arc: diagnosed Dec 2024, first few months very chaotic (daily logging
    //      then nothing for weeks). Settles mid-2025, trending MODERATE→LOW.
    _UserProfile(
      name: 'Nurul Hidayah', gender: 'Female', age: 27,
      doctorName: 'Dr. Aisha Rahman', city: 'Shah Alam',
      mtxAdherence: 0.70, hcqAdherence: 0.65,
      folicAdherence: 0.60, nsaidAdherence: 0.75,
      symptomRows: [
        // Dec 2024 — newly diagnosed, logs every day then stops
        [2024,12, 5, 5.5,1.6,5.0, 45,5.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 6, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee']],
        [2024,12, 7, 5.5,1.6,5.0, 45,5.5,['leftKnee']],
        [2024,12, 8, 6.5,1.9,6.0, 75,6.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 9, 6.0,1.8,5.5, 60,6.0,['leftKnee','rightKnee']],
        [2024,12,10, 5.5,1.7,5.0, 45,5.5,['leftKnee']],
        // then goes quiet for 3 weeks
        [2024,12,30, 5.0,1.5,4.5, 45,5.0,['leftKnee','leftWrist']],
        // Jan 2025 — logs sporadically
        [2025, 1, 8, 5.5,1.6,5.0, 45,5.5,['leftKnee','rightKnee']],
        [2025, 1,22, 5.0,1.5,4.5, 30,5.0,['leftKnee']],
        // Feb–Mar 2025 — SKIPPED
        // Apr 2025 — returns
        [2025, 4, 3, 4.5,1.4,4.0, 30,4.5,['leftKnee']],
        [2025, 4,18, 4.0,1.2,3.5, 20,4.0,['leftKnee','leftWrist']],
        // May 2025 — starts getting consistent
        [2025, 5, 2, 4.5,1.4,4.0, 30,4.5,['leftKnee']],
        [2025, 5,12, 4.0,1.2,3.5, 20,4.0,['leftKnee']],
        [2025, 5,22, 3.5,1.0,3.0, 15,3.5,['leftWrist']],
        // Jun–Aug 2025 — improving MODERATE
        [2025, 6, 5, 3.5,1.0,3.0, 15,3.5,['leftKnee']],
        [2025, 6,20, 3.0,0.9,2.5, 10,3.0,<String>[]],
        [2025, 7, 8, 3.0,0.9,2.5, 10,3.0,['leftKnee']],
        [2025, 7,25, 2.5,0.8,2.0, 10,2.5,<String>[]],
        [2025, 8,10, 2.5,0.7,2.0,  0,2.5,<String>[]],
        [2025, 8,28, 2.0,0.6,2.0,  0,2.0,['leftWrist']],
        // Sep–Dec 2025 — LOW
        [2025, 9,15, 2.0,0.6,2.0,  0,2.0,<String>[]],
        [2025,10, 5, 1.5,0.5,1.5,  0,1.5,<String>[]],
        [2025,10,25, 2.0,0.6,2.0,  0,2.0,['leftKnee']],
        [2025,11,15, 1.5,0.5,1.5,  0,1.5,<String>[]],
        [2025,12, 5, 2.0,0.6,2.0,  0,2.0,<String>[]],
        [2025,12,25, 1.5,0.5,1.5,  0,1.5,<String>[]],
        // Jan–Mar 2026 — holding LOW
        [2026, 1,15, 1.5,0.5,1.5,  0,1.5,<String>[]],
        [2026, 2,10, 2.0,0.6,2.0,  0,2.0,['leftKnee']],
        [2026, 3, 1, 1.5,0.5,1.5,  0,1.5,<String>[]],
      ],
    ),

    // ── USER 6: Kevin — active athlete, stays LOW, logs post-workout ─────────
    // Arc: LOW/REMISSION throughout. Logs only after exercise (2–3x/week).
    //      Small flare Nov 2025 after marathon attempt.
    _UserProfile(
      name: 'Kevin Loh', gender: 'Male', age: 31,
      doctorName: 'Dr. Marcus Ng', city: 'Penang',
      mtxAdherence: 0.95, hcqAdherence: 1.0,
      folicAdherence: 0.90, nsaidAdherence: 0.30,
      symptomRows: [
        [2024,12, 3, 1.5,0.4,1.5,  0,2.0,<String>[]],
        [2024,12, 6, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2024,12,10, 1.5,0.4,1.5,  0,2.0,['leftKnee']],
        [2024,12,13, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2024,12,17, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2024,12,20, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2024,12,24, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2024,12,27, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1, 3, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1, 7, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 1,10, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1,14, 1.5,0.4,1.5,  0,2.0,['leftKnee']],
        [2025, 1,17, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1,21, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 1,24, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 1,28, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 2, 4, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 2,11, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 2,18, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 2,25, 0.5,0.2,0.5,  0,1.0,<String>[]],
        // Mar–Aug 2025 — sparse, everything is fine
        [2025, 3,10, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 3,25, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 4,12, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 5, 5, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 6,10, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2025, 7,15, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2025, 8,20, 1.0,0.3,1.0,  0,1.5,<String>[]],
        // Sep 2025 — training hard
        [2025, 9, 5, 1.5,0.4,1.5,  0,2.0,['leftKnee']],
        [2025, 9,15, 2.0,0.6,2.0, 10,2.5,['leftKnee']],
        [2025, 9,25, 1.5,0.4,1.5,  0,2.0,<String>[]],
        // Oct–Nov 2025 — marathon flare
        [2025,10,10, 2.5,0.7,2.5, 10,3.0,['leftKnee','rightKnee']],
        [2025,10,25, 3.5,1.0,3.5, 20,3.5,['leftKnee','rightKnee']],
        [2025,11, 5, 4.5,1.4,4.0, 30,4.5,['leftKnee','rightKnee','leftWrist']],
        [2025,11,12, 5.0,1.5,4.5, 45,5.0,['leftKnee','rightKnee']],
        [2025,11,19, 4.0,1.2,3.5, 20,4.0,['leftKnee']],
        [2025,11,26, 3.0,0.9,3.0, 15,3.5,['leftKnee']],
        // Dec 2025–Mar 2026 — recovery to LOW
        [2025,12, 5, 2.0,0.6,2.0,  0,2.5,<String>[]],
        [2025,12,15, 1.5,0.4,1.5,  0,2.0,<String>[]],
        [2025,12,28, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2026, 1,10, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2026, 1,25, 0.5,0.2,0.5,  0,1.0,<String>[]],
        [2026, 2,10, 1.0,0.3,1.0,  0,1.5,<String>[]],
        [2026, 3, 1, 0.5,0.2,0.5,  0,1.0,<String>[]],
      ],
    ),

    // ── USER 7: Siti — elderly, sparse logging (1–2x/week max) ──────────────
    // Arc: consistently MODERATE throughout. Stiffness is high.
    //      Completely skips 3 months (Mar, Jul, Nov 2025).
    _UserProfile(
      name: 'Siti Rohani', gender: 'Female', age: 67,
      doctorName: 'Dr. Rohana Yusof', city: 'Johor Bahru',
      mtxAdherence: 0.85, hcqAdherence: 0.80,
      folicAdherence: 0.80, nsaidAdherence: 0.90,
      symptomRows: [
        [2024,12, 5, 4.5,1.4,4.0, 45,4.5,['leftKnee','rightKnee']],
        [2024,12,12, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2024,12,19, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2024,12,26, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 1, 5, 4.5,1.3,4.0, 45,4.5,['leftKnee']],
        [2025, 1,15, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 1,26, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2025, 2, 8, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 2,22, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        // Mar 2025 — SKIPPED
        [2025, 4, 7, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 4,21, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2025, 5, 9, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 5,25, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2025, 6,10, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 6,28, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        // Jul 2025 — SKIPPED
        [2025, 8, 6, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 8,25, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2025, 9,12, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025, 9,28, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2025,10, 8, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee','leftWrist']],
        [2025,10,24, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        // Nov 2025 — SKIPPED
        [2025,12, 4, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2025,12,22, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2026, 1, 8, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2026, 1,26, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
        [2026, 2,12, 5.0,1.5,4.5, 60,5.0,['leftKnee','rightKnee']],
        [2026, 3, 1, 4.5,1.4,4.0, 45,4.5,['leftKnee']],
      ],
    ),

    // ── USER 8: Raj — skips long stretches, logs intensely then vanishes ─────
    // Arc: HIGH in Dec 2024, logs every day for 2 weeks, disappears,
    //      returns May 2025 better, logs 2 weeks, gone again, returns Oct 2025.
    _UserProfile(
      name: 'Raj Kumar', gender: 'Male', age: 48,
      doctorName: 'Dr. Ravi Shankar', city: 'Kuala Lumpur',
      mtxAdherence: 0.60, hcqAdherence: 0.55,
      folicAdherence: 0.50, nsaidAdherence: 0.80,
      symptomRows: [
        // Dec 2024 — intense daily logging (flare)
        [2024,12, 1, 7.0,2.0,6.5, 90,7.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 2, 7.5,2.2,7.0,100,8.0,['leftKnee','rightKnee','rightWrist']],
        [2024,12, 3, 7.0,2.0,6.5, 90,7.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 4, 6.5,1.9,6.0, 75,7.0,['leftKnee','rightKnee']],
        [2024,12, 5, 7.0,2.0,6.5, 90,7.5,['leftKnee','rightKnee','leftWrist']],
        [2024,12, 6, 6.0,1.8,5.5, 60,6.5,['leftKnee','rightKnee']],
        [2024,12, 7, 6.5,1.9,6.0, 75,7.0,['leftKnee']],
        [2024,12, 8, 6.0,1.8,5.5, 60,6.5,['leftKnee','rightKnee']],
        [2024,12, 9, 5.5,1.7,5.0, 60,6.0,['leftKnee']],
        [2024,12,10, 6.0,1.8,5.5, 60,6.5,['leftKnee','rightKnee']],
        [2024,12,11, 5.5,1.6,5.0, 45,6.0,['leftKnee']],
        [2024,12,12, 5.0,1.5,4.5, 45,5.5,['leftKnee','leftWrist']],
        [2024,12,13, 5.5,1.6,5.0, 45,6.0,['leftKnee']],
        [2024,12,14, 5.0,1.5,4.5, 45,5.5,['leftKnee']],
        // Jan–Apr 2025 — COMPLETELY ABSENT
        // May 2025 — returns, logs 2 weeks
        [2025, 5, 1, 4.5,1.4,4.0, 30,5.0,['leftKnee','leftWrist']],
        [2025, 5, 4, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        [2025, 5, 7, 4.5,1.4,4.0, 30,4.5,['leftKnee']],
        [2025, 5,10, 4.0,1.2,3.5, 20,4.5,['leftWrist']],
        [2025, 5,13, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025, 5,16, 3.0,0.9,3.0, 15,3.5,<String>[]],
        [2025, 5,19, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025, 5,22, 3.0,0.9,2.5, 10,3.5,<String>[]],
        [2025, 5,25, 2.5,0.8,2.5, 10,3.0,<String>[]],
        [2025, 5,28, 3.0,0.9,2.5, 10,3.5,['leftKnee']],
        // Jun–Sep 2025 — ABSENT
        // Oct 2025 — returns again, logs for 3 weeks
        [2025,10, 1, 4.0,1.2,3.5, 20,4.5,['leftKnee','leftWrist']],
        [2025,10, 5, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025,10, 9, 4.0,1.2,3.5, 20,4.5,['leftKnee']],
        [2025,10,13, 3.5,1.0,3.0, 15,4.0,['leftWrist']],
        [2025,10,17, 3.0,0.9,3.0, 15,3.5,<String>[]],
        [2025,10,21, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025,10,25, 3.0,0.9,2.5, 10,3.5,<String>[]],
        // Nov–Dec 2025 — sparse
        [2025,11,10, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2025,11,28, 3.0,0.9,2.5, 10,3.5,<String>[]],
        [2025,12,15, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        // Jan–Mar 2026
        [2026, 1,12, 3.0,0.9,2.5, 10,3.5,<String>[]],
        [2026, 2,10, 3.5,1.0,3.0, 15,4.0,['leftKnee']],
        [2026, 3, 5, 3.0,0.9,2.5, 10,3.5,<String>[]],
      ],
    ),

    // ── USER 9: Mei — stress-correlated, mood-driven logging ────────────────
    // Arc: clear stress↔flare pattern. Logs whenever stressed.
    //      Big work stress Mar–Apr 2025 → HIGH. Good Jun–Aug. Bad again Dec.
    _UserProfile(
      name: 'Mei Ling', gender: 'Female', age: 38,
      doctorName: 'Dr. Chen Wei Ming', city: 'Cyberjaya',
      mtxAdherence: 0.85, hcqAdherence: 0.80,
      folicAdherence: 0.75, nsaidAdherence: 0.65,
      symptomRows: [
        [2024,12, 8, 3.0,0.9,2.5, 15,4.0,['leftKnee']],
        [2024,12,15, 2.5,0.8,2.0, 10,3.5,<String>[]],
        [2024,12,22, 3.0,0.9,2.5, 15,4.0,['leftWrist']],
        [2024,12,29, 2.5,0.8,2.0, 10,3.5,<String>[]],
        [2025, 1, 6, 2.0,0.6,2.0, 10,3.0,<String>[]],
        [2025, 1,14, 2.5,0.7,2.5, 10,3.5,['leftKnee']],
        [2025, 1,22, 2.0,0.6,2.0,  0,3.0,<String>[]],
        [2025, 2, 3, 2.5,0.7,2.5, 10,3.5,['leftKnee']],
        [2025, 2,17, 2.0,0.6,2.0,  0,3.0,<String>[]],
        // Mar 2025 — work project, stress 9/10, flare
        [2025, 3, 3, 3.5,1.0,3.5, 20,7.0,['leftKnee','leftWrist']],
        [2025, 3, 8, 4.5,1.4,4.5, 30,8.0,['leftKnee','rightKnee','leftWrist']],
        [2025, 3,13, 5.5,1.7,5.0, 60,8.5,['leftKnee','rightKnee','leftWrist']],
        [2025, 3,18, 6.0,1.8,5.5, 75,9.0,['leftKnee','rightKnee','rightWrist']],
        [2025, 3,23, 6.5,1.9,6.0, 75,8.5,['leftKnee','rightKnee','leftWrist']],
        [2025, 3,28, 7.0,2.0,6.5, 90,9.0,['leftKnee','rightKnee','rightWrist','leftWrist']],
        // Apr 2025 — still stressed
        [2025, 4, 3, 6.5,1.9,6.0, 75,8.0,['leftKnee','rightKnee']],
        [2025, 4,10, 6.0,1.8,5.5, 60,7.5,['leftKnee','rightKnee']],
        [2025, 4,17, 5.5,1.7,5.0, 60,7.0,['leftKnee','leftWrist']],
        [2025, 4,24, 5.0,1.5,4.5, 45,6.5,['leftKnee']],
        // May 2025 — project over, stress drops
        [2025, 5, 5, 4.0,1.2,3.5, 20,5.0,['leftKnee']],
        [2025, 5,18, 3.0,0.9,2.5, 10,3.5,<String>[]],
        // Jun–Aug 2025 — LOW, stress 2–3
        [2025, 6, 8, 2.0,0.6,2.0,  0,2.5,<String>[]],
        [2025, 6,25, 1.5,0.5,1.5,  0,2.0,<String>[]],
        [2025, 7,15, 2.0,0.6,2.0,  0,2.5,<String>[]],
        [2025, 8, 5, 1.5,0.5,1.5,  0,2.0,<String>[]],
        [2025, 8,25, 2.0,0.6,2.0,  0,2.5,<String>[]],
        // Sep–Oct 2025 — stable
        [2025, 9,10, 2.0,0.6,2.0,  0,3.0,<String>[]],
        [2025,10, 5, 2.5,0.7,2.5, 10,3.5,['leftKnee']],
        [2025,10,25, 2.0,0.6,2.0,  0,3.0,<String>[]],
        // Nov–Dec 2025 — year-end stress
        [2025,11, 8, 3.0,0.9,3.0, 15,6.0,['leftKnee']],
        [2025,11,22, 4.0,1.2,4.0, 30,7.5,['leftKnee','leftWrist']],
        [2025,12, 5, 5.0,1.5,5.0, 45,8.0,['leftKnee','rightKnee','leftWrist']],
        [2025,12,15, 5.5,1.7,5.0, 60,8.5,['leftKnee','rightKnee']],
        [2025,12,25, 4.5,1.4,4.5, 30,7.0,['leftKnee']],
        // Jan–Mar 2026 — new year, stress drops
        [2026, 1, 8, 3.5,1.0,3.5, 20,5.0,['leftKnee']],
        [2026, 1,22, 2.5,0.8,2.5, 10,4.0,<String>[]],
        [2026, 2, 8, 2.0,0.6,2.0,  0,3.0,<String>[]],
        [2026, 2,22, 1.5,0.5,1.5,  0,2.5,<String>[]],
        [2026, 3, 8, 2.0,0.6,2.0,  0,3.0,<String>[]],
      ],
    ),

    // ── USER 10: Hassan — post-surgery recovery arc ──────────────────────────
    // Arc: knee replacement surgery Jan 2025. Starts HIGH, steadily
    //      improves month by month. Logs very diligently during recovery.
    //      Skips Dec 2025 (holiday).
    _UserProfile(
      name: 'Hassan Abdullah', gender: 'Male', age: 61,
      doctorName: 'Dr. Zainal Abidin', city: 'Kuala Lumpur',
      mtxAdherence: 0.90, hcqAdherence: 0.85,
      folicAdherence: 0.85, nsaidAdherence: 0.95,
      symptomRows: [
        // Dec 2024 — pre-surgery, HIGH
        [2024,12, 2, 7.0,2.0,6.5, 90,6.5,['leftKnee','rightKnee']],
        [2024,12, 6, 7.5,2.2,7.0,100,7.0,['leftKnee','rightKnee','leftWrist']],
        [2024,12,10, 8.0,2.3,7.5,100,7.5,['leftKnee','rightKnee']],
        [2024,12,15, 7.5,2.2,7.0, 90,7.0,['leftKnee','rightKnee']],
        [2024,12,20, 7.0,2.0,6.5, 90,6.5,['leftKnee','rightKnee']],
        [2024,12,26, 7.5,2.2,7.0,100,7.0,['leftKnee','rightKnee','leftWrist']],
        [2024,12,31, 7.0,2.0,6.5, 90,6.5,['leftKnee','rightKnee']],
        // Jan 2025 — surgery day Jan 15, post-op HIGH
        [2025, 1, 3, 7.5,2.2,7.0,100,7.0,['leftKnee','rightKnee']],
        [2025, 1, 8, 8.0,2.3,7.5,100,7.5,['leftKnee','rightKnee']],
        [2025, 1,13, 7.5,2.2,7.0, 90,7.0,['leftKnee','rightKnee']],
        [2025, 1,18, 8.5,2.5,8.0,120,8.0,['leftKnee','rightKnee']],  // post-surgery
        [2025, 1,22, 8.0,2.3,7.5,100,7.5,['leftKnee','rightKnee']],
        [2025, 1,26, 7.5,2.2,7.0, 90,7.0,['leftKnee']],
        [2025, 1,30, 7.0,2.0,6.5, 90,6.5,['leftKnee']],
        // Feb 2025 — physio, still HIGH
        [2025, 2, 3, 7.0,2.0,6.5, 90,6.5,['leftKnee']],
        [2025, 2, 8, 6.5,1.9,6.0, 75,6.0,['leftKnee']],
        [2025, 2,13, 6.0,1.8,5.5, 60,5.5,['leftKnee']],
        [2025, 2,18, 5.5,1.7,5.0, 60,5.0,['leftKnee']],
        [2025, 2,23, 5.0,1.5,4.5, 45,4.5,['leftKnee']],
        [2025, 2,28, 4.5,1.4,4.0, 30,4.0,['leftKnee']],
        // Mar 2025 — MODERATE, improving
        [2025, 3, 5, 4.0,1.2,3.5, 20,3.5,['leftKnee']],
        [2025, 3,10, 3.5,1.0,3.0, 15,3.0,['leftKnee']],
        [2025, 3,15, 3.0,0.9,2.5, 10,2.5,<String>[]],
        [2025, 3,20, 3.5,1.0,3.0, 15,3.0,['leftKnee']],
        [2025, 3,25, 3.0,0.9,2.5, 10,2.5,<String>[]],
        // Apr–Jun 2025 — LOW, continuing recovery
        [2025, 4, 3, 2.5,0.8,2.0, 10,2.0,<String>[]],
        [2025, 4,15, 2.0,0.6,2.0,  0,2.0,<String>[]],
        [2025, 4,28, 2.5,0.7,2.5, 10,2.0,<String>[]],
        [2025, 5,10, 2.0,0.6,2.0,  0,1.5,<String>[]],
        [2025, 5,25, 1.5,0.5,1.5,  0,1.5,<String>[]],
        [2025, 6,10, 2.0,0.6,2.0,  0,2.0,<String>[]],
        [2025, 6,28, 1.5,0.5,1.5,  0,1.5,<String>[]],
        // Jul–Nov 2025 — LOW/REMISSION
        [2025, 7,15, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025, 8,10, 1.5,0.4,1.5,  0,1.5,<String>[]],
        [2025, 9, 5, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2025,10,12, 1.5,0.4,1.5,  0,1.5,<String>[]],
        [2025,11,15, 1.0,0.3,1.0,  0,1.0,<String>[]],
        // Dec 2025 — holiday, SKIPPED
        // Jan–Mar 2026 — REMISSION
        [2026, 1, 8, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2026, 1,25, 0.5,0.2,0.5,  0,0.5,<String>[]],
        [2026, 2,12, 1.0,0.3,1.0,  0,1.0,<String>[]],
        [2026, 3, 1, 0.5,0.2,0.5,  0,0.5,<String>[]],
      ],
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // SEED ONE USER
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _seedUser(String uid, _UserProfile p) async {
    await _patchUserTierFields(uid, p);
    await _seedSymptomLogs(uid, p);
    await _seedMedications(uid, p);
    await _seedAppointments(uid, p);
    print('[Seed] ✓ ${p.name} complete');
  }

  static Future<void> _patchUserTierFields(String uid, _UserProfile p) async {
    final lastRow = p.symptomRows.last;
    final score   = _rapid3(
        (lastRow[3] as num).toDouble(),
        (lastRow[4] as num).toDouble(),
        (lastRow[5] as num).toDouble());
    await _db.collection('users').doc(uid).update({
      'activeRapid3Tier':  _tier(score),
      'activeRapid3Score': score,
      'tierUpdatedAt':     Timestamp.now(),
      'tierLogDate':       _dateKey(lastRow[0] as int, lastRow[1] as int, lastRow[2] as int),
      'weatherCity':       p.city,
      'displayName':       p.name,
      'gender':            p.gender,
      'age':               p.age,
      'doctorName':        p.doctorName,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYMPTOM LOGS
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _seedSymptomLogs(String uid, _UserProfile p) async {
    final col = _db.collection('users').doc(uid).collection('symptomLogs');
    int count = 0;
    for (final row in p.symptomRows) {
      final year      = row[0] as int;
      final month     = row[1] as int;
      final day       = row[2] as int;
      final pain      = (row[3] as num).toDouble();
      final func      = (row[4] as num).toDouble();
      final global    = (row[5] as num).toDouble();
      final stiff     = row[6] as int;
      final stress    = (row[7] as num).toDouble();
      final joints    = List<String>.from(row[8] as List);
      final score     = _rapid3(pain, func, global);
      final tier      = _tier(score);
      final dt        = DateTime(year, month, day, 8, 0);
      final key       = _dateKey(year, month, day);

      await col.doc('log_$key').set({
        'logId':                   'log_$key',
        'userId':                  uid,
        'logDate':                 key,
        'logTime':                 dt.toIso8601String(),
        'timestamp':               dt.millisecondsSinceEpoch,
        'createdAt':               dt.millisecondsSinceEpoch,
        'updatedAt':               dt.millisecondsSinceEpoch,
        'pain':                    pain,
        'function':                func,
        'globalAssessment':        global,
        'rapid3Score':             score,
        'rapid3Tier':              tier,
        'tireEmoij':               _emoji(tier),
        'tierColor':               _color(tier),
        'affectedJoints':          joints,
        'morningStiffnessMinutes': stiff,
        'stressLevel':             stress,
        'additionalNotes':         '',
        'deviceType':              'Mobile',
        'appVersion':              '1.0.0',
      });
      count++;
    }
    print('[Seed]   symptomLogs: $count');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEDICATIONS + DOSE LOGS
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _seedMedications(String uid, _UserProfile p) async {
    final medRef = _db.collection('users').doc(uid).collection('medications');
    final logRef = _db.collection('users').doc(uid).collection('logs');
    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);

    // ── Write med docs ─────────────────────────────────────────────────────
    final meds = [
      {'docId': 'med_mtx', 'name': 'Methotrexate', 'dosage': '15mg',
       'frequency': 'Weekly', 'weeklyDays': [1],
       'reminderTime': {'hour': 9, 'minute': 0}},
      {'docId': 'med_folic', 'name': 'Folic Acid', 'dosage': '5mg',
       'frequency': 'Daily', 'weeklyDays': [],
       'reminderTime': {'hour': 8, 'minute': 0}},
      {'docId': 'med_hcq', 'name': 'Hydroxychloroquine', 'dosage': '200mg',
       'frequency': 'Twice Daily', 'weeklyDays': [],
       'reminderTime': {'hour': 8, 'minute': 0}},
      {'docId': 'med_pred', 'name': 'Prednisolone', 'dosage': '5mg',
       'frequency': 'Daily', 'weeklyDays': [],
       'reminderTime': {'hour': 7, 'minute': 30}},
      {'docId': 'med_naproxen', 'name': 'Naproxen', 'dosage': '500mg',
       'frequency': 'Twice Daily', 'weeklyDays': [],
       'reminderTime': {'hour': 12, 'minute': 0}},
    ];

    for (final med in meds) {
      await medRef.doc(med['docId'] as String).set({
        'name':             med['name'],
        'dosage':           med['dosage'],
        'frequency':        med['frequency'],
        'medicationType':   'Tablet',
        'mealTiming':       'With Meal',
        'stockCurrent':     10,
        'stockMax':         30,
        'perDose':          1,
        'isReminderOn':     true,
        'reminderTime':     med['reminderTime'],
        'eveningReminderTime': med['frequency'] == 'Twice Daily'
            ? {'hour': 20, 'minute': 0} : null,
        'weeklyDays':       med['weeklyDays'],
        'knownSideEffects': <String>[],
        'startDate':        today.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'endDate':          null,
        'firstTaken':       today.subtract(const Duration(days: 180)).millisecondsSinceEpoch,
        'lastTaken':        today.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'description':      '',
      });
    }

    // ── Write dose logs — last 30 days only ───────────────────────────────
    int logCount = 0;
    final mtxPct   = (p.mtxAdherence   * 100).round();
    final hcqPct   = (p.hcqAdherence   * 100).round();
    final folicPct = (p.folicAdherence  * 100).round();
    final nsaidPct = (p.nsaidAdherence  * 100).round();

    for (int offset = 30; offset >= 1; offset--) {
      final day     = today.subtract(Duration(days: offset));
      final weekday = day.weekday;

      // Folic (skip Monday)
      if (weekday != 1 && _take(folicPct, offset)) {
        await logRef.add({
          'medicationId': 'med_folic', 'medicationName': 'Folic Acid',
          'timestamp': _tsMs(day, 8, offset % 20),
          'doseNumber': 1, 'wasLate': false, 'sideEffectsReported': <String>[], 'notes': null,
        });
        logCount++;
      }
      // HCQ morning
      if (_take(hcqPct, offset + 7)) {
        await logRef.add({
          'medicationId': 'med_hcq', 'medicationName': 'Hydroxychloroquine',
          'timestamp': _tsMs(day, 8, 5 + offset % 15),
          'doseNumber': 1, 'wasLate': false, 'sideEffectsReported': <String>[], 'notes': null,
        });
        logCount++;
      }
      // HCQ evening
      if (_take((hcqPct - 10).clamp(0, 100), offset + 100)) {
        await logRef.add({
          'medicationId': 'med_hcq', 'medicationName': 'Hydroxychloroquine',
          'timestamp': _tsMs(day, 20, offset % 30),
          'doseNumber': 2, 'wasLate': false, 'sideEffectsReported': <String>[], 'notes': null,
        });
        logCount++;
      }
      // MTX weekly
      if (weekday == 1 && _take(mtxPct, offset + 200)) {
        await logRef.add({
          'medicationId': 'med_mtx', 'medicationName': 'Methotrexate',
          'timestamp': _tsMs(day, 9, 15),
          'doseNumber': 1, 'wasLate': false,
          'sideEffectsReported': ['Nausea'], 'notes': null,
        });
        logCount++;
      }
      // Naproxen
      if (_take(nsaidPct, offset + 50)) {
        await logRef.add({
          'medicationId': 'med_naproxen', 'medicationName': 'Naproxen',
          'timestamp': _tsMs(day, 12, 0),
          'doseNumber': 1, 'wasLate': false, 'sideEffectsReported': <String>[], 'notes': null,
        });
        logCount++;
      }
    }
    print('[Seed]   meds: 5 docs, logs: $logCount');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APPOINTMENTS — 2 upcoming + 3 completed per user
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _seedAppointments(String uid, _UserProfile p) async {
    final col   = _db.collection('users').doc(uid).collection('appointments');
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final appts = [
      {
        'title': 'Rheumatology Follow-up', 'personInCharge': p.doctorName,
        'location': 'Hospital Clinic, Level 4',
        'dateTime': Timestamp.fromDate(today.add(const Duration(days: 7, hours: 10))),
        'preNotes': 'Discuss latest RAPID3 trend. Review medication adherence.',
        'postNotes': '', 'isCompleted': false,
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 5))),
      },
      {
        'title': 'Blood Test — Full Panel', 'personInCharge': 'Lab',
        'location': 'Pathology Lab, Ground Floor',
        'dateTime': Timestamp.fromDate(today.add(const Duration(days: 14, hours: 8))),
        'preNotes': 'Fasting required. FBC, LFT, ESR, CRP.',
        'postNotes': '', 'isCompleted': false,
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 2))),
      },
      {
        'title': 'Rheumatology Review', 'personInCharge': p.doctorName,
        'location': 'Hospital Clinic, Level 4',
        'dateTime': Timestamp.fromDate(today.subtract(const Duration(days: 30, hours: -10))),
        'preNotes': 'Report pain levels. Ask about exercise plan.',
        'postNotes': 'Medication adjusted. Follow-up in 4 weeks.',
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(today.subtract(const Duration(days: 30))),
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 40))),
      },
      {
        'title': 'Blood Test — MTX Monitoring', 'personInCharge': 'Lab',
        'location': 'Pathology Lab, Ground Floor',
        'dateTime': Timestamp.fromDate(today.subtract(const Duration(days: 60, hours: -8))),
        'preNotes': 'Routine LFT and FBC for Methotrexate monitoring.',
        'postNotes': 'LFT normal. ESR elevated. Results sent to doctor.',
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(today.subtract(const Duration(days: 60))),
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 62))),
      },
      {
        'title': 'Physiotherapy Session', 'personInCharge': 'Physiotherapist',
        'location': 'Physio Clinic',
        'dateTime': Timestamp.fromDate(today.subtract(const Duration(days: 90, hours: -14))),
        'preNotes': 'Hand and wrist mobility exercises.',
        'postNotes': 'Grip strength improving. Continue home program.',
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(today.subtract(const Duration(days: 90))),
        'createdAt': Timestamp.fromDate(today.subtract(const Duration(days: 92))),
      },
    ];

    for (final a in appts) await col.add(a);
    print('[Seed]   appointments: ${appts.length}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GLOBAL COLLECTIONS (same as original seed)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _seedGlobalCollections() async {
    // rapid3Question
    final q = _db.collection('rapid3Question');
    await q.doc('painQuestion').set({
      'id':'painQuestion','questionNumber':1,
      'question':'How would you describe your overall pain level today?',
      'category':'pain','type':'slider','minValue':0.0,'maxValue':10.0,
      'minLabel':'No pain','maxLabel':'Worst possible pain','unit':'/10',
    });
    await q.doc('functionQuestion').set({
      'id':'functionQuestion','questionNumber':2,
      'question':'How much difficulty do you have with daily activities?',
      'category':'function','type':'radio','minValue':0.0,'maxValue':3.0,
      'minLabel':'No difficulty','maxLabel':'Cannot do','unit':'/3',
    });
    await q.doc('globalQuestion').set({
      'id':'globalQuestion','questionNumber':3,
      'question':'Considering all the ways RA has affected you, how are you doing today?',
      'category':'global','type':'slider','minValue':0.0,'maxValue':10.0,
      'minLabel':'Very well','maxLabel':'Very poor','unit':'/10',
    });

    // rapid3def
    final d = _db.collection('rapid3def');
    for (final e in {
      'REMISSION': {'tierName':'Remission','emoji':'🟢','colorHex':'#10B981','rapid3Min':0.0,'rapid3Max':1.0},
      'LOW':       {'tierName':'Low Disease Activity','emoji':'🟡','colorHex':'#F59E0B','rapid3Min':1.0,'rapid3Max':2.0},
      'MODERATE':  {'tierName':'Moderate Disease Activity','emoji':'🟠','colorHex':'#F97316','rapid3Min':2.0,'rapid3Max':4.0},
      'HIGH':      {'tierName':'High Disease Activity','emoji':'🔴','colorHex':'#EF4444','rapid3Min':4.0,'rapid3Max':10.0},
    }.entries) {
      await d.doc(e.key).set({'tierId': e.key, ...e.value});
    }
    print('[Seed] ✓ global collections');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  static double _rapid3(double pain, double func, double global) =>
      double.parse(((pain + func * (10 / 3) + global) / 3).toStringAsFixed(1));

  static String _tier(double s) {
    if (s <= 1.0) return 'REMISSION';
    if (s <= 2.0) return 'LOW';
    if (s <= 4.0) return 'MODERATE';
    return 'HIGH';
  }

  static String _dateKey(int y, int m, int d) =>
      '$y${m.toString().padLeft(2,'0')}${d.toString().padLeft(2,'0')}';

  static String _emoji(String t) =>
      const {'REMISSION':'🟢','LOW':'🟡','MODERATE':'🟠','HIGH':'🔴'}[t] ?? '⚪';

  static String _color(String t) =>
      const {'REMISSION':'#10B981','LOW':'#F59E0B','MODERATE':'#F97316','HIGH':'#EF4444'}[t] ?? '#6B7280';

  static bool _take(int pct, int seed) => (seed * 37 + 13) % 100 < pct;

  static int _tsMs(DateTime day, int hour, int min) =>
      DateTime(day.year, day.month, day.day, hour, min).millisecondsSinceEpoch;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEED BUTTON WIDGET
// Drop anywhere during development. Remove before production.
//
// HOW TO USE:
//   1. Replace each empty string '' below with a real Firebase UID
//   2. UIDs you don't have yet → leave as '' (they are skipped)
//   3. Drop <SeedMultiUserButton /> onto any dev screen
//   4. Tap the button once
// ─────────────────────────────────────────────────────────────────────────────
class SeedMultiUserButton extends StatefulWidget {
  const SeedMultiUserButton({super.key});

  @override
  State<SeedMultiUserButton> createState() => _SeedMultiUserButtonState();
}

class _SeedMultiUserButtonState extends State<SeedMultiUserButton> {
  bool   _busy   = false;
  String _status = '';

  // ── PASTE YOUR 10 UIDs HERE ────────────────────────────────────────────────
  static const _uids = [
    '',   // User 1: Farah Izzati        — steady improver
    '',   // User 2: Amir Zulkifli       — chronic moderate
    '',   // User 3: Priya Nair          — mostly remission, one flare
    '',   // User 4: David Tan           — poor adherence, worsening
    '',   // User 5: Nurul Hidayah       — newly diagnosed, erratic
    '',   // User 6: Kevin Loh           — athlete, stays low
    '',   // User 7: Siti Rohani         — elderly, sparse logging
    '',   // User 8: Raj Kumar           — skips long stretches
    '',   // User 9: Mei Ling            — stress-correlated flares
    '',   // User 10: Hassan Abdullah    — post-surgery recovery
  ];

  Future<void> _run() async {
    final filled = _uids.where((u) => u.trim().isNotEmpty).toList();
    if (filled.isEmpty) {
      setState(() => _status = '❌ No UIDs filled in — edit _uids list above.');
      return;
    }
    setState(() { _busy = true; _status = 'Seeding ${filled.length} users…'; });
    try {
      await SeedMultiUser.seedAll(_uids.toList());
      setState(() => _status = '✅ Done! Seeded ${filled.length} users. Hot-restart the app.');
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: _busy
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.group_add_rounded),
          label: Text(_busy ? 'Seeding…' : '🌱 Seed 10 Users'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          onPressed: _busy ? null : _run,
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _status.startsWith('✅') ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }
}