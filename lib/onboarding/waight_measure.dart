// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double selectedWeightKg = 57;
  bool isKgSelected = false;

  double get selectedWeightLb => selectedWeightKg * 2.20462;

  Future<void> _showWeightInputDialog() async {
    final currentValue = isKgSelected
        ? selectedWeightKg.round().toString()
        : selectedWeightLb.round().toString();
    final unit = isKgSelected ? 'kg' : 'lb';
    final controller = TextEditingController(text: currentValue);

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set weight in $unit'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: isKgSelected ? 'e.g. 57' : 'e.g. 125',
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
    final parsed = double.tryParse(value);
    if (parsed == null) return;

    if (isKgSelected) {
      setState(() => selectedWeightKg = parsed.clamp(30, 200));
      return;
    }

    final convertedKg = parsed / 2.20462;
    setState(() => selectedWeightKg = convertedKg.clamp(30, 200));
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
        final mainValue = isKgSelected
            ? selectedWeightKg.round().toString()
            : selectedWeightLb.round().toString();
        final mainUnit = isKgSelected ? 'kg' : 'lb';
        final secondaryValue = isKgSelected
            ? selectedWeightLb.round().toString()
            : selectedWeightKg.round().toString();
        final secondaryUnit = isKgSelected ? 'lb' : 'kg';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                            "What's your weight?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _UnitSwitch(
                            isKgSelected: isKgSelected,
                            onKgTap: () => setState(() => isKgSelected = true),
                            onLbTap: () =>
                                setState(() => isKgSelected = false),
                          ),
                          const SizedBox(height: 34),
                          _WeightPill(value: mainValue, unit: mainUnit),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showWeightInputDialog,
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
                          _WeightPill(value: secondaryValue, unit: secondaryUnit),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 84),
                      child: AppButton(
                        label: 'Next',
                        onPressed: () => Get.toNamed(Routes.home),
                        width: double.infinity,
                        height: 48,
                        backgroundColor: const Color(0xFF1D3DBB),
                        borderRadius: 10,
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

class _UnitSwitch extends StatelessWidget {
  final bool isKgSelected;
  final VoidCallback onKgTap;
  final VoidCallback onLbTap;

  const _UnitSwitch({
    required this.isKgSelected,
    required this.onKgTap,
    required this.onLbTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E9F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _UnitChip(
            label: 'kg',
            selected: isKgSelected,
            onTap: onKgTap,
          ),
          const SizedBox(width: 3),
          _UnitChip(
            label: 'lb',
            selected: !isKgSelected,
            onTap: onLbTap,
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnitChip({
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
            color: selected ? const Color(0xFF1D3DBB) : Colors.transparent,
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

class _WeightPill extends StatelessWidget {
  final String value;
  final String unit;

  const _WeightPill({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E7E7),
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

