// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final args = Get.arguments;
    final asChangePassword =
        args is Map && args['asChangePassword'] == true;
    if (_formKey.currentState!.validate()) {
      Get.toNamed(
        Routes.otpForgotPassword,
        arguments: {'asChangePassword': asChangePassword},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final asChangePassword =
        args is Map && args['asChangePassword'] == true;
    final screenTitle = asChangePassword
        ? 'Change Password'
        : 'Forgot Password';
    final helperText = asChangePassword
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

        /// 🔥 Desktop specific padding fix
        EdgeInsets fieldPadding = const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        );

        if (width >= 1200) {
          paddingH = width * 0.25;
          titleSize = width * 0.035;
          fieldFontSize = width * 0.022;

          fieldPadding = const EdgeInsets.symmetric(
            vertical: 12, // 👈 height control
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
            backgroundColor: Colors.blue.shade900,
            title: Text(screenTitle, style: const TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: height * 0.08),

                  /// Icon
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.lock_reset,
                      size: iconSize,
                      color: Colors.blue.shade900,
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// Title
                  Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: height * 0.015),

                  /// Description
                  Text(
                    helperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),

                  SizedBox(height: height * 0.04),

                  /// Email Field (Width + Height FIXED)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: TextFormField(
                        controller: emailController,
                        style: TextStyle(fontSize: fieldFontSize),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Email is required';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                          ).hasMatch(value))
                            return 'Enter a valid email';
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          hintText: 'Email',
                          contentPadding: fieldPadding, // 👈 KEY FIX
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// Button
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: AppButton(
                        label: 'Send OTP',
                        onPressed: _submit,
                        width: double.infinity,
                        height: buttonHeight,
                        backgroundColor: Colors.blue.shade900,
                        borderRadius: 12,
                        fontSize: fieldFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// Back
                  GestureDetector(
                    onTap: () => Get.offAllNamed(Routes.login),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue.shade900,
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

