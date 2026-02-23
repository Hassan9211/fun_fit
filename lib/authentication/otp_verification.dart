// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class OtpScreen extends StatefulWidget {
  final OtpPurpose purpose;

  const OtpScreen({super.key, required this.purpose});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _isVerifying = false;

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get title {
    switch (widget.purpose) {
      case OtpPurpose.signup:
        return 'Verify Your Account';
      case OtpPurpose.forgotPassword:
        return 'Verify OTP';
      case OtpPurpose.signin:
        return 'Verify Your Account';
    }
  }

  String get subtitle {
    switch (widget.purpose) {
      case OtpPurpose.signup:
        return 'Enter the OTP sent for first time signup';
      case OtpPurpose.forgotPassword:
        return 'Enter the OTP sent to reset your password';
      case OtpPurpose.signin:
        return 'Enter the OTP sent to verify your account';
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((e) => e.text).join();

    final requiresCompleteOtp = widget.purpose != OtpPurpose.forgotPassword;
    if (requiresCompleteOtp && otp.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter complete OTP')));
      return;
    }

    setState(() => _isVerifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isVerifying = false);

    switch (widget.purpose) {
      case OtpPurpose.signup:
        Get.offNamed(Routes.registrationSuccess);
        break;
      case OtpPurpose.forgotPassword:
        final args = Get.arguments;
        final asChangePassword =
            args is Map && args['asChangePassword'] == true;
        Get.offNamed(
          Routes.passwordResetSuccess,
          arguments: {'asChangePassword': asChangePassword},
        );
        break;
      case OtpPurpose.signin:
        Get.offNamed(Routes.home);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final hPadding = isDesktop
            ? width * 0.25
            : isTablet
            ? width * 0.16
            : 24.0;
        final otpBoxWidth = isDesktop
            ? 64.0
            : isTablet
            ? 60.0
            : 55.0;
        final titleSize = isDesktop
            ? 32.0
            : isTablet
            ? 28.0
            : 26.0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Verification Code',
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: otpBoxWidth,
                          child: TextField(
                            controller: _controllers[index],
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      label: _isVerifying ? 'Please wait...' : 'Continue',
                      onPressed: _isVerifying ? null : _verifyOtp,
                      width: double.infinity,
                      height: 50,
                      backgroundColor: Colors.black,
                      borderRadius: 8,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
