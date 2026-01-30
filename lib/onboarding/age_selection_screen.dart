// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/onboarding/height_measure.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  int selectedAge = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double titleSize = width * 0.075;
        double ageSize = width * 0.1;
        double buttonFont = width * 0.045;
        double paddingH = width * 0.08;
        double buttonHeight = 52;

        if (width >= 1200) {
          titleSize = width * 0.04;
          ageSize = width * 0.06;
          buttonFont = width * 0.025;
          paddingH = width * 0.3;
        } else if (width >= 800) {
          titleSize = width * 0.05;
          ageSize = width * 0.075;
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
                  'What is your age?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.06),

                /// Selected Age
                Text(
                  '$selectedAge',
                  style: TextStyle(
                    fontSize: ageSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),

                SizedBox(height: height * 0.02),

                /// Age Label
                Text(
                  'Years',
                  style: TextStyle(
                    fontSize: buttonFont,
                    color: Colors.grey.shade700,
                  ),
                ),

                SizedBox(height: height * 0.04),

                /// Age Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue.shade900,
                    inactiveTrackColor: Colors.blue.shade900.withOpacity(0.2),
                    thumbColor: Colors.blue.shade900,
                    overlayColor: Colors.blue.shade900.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 10,
                    max: 80,
                    divisions: 70,
                    value: selectedAge.toDouble(),
                    label: selectedAge.toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedAge = value.round();
                      });
                    },
                  ),
                ),

                SizedBox(height: height * 0.06),

                /// Next Button
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HeightSelectionScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: buttonFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
