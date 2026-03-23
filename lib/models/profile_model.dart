import 'dart:math';

class UserProfile {
  String username;
  final String email; // Cannot be changed per instructions
  String phone;
  String password;
  String referralCode;
  String? raDiagnosisDate;
  String? raNotes;
  bool pushNotifications;
  bool darkTheme;

  UserProfile({
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.referralCode,
    this.raDiagnosisDate,
    this.raNotes,
    this.pushNotifications = true,
    this.darkTheme = false,
  });

  // Feature: Auto-generate referral code for new profiles
  static String generateReferralCode() {
    return (Random().nextInt(900000) + 100000).toString();
  }
}

class HealthSummary {
  final int symptomRecords;
  final int lifestyleActivities;
  final int medicationsAdded;
  final int notesRecorded;

  HealthSummary({
    this.symptomRecords = 0,
    this.lifestyleActivities = 0,
    this.medicationsAdded = 0,
    this.notesRecorded = 0,
  });
}