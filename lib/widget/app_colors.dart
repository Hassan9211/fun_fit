import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1D3DBB);
  static const Color primaryDark = Color(0xFF2949C8);
  static const Color transparentPrimary = Color(0x001D3DBB);
  static const Color appBackground = Color(0xFFF3F5FB);
  static const Color white = Colors.white;

  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF8A94A6);
  static const Color textTitle = Color(0xFF111827);
  static const Color textHeaderHint = Color(0xFF47516B);
  static const Color textCardHint = Color(0xFF5E6B86);

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color avatarBg = Color(0xFFEAEFFD);
  static const Color successPale = Color(0xFFEFF4EA);
  static const Color danger = Color(0xFFEF4444);
  static const Color navUnselected = Color(0xFFB0B7C3);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color surfaceMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E293B) : appBackground;

  static Color textPrimaryFor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : textSecondary;

  static Color textMutedFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF7C8BA1) : textMuted;

  static Color textTitleFor(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : textTitle;

  static Color borderLightFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : borderLight;

  static Color avatarBgFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF27344A) : avatarBg;

  static Color successPaleFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B2B1F) : successPale;

  static Color navUnselectedFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : navUnselected;
}
