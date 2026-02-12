// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? selectedGender;

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
                  'What is your gender?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.06),

                /// Male
                _genderOption(
                  label: 'Male',
                  icon: Icons.male,
                  isSelected: selectedGender == 'male',
                  fontSize: optionFont,
                  onTap: () {
                    setState(() {
                      selectedGender = 'male';
                    });
                  },
                ),

                SizedBox(height: height * 0.025),

                /// Female
                _genderOption(
                  label: 'Female',
                  icon: Icons.female,
                  isSelected: selectedGender == 'female',
                  fontSize: optionFont,
                  onTap: () {
                    setState(() {
                      selectedGender = 'female';
                    });
                  },
                ),

                SizedBox(height: height * 0.06),

                /// Next Button
                AppButton(
                  label: 'Next',
                  onPressed: selectedGender == null
                      ? null
                      : () => Get.toNamed(Routes.goal),
                  width: double.infinity,
                  height: buttonHeight,
                  backgroundColor: Colors.blue.shade900,
                  borderRadius: 14,
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

  /// Gender Option Widget
  Widget _genderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    final bgColor = isSelected ? Colors.blue.shade900 : Colors.white;
    final textColor = isSelected ? Colors.white : Colors.blue.shade900;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade900, width: 1.5),
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
