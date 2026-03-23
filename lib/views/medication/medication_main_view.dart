// lib/views/medication/medication_main_view.dart
// Entry point for the Medication module.
// Tabs: Today (schedule + adherence) | Medication List (CRUD)

import 'package:arthro/widgets/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/medication_controller.dart';
import 'medication_today_view.dart';
import 'medication_stock_view.dart';

class MedicationMainView extends StatelessWidget {
  /// Pass the patient's uid when a guardian is viewing; null = own data.
  final String? uid;
  const MedicationMainView({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MedicationController(uid: uid),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor: AppColors.bgCard,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.border,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medications', style: AppTextStyles.sectionTitle()),
                Text(
                  'Adherence intelligence',
                  style: AppTextStyles.labelCaps(),
                ),
              ],
            ),
            bottom: TabBar(
              labelStyle: AppTextStyles.label(),
              unselectedLabelStyle: AppTextStyles.caption(),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              dividerColor: AppColors.divider,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Medications'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              MedicationTodayView(),
              MedicationListView(),
            ],
          ),
        ),
      ),
    );
  }
}