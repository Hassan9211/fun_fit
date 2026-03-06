import 'package:flutter/material.dart';
import 'package:fun_fit/services/auth_api_service.dart';
import 'package:fun_fit/services/auth_session_storage.dart';
import 'package:fun_fit/widget/app_colors.dart';
import 'package:fun_fit/widget/app_button.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:fun_fit/widget/password_strength_checklist.dart';
import 'package:get/get.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApi = AuthApiService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _isResetFlow = false;
  bool _asChangePassword = false;
  String _resetEmail = '';
  String _verifiedOtp = '';
  Map<String, dynamic>? _verificationData;
  late final FocusNode _currentPasswordFocusNode;
  late final FocusNode _newPasswordFocusNode;
  late final FocusNode _confirmPasswordFocusNode;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _isResetFlow = args['asResetFlow'] == true;
      _asChangePassword = args['asChangePassword'] == true;
      _resetEmail = (args['email'] ?? '').toString().trim();
      _verifiedOtp = (args['otp'] ?? '').toString().trim();
      final rawVerifyData = args['verifyData'];
      if (rawVerifyData is Map<String, dynamic>) {
        _verificationData = rawVerifyData;
      } else if (rawVerifyData is Map) {
        _verificationData = rawVerifyData.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }
    _currentPasswordFocusNode = FocusNode()..addListener(_onFieldFocusChanged);
    _newPasswordFocusNode = FocusNode()..addListener(_onFieldFocusChanged);
    _confirmPasswordFocusNode = FocusNode()..addListener(_onFieldFocusChanged);
  }

  void _onFieldFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _currentPasswordFocusNode.removeListener(_onFieldFocusChanged);
    _newPasswordFocusNode.removeListener(_onFieldFocusChanged);
    _confirmPasswordFocusNode.removeListener(_onFieldFocusChanged);
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMutedFor(context)),
      filled: true,
      fillColor: AppColors.surfaceMuted(context),
      prefixIcon: Icon(icon, color: AppColors.textSecondaryFor(context)),
      suffixIcon: IconButton(
        icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Future<void> _submitChangePassword() async {
    if (_isResetFlow) {
      await _submitResetPassword();
      return;
    }
    await _submitCurrentPasswordFlow();
  }

  Future<void> _submitCurrentPasswordFlow() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final email = await AuthSessionStorage.readEmail();
    if (email.isEmpty) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      return;
    }

    final token = await AuthSessionStorage.readToken();
    final result = await _authApi.changePassword(
      email: email,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await AuthSessionStorage.clear();
    if (!mounted) return;
    Get.offAllNamed(Routes.login);
  }

  Future<void> _submitResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final fallbackEmail = await AuthSessionStorage.readEmail();
    final email = _resetEmail.isNotEmpty ? _resetEmail : fallbackEmail;
    final otp = _verifiedOtp.trim();
    if (email.isEmpty || otp.isEmpty) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification expired. Please request OTP again.'),
        ),
      );
      return;
    }

    final result = await _authApi.resetPassword(
      email: email,
      otp: otp,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
      verificationData: _verificationData,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    await AuthSessionStorage.clear();
    if (!mounted) return;
    Get.offAllNamed(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double paddingH = width * 0.06;
        final pageTitle = _isResetFlow && !_asChangePassword
            ? 'Reset Password'
            : 'Change Password';
        final buttonLabel = _isResetFlow ? 'Reset Password' : 'Update Password';

        if (width >= 1200) {
          paddingH = width * 0.25;
        } else if (width >= 800) {
          paddingH = width * 0.15;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              pageTitle,
              style: TextStyle(
                color: AppColors.textTitleFor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(paddingH, 20, paddingH, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isResetFlow) ...[
                    TextFormField(
                      controller: _currentPasswordController,
                      focusNode: _currentPasswordFocusNode,
                      obscureText: _obscureCurrent,
                      onChanged: (_) => setState(() {}),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Current password required'
                          : null,
                      decoration: _fieldDecoration(
                        context: context,
                        hint: 'Current Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureCurrent,
                        onToggle: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                      ),
                    ),
                    if (_currentPasswordFocusNode.hasFocus)
                      PasswordStrengthChecklist(
                        password: _currentPasswordController.text,
                        title: 'Current password pattern',
                      ),
                    const SizedBox(height: 8),
                  ],
                  TextFormField(
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    obscureText: _obscureNew,
                    onChanged: (_) => setState(() {}),
                    validator: (value) => PasswordPolicy.validateStrong(value),
                    decoration: _fieldDecoration(
                      context: context,
                      hint: 'New Password',
                      icon: Icons.lock,
                      obscureText: _obscureNew,
                      onToggle: () {
                        setState(() => _obscureNew = !_obscureNew);
                      },
                    ),
                  ),
                  if (_newPasswordFocusNode.hasFocus)
                    PasswordStrengthChecklist(
                      password: _newPasswordController.text,
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirm,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final strongCheck = PasswordPolicy.validateStrong(value);
                      if (strongCheck != null) return strongCheck;
                      if (value != _newPasswordController.text) {
                        return 'Confirm password does not match';
                      }
                      return null;
                    },
                    decoration: _fieldDecoration(
                      context: context,
                      hint: 'Confirm Password',
                      icon: Icons.lock_reset,
                      obscureText: _obscureConfirm,
                      onToggle: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  if (_confirmPasswordFocusNode.hasFocus)
                    PasswordStrengthChecklist(
                      password: _confirmPasswordController.text,
                      title: 'Confirm password pattern',
                    ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: _isSubmitting ? 'Please wait...' : buttonLabel,
                    onPressed: _isSubmitting ? null : _submitChangePassword,
                    width: double.infinity,
                    height: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: 8,
                    fontWeight: FontWeight.bold,
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
