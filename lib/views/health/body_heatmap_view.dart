// lib/views/health/symptom/body_heatmap_view.dart
// Step 1b: Interactive Body Heat Map
// User taps body parts to mark affected joints (clear → mild → severe → clear).

import 'dart:async';
import 'package:arthro/widgets/app_theme.dart';
import 'package:arthro/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/health_controller.dart';
import '../../../models/health_model.dart';

class BodyHeatmapView extends StatelessWidget {
  const BodyHeatmapView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HealthController>();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.primary,
          onPressed: () => ctrl.goToStep(HealthStep.symptomQuestions),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('STEP 2 OF 3', style: AppTextStyles.labelCaps()),
            Text('Joint Heat Map', style: AppTextStyles.sectionTitle()),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm,
            ),
            child: StepIndicator(total: 3, current: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Tap each joint to mark pain level. Tap again to cycle through severity.',
                            style: AppTextStyles.bodySmall(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: AppColors.jointNormal, label: 'No pain'),
                      const SizedBox(width: AppSpacing.base),
                      _LegendDot(color: AppColors.tierLow, label: 'Mild'),
                      const SizedBox(width: AppSpacing.base),
                      _LegendDot(color: AppColors.tierHigh, label: 'Severe'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Body diagram
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 480,
                      child: _BodyDiagram(joints: ctrl.bodyJoints, onTap: ctrl.toggleJoint),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Selected joints summary
                  if (ctrl.selectedJoints.isNotEmpty) ...[
                    SectionHeader(
                      title: 'Affected Joints',
                      subtitle: '${ctrl.selectedJoints.length} joint(s) selected',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ctrl.bodyJoints
                          .where((j) => j.isSelected)
                          .map((j) => _JointChip(joint: j, onRemove: () => ctrl.toggleJoint(j.id)))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.accessibility_new_rounded,
                              size: 40, color: AppColors.textMuted),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No joints selected\n(optional — you can skip)',
                            style: AppTextStyles.caption(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ],
              ),
            ),
          ),
          // ── Bottom nav ──
          _BottomBar(
            onNext:  ctrl.nextToStiffness,
            onBack:  () => ctrl.goToStep(HealthStep.symptomQuestions),
            nextLabel: ctrl.selectedJoints.isEmpty
                ? 'Skip & Continue →'
                : 'Continue →',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BODY DIAGRAM — Custom paint layout with joint labels
// ─────────────────────────────────────────────
class _BodyDiagram extends StatefulWidget {
  final List<BodyJoint> joints;
  final void Function(String) onTap;
  const _BodyDiagram({required this.joints, required this.onTap});

  @override
  State<_BodyDiagram> createState() => _BodyDiagramState();
}

class _BodyDiagramState extends State<_BodyDiagram> {
  // Track which joint label is currently shown
  String? _activeLabel;
  Offset? _labelPos;
  Timer? _labelTimer;

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _handleTap(String jointId, Offset pos) {
    widget.onTap(jointId);
    final joint = widget.joints.firstWhere((j) => j.id == jointId);
    // Show label for 2 seconds then hide
    setState(() {
      _activeLabel = joint.label;
      _labelPos    = pos;
    });
    _labelTimer?.cancel();
    _labelTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _activeLabel = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Silhouette outline
        CustomPaint(
          size: const Size(300, 480),
          painter: _BodySilhouettePainter(),
        ),
        // Joint tap targets
        ...widget.joints.map((j) => _jointWidget(j)),
        // Floating label tooltip
        if (_activeLabel != null && _labelPos != null)
          _FloatingJointLabel(label: _activeLabel!, pos: _labelPos!),
      ],
    );
  }

  Widget _jointWidget(BodyJoint joint) {
    final pos = _jointPositions[joint.id];
    if (pos == null) return const SizedBox.shrink();

    Color color;
    switch (joint.severity) {
      case 'mild':   color = AppColors.tierLow;  break;
      case 'severe': color = AppColors.tierHigh; break;
      default:       color = AppColors.jointNormal;
    }

    return Positioned(
      left: pos.dx - 14,
      top:  pos.dy - 14,
      child: GestureDetector(
        onTap: () => _handleTap(joint.id, pos),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: joint.isSelected ? Colors.white : AppColors.border,
              width: joint.isSelected ? 2 : 1.5,
            ),
            boxShadow: joint.isSelected
                ? [BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8, spreadRadius: 2,
                  )]
                : [],
          ),
          child: joint.isSelected
              ? Icon(
                  joint.severity == 'severe'
                      ? Icons.warning_rounded
                      : Icons.circle,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  /// Joint positions on a 300×480 canvas
  static const Map<String, Offset> _jointPositions = {
    'neck':            Offset(150, 60),
    'left_shoulder':   Offset(95,  95),
    'right_shoulder':  Offset(205, 95),
    'left_elbow':      Offset(72,  160),
    'right_elbow':     Offset(228, 160),
    'left_wrist':      Offset(60,  220),
    'right_wrist':     Offset(240, 220),
    'left_hand':       Offset(52,  260),
    'right_hand':      Offset(248, 260),
    'lower_back':      Offset(150, 200),
    'left_hip':        Offset(110, 230),
    'right_hip':       Offset(190, 230),
    'left_knee':       Offset(110, 330),
    'right_knee':      Offset(190, 330),
    'left_ankle':      Offset(105, 415),
    'right_ankle':     Offset(195, 415),
    'left_foot':       Offset(95,  455),
    'right_foot':      Offset(205, 455),
  };
}

// ─────────────────────────────────────────────
// FLOATING JOINT LABEL — shows on tap, auto-hides after 2s
// ─────────────────────────────────────────────
class _FloatingJointLabel extends StatelessWidget {
  final String label;
  final Offset pos;
  const _FloatingJointLabel({required this.label, required this.pos});

  @override
  Widget build(BuildContext context) {
    // Position the label above the tapped joint
    // Clamp so it never goes off the left/right edge of 300px canvas
    final labelX = (pos.dx - 40).clamp(0.0, 220.0);
    final labelY = (pos.dy - 46).clamp(0.0, 460.0);

    return Positioned(
      left: labelX,
      top:  labelY,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BODY SILHOUETTE PAINTER
// ─────────────────────────────────────────────
class _BodySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBorder.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = AppColors.primarySurface.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Head
    final headRect = Rect.fromCenter(center: const Offset(150, 32), width: 36, height: 42);
    canvas.drawOval(headRect, fill);
    canvas.drawOval(headRect, paint);

    // Torso
    final torsoPath = Path()
      ..moveTo(100, 80)
      ..lineTo(90, 220)
      ..lineTo(115, 250)
      ..lineTo(185, 250)
      ..lineTo(210, 220)
      ..lineTo(200, 80)
      ..close();
    canvas.drawPath(torsoPath, fill);
    canvas.drawPath(torsoPath, paint);

    // Left arm
    final lArmPath = Path()
      ..moveTo(100, 85)
      ..quadraticBezierTo(68, 150, 55, 265);
    canvas.drawPath(lArmPath, paint);

    // Right arm
    final rArmPath = Path()
      ..moveTo(200, 85)
      ..quadraticBezierTo(232, 150, 245, 265);
    canvas.drawPath(rArmPath, paint);

    // Left leg
    final lLegPath = Path()
      ..moveTo(120, 248)
      ..lineTo(105, 410)
      ..lineTo(90, 468);
    canvas.drawPath(lLegPath, paint);

    // Right leg
    final rLegPath = Path()
      ..moveTo(180, 248)
      ..lineTo(195, 410)
      ..lineTo(210, 468);
    canvas.drawPath(rLegPath, paint);

    // Neck
    canvas.drawLine(const Offset(140, 52), const Offset(140, 80), paint);
    canvas.drawLine(const Offset(160, 52), const Offset(160, 80), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color,
            border: Border.all(color: AppColors.border)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption()),
      ],
    );
  }
}

class _JointChip extends StatelessWidget {
  final BodyJoint joint;
  final VoidCallback onRemove;
  const _JointChip({required this.joint, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = joint.severity == 'severe' ? AppColors.tierHigh : AppColors.tierLow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(joint.label, style: AppTextStyles.caption().copyWith(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  const _BottomBar({required this.onNext, this.onBack, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.md,
        AppSpacing.base, AppSpacing.base + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: AppShadows.subtle(),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(flex: 3, child: AppButton(label: nextLabel, onTap: onNext)),
        ],
      ),
    );
  }
}