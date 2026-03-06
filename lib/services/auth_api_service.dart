import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _legacyLanBaseUrl = 'http://192.168.2.125:8000';
  static const String _signupPath = '/api/signup';
  static const String _loginPath = '/api/login';
  static const String _requestForgotOtpPath = '/api/forgot-password';
  static const String _requestSigninOtpPath = '/api/login/request-otp';
  static const String _verifySignupOtpPath = '/api/signup/verify-otp';
  static const String _verifyForgotOtpPath = '/api/forgot-password/verify-otp';
  static const String _verifySigninOtpPath = '/api/login/verify-otp';
  static const String _resetPasswordPath = '/api/reset-password';
  static const String _changePasswordPath = '/auth/change-password';
  static const String _saveOnboardingPath = '/api/onboarding';

  final String baseUrl;
  final List<String> _baseUrlCandidates;
  final http.Client _client;

  AuthApiService({String? baseUrl, http.Client? client})
    : _baseUrlCandidates = _resolveBaseUrls(baseUrl ?? _configuredBaseUrl),
      baseUrl = _resolvePrimaryBaseUrl(baseUrl ?? _configuredBaseUrl),
      _client = client ?? http.Client();

  static bool get _isAndroidRuntime {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } on UnsupportedError {
      return false;
    }
  }

  static String? _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var normalized = trimmed
        .replaceFirst(RegExp(r'^http:///+'), 'http://')
        .replaceFirst(RegExp(r'^https:///+'), 'https://');

    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed == null || parsed.host.isEmpty) return null;

    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  static List<String> _resolveBaseUrls(String raw) {
    final explicitBaseUrl = _normalizeBaseUrl(raw);
    if (explicitBaseUrl != null) {
      return <String>[explicitBaseUrl];
    }

    final fallbackBaseUrl = _isAndroidRuntime
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
    final defaults = <String>[
      raw,
      _configuredBaseUrl,
      _legacyLanBaseUrl,
      fallbackBaseUrl,
      'http://127.0.0.1:8000',
      if (_isAndroidRuntime) 'http://10.0.2.2:8000',
    ];

    final result = <String>[];
    for (final entry in defaults) {
      final normalized = _normalizeBaseUrl(entry);
      if (normalized == null) continue;
      if (!result.contains(normalized)) {
        result.add(normalized);
      }
    }

    if (result.isEmpty) {
      result.add(fallbackBaseUrl);
    }

    return result;
  }

  static String _resolvePrimaryBaseUrl(String raw) {
    return _resolveBaseUrls(raw).first;
  }

  Uri _buildUri(String path, {String? baseUrlOverride}) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseUrl = baseUrlOverride ?? this.baseUrl;
    final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
    return base.resolve(normalizedPath);
  }

  Future<AuthApiResult> signup({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    String? countryName,
    String? countryCode,
    String? countryPhoneCode,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    final dialCode = countryPhoneCode?.trim();
    final fullPhone = (dialCode == null || dialCode.isEmpty)
        ? trimmedPhone
        : '+$dialCode$trimmedPhone';

    final payload = <String, dynamic>{
      'name': fullName.trim(),
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'confirm_password': confirmPassword,
      'confirmPassword': confirmPassword,
      'password_confirmation': confirmPassword,
      'phone': trimmedPhone,
      'phone_number': trimmedPhone,
      'full_phone': fullPhone,
      'country': (countryName ?? '').trim().isNotEmpty
          ? countryName!.trim()
          : countryCode,
      'country_name': countryName,
      'countryName': countryName,
      'country_code': countryCode,
      'countryCode': countryCode,
      'country_phone_code': countryPhoneCode,
      'countryPhoneCode': countryPhoneCode,
    };

    try {
      return _postJson(path: _signupPath, payload: payload, actionName: 'Signup');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'username': normalizedEmail,
      'identifier': normalizedEmail,
      'password': password,
    };

    try {
      return _postJson(path: _loginPath, payload: payload, actionName: 'Login');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> requestOtp({
    required String email,
    required String purpose,
    String? password,
  }) async {
    final purposeAliases = _purposeAliases(purpose);
    final requestPath = switch (purposeAliases.primary) {
      'signin' => _requestSigninOtpPath,
      _ => _requestForgotOtpPath,
    };
    final normalizedEmail = email.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      if (purposeAliases.primary == 'signin') ...{
        'username': normalizedEmail,
        'identifier': normalizedEmail,
        if (password != null && password.trim().isNotEmpty)
          'password': password,
      } else ...{
        'purpose': purposeAliases.primary,
        'otp_purpose': purposeAliases.primary,
        'type': purposeAliases.primary,
        'flow': purposeAliases.primary,
        'purpose_alt': purposeAliases.secondary,
      },
    };

    try {
      return _postJson(
        path: requestPath,
        payload: payload,
        actionName: 'OTP request',
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final purposeAliases = _purposeAliases(purpose);
    final verifyPath = switch (purposeAliases.primary) {
      'signup' => _verifySignupOtpPath,
      'forgotPassword' => _verifyForgotOtpPath,
      'signin' => _verifySigninOtpPath,
      _ => _verifyForgotOtpPath,
    };
    final normalizedEmail = email.trim();
    final normalizedOtp = otp.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'otp': normalizedOtp,
      'code': normalizedOtp,
      'otp_code': normalizedOtp,
    };
    if (purposeAliases.primary != 'signin') {
      payload['purpose'] = purposeAliases.primary;
      payload['otp_purpose'] = purposeAliases.primary;
      payload['type'] = purposeAliases.primary;
      payload['purpose_alt'] = purposeAliases.secondary;
    }

    try {
      return _postJson(path: verifyPath, payload: payload, actionName: 'OTP verify');
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    String? bearerToken,
  }) async {
    final normalizedEmail = email.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'current_password': currentPassword,
      'currentPassword': currentPassword,
      'old_password': currentPassword,
      'new_password': newPassword,
      'newPassword': newPassword,
      'password': newPassword,
      'confirm_password': confirmPassword,
      'confirmPassword': confirmPassword,
      'password_confirmation': confirmPassword,
    };

    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      return _postJson(
        path: _changePasswordPath,
        payload: payload,
        actionName: 'Change password',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
    Map<String, dynamic>? verificationData,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedOtp = otp.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'otp': normalizedOtp,
      'code': normalizedOtp,
      'otp_code': normalizedOtp,
      'new_password': newPassword,
      'newPassword': newPassword,
      'password': newPassword,
      'confirm_password': confirmPassword,
      'confirmPassword': confirmPassword,
      'password_confirmation': confirmPassword,
    };

    final resetToken = _extractValueByKeys(
      source: verificationData,
      keys: const <String>[
        'reset_token',
        'resetToken',
        'token',
        'verification_token',
        'verificationToken',
      ],
    );
    if (resetToken != null) {
      payload['reset_token'] = resetToken;
      payload['resetToken'] = resetToken;
      payload['token'] = resetToken;
    }

    try {
      return _postJson(
        path: _resetPasswordPath,
        payload: payload,
        actionName: 'Reset password',
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> saveOnboardingProfile({
    required Map<String, dynamic> onboardingData,
    String? email,
    String? bearerToken,
  }) async {
    final heightCm = onboardingData['heightCm'];
    final weightKg = onboardingData['weightKg'];
    final heightUnit = onboardingData['heightUnit'];
    final weightUnit = onboardingData['weightUnit'];

    final payload = <String, dynamic>{
      ...onboardingData,
      if (onboardingData['fitnessLevel'] != null)
        'fitness_level': onboardingData['fitnessLevel'],
      if (onboardingData['birthYear'] != null)
        'birth_year': onboardingData['birthYear'],
      if (heightCm != null) ...{
        'height_cm': heightCm,
        'height': heightCm,
      },
      if (weightKg != null) ...{
        'weight_kg': weightKg,
        'weight': weightKg,
      },
      if (heightUnit != null) ...{
        'height_unit': heightUnit,
        'heightUnit': heightUnit,
      },
      if (weightUnit != null) ...{
        'weight_unit': weightUnit,
        'weightUnit': weightUnit,
      },
    };

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      payload['email'] = normalizedEmail;
    }

    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      return _postJson(
        path: _saveOnboardingPath,
        payload: payload,
        actionName: 'Onboarding save',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Map<String, dynamic>? _safeJsonDecode(String body) {
    final normalized = body.trim();
    if (normalized.isEmpty) return null;
    try {
      final parsed = jsonDecode(normalized);
      if (parsed is Map<String, dynamic>) return parsed;
    } on FormatException {
      return null;
    }
    return null;
  }

  String? _extractMessage(Map<String, dynamic>? json) {
    if (json == null) return null;
    final message = json['message'] ?? json['error'] ?? json['detail'];
    final normalizedMessage =
        message is String && message.trim().isNotEmpty ? message.trim() : null;

    final errors = json['errors'];
    final validationMessage = _extractValidationMessage(errors);
    if (validationMessage != null) {
      if (normalizedMessage != null &&
          normalizedMessage.toLowerCase() != 'the given data was invalid.') {
        return '$normalizedMessage $validationMessage';
      }
      return validationMessage;
    }

    if (normalizedMessage != null) return normalizedMessage;
    return null;
  }

  String? _extractValidationMessage(dynamic rawErrors) {
    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) return first.trim();
        }
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    if (rawErrors is List && rawErrors.isNotEmpty) {
      final first = rawErrors.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
    return null;
  }

  String? _extractValueByKeys({
    required Map<String, dynamic>? source,
    required List<String> keys,
  }) {
    if (source == null) return null;
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<AuthApiResult> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required String actionName,
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final attemptedUris = <Uri>[];
    Object? lastNetworkError;

    for (final candidateBaseUrl in _baseUrlCandidates) {
      final uri = _buildUri(path, baseUrlOverride: candidateBaseUrl);
      attemptedUris.add(uri);
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }..addAll(extraHeaders);

        final response = await _client
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 12));

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
      } on TimeoutException catch (e) {
        lastNetworkError = e;
        continue;
      } on SocketException catch (e) {
        lastNetworkError = e;
        continue;
      } on http.ClientException catch (e) {
        lastNetworkError = e;
        continue;
      } catch (e) {
        lastNetworkError = e;
        continue;
      }
    }

    final attempted = attemptedUris.map((e) => e.toString()).join(', ');
    if (lastNetworkError is TimeoutException) {
      return AuthApiResult(
        success: false,
        message:
            'Request timeout. Tried API URLs: $attempted. '
            'If you are on a real Android phone, keep backend on 0.0.0.0 and use PC LAN IP.',
        statusCode: 408,
      );
    }
    if (lastNetworkError is SocketException) {
      return AuthApiResult(
        success: false,
        message:
            'Network error. Tried API URLs: $attempted. '
            'Verify backend is running and reachable from this device.',
        statusCode: 503,
      );
    }
    if (lastNetworkError is http.ClientException) {
      return AuthApiResult(
        success: false,
        message:
            'Browser blocked request or API unreachable. '
            'Tried API URL: $attempted. If running Flutter Web, enable CORS on backend.',
        statusCode: 0,
      );
    }
    return _unexpectedError();
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
