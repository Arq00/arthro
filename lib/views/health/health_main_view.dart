// lib/views/health/health_main_view.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/health_controller.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'symptoms_question_view.dart';
import 'body_heatmap_view.dart';
import 'morning_stiffness_view.dart';
import 'rapdi3_result_view.dart';
import 'lifestyle_view.dart';

class HealthMainView extends StatefulWidget {
  /// Pass the patient's uid when a guardian is viewing.
  /// Falls back to FirebaseAuth.currentUser?.uid if empty/null.
  final String userId;
  const HealthMainView({Key? key, required this.userId}) : super(key: key);

  @override
  State<HealthMainView> createState() => _HealthMainViewState();
}

class _HealthMainViewState extends State<HealthMainView> {
  HealthController? _ctrl;

  /// Returns the definitive non-empty user ID.
  /// Priority: widget.userId → FirebaseAuth.currentUser.uid
  String get _resolvedUserId {
    if (widget.userId.isNotEmpty) return widget.userId;
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  /// Re-init when the userId prop changes (guardian switches patient).
  @override
  void didUpdateWidget(HealthMainView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _ctrl?.dispose();
      _ctrl = null;
      _initController();
    }
  }

  void _initController() {
    final uid = _resolvedUserId;
    if (uid.isEmpty) {
      // Auth not ready yet — wait for FirebaseAuth state then retry
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (user != null && mounted) {
          setState(() {
            _ctrl = HealthController(userId: user.uid)..init();
          });
        }
      });
    } else {
      setState(() {
        _ctrl = HealthController(userId: uid)..init();
      });
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _ctrl!,
      child: Consumer<HealthController>(
        builder: (context, ctrl, _) {
          return Scaffold(
            backgroundColor: AppColors.bgPage,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: _buildCurrentStep(ctrl),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(HealthController ctrl) {
    switch (ctrl.currentStep) {
      case HealthStep.symptomQuestions:
        return const SymptomQuestionsView(key: ValueKey('symptom'));
      case HealthStep.bodyHeatmap:
        return const BodyHeatmapView(key: ValueKey('heatmap'));
      case HealthStep.morningStiffness:
        return const MorningStiffnessView(key: ValueKey('stiffness'));
      case HealthStep.result:
        return const Rapid3ResultView(key: ValueKey('result'));
      case HealthStep.lifestyle:
        return const LifestyleView(key: ValueKey('lifestyle'));
    }
  }
}