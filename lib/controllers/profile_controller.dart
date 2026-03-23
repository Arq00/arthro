import 'dart:math';
import 'package:flutter/material.dart';

class ProfileController {
  // --- Profile Data ---
  String username = "Asry Mile";
  final String email = "example@example.com"; 
  String phone = "+460 1116026352";
  String? raDiagnosisDate;
  String? raNotes = "Morning stiffness in hands.";
  late String referralCode;

  // --- Summary Data (Mocked from other modules) ---
  int symptomLogs = 14;      // From Health Tracking
  int lifestyleLogs = 32;    // From Health Tracking
  int activeMeds = 3;        // From Medication Module
  int upcomingAppts = 2;     // From Appointment Module

  ProfileController() {
    referralCode = _generateReferralCode();
  }

  // Feature: Auto-generate 9-digit referral code
  String _generateReferralCode() {
    return (Random().nextInt(900000000) + 100000000).toString();
  }

  // Logic to save updated info
  void handleSave(String newName, String newPhone, String newNotes) {
    username = newName;
    phone = newPhone;
    raNotes = newNotes;
    // In a real app, you'd call an API or Database here
  }
}