// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';

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
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double paddingH = width * 0.06;
        double titleSize = width * 0.06;
        double fieldFontSize = width * 0.045;
        double buttonHeight = 50;

        EdgeInsets fieldPadding = const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        );

        if (width >= 1200) {
          paddingH = width * 0.25;
          titleSize = width * 0.035;
          fieldFontSize = width * 0.022;

          fieldPadding = const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          );
        } else if (width >= 800) {
          paddingH = width * 0.15;
          titleSize = width * 0.045;
          fieldFontSize = width * 0.03;

          fieldPadding = const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          );
        }

        double avatarRadius = (width * 0.08).clamp(35.0, 60.0);
        double iconSize = avatarRadius * 1.1;

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
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: height * 0.08),
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.lock_reset,
                      size: iconSize,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTitleFor(context),
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  Text(
                    helperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: TextFormField(
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
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: AppButton(
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
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  GestureDetector(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
