// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  late final List<int> _years;
  late final FixedExtentScrollController _yearController;
  late int _selectedBirthYear;

  Map<String, dynamic> _readOnboardingData() {
    final args = Get.arguments;
    if (args is! Map) return <String, dynamic>{};
    return args.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

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
        final info = ResponsiveInfo.fromConstraints(constraints);
        final contentMaxWidth = info.isMobile
            ? info.width
            : info.maxWidth(mobile: info.width, tablet: 400, desktop: 460);
        final titleSize = info.value(mobile: 32, tablet: 34, desktop: 38);
        final buttonFont = info.value(mobile: 14, tablet: 15, desktop: 16);
        final backButtonSize = info.value(mobile: 30, tablet: 32, desktop: 34);

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
                          width: backButtonSize,
                          height: backButtonSize,
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
                            height: info.value(mobile: 190, tablet: 200, desktop: 210),
                            width: info.value(mobile: 180, tablet: 190, desktop: 210),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: info.value(mobile: 140, tablet: 150, desktop: 164),
                                  height: info.value(mobile: 42, tablet: 44, desktop: 46),
                                  decoration: BoxDecoration(
                                    color: AppColors.cFFF3F4F6,
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
                                            fontSize: selected
                                                ? info.value(
                                                    mobile: 30,
                                                    tablet: 32,
                                                    desktop: 34,
                                                  )
                                                : info.value(
                                                    mobile: 26,
                                                    tablet: 28,
                                                    desktop: 30,
                                                  ),
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
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        info.value(mobile: 28, tablet: 34, desktop: 40),
                      ),
                      child: AppButton(
                        label: 'Next',
                        onPressed: () {
                          final onboardingData = _readOnboardingData();
                          onboardingData['birthYear'] = _selectedBirthYear;
                          onboardingData['age'] = _selectedAge;
                          Get.toNamed(Routes.height, arguments: onboardingData);
                        },
                        width: double.infinity,
                        height: info.value(mobile: 48, tablet: 50, desktop: 52),
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

