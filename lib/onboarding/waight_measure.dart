// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({super.key});

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen> {
  double selectedWeightKg = 57;
  bool isKgSelected = false;
  bool _isSaving = false;
  final AuthApiService _authApi = AuthApiService();

  double get selectedWeightLb => selectedWeightKg * 2.20462;

  Map<String, dynamic> _readOnboardingData() {
    final args = Get.arguments;
    if (args is! Map) return <String, dynamic>{};
    return args.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSaving = true);

    final onboardingData = _readOnboardingData();
    onboardingData['weightKg'] = double.parse(
      selectedWeightKg.toStringAsFixed(1),
    );
    onboardingData['weightLb'] = double.parse(
      selectedWeightLb.toStringAsFixed(1),
    );
    onboardingData['weightUnit'] = isKgSelected ? 'kg' : 'lb';

    final email = (onboardingData['email'] ?? '').toString().trim();
    var token = (onboardingData['authToken'] ?? '').toString().trim();
    if (token.isEmpty) {
      token = await AuthSessionStorage.readToken();
    }
    final result = await _authApi.saveOnboardingProfile(
      onboardingData: onboardingData,
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    Get.offAllNamed(Routes.home);
  }

  Future<void> _showWeightInputDialog() async {
    final currentValue = isKgSelected
        ? selectedWeightKg.round().toString()
        : selectedWeightLb.round().toString();
    final unit = isKgSelected ? 'kg' : 'lb';
    final controller = TextEditingController(text: currentValue);

    final value = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
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
        final info = ResponsiveInfo.fromConstraints(constraints);
        final contentMaxWidth = info.isMobile
            ? info.width
            : info.maxWidth(mobile: info.width, tablet: 400, desktop: 460);
        final titleSize = info.value(mobile: 32, tablet: 34, desktop: 38);
        final buttonFont = info.value(mobile: 14, tablet: 15, desktop: 16);
        final backButtonSize = info.value(mobile: 30, tablet: 32, desktop: 34);
        final mainValue = isKgSelected
            ? selectedWeightKg.round().toString()
            : selectedWeightLb.round().toString();
        final mainUnit = isKgSelected ? 'kg' : 'lb';
        final secondaryValue = isKgSelected
            ? selectedWeightLb.round().toString()
            : selectedWeightKg.round().toString();
        final secondaryUnit = isKgSelected ? 'lb' : 'kg';

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
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        info.value(mobile: 28, tablet: 34, desktop: 40),
                      ),
                      child: AppButton(
                        label: _isSaving ? 'Please wait...' : 'Next',
                        onPressed: _isSaving ? null : _submitOnboarding,
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
        color: AppColors.cFFF3F4F6,
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

class _WeightPill extends StatelessWidget {
  final String value;
  final String unit;

  const _WeightPill({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cFFF3F4F6,
        border: Border.all(color: AppColors.cFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }
}

