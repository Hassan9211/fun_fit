import 'package:flutter/material.dart';
import 'package:fun_fit/widget/app_colors.dart';

class PasswordPolicy {
  static bool hasMinLength(String value) => value.length >= 8;

  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool hasNumber(String value) => RegExp(r'\d').hasMatch(value);

  static bool hasSpecialChar(String value) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\];`~]').hasMatch(value);

  static bool isStrong(String value) {
    return hasMinLength(value) &&
        hasUppercase(value) &&
        hasLowercase(value) &&
        hasNumber(value) &&
        hasSpecialChar(value);
  }

  static String? validateStrong(String? value, {bool required = true}) {
    final password = (value ?? '').trim();
    if (required && password.isEmpty) return 'Password required';
    if (password.isEmpty) return null;
    if (!isStrong(password)) {
      return 'Use 8+ chars with uppercase, lowercase, number, special character';
    }
    return null;
  }
}

class PasswordStrengthChecklist extends StatelessWidget {
  final String password;
  final String title;

  const PasswordStrengthChecklist({
    super.key,
    required this.password,
    this.title = 'Strong password suggestion',
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.surfaceMuted(context);
    final borderColor = AppColors.borderLightFor(context);
    final titleColor = AppColors.textSecondaryFor(context);
    final rules = <({String label, bool met})>[
      (
        label: 'At least 8 characters',
        met: PasswordPolicy.hasMinLength(password),
      ),
      (
        label: 'At least 1 uppercase letter',
        met: PasswordPolicy.hasUppercase(password),
      ),
      (
        label: 'At least 1 lowercase letter',
        met: PasswordPolicy.hasLowercase(password),
      ),
      (label: 'At least 1 number', met: PasswordPolicy.hasNumber(password)),
      (
        label: 'At least 1 special character',
        met: PasswordPolicy.hasSpecialChar(password),
      ),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          ...rules.map((rule) => _RuleItem(label: rule.label, met: rule.met)),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String label;
  final bool met;

  const _RuleItem({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.cFF16A34A : AppColors.cFF9CA3AF;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: met ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
