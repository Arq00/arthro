// lib/views/appointment/appointment_main_view.dart

import 'package:arthro/widgets/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/appointment_controller.dart';
import 'appointment_list_view.dart';
import 'appointment_history_view.dart';
import 'appointment_form_view.dart';

class AppointmentMainView extends StatelessWidget {
  final String? uid;
  const AppointmentMainView({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppointmentController(uid: uid),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor:        AppColors.bgCard,
            elevation:              0,
            scrolledUnderElevation: 1,
            shadowColor:            AppColors.border,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appointments', style: AppTextStyles.sectionTitle()),
                Text('TRACK & MANAGE', style: AppTextStyles.labelCaps()),
              ],
            ),
            bottom: TabBar(
              labelStyle:           AppTextStyles.label(),
              unselectedLabelStyle: AppTextStyles.caption(),
              labelColor:           AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor:       AppColors.primary,
              indicatorWeight:      2.5,
              dividerColor:         AppColors.divider,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AppointmentListView(),
              AppointmentHistoryView(),
            ],
          ),
          floatingActionButton: Builder(
            builder: (ctx) => FloatingActionButton(
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                          value: ctx.read<AppointmentController>(),
                          child: const AppointmentFormView(),
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}