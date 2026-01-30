// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double selectedWeight = 70;
  bool isKg = true; // toggle kg / lb

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double titleSize = width * 0.075;
        double valueSize = width * 0.08;
        double buttonFont = width * 0.045;
        double paddingH = width * 0.08;
        double buttonHeight = 52;

        if (width >= 1200) {
          titleSize = width * 0.04;
          valueSize = width * 0.06;
          buttonFont = width * 0.025;
          paddingH = width * 0.3;
        } else if (width >= 800) {
          titleSize = width * 0.05;
          valueSize = width * 0.07;
          buttonFont = width * 0.035;
          paddingH = width * 0.2;
        }

        double displayWeight = isKg
            ? selectedWeight
            : (selectedWeight * 2.20462); // convert kg to lb

        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What is your weight?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.04),

                /// Toggle kg / lb
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('kg'),
                      selected: isKg,
                      onSelected: (val) => setState(() => isKg = true),
                      selectedColor: Colors.blue.shade900,
                      labelStyle: TextStyle(
                        color: isKg ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('lb'),
                      selected: !isKg,
                      onSelected: (val) => setState(() => isKg = false),
                      selectedColor: Colors.blue.shade900,
                      labelStyle: TextStyle(
                        color: !isKg ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.06),

                /// Display Weight
                Text(
                  '${displayWeight.toStringAsFixed(1)} ${isKg ? 'kg' : 'lb'}',
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),

                SizedBox(height: height * 0.03),

                /// Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.blue.shade900,
                    inactiveTrackColor: Colors.blue.shade900.withOpacity(0.2),
                    thumbColor: Colors.blue.shade900,
                    overlayColor: Colors.blue.shade900.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 30,
                    max: 150,
                    divisions: 120,
                    value: selectedWeight,
                    label: '${selectedWeight.toStringAsFixed(0)} kg',
                    onChanged: (val) => setState(() => selectedWeight = val),
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
                      // Navigate to next onboarding screen
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
