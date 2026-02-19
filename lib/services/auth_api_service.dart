import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class SignupResult {
  final bool success;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  const SignupResult({
    required this.success,
    required this.message,
    required this.statusCode,
    this.data,
  });
}

class AuthApiResult {
  final bool success;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  const AuthApiResult({
    required this.success,
    required this.message,
    required this.statusCode,
    this.data,
  });
}

class AuthApiService {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String _signupPath = '/auth/signup';
  static const String _loginPath = '/auth/login';
  static const String _requestOtpPath = '/auth/request-otp';
  static const String _verifyOtpPath = '/auth/verify-otp';

  final String baseUrl;
  final http.Client _client;

  AuthApiService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _defaultBaseUrl).trim(),
      _client = client ?? http.Client();

  Future<AuthApiResult> signup({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? countryCode,
    String? countryPhoneCode,
  }) async {
    final uri = Uri.parse('$baseUrl$_signupPath');
    final trimmedPhone = phoneNumber.trim();
    final dialCode = countryPhoneCode?.trim();
    final fullPhone =
        (dialCode == null || dialCode.isEmpty)
            ? trimmedPhone
            : '+$dialCode$trimmedPhone';

    final payload = <String, dynamic>{
      'name': fullName.trim(),
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'phone': trimmedPhone,
      'phone_number': trimmedPhone,
      'full_phone': fullPhone,
      'country_code': countryCode,
      'country_phone_code': countryPhoneCode,
    };

    try {
      return _postJson(uri: uri, payload: payload, actionName: 'Signup');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl$_loginPath');
    final normalizedEmail = email.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'username': normalizedEmail,
      'identifier': normalizedEmail,
      'password': password,
    };

    try {
      return _postJson(uri: uri, payload: payload, actionName: 'Login');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> requestOtp({
    required String email,
    required String purpose,
  }) async {
    final uri = Uri.parse('$baseUrl$_requestOtpPath');
    final normalizedEmail = email.trim();
    final purposeAliases = _purposeAliases(purpose);
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'purpose': purposeAliases.primary,
      'otp_purpose': purposeAliases.primary,
      'type': purposeAliases.primary,
      'flow': purposeAliases.primary,
      'purpose_alt': purposeAliases.secondary,
    };

    try {
      return _postJson(uri: uri, payload: payload, actionName: 'OTP request');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final uri = Uri.parse('$baseUrl$_verifyOtpPath');
    final normalizedEmail = email.trim();
    final normalizedOtp = otp.trim();
    final purposeAliases = _purposeAliases(purpose);
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'otp': normalizedOtp,
      'code': normalizedOtp,
      'otp_code': normalizedOtp,
      'purpose': purposeAliases.primary,
      'otp_purpose': purposeAliases.primary,
      'type': purposeAliases.primary,
      'purpose_alt': purposeAliases.secondary,
    };

    try {
      return _postJson(uri: uri, payload: payload, actionName: 'OTP verify');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.trim().isEmpty) return null;
    final parsed = jsonDecode(body);
    if (parsed is Map<String, dynamic>) return parsed;
    return null;
  }

  String? _extractMessage(Map<String, dynamic>? json) {
    if (json == null) return null;
    final message = json['message'] ?? json['error'] ?? json['detail'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return null;
  }

  Future<AuthApiResult> _postJson({
    required Uri uri,
    required Map<String, dynamic> payload,
    required String actionName,
  }) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final decoded = _safeJsonDecode(response.body);
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final message =
          _extractMessage(decoded) ??
          (ok
              ? '$actionName successful.'
              : '$actionName failed with status ${response.statusCode}.');

      return AuthApiResult(
        success: ok,
        message: message,
        statusCode: response.statusCode,
        data: decoded,
      );
    } on TimeoutException {
      return AuthApiResult(
        success: false,
        message:
            'Request timeout. Check if API is reachable at ${uri.toString()}',
        statusCode: 408,
      );
    } on SocketException catch (e) {
      return AuthApiResult(
        success: false,
        message:
            'Network error (${e.message}). Verify API URL: ${uri.toString()}',
        statusCode: 503,
      );
    }
  }

  AuthApiResult _unexpectedError() {
    return const AuthApiResult(
      success: false,
      message: 'Unexpected error. Please try again.',
      statusCode: 500,
    );
  }

  ({String primary, String secondary}) _purposeAliases(String rawPurpose) {
    final value = rawPurpose.trim();
    switch (value) {
      case 'forgotPassword':
      case 'forgot_password':
        return (primary: 'forgotPassword', secondary: 'forgot_password');
      case 'signin':
      case 'sign_in':
      case 'login':
        return (primary: 'signin', secondary: 'login');
      case 'signup':
      case 'sign_up':
      case 'register':
        return (primary: 'signup', secondary: 'register');
      default:
        return (primary: value, secondary: value);
    }
  }
}
