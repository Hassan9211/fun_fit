// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/password_strength_checklist.dart';
import '../widget/responsive_layout.dart';

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
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final rememberedEmail = await AuthSessionStorage.readRememberedEmail();
    if (!mounted || rememberedEmail.isEmpty) return;
    setState(() {
      rememberMe = true;
      emailController.text = rememberedEmail;
    });
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
      persistSession: rememberMe,
    );
    if (rememberMe) {
      await AuthSessionStorage.saveRememberedEmail(email);
    } else {
      await AuthSessionStorage.clearRememberedEmail();
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final titleSize = info.value(mobile: 28, tablet: 32, desktop: 36);
        final buttonFontSize = info.value(mobile: 15, tablet: 16, desktop: 16);
        final buttonHeight = info.value(mobile: 50, tablet: 52, desktop: 54);
        final sectionGap = info.value(mobile: 20, tablet: 24, desktop: 28);

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
          body: SafeArea(
            child: SingleChildScrollView(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 440,
                tabletMaxWidth: 500,
                desktopMaxWidth: 560,
                padding: info.pagePadding(
                  mobileHorizontal: 16,
                  tabletHorizontal: 24,
                  desktopHorizontal: 32,
                  mobileVertical: 20,
                  tabletVertical: 28,
                  desktopVertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: obscurePassword,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
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
                      if (_passwordFocusNode.hasFocus) ...[
                        const SizedBox(height: 12),
                        PasswordStrengthChecklist(
                          password: passwordController.text,
                          title: 'Password format suggestion',
                        ),
                      ],
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, rowConstraints) {
                          final useVerticalLayout = rowConstraints.maxWidth < 360;
                          final rememberRow = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                                activeColor: Colors.black,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                              const Text('Remember me'),
                            ],
                          );
                          final forgotAction = GestureDetector(
                            onTap: () => Get.toNamed(Routes.forgotPassword),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.textTitleFor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );

                          if (useVerticalLayout) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                rememberRow,
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: forgotAction,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: rememberRow),
                              forgotAction,
                            ],
                          );
                        },
                      ),
                      SizedBox(
                        height: info.value(mobile: 18, tablet: 22, desktop: 24),
                      ),
                      AppButton(
                        label: _isSubmitting ? 'Please wait...' : 'Continue',
                        onPressed: _isSubmitting ? null : _login,
                        width: double.infinity,
                        height: buttonHeight,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: 8,
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: sectionGap),
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
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          runSpacing: 12,
                          children: [
                            _socialButton(
                              icon: Icons.telegram,
                              color: AppColors.cFF0EA5E9,
                              onTap: () {},
                              context: context,
                            ),
                            _socialButton(
                              icon: Icons.facebook,
                              color: AppColors.cFF1877F2,
                              onTap: () {},
                              context: context,
                            ),
                            _socialButton(
                              icon: Icons.apple,
                              color: AppColors.textPrimaryFor(context),
                              onTap: () {},
                              context: context,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runSpacing: 4,
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
                ? AppColors.cFFE5E7EB
                : AppColors.borderLightFor(ctx),
          ),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
