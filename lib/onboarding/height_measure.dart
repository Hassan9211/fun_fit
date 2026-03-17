// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen> {
  double selectedHeightCm = 180;
  bool isCmSelected = false;

  Map<String, dynamic> _readOnboardingData() {
    final args = Get.arguments;
    if (args is! Map) return <String, dynamic>{};
    return args.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  String get _feetInchesText {
    final totalInches = selectedHeightCm / 2.54;
    var feet = totalInches ~/ 12;
    var inches = (totalInches - (feet * 12)).round();
    if (inches == 12) {
      feet += 1;
      inches = 0;
    }
    return '$feet.${inches.toString().padLeft(2, '0')}';
  }

  Future<void> _showHeightInputDialog() async {
    final currentValue = isCmSelected
        ? selectedHeightCm.round().toString()
        : _feetInchesText;
    final unit = isCmSelected ? 'cm' : 'ft';
    final controller = TextEditingController(text: currentValue);

    final value = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return AlertDialog(
          title: Text('Set height in $unit'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: isCmSelected ? 'e.g. 180' : 'e.g. 5.10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (value == null || value.isEmpty) return;
    if (isCmSelected) {
      final cm = double.tryParse(value);
      if (cm == null) return;
      setState(() => selectedHeightCm = cm.clamp(100, 220));
      return;
    }

    final match = RegExp(r"^(\d{1,2})(?:[.' :](\d{1,2}))?$").firstMatch(value);
    if (match == null) return;
    final feet = int.tryParse(match.group(1) ?? '');
    final inches = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (feet == null || inches > 11) return;
    final totalInches = (feet * 12) + inches;
    final cm = totalInches * 2.54;
    setState(() => selectedHeightCm = cm.clamp(100, 220));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final contentMaxWidth = isDesktop
            ? 420.0
            : isTablet
            ? 380.0
            : width;

        final titleSize = isDesktop
            ? 38.0
            : isTablet
            ? 34.0
            : 36.0;
        final buttonFont = isDesktop
            ? 16.0
            : isTablet
            ? 15.0
            : 14.0;

        final mainValue = isCmSelected
            ? selectedHeightCm.round().toString()
            : _feetInchesText;
        final mainUnit = isCmSelected ? 'cm' : 'ft';
        final secondaryValue = isCmSelected
            ? _feetInchesText
            : selectedHeightCm.round().toString();
        final secondaryUnit = isCmSelected ? 'ft' : 'cm';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.arrow_back,
                              size: 16,
                              color: Colors.black54,
                            ),
                            onPressed: () => Get.back(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "What's your height?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _HeightUnitSwitch(
                            isCmSelected: isCmSelected,
                            onCmTap: () => setState(() => isCmSelected = true),
                            onFtTap: () =>
                                setState(() => isCmSelected = false),
                          ),
                          const SizedBox(height: 34),
                          _HeightPill(value: mainValue, unit: mainUnit),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showHeightInputDialog,
                            child: const Text(
                              'Tap to edit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HeightPill(
                            value: secondaryValue,
                            unit: secondaryUnit,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 84),
                      child: AppButton(
                        label: 'Next',
                        onPressed: () {
                          final onboardingData = _readOnboardingData();
                          onboardingData['heightCm'] = double.parse(
                            selectedHeightCm.toStringAsFixed(1),
                          );
                          onboardingData['heightFt'] = _feetInchesText;
                          onboardingData['heightUnit'] =
                              isCmSelected ? 'cm' : 'ft';
                          Get.toNamed(Routes.weight, arguments: onboardingData);
                        },
                        width: double.infinity,
                        height: 48,
                        backgroundColor: Colors.black,
                        borderRadius: 8,
                        fontSize: buttonFont,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _HeightUnitSwitch extends StatelessWidget {
  final bool isCmSelected;
  final VoidCallback onCmTap;
  final VoidCallback onFtTap;

  const _HeightUnitSwitch({
    required this.isCmSelected,
    required this.onCmTap,
    required this.onFtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cFFF3F4F6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _HeightUnitChip(
            label: 'cm',
            selected: isCmSelected,
            onTap: onCmTap,
          ),
          const SizedBox(width: 3),
          _HeightUnitChip(
            label: 'ft',
            selected: !isCmSelected,
            onTap: onFtTap,
          ),
        ],
      ),
    );
  }
}

class _HeightUnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HeightUnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeightPill extends StatelessWidget {
  final String value;
  final String unit;

  const _HeightPill({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.cFFF3F4F6,
        border: Border.all(color: AppColors.cFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: RichText(
        text: TextSpan(
          text: value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 34,
            height: 1,
          ),
          children: [
            TextSpan(
              text: ' $unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

