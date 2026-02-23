// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
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

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Get.toNamed(
      Routes.otpForgotPassword,
      arguments: {'asChangePassword': asChangePassword},
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final asChangePassword = args is Map && args['asChangePassword'] == true;
    final screenTitle = asChangePassword ? 'Change Password' : 'Forgot Password';
    final helperText =
        asChangePassword
            ? 'Enter your mail address to receive a password reset link.'
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

          fieldPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 14);
        } else if (width >= 800) {
          paddingH = width * 0.15;
          titleSize = width * 0.045;
          fieldFontSize = width * 0.03;

          fieldPadding = const EdgeInsets.symmetric(vertical: 14, horizontal: 14);
        }

        double avatarRadius = (width * 0.08).clamp(35.0, 60.0);
        double iconSize = avatarRadius * 1.1;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              screenTitle,
              style: const TextStyle(color: Colors.black87),
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
                    backgroundColor: Colors.black,
                    child: Icon(
                      Icons.lock_reset,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  Text(
                    helperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF6B7280),
                          ),
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: fieldPadding,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black54),
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
                        backgroundColor: Colors.black,
                        borderRadius: 8,
                        fontSize: fieldFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.04),
                  GestureDetector(
                    onTap: () => Get.offAllNamed(Routes.login),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
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
