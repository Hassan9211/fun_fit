// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen> {
  double selectedHeight = 170;
  bool isCm = true; // toggle between cm / ft

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

        double displayHeight = isCm
            ? selectedHeight
            : (selectedHeight / 30.48); // convert cm to ft

        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What is your height?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.04),

                /// Toggle cm / ft
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('cm'),
                      selected: isCm,
                      onSelected: (val) => setState(() => isCm = true),
                      selectedColor: Colors.blue.shade900,
                      labelStyle: TextStyle(
                        color: isCm ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('ft'),
                      selected: !isCm,
                      onSelected: (val) => setState(() => isCm = false),
                      selectedColor: Colors.blue.shade900,
                      labelStyle: TextStyle(
                        color: !isCm ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.06),

                /// Display Height
                Text(
                  '${displayHeight.toStringAsFixed(1)} ${isCm ? 'cm' : 'ft'}',
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
                    min: 100,
                    max: 220,
                    divisions: 120,
                    value: selectedHeight,
                    label: '${selectedHeight.toStringAsFixed(0)} cm',
                    onChanged: (val) => setState(() => selectedHeight = val),
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
                    onPressed: () => Get.toNamed(Routes.weight),
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
