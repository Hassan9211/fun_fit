// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

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
      case OtpPurpose.forgotPassword:
        return 'Verify OTP';
    }
  }

  String get subtitle {
    switch (widget.purpose) {
      case OtpPurpose.forgotPassword:
        return 'Enter the OTP sent to reset your password';
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
      OtpPurpose.forgotPassword => 'forgotPassword',
    };
    final otpToken = await AuthSessionStorage.readOtpToken();
    final result = await _authApi.verifyOtp(
      email: email,
      otp: otp,
      purpose: purposeValue,
      token: otpToken.isEmpty ? null : otpToken,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final otpBoxWidth = info.value(mobile: 55, tablet: 60, desktop: 64);
        final titleSize = info.value(mobile: 26, tablet: 28, desktop: 32);
        final otpSpacing = info.value(mobile: 10, tablet: 12, desktop: 14);

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
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 420,
                tabletMaxWidth: 500,
                desktopMaxWidth: 560,
                padding: info.pagePadding(
                  mobileHorizontal: 16,
                  tabletHorizontal: 24,
                  desktopHorizontal: 32,
                  mobileVertical: 28,
                  tabletVertical: 40,
                  desktopVertical: 48,
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
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
                    SizedBox(height: info.value(mobile: 28, tablet: 32, desktop: 36)),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: otpSpacing,
                      runSpacing: otpSpacing,
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
                    SizedBox(height: info.value(mobile: 28, tablet: 32, desktop: 36)),
                    AppButton(
                      label: _isVerifying ? 'Please wait...' : 'Continue',
                      onPressed: _isVerifying ? null : _verifyOtp,
                      width: double.infinity,
                      height: info.value(
                        mobile: 50,
                        tablet: 52,
                        desktop: 54,
                      ),
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
