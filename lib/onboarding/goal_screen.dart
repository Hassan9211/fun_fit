// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String? selectedGoal;

  Map<String, dynamic> _readOnboardingData() {
    final args = Get.arguments;
    if (args is! Map) return <String, dynamic>{};
    return args.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final titleSize = info.value(mobile: 30, tablet: 34, desktop: 38);
        final optionFont = info.value(mobile: 16, tablet: 17, desktop: 18);
        final buttonFont = info.value(mobile: 15, tablet: 16, desktop: 17);
        final buttonHeight = info.value(mobile: 52, tablet: 54, desktop: 56);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 420,
                tabletMaxWidth: 500,
                desktopMaxWidth: 540,
                padding: info.pagePadding(
                  mobileHorizontal: 20,
                  tabletHorizontal: 28,
                  desktopHorizontal: 36,
                  mobileVertical: 24,
                  tabletVertical: 32,
                  desktopVertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'What is your goal?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: info.value(mobile: 28, tablet: 32, desktop: 36),
                    ),
                    _goalOption(
                      label: 'Lose Fat',
                      icon: Icons.local_fire_department,
                      isSelected: selectedGoal == 'lose_fat',
                      fontSize: optionFont,
                      onTap: () {
                        setState(() => selectedGoal = 'lose_fat');
                      },
                    ),
                    SizedBox(
                      height: info.value(mobile: 12, tablet: 14, desktop: 16),
                    ),
                    _goalOption(
                      label: 'Stay Fit',
                      icon: Icons.favorite,
                      isSelected: selectedGoal == 'stay_fit',
                      fontSize: optionFont,
                      onTap: () {
                        setState(() => selectedGoal = 'stay_fit');
                      },
                    ),
                    SizedBox(
                      height: info.value(mobile: 12, tablet: 14, desktop: 16),
                    ),
                    _goalOption(
                      label: 'Build Muscle',
                      icon: Icons.fitness_center,
                      isSelected: selectedGoal == 'build_muscle',
                      fontSize: optionFont,
                      onTap: () {
                        setState(() => selectedGoal = 'build_muscle');
                      },
                    ),
                    SizedBox(
                      height: info.value(mobile: 28, tablet: 32, desktop: 36),
                    ),
                    AppButton(
                      label: 'Next',
                      onPressed: selectedGoal == null
                          ? null
                          : () {
                              final onboardingData = _readOnboardingData();
                              onboardingData['goal'] = selectedGoal;
                              Get.toNamed(
                                Routes.fitnessLevel,
                                arguments: onboardingData,
                              );
                            },
                      width: double.infinity,
                      height: buttonHeight,
                      backgroundColor: Colors.black,
                      borderRadius: 8,
                      fontSize: buttonFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Goal Option Widget
  Widget _goalOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? Colors.black : AppColors.cFFF3F4F6;
    final textColor = isSelected ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : AppColors.cFFE5E7EB,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: fontSize + 6),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

