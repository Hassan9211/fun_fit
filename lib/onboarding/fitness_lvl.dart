// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class FitnessLevelScreen extends StatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  State<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends State<FitnessLevelScreen> {
  String? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double titleSize = width * 0.075;
        double optionFont = width * 0.045;
        double buttonFont = width * 0.045;
        double paddingH = width * 0.08;
        double buttonHeight = 52;

        if (width >= 1200) {
          titleSize = width * 0.04;
          optionFont = width * 0.025;
          buttonFont = width * 0.025;
          paddingH = width * 0.3;
        } else if (width >= 800) {
          titleSize = width * 0.05;
          optionFont = width * 0.035;
          buttonFont = width * 0.035;
          paddingH = width * 0.2;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Title
                Text(
                  'What is your fitness level?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.06),

                /// Beginner
                _levelOption(
                  label: 'Beginner',
                  isSelected: selectedLevel == 'beginner',
                  fontSize: optionFont,
                  onTap: () {
                    setState(() {
                      selectedLevel = 'beginner';
                    });
                  },
                ),

                SizedBox(height: height * 0.025),

                /// Intermediate
                _levelOption(
                  label: 'Intermediate',
                  isSelected: selectedLevel == 'intermediate',
                  fontSize: optionFont,
                  onTap: () {
                    setState(() {
                      selectedLevel = 'intermediate';
                    });
                  },
                ),

                SizedBox(height: height * 0.025),

                /// Advanced
                _levelOption(
                  label: 'Advanced',
                  isSelected: selectedLevel == 'advanced',
                  fontSize: optionFont,
                  onTap: () {
                    setState(() {
                      selectedLevel = 'advanced';
                    });
                  },
                ),

                SizedBox(height: height * 0.06),

                /// Next Button
                AppButton(
                  label: 'Next',
                  onPressed: selectedLevel == null
                      ? null
                      : () => Get.toNamed(Routes.age),
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
        );
      },
    );
  }

  /// Fitness Level Option Widget
  Widget _levelOption({
    required String label,
    required bool isSelected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? Colors.black : const Color(0xFFF3F4F6);
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
            color: isSelected ? Colors.black : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

