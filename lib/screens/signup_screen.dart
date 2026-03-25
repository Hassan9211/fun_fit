// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_local_variable

import 'package:country_picker/country_picker.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/password_strength_checklist.dart';
import '../widget/responsive_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  Country? selectedCountry;
  bool agreeTerms = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApi = AuthApiService();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode()..addListener(_onFieldFocusChanged);
    _confirmPasswordFocusNode = FocusNode()..addListener(_onFieldFocusChanged);
  }

  void _onFieldFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_onFieldFocusChanged);
    _confirmPasswordFocusNode.removeListener(_onFieldFocusChanged);
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
    if (selectedCountry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select country')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final email = emailController.text.trim();
    final password = passwordController.text;
    var authToken = '';

    try {
      final result = await _authApi.signup(
        fullName: fullNameController.text.trim(),
        email: email,
        password: password,
        confirmPassword: confirmPasswordController.text,
        phoneNumber: phoneController.text.trim(),
        countryName: selectedCountry!.name,
        countryCode: selectedCountry!.countryCode,
        countryPhoneCode: selectedCountry!.phoneCode,
      );
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      authToken = AuthSessionStorage.extractToken(result.data) ?? '';
      await AuthSessionStorage.savePendingEmail(email);
      await AuthSessionStorage.markLoggedIn(email: email, responseData: result.data);
      if (authToken.isEmpty) {
        authToken = await AuthSessionStorage.readToken();
      }

      if (authToken.isEmpty) {
        final loginResult = await _authApi.login(email: email, password: password);
        if (loginResult.success) {
          authToken = AuthSessionStorage.extractToken(loginResult.data) ?? '';
          await AuthSessionStorage.markLoggedIn(
            email: email,
            responseData: loginResult.data,
          );
          if (authToken.isEmpty) {
            authToken = await AuthSessionStorage.readToken();
          }
        }
      }

      if (!mounted) return;
      Get.offAllNamed(
        Routes.ready,
        arguments: <String, dynamic>{
          'email': email,
          if (authToken.isNotEmpty) 'authToken': authToken,
        },
      );
    } catch (e, s) {
      debugPrint('Signup exception: $e');
      debugPrintStack(stackTrace: s);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup exception: $e')));
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _loginStyleDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    String? prefixText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    final borderColor = AppColors.borderLightFor(context);
    final hintColor = AppColors.textMutedFor(context);
    final iconColor = AppColors.textSecondaryFor(context);
    final focusColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.7);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: prefixIcon ?? Icon(icon, color: iconColor),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      filled: true,
      fillColor: AppColors.surfaceMuted(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focusColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final titleSize = info.value(mobile: 28, tablet: 32, desktop: 36);
        final fieldFontSize = info.value(mobile: 15, tablet: 16, desktop: 16);
        final spacing = info.value(mobile: 18, tablet: 22, desktop: 26);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Sign up',
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
                mobileMaxWidth: 460,
                tabletMaxWidth: 520,
                desktopMaxWidth: 580,
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
                    children: [
                      Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),
                      _textFormField(
                        controller: fullNameController,
                        hint: 'Full Name',
                        icon: Icons.person,
                        fontSize: fieldFontSize,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Full name required'
                            : null,
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
                              onSelect: (c) =>
                                  setState(() => selectedCountry = c),
                            );
                          },
                          decoration: _loginStyleDecoration(
                            context,
                            hint: selectedCountry?.name ?? 'Select Country',
                            icon: Icons.flag,
                            prefixIcon: selectedCountry != null
                                ? Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: CountryFlag.fromCountryCode(
                                      selectedCountry!.countryCode,
                                    ),
                                  )
                                : const Icon(Icons.flag),
                          ),
                        ),
                      ),
                      _textFormField(
                        controller: phoneController,
                        hint: 'Phone Number',
                        icon: Icons.phone,
                        fontSize: fieldFontSize,
                        keyboardType: TextInputType.phone,
                        prefixText: selectedCountry != null
                            ? '+${selectedCountry!.phoneCode} '
                            : null,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Phone required'
                            : null,
                      ),
                      _textFormField(
                        controller: emailController,
                        hint: 'Email',
                        icon: Icons.email,
                        fontSize: fieldFontSize,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                          ).hasMatch(v)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      _textFormField(
                        controller: passwordController,
                        focusNode: _passwordFocusNode,
                        hint: 'Password',
                        icon: Icons.lock,
                        fontSize: fieldFontSize,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        toggleVisibility: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        validator: (v) => PasswordPolicy.validateStrong(v),
                      ),
                      if (_passwordFocusNode.hasFocus) ...[
                        const SizedBox(height: 12),
                        PasswordStrengthChecklist(
                          password: passwordController.text,
                        ),
                      ],
                      _textFormField(
                        controller: confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline,
                        fontSize: fieldFontSize,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) => setState(() {}),
                        toggleVisibility: () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                        validator: (v) {
                          final strongCheck = PasswordPolicy.validateStrong(v);
                          if (strongCheck != null) return strongCheck;
                          if (v != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      if (_confirmPasswordFocusNode.hasFocus) ...[
                        const SizedBox(height: 12),
                        PasswordStrengthChecklist(
                          password: confirmPasswordController.text,
                          title: 'Confirm password pattern',
                        ),
                      ],
                      Row(
                        children: [
                          Checkbox(
                            value: agreeTerms,
                            activeColor: Colors.black,
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
                        label: _isSubmitting ? 'Please wait...' : 'Sign Up',
                        onPressed: _isSubmitting ? null : _submitSignup,
                        width: double.infinity,
                        height: info.value(
                          mobile: 50,
                          tablet: 52,
                          desktop: 54,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        borderRadius: 8,
                        fontSize: fieldFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: spacing),
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
                      SizedBox(height: spacing),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runSpacing: 4,
                          children: [
                            const Text('Already have an account? '),
                            GestureDetector(
                              onTap: () => Get.toNamed(Routes.login),
                              child: Text(
                                'Login',
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

  Widget _textFormField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    double fontSize = 16,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: _loginStyleDecoration(
          context,
          hint: hint,
          icon: icon,
          prefixText: prefixText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}
