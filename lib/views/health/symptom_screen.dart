// lib/views/symptom/symptom_screen.dart
// This file serves as the bridge between GlobalNavigation
// (which calls SymptomScreen(userId:)) and the Health module.
// It simply mounts HealthMainView with the given userId.
// GlobalNavigation uses: import 'package:arthro/views/symptom/symptom_screen.dart'

import 'package:flutter/material.dart';
import '../health/health_main_view.dart';

class SymptomScreen extends StatelessWidget {
  final String userId;
  const SymptomScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HealthMainView(userId: userId);
  }
}