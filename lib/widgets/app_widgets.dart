
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────
// APP CARD
// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.shadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: shadow ?? AppShadows.subtle(),
        ),
        padding: padding ?? const EdgeInsets.all(AppSpacing.base),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TIER BADGE
// ─────────────────────────────────────────────
class TierBadge extends StatelessWidget {
  final String tier;
  final bool large;

  const TierBadge({Key? key, required this.tier, this.large = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppTierHelper.color(tier);
    final bg    = AppTierHelper.bgColor(tier);
    final emoji = AppTierHelper.emoji(tier);
    final label = AppTierHelper.label(tier);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: large ? 16 : 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFontsHelper.jakartaSans(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP INDICATOR
// ─────────────────────────────────────────────
class StepIndicator extends StatelessWidget {
  final int total;
  final int current;

  const StepIndicator({Key? key, required this.total, required this.current})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive   = i == current;
        final isComplete = i < current;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: isComplete || isActive
                  ? AppColors.primary
                  : AppColors.primaryBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    Key? key, required this.title, this.subtitle, this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle()),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.caption()),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PRIMARY BUTTON
// ─────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final bool outlined;

  const AppButton({
    Key? key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.color,
    this.outlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : bg,
          border: outlined ? Border.all(color: bg, width: 1.5) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: outlined ? [] : AppShadows.card(),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: outlined ? bg : Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: outlined ? bg : Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.buttonPrimary().copyWith(
                        color: outlined ? bg : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INFO ROW (label + value pair)
// ─────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.caption()),
          ),
          Text(
            value,
            style: AppTextStyles.cardTitle().copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8), trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEATHER CHIP
// ─────────────────────────────────────────────
class WeatherRiskChip extends StatelessWidget {
  final String label;
  final String riskLevel; // 'low', 'moderate', 'high'
  final IconData icon;

  const WeatherRiskChip({
    Key? key,
    required this.label,
    required this.riskLevel,
    required this.icon,
  }) : super(key: key);

  Color get _color {
    switch (riskLevel) {
      case 'high':     return AppColors.tierHigh;
      case 'moderate': return AppColors.tierModerate;
      default:         return AppColors.tierRemission;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: _color, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GOOGLE FONTS HELPER (avoids import in every file)
// ─────────────────────────────────────────────
class GoogleFontsHelper {
  GoogleFontsHelper._();

  static TextStyle jakartaSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}