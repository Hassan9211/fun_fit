// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';

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

  void _verifyOtp() {
    final otp = _controllers.map((e) => e.text).join();

    if (otp.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter complete OTP')));
      return;
    }

    /// 🔁 NAVIGATION BASED ON PURPOSE
    switch (widget.purpose) {
      case OtpPurpose.signup:
        Get.offNamed(Routes.registrationSuccess);
        break;

      case OtpPurpose.forgotPassword:
        Get.offNamed(Routes.passwordResetSuccess);
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
            title: const Text('OTP Verification'),
            backgroundColor: Colors.blue.shade900,
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _verifyOtp,
                        child: const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
