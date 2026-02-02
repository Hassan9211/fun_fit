// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fun_fit/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      /// 👉 SAME OTP SCREEN (LOGIN PURPOSE)
      Get.toNamed(Routes.otpSignin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double paddingH = width * 0.06;
        double fontTitle = width * 0.07;
        double fontField = width * 0.045;
        double buttonHeight = 50;
        double socialRadius = 22;

        if (width >= 1200) {
          paddingH = width * 0.25;
          fontTitle = width * 0.04;
          fontField = width * 0.025;
        } else if (width >= 800) {
          paddingH = width * 0.15;
          fontTitle = width * 0.05;
          fontField = width * 0.035;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Login', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.blue.shade900,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: paddingH),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.05),

                  /// Welcome
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: fontTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  /// Password
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Password is required';
                        if (value.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  /// Remember / Forgot
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                        activeColor: Colors.blue.shade900,
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.03),

                  /// Continue
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
                      onPressed: _login,
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: fontField,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.04),

                  /// OR
                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton(
                        icon: Icons.telegram,
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),

                      _socialButton(
                        icon: Icons.facebook,
                        color: Colors.blue.shade900,
                        onTap: () {},
                      ),
                      const SizedBox(width: 20),

                      _socialButton(
                        icon: Icons.apple,
                        color: Colors.black,
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.04),

                  /// Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don’t have an account? '),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.signup),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
