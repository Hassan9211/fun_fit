import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF111111);
  static const Color primaryDark = Color(0xFF000000);
  static const Color transparentPrimary = Color(0x00111111);
  static const Color appBackground = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF3F4F6);
  static const Color inputFill = Color(0xFFF3F4F6);
  static const Color white = Colors.white;

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textTitle = Color(0xFF111111);
  static const Color textHeaderHint = Color(0xFF6B7280);
  static const Color textCardHint = Color(0xFF6B7280);

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color avatarBg = Color(0xFFF3F4F6);
  static const Color successPale = Color(0xFFF3F4F6);
  static const Color danger = Color(0xFFEF4444);
  static const Color navUnselected = Color(0xFF9CA3AF);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) => white;

  static Color surfaceMuted(BuildContext context) => surfaceSoft;

  static Color textPrimaryFor(BuildContext context) => textPrimary;

  static Color textSecondaryFor(BuildContext context) => textSecondary;

  static Color textMutedFor(BuildContext context) => textMuted;

  static Color textTitleFor(BuildContext context) => textTitle;

  static Color borderLightFor(BuildContext context) => borderLight;

  static Color avatarBgFor(BuildContext context) => avatarBg;

  static Color successPaleFor(BuildContext context) => successPale;

  static Color navUnselectedFor(BuildContext context) => navUnselected;
}
