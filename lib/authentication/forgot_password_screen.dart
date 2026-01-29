// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fun_fit/authentication/otp_verification.dart';

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
    if (_formKey.currentState!.validate()) {
      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpVerificationScreen(emailOrPhone: emailController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double paddingH = width * 0.06;
        double titleSize = width * 0.06;
        double fieldSize = width * 0.045;
        double buttonHeight = 50;

        if (width >= 1200) {
          paddingH = width * 0.25;
          titleSize = width * 0.035;
          fieldSize = width * 0.025;
        } else if (width >= 800) {
          paddingH = width * 0.15;
          titleSize = width * 0.045;
          fieldSize = width * 0.035;
        }

        // Controlled avatar size
        double avatarRadius = (width * 0.08).clamp(35.0, 60.0);
        double iconSize = avatarRadius * 1.1;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.blue.shade900,
            title: const Text(
              'Forgot Password',
              style: TextStyle(color: Colors.white),
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

                  // 🔐 Icon Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100,
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(
                        Icons.lock_reset,
                        size: iconSize,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  // Title
                  Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: height * 0.015),

                  // Description
                  Text(
                    'Enter your email address and we will send you a 4-digit OTP to reset your password.',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: height * 0.04),

                  // Email Field
                  TextFormField(
                    controller: emailController,
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
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: fieldSize,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        'Send Reset Link',
                        style: TextStyle(
                          fontSize: fieldSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  // Back to Login
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
