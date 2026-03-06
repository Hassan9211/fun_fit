// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/password_strength_checklist.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool obscurePassword = true;
  bool _isSubmitting = false;
  late final FocusNode _passwordFocusNode;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthApiService _authApi = AuthApiService();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode()..addListener(_onPasswordFocusChanged);
  }

  void _onPasswordFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_onPasswordFocusChanged);
    _passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final email = emailController.text.trim();
    final password = passwordController.text;
    final result = await _authApi.login(email: email, password: password);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await AuthSessionStorage.markLoggedIn(
      email: email,
      responseData: result.data,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Get.offAllNamed(Routes.home);
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Sign in',
              style: TextStyle(
                color: AppColors.textTitleFor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
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
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
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

                  /// Password
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: TextFormField(
                      controller: passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: obscurePassword,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return 'Password is required';
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: AppColors.textSecondaryFor(context),
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: AppColors.textMutedFor(context),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceMuted(context),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
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
                  if (_passwordFocusNode.hasFocus)
                    PasswordStrengthChecklist(
                      password: passwordController.text,
                      title: 'Password format suggestion',
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
                        activeColor: Colors.black,
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.forgotPassword),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.textTitleFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.03),

                  /// Continue
                  AppButton(
                    label: _isSubmitting ? 'Please wait...' : 'Continue',
                    onPressed: _isSubmitting ? null : _login,
                    width: double.infinity,
                    height: buttonHeight,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: 8,
                    fontSize: fontField,
                    fontWeight: FontWeight.bold,
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
                        color: const Color(0xFF0EA5E9),
                        onTap: () {},
                        context: context,
                      ),
                      const SizedBox(width: 20),

                      _socialButton(
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        onTap: () {},
                        context: context,
                      ),
                      const SizedBox(width: 20),

                      _socialButton(
                        icon: Icons.apple,
                        color: AppColors.textPrimaryFor(context),
                        onTap: () {},
                        context: context,
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.04),

                  /// Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.signup),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.textTitleFor(context),
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
    BuildContext? context,
  }) {
    final ctx = context;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ctx == null ? Colors.white : AppColors.surface(ctx),
          border: Border.all(
            color: ctx == null
                ? const Color(0xFFE5E7EB)
                : AppColors.borderLightFor(ctx),
          ),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
