// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
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
  final AuthApiService _authApi = AuthApiService();
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
    final otp = _controllers.map((e) => e.text.trim()).join();
    if (otp.length != 4 || !RegExp(r'^\d{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter complete OTP')));
      return;
    }

    setState(() => _isVerifying = true);
    final args = Get.arguments;
    String email = '';
    if (args is Map) {
      email = (args['email'] ?? '').toString().trim();
    }
    if (email.isEmpty) {
      email = await AuthSessionStorage.readEmail();
    }
    if (email.isEmpty) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please try again.')),
      );
      return;
    }

    final purposeValue = switch (widget.purpose) {
      OtpPurpose.signup => 'signup',
      OtpPurpose.forgotPassword => 'forgotPassword',
      OtpPurpose.signin => 'signin',
    };
    final result = await _authApi.verifyOtp(
      email: email,
      otp: otp,
      purpose: purposeValue,
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

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
          Routes.changePassword,
          arguments: {
            'asResetFlow': true,
            'asChangePassword': asChangePassword,
            'email': email,
            'otp': otp,
            'verifyData': result.data,
          },
        );
        break;
      case OtpPurpose.signin:
        await AuthSessionStorage.markLoggedIn(
          email: email,
          responseData: result.data,
        );
        if (!mounted) return;
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Verification Code',
              style: TextStyle(color: AppColors.textTitleFor(context)),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                      style: TextStyle(
                        color: AppColors.textSecondaryFor(context),
                      ),
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
                              fillColor: AppColors.surfaceMuted(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.borderLightFor(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.borderLightFor(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.7),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
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
