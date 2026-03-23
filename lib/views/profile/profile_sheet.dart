// lib/views/profile/profile_sheet.dart
// Opens ProfileView as a draggable bottom sheet (3/4 screen height).
// Uses a nested Navigator so AccountSettings + Security push/pop
// entirely inside the sheet without touching the main nav stack.

import 'package:flutter/material.dart';
import 'package:arthro/views/profile/profile_view.dart';
import 'package:arthro/widgets/app_theme.dart';

/// Call this from any widget to open the profile sheet.
/// e.g. GestureDetector(onTap: () => showProfileSheet(context))
void showProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context:            context,
    isScrollControlled: true,
    backgroundColor:    Colors.transparent,
    barrierColor:       Colors.black.withOpacity(0.4),
    builder: (sheetContext) =>
        _ProfileSheet(rootContext: context),
  );
}

class _ProfileSheet extends StatelessWidget {
  final BuildContext rootContext;
  const _ProfileSheet({required this.rootContext});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      // 3/4 of screen height
      height: screenH * 0.75,
      decoration: BoxDecoration(
        color:        AppColors.bgPage,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
        boxShadow: AppShadows.elevated(),
      ),
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // ── Nested Navigator ───────────────────────────────────────────
          // Keeps AccountSettingsView + SecurityView scoped inside
          // the sheet so they don't affect the main nav stack.
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl)),
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => ProfileView(
                    onLogout: () {
                      // Close the sheet first, then logout navigates to Welcome
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}