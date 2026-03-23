// lib/views/navigation/global_navigation.dart

import 'package:arthro/controllers/auth_controller.dart';
import 'package:arthro/views/auth/guardian_enter_code.dart';
import 'package:arthro/views/health/symptom_screen.dart';
import 'package:arthro/views/home/home_view.dart';
import 'package:arthro/views/report/report_view.dart';
import 'package:arthro/widgets/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:arthro/views/medication/medication_main_view.dart';
import 'package:arthro/views/appointment/appointment_main_view.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<GlobalNavigationState> globalNavKey =
    GlobalKey<GlobalNavigationState>();


class GlobalNavigation extends StatefulWidget {
  final int initialIndex;
  const GlobalNavigation({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  GlobalNavigationState createState() => GlobalNavigationState();
}

class GlobalNavigationState extends State<GlobalNavigation> {
  late int _currentIndex;
  bool _approvalDialogShown = false;
  bool _listenerStarted = false;

  void switchTab(int index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listenerStarted) {
        _listenerStarted = true;
        _listenForGuardianRequests();
      }
    });
  }

  void _listenForGuardianRequests() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.currentUser;
    if (user == null || user.role != 'patient') return;

    FirebaseFirestore.instance
        .collection('connectionRequests')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['status'] == 'pending' && !_approvalDialogShown) {
          _approvalDialogShown = true;
          _showApprovalDialog(
            data['guardianName'] ?? 'Someone',
            data['requestId'],
            auth,
          );
        }
      } else {
        _approvalDialogShown = false;
      }
    });
  }

  void _showApprovalDialog(
      String name, String guardianId, AuthController auth) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _isProcessing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.people_outline_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Guardian Request', style: AppTextStyles.sectionTitle()),
            ]),
            content: Text(
              '$name wants to become your Guardian and view your health data. Do you approve?',
              style: AppTextStyles.body(),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () async {
                  setDialogState(() => _isProcessing = true);
                  await auth.rejectGuardianRequest();
                  if (mounted) Navigator.pop(context);
                },
                child: Text('Deny',
                    style: AppTextStyles.buttonSecondary()
                        .copyWith(color: AppColors.error)),
              ),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  setDialogState(() => _isProcessing = true);
                  await auth.approveGuardianRequest(guardianId);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Approve'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;

    final isGuardian = user?.role == 'guardian';
    final isGuardianUnlinked = isGuardian &&
        (user?.patientId == null || user!.patientId!.isEmpty);

    // Unlinked guardian sees ONLY the link screen, no tabs
    if (isGuardianUnlinked) {
      return GuardianLinkView(
        onLogout: () => auth.logout(context),
      );
    }

    // Wait for uid to be resolved before mounting any tab —
    // prevents empty string being passed to Firestore document paths.
    final effectiveDataId = auth.effectiveDataId ?? user?.uid;
    if (effectiveDataId == null || effectiveDataId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeView(),                                    // 0 Home
          SymptomScreen(userId: effectiveDataId),              // 1 Health
          MedicationMainView(uid: effectiveDataId),            // 2 Meds
          AppointmentMainView(uid: effectiveDataId),           // 3 Appointment
          ReportView(uid: effectiveDataId),                    // 4 Report
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bgCard,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          selectedLabelStyle:
              AppTextStyles.labelCaps().copyWith(color: AppColors.primary),
          unselectedLabelStyle: AppTextStyles.labelCaps(),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication),
              label: 'Meds',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Appointment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Report',
            ),
          ],
        ),
      ),
    );
  }
}