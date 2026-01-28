// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures

import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:fun_fit/screens/login_screen.dart';
import 'package:fun_fit/screens/registration_screen.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to the Terms & Conditions'),
          ),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Responsive values
        double paddingH = width * 0.06;
        double paddingV = height * 0.03;
        double fontSizeTitle = width * 0.07;
        double fontSizeField = width * 0.045;
        double buttonHeight = height * 0.065;
        double socialRadius = 22;
        double spacing = height * 0.02;

        if (width >= 1200) {
          // Desktop
          paddingH = width * 0.2;
          paddingV = height * 0.05;
          fontSizeTitle = width * 0.04;
          fontSizeField = width * 0.025;
          buttonHeight = height * 0.06;
          socialRadius = 26;
        } else if (width >= 800) {
          // Tablet
          paddingH = width * 0.12;
          paddingV = height * 0.04;
          fontSizeTitle = width * 0.055;
          fontSizeField = width * 0.035;
          buttonHeight = height * 0.06;
          socialRadius = 24;
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
              vertical: paddingV,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing),

                  _inputField(
                    controller: fullNameController,
                    hint: 'Full Name',
                    icon: Icons.person,
                    fontSize: fontSizeField,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Full Name is required';
                      return null;
                    },
                  ),
                  _inputField(
                    controller: phoneController,
                    hint: 'Phone Number',
                    icon: Icons.phone,
                    fontSize: fontSizeField,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Phone Number is required';
                      return null;
                    },
                  ),

                  // Country Picker
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing),
                    child: TextFormField(
                      readOnly: true,
                      validator: (value) {
                        if (selectedCountry == null)
                          return 'Country is required';
                        return null;
                      },
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          onSelect: (Country country) {
                            setState(() => selectedCountry = country);
                          },
                        );
                      },
                      decoration: InputDecoration(
                        prefixIcon: selectedCountry != null
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 24,
                                  height: 16,
                                  child: CountryFlag.fromCountryCode(
                                    selectedCountry!.countryCode,
                                  ),
                                ),
                              )
                            : const Icon(Icons.flag),
                        hintText: selectedCountry?.name ?? 'Select Country',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  _inputField(
                    controller: emailController,
                    hint: 'Email',
                    icon: Icons.email,
                    fontSize: fontSizeField,
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
                  ),
                  _inputField(
                    controller: passwordController,
                    hint: 'Password',
                    icon: Icons.lock,
                    fontSize: fontSizeField,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Password is required';
                      if (value.length < 6)
                        return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),

                  _inputField(
                    controller: confirmPasswordController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    fontSize: fontSizeField,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    toggleVisibility: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Confirm your password';
                      if (value != passwordController.text)
                        return 'Passwords do not match';
                      return null;
                    },
                  ),

                  SizedBox(height: 10),

                  // Terms Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: agreeTerms,
                        onChanged: (bool? value) =>
                            setState(() => agreeTerms = value ?? false),
                        activeColor: Colors.blue.shade900,
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => agreeTerms = !agreeTerms),
                          child: Text(
                            'I agree to the (Terms & Conditions!)',
                            style: TextStyle(fontSize: fontSizeField),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  // Sign Up Button
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
                      onPressed: _submitForm,
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: fontSizeField,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: spacing * 2),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: TextStyle(fontSize: fontSizeField),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  SizedBox(height: spacing),

                  // Social Media Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _socialIcon(
                        Icons.telegram,
                        Colors.red,
                        radius: socialRadius,
                      ),
                      _socialIcon(
                        Icons.facebook,
                        Colors.blue,
                        radius: socialRadius,
                      ),
                      _socialIcon(
                        Icons.apple,
                        Colors.purple,
                        radius: socialRadius,
                      ),
                    ],
                  ),

                  SizedBox(height: spacing * 2),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: fontSizeField),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: fontSizeField,
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

  Widget _inputField({
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          hintStyle: TextStyle(fontSize: fontSize),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, {double radius = 22}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.1),
      child: IconButton(
        icon: Icon(icon, color: color, size: radius),
        onPressed: () {},
      ),
    );
  }
}
