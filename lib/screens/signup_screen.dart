// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_local_variable

import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  Country? selectedCountry;
  bool agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Conditions')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', emailController.text.trim());
    Get.toNamed(Routes.otpSignup);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double paddingH = width * 0.06;
        double fontSizeTitle = width * 0.07;
        double fontSizeField = width * 0.045;
        double spacing = height * 0.02;

        if (width >= 1200) {
          paddingH = width * 0.2;
          fontSizeTitle = width * 0.04;
          fontSizeField = width * 0.025;
        } else if (width >= 800) {
          paddingH = width * 0.12;
          fontSizeTitle = width * 0.055;
          fontSizeField = width * 0.035;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.blue.shade900,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: spacing,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing),

                  _textFormField(
                    controller: fullNameController,
                    hint: 'Full Name',
                    icon: Icons.person,
                    fontSize: fontSizeField,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Full name required'
                        : null,
                  ),

                  _textFormField(
                    controller: phoneController,
                    hint: 'Phone Number',
                    icon: Icons.phone,
                    fontSize: fontSizeField,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Phone required' : null,
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      readOnly: true,
                      validator: (_) =>
                          selectedCountry == null ? 'Select country' : null,
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (c) => setState(() => selectedCountry = c),
                        );
                      },
                      decoration: InputDecoration(
                        prefixIcon: selectedCountry != null
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: CountryFlag.fromCountryCode(
                                  selectedCountry!.countryCode,
                                ),
                              )
                            : const Icon(Icons.flag),
                        hintText: selectedCountry?.name ?? 'Select Country',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  _textFormField(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.email,
                    fontSize: fontSizeField,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                      ).hasMatch(v))
                        return 'Invalid email';
                      return null;
                    },
                  ),

                  _textFormField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock,
                    fontSize: fontSizeField,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    toggleVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),

                  _textFormField(
                    controller: confirmPasswordController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    fontSize: fontSizeField,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm password';
                      if (v != passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: agreeTerms,
                        activeColor: Colors.blue.shade900,
                        onChanged: (v) =>
                            setState(() => agreeTerms = v ?? false),
                      ),
                      const Expanded(
                        child: Text('I agree to the Terms & Conditions'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  AppButton(
                    label: 'Sign Up',
                    onPressed: _submitSignup,
                    width: double.infinity,
                    height: 50,
                    backgroundColor: Colors.blue.shade900,
                    borderRadius: 12,
                    fontSize: fontSizeField,
                    fontWeight: FontWeight.bold,
                  ),

                  const SizedBox(height: 25),
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
                  SizedBox(height: spacing * 1.5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.login),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _textFormField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    double fontSize = 16,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

