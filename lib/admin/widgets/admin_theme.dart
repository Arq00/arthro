// lib/admin/admin_theme.dart
import 'package:flutter/material.dart';

class AdminTheme {
  static const primary      = Color(0xFF1B5F5F);
  static const primaryLight = Color(0xFF2D8080);
  static const primaryDark  = Color(0xFF0F3D3D);
  static const accent       = Color(0xFF00BFA5);
  static const accentLight  = Color(0xFFE0F7F5);

  static const bg     = Color(0xFFF0F4F8);
  static const bgCard = Color(0xFFFFFFFF);
  static const navBg  = Color(0xFF0D3333);

  static const green   = Color(0xFF10B981);
  static const greenBg = Color(0xFFECFDF5);
  static const amber   = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFFFBEB);
  static const orange  = Color(0xFFF97316);
  static const orangeBg= Color(0xFFFFF7ED);
  static const red     = Color(0xFFEF4444);
  static const redBg   = Color(0xFFFEF2F2);
  static const grey    = Color(0xFF9CA3AF);
  static const greyBg  = Color(0xFFF3F4F6);

  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFE5E7EB);

  static const fontFamily = 'Roboto';

  static Color tierColor(String t) {
    switch (t.toUpperCase()) {
      case 'REMISSION': return green;
      case 'LOW':       return amber;
      case 'MODERATE':  return orange;
      case 'HIGH':      return red;
      default:          return grey;
    }
  }

  static Color tierBg(String t) {
    switch (t.toUpperCase()) {
      case 'REMISSION': return greenBg;
      case 'LOW':       return amberBg;
      case 'MODERATE':  return orangeBg;
      case 'HIGH':      return redBg;
      default:          return greyBg;
    }
  }

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2))],
  );

  static BoxDecoration gradientCard(List<Color> colors,
      {double radius = 16}) =>
      BoxDecoration(
        gradient: LinearGradient(colors: colors,
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(
            color: colors.first.withOpacity(0.28),
            blurRadius: 16, offset: const Offset(0, 6))],
      );

  static const tsTitle = TextStyle(fontSize: 22,
      fontWeight: FontWeight.w700, color: textPrimary, fontFamily: fontFamily);
  static const tsSectionTitle = TextStyle(fontSize: 16,
      fontWeight: FontWeight.w600, color: textPrimary, fontFamily: fontFamily);
  static const tsCardTitle = TextStyle(fontSize: 14,
      fontWeight: FontWeight.w600, color: textPrimary, fontFamily: fontFamily);
  static const tsBody = TextStyle(fontSize: 13,
      color: textSecondary, fontFamily: fontFamily);
  static const tsSmall = TextStyle(fontSize: 11,
      color: textMuted, fontFamily: fontFamily);
  static const tsLabel = TextStyle(fontSize: 11,
      fontWeight: FontWeight.w600, color: textMuted,
      fontFamily: fontFamily, letterSpacing: 0.8);

  static InputDecoration inputDeco(String hint, {IconData? icon}) =>
      InputDecoration(
        hintText: hint, hintStyle: tsBody,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: textMuted) : null,
        filled: true, fillColor: bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5)),
      );

  static ButtonStyle primaryBtn({Color? color}) => ElevatedButton.styleFrom(
    backgroundColor: color ?? primary, foregroundColor: Colors.white,
    elevation: 0, minimumSize: Size.zero,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        fontFamily: fontFamily),
  );
}