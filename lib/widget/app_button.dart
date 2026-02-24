import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppButtonVariant { primary, success, danger, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double? fontSize;
  final FontWeight fontWeight;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    super.key,
  });

  Color _variantBackgroundColor() {
    switch (variant) {
      case AppButtonVariant.success:
        return AppColors.success;
      case AppButtonVariant.danger:
        return AppColors.danger;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.primary:
        return AppColors.primary;
    }
  }

  Color _variantTextColor() {
    switch (variant) {
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.success:
      case AppButtonVariant.danger:
      case AppButtonVariant.primary:
        return AppColors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundColor ?? _variantBackgroundColor();
    final resolvedTextColor = textColor ?? _variantTextColor();
    final isOutline = variant == AppButtonVariant.outline;
    final resolvedDisabledBackground = isOutline
        ? Colors.transparent
        : resolvedBackground.withValues(alpha: 0.6);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: resolvedBackground,
      foregroundColor: resolvedTextColor,
      disabledBackgroundColor: resolvedDisabledBackground,
      disabledForegroundColor: resolvedTextColor.withValues(alpha: 0.7),
      elevation: isOutline ? 0 : null,
      side: isOutline ? const BorderSide(color: AppColors.primary) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      ),
    );

    final child = icon == null
        ? ElevatedButton(
            style: buttonStyle,
            onPressed: onPressed,
            child: Text(
              label,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          )
        : ElevatedButton.icon(
            style: buttonStyle,
            onPressed: onPressed,
            icon: Icon(icon, size: 18, color: resolvedTextColor),
            label: Text(
              label,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          );

    return SizedBox(width: width, height: height, child: child);
  }
}
