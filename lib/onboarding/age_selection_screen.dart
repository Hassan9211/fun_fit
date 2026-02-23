// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  late final List<int> _years;
  late final FixedExtentScrollController _yearController;
  late int _selectedBirthYear;

  int get _currentYear => DateTime.now().year;
  int get _selectedAge => _currentYear - _selectedBirthYear;

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      (_currentYear - 1950) + 1,
      (index) => 1950 + index,
    );
    _selectedBirthYear = _currentYear - 22;
    final initialIndex = _years.indexOf(_selectedBirthYear);
    _yearController = FixedExtentScrollController(
      initialItem: initialIndex < 0 ? _years.length - 1 : initialIndex,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
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
                            "What's your Age?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 190,
                            width: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                ListWheelScrollView.useDelegate(
                                  controller: _yearController,
                                  itemExtent: 38,
                                  perspective: 0.003,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setState(() => _selectedBirthYear = _years[index]);
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: _years.length,
                                    builder: (context, index) {
                                      final year = _years[index];
                                      final selected = year == _selectedBirthYear;
                                      return Center(
                                        child: Text(
                                          '$year',
                                          style: TextStyle(
                                            fontSize: selected ? 30 : 26,
                                            fontWeight: selected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: selected
                                                ? Colors.black
                                                : Colors.black45,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Age: $_selectedAge years',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 84),
                      child: AppButton(
                        label: 'Next',
                        onPressed: () => Get.toNamed(
                          Routes.height,
                          arguments: {
                            'birthYear': _selectedBirthYear,
                            'age': _selectedAge,
                          },
                        ),
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

