// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final AuthApiService _authApi = AuthApiService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final args = Get.arguments;
    final asChangePassword = args is Map && args['asChangePassword'] == true;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    final email = emailController.text.trim();
    final result = await _authApi.requestOtp(
      email: email,
      purpose: 'forgotPassword',
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await AuthSessionStorage.savePendingEmail(email);
    final otpToken = AuthSessionStorage.extractToken(result.data);
    if (otpToken != null && otpToken.trim().isNotEmpty) {
      await AuthSessionStorage.saveOtpToken(otpToken);
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Get.toNamed(
      Routes.otpForgotPassword,
      arguments: {'asChangePassword': asChangePassword, 'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final asChangePassword = args is Map && args['asChangePassword'] == true;
    final screenTitle = asChangePassword
        ? 'Change Password'
        : 'Forgot Password';
    final helperText = asChangePassword
        ? 'Enter your email address and we will send you a 4-digit OTP to change your password.'
        : 'Enter your email address and we will send you a 4-digit OTP to reset your password.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final titleSize = info.value(mobile: 28, tablet: 32, desktop: 36);
        final fieldFontSize = info.value(mobile: 15, tablet: 16, desktop: 16);
        final buttonHeight = info.value(mobile: 50, tablet: 52, desktop: 54);
        final avatarRadius = info.value(mobile: 42, tablet: 50, desktop: 58);
        final iconSize = avatarRadius * 1.1;
        final fieldPadding = EdgeInsets.symmetric(
          vertical: info.value(mobile: 16, tablet: 14, desktop: 14),
          horizontal: 14,
        );

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              screenTitle,
              style: TextStyle(color: AppColors.textTitleFor(context)),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 460,
                tabletMaxWidth: 520,
                desktopMaxWidth: 560,
                padding: info.pagePadding(
                  mobileHorizontal: 16,
                  tabletHorizontal: 24,
                  desktopHorizontal: 32,
                  mobileVertical: 28,
                  tabletVertical: 40,
                  desktopVertical: 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.lock_reset,
                          size: iconSize,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: info.value(mobile: 24, tablet: 28, desktop: 32)),
                      Text(
                        'Reset Your Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTitleFor(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        helperText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                      SizedBox(height: info.value(mobile: 24, tablet: 28, desktop: 32)),
                      TextFormField(
                        controller: emailController,
                        style: TextStyle(fontSize: fieldFontSize),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email,
                            color: AppColors.textSecondaryFor(context),
                          ),
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            color: AppColors.textMutedFor(context),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceMuted(context),
                          contentPadding: fieldPadding,
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
                      ),
                      SizedBox(height: info.value(mobile: 20, tablet: 24, desktop: 28)),
                      AppButton(
                        label: _isSubmitting ? 'Please wait...' : 'Continue',
                        onPressed: _isSubmitting ? null : _submit,
                        width: double.infinity,
                        height: buttonHeight,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: 8,
                        fontSize: fieldFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: info.value(mobile: 20, tablet: 24, desktop: 28)),
                      Center(
                        child: GestureDetector(
                          onTap: () => Get.offAllNamed(Routes.login),
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textTitleFor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
