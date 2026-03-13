import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
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
    defaultValue: 'http://192.168.2.114:8000/api',
  );
  static const String _legacyLanBaseUrl = 'http://192.168.2.114:8000/api';
  static const String _signupPath = '/register';
  static const String _loginPath = '/login';
  static const String _requestOtpPath = '/send_otp';
  static const String _verifyOtpPath = '/validate_otp';
  static const String _updatePasswordPath = '/update_password';
  static const String _resetPasswordPath = '/reset_password';
  static const String _updateProfilePath = '/update_profile';
  static const String _updateFitnessLevelPath = '/update_fitness_level';
  static const String _userProfilePath = '/user_profile';
  static const String _updatePreferencesPath = '/update_preferences';
  static const String _notificationsPath = '/notifications';
  static const String _foodLogCreatePath = '/create_food_log';
  static const String _foodLogMyPath = '/my_food_logs';
  static const String _foodLogAllPath = '/all_food_logs';
  static const String _allChallengesPath = '/all_challenges';
  static const String _commentFoodLogPath = '/comment_food_log';
  static const String _likeFoodLogPath = '/like_food_log';
  static const String _likeFoodLogCommentPath = '/like_food_log_comment';
  static const String _deleteFoodLogPath = '/delete_food_log';
  static const String _addRecipePath = '/add_recipe';
  static const String _getRecipesPath = '/get_recipes';
  static const String _updateProfileImgPath = '/update_profile_img';
  static const String _followPath = '/follow';
  static const String _updateFcmPath = '/update_fcm';
  static const String _createSubscriptionPath = '/create_subscription';
  static const String _updateSubscriptionPath = '/update_subscription';
  static const String _tokenLoginPath = '/token_login';
  static const String _leaderboardPath = '/leaderboard';
  static const String _guidesPath = '/guides';
  static const String _guidePath = '/guide';
  static const String _guideCategoriesPath = '/guide_categories';
  static const String _helpFaqsPath = '/help_faqs';
  static const String _getShortsPath = '/get_shorts';
  static const String _searchVideosPath = '/search_videos';
  static const String _createReelPath = '/create_reel';
  static const String _reelsPath = '/reels';
  static const String _myReelsPath = '/my_reels';
  static const String _likeReelPath = '/like_reel';
  static const String _commentReelPath = '/comment_reel';
  static const String _getContactsPath = '/get_contacts';
  static const String _sendMessagePath = '/send_message';
  static const String _createChallengePath = '/create_challenge';
  static const String _acceptChallengePath = '/accept_challenge';
  static const String _likeChallengePath = '/like_challenge';
  static const String _commentPath = '/comment';

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
      return _expandBaseUrlCandidates(<String>[explicitBaseUrl]);
    }

    final fallbackBaseUrl = _isAndroidRuntime
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
    final defaults = <String>[
      raw,
      _configuredBaseUrl,
      fallbackBaseUrl,
      'http://127.0.0.1:8000/api',
      if (_isAndroidRuntime) 'http://10.0.2.2:8000/api',
      _legacyLanBaseUrl,
    ];

    final result = <String>[];
    for (final entry in defaults) {
      final normalized = _normalizeBaseUrl(entry);
      if (normalized == null) continue;
      if (!result.contains(normalized)) result.add(normalized);
      final apiVariant = _withApiSuffixIfNeeded(normalized);
      if (apiVariant != normalized && !result.contains(apiVariant)) {
        result.add(apiVariant);
      }
    }

    if (result.isEmpty) {
      result.add(fallbackBaseUrl);
    }

    return result;
  }

  static List<String> _expandBaseUrlCandidates(List<String> baseUrls) {
    final expanded = <String>[];
    for (final base in baseUrls) {
      if (!expanded.contains(base)) expanded.add(base);
      final apiVariant = _withApiSuffixIfNeeded(base);
      if (apiVariant != base && !expanded.contains(apiVariant)) {
        expanded.add(apiVariant);
      }
    }
    return expanded;
  }

  static String _withApiSuffixIfNeeded(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    if (uri.path.isEmpty || uri.path == '/') {
      return baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
    }
    return baseUrl;
  }

  static String _resolvePrimaryBaseUrl(String raw) {
    return _resolveBaseUrls(raw).first;
  }

  Uri _buildUri(
    String path, {
    String? baseUrlOverride,
    Map<String, String>? queryParameters,
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final baseUrl = baseUrlOverride ?? this.baseUrl;
    final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
    final uri = base.resolve(normalizedPath);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        ...queryParameters,
      },
    );
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
      return _postJson(
        path: _signupPath,
        payload: payload,
        actionName: 'Signup',
      );
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
    final normalizedEmail = email.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'purpose': purposeAliases.primary,
      'otp_purpose': purposeAliases.primary,
      'type': purposeAliases.primary,
      'flow': purposeAliases.primary,
      'purpose_alt': purposeAliases.secondary,
      if (password != null && password.trim().isNotEmpty)
        'password': password,
    };

    try {
      return _postJson(
        path: _requestOtpPath,
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
    String? token,
  }) async {
    final purposeAliases = _purposeAliases(purpose);
    final normalizedEmail = email.trim();
    final normalizedOtp = otp.trim();
    final payload = <String, dynamic>{
      'email': normalizedEmail,
      'otp': normalizedOtp,
      'code': normalizedOtp,
      'otp_code': normalizedOtp,
    };
    payload['purpose'] = purposeAliases.primary;
    payload['otp_purpose'] = purposeAliases.primary;
    payload['type'] = purposeAliases.primary;
    payload['purpose_alt'] = purposeAliases.secondary;
    final normalizedToken = token?.trim();
    if (normalizedToken != null && normalizedToken.isNotEmpty) {
      payload['token'] = normalizedToken;
      payload['verification_token'] = normalizedToken;
      payload['verificationToken'] = normalizedToken;
      payload['otp_token'] = normalizedToken;
      payload['otpToken'] = normalizedToken;
    }

    try {
      final primaryResult = await _postJson(
        path: _verifyOtpPath,
        payload: payload,
        actionName: 'OTP verify',
      );
      if (primaryResult.success) {
        return primaryResult;
      }

      if (primaryResult.statusCode == 404 || primaryResult.statusCode == 405) {
        final fallbackPaths = <String>['/verify_otp', '/verifyOtp'];
        for (final path in fallbackPaths) {
          final fallbackResult = await _postJson(
            path: path,
            payload: payload,
            actionName: 'OTP verify',
          );
          if (fallbackResult.success) {
            return fallbackResult;
          }
        }
      }

      return primaryResult;
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
        path: _updatePasswordPath,
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
    final purposeAliases = _purposeAliases('forgotPassword');
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
      'purpose': purposeAliases.primary,
      'otp_purpose': purposeAliases.primary,
      'type': purposeAliases.primary,
      'flow': purposeAliases.primary,
      'purpose_alt': purposeAliases.secondary,
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
      final primaryResult = await _postJson(
        path: _updatePasswordPath,
        payload: payload,
        actionName: 'Reset password',
      );
      if (primaryResult.success) {
        return primaryResult;
      }

      if (primaryResult.statusCode == 404 ||
          primaryResult.statusCode == 405 ||
          (primaryResult.statusCode == 500 &&
              primaryResult.message ==
                  'Unexpected error. Please try again.')) {
        final fallbackPaths = <String>[_resetPasswordPath, '/resetPassword'];
        for (final path in fallbackPaths) {
          final fallbackResult = await _postJson(
            path: path,
            payload: payload,
            actionName: 'Reset password',
          );
          if (fallbackResult.success) {
            return fallbackResult;
          }
        }
      }

      return primaryResult;
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
      if (heightCm != null) ...{'height_cm': heightCm, 'height': heightCm},
      if (weightKg != null) ...{'weight_kg': weightKg, 'weight': weightKg},
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
      final profileResult = await _postJson(
        path: _updateProfilePath,
        payload: payload,
        actionName: 'Onboarding profile',
        extraHeaders: extraHeaders,
      );

      final fitness = onboardingData['fitnessLevel'] ??
          onboardingData['fitness_level'];
      if (fitness != null) {
        await _postJson(
          path: _updateFitnessLevelPath,
          payload: <String, dynamic>{
            'fitness_level': fitness,
            'fitnessLevel': fitness,
          },
          actionName: 'Onboarding fitness level',
          extraHeaders: extraHeaders,
        );
      }

      return profileResult;
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchHomeData({
    String? email,
    String? bearerToken,
  }) async {
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final notificationsResult = await _getJson(
        path: _notificationsPath,
        actionName: 'Notifications',
        extraHeaders: extraHeaders,
      );
      final challengesResult = await _getJson(
        path: _allChallengesPath,
        actionName: 'Challenges',
        extraHeaders: extraHeaders,
      );

      final notifications = _extractList(notificationsResult.data);
      final challenges = _extractList(challengesResult.data);

      return AuthApiResult(
        success: true,
        message: 'Home data loaded.',
        statusCode: 200,
        data: <String, dynamic>{
          ...?_entryIfNotNull('notifications', notifications),
          ...?_entryIfNotNull('challenges', challenges),
        },
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchProfileData({
    String? email,
    String? bearerToken,
  }) async {
    final normalizedEmail = email?.trim();
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    final queryParameters = <String, String>{};
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      queryParameters['email'] = normalizedEmail;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '[Profile] fetch candidates=$_baseUrlCandidates '
          'hasToken=${token != null && token.isNotEmpty} '
          'query=$queryParameters',
        );
      }

      final result = await _getJson(
        path: _userProfilePath,
        actionName: 'Profile data',
        extraHeaders: extraHeaders,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint(
          '[Profile] fetch status=${result.statusCode} '
          'success=${result.success} message=${result.message}',
        );
      }

      return result;
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> saveProfileData({
    required Map<String, dynamic> profileData,
    String? email,
    String? bearerToken,
  }) async {
    final normalizedEmail = email?.trim();
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    final payload = <String, dynamic>{
      ...profileData,
      if (normalizedEmail != null && normalizedEmail.isNotEmpty)
        'email': normalizedEmail,
    };

    try {
      if (kDebugMode) {
        debugPrint(
          '[Profile] save candidates=$_baseUrlCandidates '
          'hasToken=${token != null && token.isNotEmpty} '
          'payloadKeys=${payload.keys.toList()}',
        );
      }

      final result = await _postJson(
        path: _updateProfilePath,
        payload: payload,
        actionName: 'Profile update',
        extraHeaders: extraHeaders,
      );

      if (kDebugMode) {
        debugPrint(
          '[Profile] save status=${result.statusCode} '
          'success=${result.success} message=${result.message}',
        );
      }
      return result;
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> saveHomeData({
    required Map<String, dynamic> homeData,
    String? email,
    String? bearerToken,
  }) async {
    final normalizedEmail = email?.trim();
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final fitness = homeData['fitness_level'] ??
          homeData['fitnessLevel'] ??
          homeData['selected_category'] ??
          homeData['selectedCategory'] ??
          homeData['category'];
      if (fitness == null) {
        return const AuthApiResult(
          success: true,
          message: 'No home data to save.',
          statusCode: 200,
        );
      }

      return _postJson(
        path: _updateFitnessLevelPath,
        payload: <String, dynamic>{
          'fitness_level': fitness,
          'fitnessLevel': fitness,
          if (normalizedEmail != null && normalizedEmail.isNotEmpty)
            'email': normalizedEmail,
        },
        actionName: 'Update fitness level',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchFoodLogData({
    String? email,
    String? bearerToken,
  }) async {
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final allResult = await _getJson(
        path: _foodLogAllPath,
        actionName: 'Food log (all)',
        extraHeaders: extraHeaders,
      );
      final myResult = await _getJson(
        path: _foodLogMyPath,
        actionName: 'Food log (mine)',
        extraHeaders: extraHeaders,
      );

      final allPosts = _extractList(allResult.data);
      final myPosts = _extractList(myResult.data);

      return AuthApiResult(
        success: true,
        message: 'Food log loaded.',
        statusCode: 200,
        data: <String, dynamic>{
          ...?_entryIfNotNull('public_posts', allPosts),
          ...?_entryIfNotNull('my_posts', myPosts),
        },
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> saveFoodLogPost({
    required Map<String, dynamic> postData,
    String? email,
    String? bearerToken,
  }) async {
    final normalizedEmail = email?.trim();
    final token = bearerToken?.trim();
    final extraHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }

    final contentValue =
        (postData['content'] ??
                postData['message'] ??
                postData['text'] ??
                postData['body'])
            ?.toString()
            .trim();
    final titleValue =
        (postData['title'] ?? postData['name'])?.toString().trim();
    final descriptionValue =
        (postData['description'] ?? postData['details'])?.toString().trim();

    final payload = <String, dynamic>{
      ...postData,
      if (titleValue == null || titleValue.isEmpty)
        'title': contentValue ?? '',
      if (descriptionValue == null || descriptionValue.isEmpty)
        'description': contentValue ?? '',
      'post': postData,
      'foodlog': postData,
      if (normalizedEmail != null && normalizedEmail.isNotEmpty)
        'email': normalizedEmail,
    };

    try {
      return _postJson(
        path: _foodLogCreatePath,
        payload: payload,
        actionName: 'Food log post',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> commentFoodLog({
    required Map<String, dynamic> commentData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _commentFoodLogPath,
        payload: commentData,
        actionName: 'Food log comment',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> likeFoodLog({
    required Map<String, dynamic> likeData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _likeFoodLogPath,
        payload: likeData,
        actionName: 'Food log like',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> likeFoodLogComment({
    required Map<String, dynamic> likeData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _likeFoodLogCommentPath,
        payload: likeData,
        actionName: 'Food log comment like',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> deleteFoodLog({
    required Map<String, dynamic> deleteData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _deleteFoodLogPath,
        payload: deleteData,
        actionName: 'Food log delete',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> updateProfileImage({
    required String imagePath,
    String? bearerToken,
  }) async {
    return _postMultipart(
      path: _updateProfileImgPath,
      files: <String, String>{'image': imagePath},
      fields: const <String, String>{},
      bearerToken: bearerToken,
      actionName: 'Update profile image',
    );
  }

  Future<AuthApiResult> followUser({
    required Map<String, dynamic> followData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _followPath,
        payload: followData,
        actionName: 'Follow user',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> updateFcm({
    required Map<String, dynamic> fcmData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _updateFcmPath,
        payload: fcmData,
        actionName: 'Update FCM',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> createSubscription({
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _createSubscriptionPath,
        payload: data,
        actionName: 'Create subscription',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> updateSubscription({
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _updateSubscriptionPath,
        payload: data,
        actionName: 'Update subscription',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> tokenLogin({String? bearerToken}) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _tokenLoginPath,
        actionName: 'Token login',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> addRecipe({
    required Map<String, dynamic> recipeData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _addRecipePath,
        payload: recipeData,
        actionName: 'Add recipe',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> getRecipes({
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _getRecipesPath,
        payload: queryParameters ?? const <String, String>{},
        actionName: 'Get recipes',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchLeaderboard({
    Map<String, dynamic>? requestData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _leaderboardPath,
        payload: requestData ?? const <String, dynamic>{},
        actionName: 'Leaderboard',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchChallenges({String? bearerToken}) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _allChallengesPath,
        actionName: 'Challenges',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchGuides({
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _guidesPath,
        actionName: 'Guides',
        extraHeaders: extraHeaders,
        queryParameters: queryParameters ?? const <String, String>{},
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchGuide({
    required String guideId,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _guidePath,
        actionName: 'Guide',
        extraHeaders: extraHeaders,
        queryParameters: <String, String>{'guide_id': guideId},
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchGuideCategories({String? bearerToken}) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _guideCategoriesPath,
        actionName: 'Guide categories',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchHelpFaqs({String? lang}) async {
    final query = <String, String>{};
    if (lang != null && lang.trim().isNotEmpty) {
      query['lang'] = lang.trim();
    }
    try {
      return _getJson(
        path: _helpFaqsPath,
        actionName: 'Help FAQs',
        queryParameters: query,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> updatePreferences({
    String? languageCode,
    String? themeMode,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    final payload = <String, dynamic>{
      if (languageCode != null && languageCode.trim().isNotEmpty)
        'language': languageCode.trim(),
      if (themeMode != null && themeMode.trim().isNotEmpty)
        'theme': themeMode.trim(),
      if (languageCode != null && languageCode.trim().isNotEmpty)
        'language_code': languageCode.trim(),
      if (themeMode != null && themeMode.trim().isNotEmpty)
        'theme_mode': themeMode.trim(),
    };
    try {
      return _postJson(
        path: _updatePreferencesPath,
        payload: payload,
        actionName: 'Update preferences',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchReels({
    Map<String, String>? queryParameters,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _reelsPath,
        actionName: 'Reels',
        extraHeaders: extraHeaders,
        queryParameters: queryParameters ?? const <String, String>{},
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchMyReels({String? bearerToken}) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _myReelsPath,
        actionName: 'My reels',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> createReel({
    required String videoPath,
    String? thumbnailPath,
    String? caption,
    String? privacy,
    String? bearerToken,
  }) async {
    return _postMultipart(
      path: _createReelPath,
      files: <String, String>{
        'video': videoPath,
        if (thumbnailPath != null && thumbnailPath.trim().isNotEmpty)
          'thumbnail': thumbnailPath,
      },
      fields: <String, String>{
        if (caption != null && caption.trim().isNotEmpty)
          'caption': caption.trim(),
        if (privacy != null && privacy.trim().isNotEmpty)
          'privacy': privacy.trim(),
      },
      bearerToken: bearerToken,
      actionName: 'Create reel',
    );
  }

  Future<AuthApiResult> likeReel({
    required Map<String, dynamic> likeData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _likeReelPath,
        payload: likeData,
        actionName: 'Like reel',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> commentReel({
    required Map<String, dynamic> commentData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _commentReelPath,
        payload: commentData,
        actionName: 'Comment reel',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchContacts({String? bearerToken}) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _getJson(
        path: _getContactsPath,
        actionName: 'Contacts',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> sendMessage({
    required Map<String, dynamic> messageData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _sendMessagePath,
        payload: messageData,
        actionName: 'Send message',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> createChallenge({
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _createChallengePath,
        payload: data,
        actionName: 'Create challenge',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> acceptChallenge({
    required Map<String, dynamic> data,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _acceptChallengePath,
        payload: data,
        actionName: 'Accept challenge',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> likeChallenge({
    required Map<String, dynamic> likeData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _likeChallengePath,
        payload: likeData,
        actionName: 'Like challenge',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> commentOnChallenge({
    required Map<String, dynamic> commentData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _commentPath,
        payload: commentData,
        actionName: 'Challenge comment',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> fetchShorts({
    Map<String, dynamic>? requestData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _getShortsPath,
        payload: requestData ?? const <String, dynamic>{},
        actionName: 'Shorts',
        extraHeaders: extraHeaders,
      );
    } catch (_) {
      return _unexpectedError();
    }
  }

  Future<AuthApiResult> searchVideos({
    required Map<String, dynamic> requestData,
    String? bearerToken,
  }) async {
    final extraHeaders = <String, String>{};
    final token = bearerToken?.trim();
    if (token != null && token.isNotEmpty) {
      extraHeaders['Authorization'] = 'Bearer $token';
    }
    try {
      return _postJson(
        path: _searchVideosPath,
        payload: requestData,
        actionName: 'Search videos',
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
    final normalizedMessage = message is String && message.trim().isNotEmpty
        ? message.trim()
        : null;

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

  List<dynamic>? _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final key in const <String>['data', 'items', 'results', 'list']) {
        final nested = value[key];
        if (nested is List) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _entryIfNotNull(String key, dynamic value) {
    if (value == null) return null;
    return <String, dynamic>{key: value};
  }

  Future<AuthApiResult> _postMultipart({
    required String path,
    required Map<String, String> files,
    required Map<String, String> fields,
    required String actionName,
    String? bearerToken,
  }) async {
    final attemptedUris = <Uri>[];
    Object? lastNetworkError;

    for (final candidateBaseUrl in _baseUrlCandidates) {
      final uri = _buildUri(path, baseUrlOverride: candidateBaseUrl);
      attemptedUris.add(uri);
      try {
        final request = http.MultipartRequest('POST', uri);
        if (bearerToken != null && bearerToken.trim().isNotEmpty) {
          request.headers['Authorization'] = 'Bearer ${bearerToken.trim()}';
        }
        request.fields.addAll(fields);
        for (final entry in files.entries) {
          final file = File(entry.value);
          if (!file.existsSync()) continue;
          request.files.add(await http.MultipartFile.fromPath(entry.key, file.path));
        }

        final streamed = await request.send().timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamed);
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
            'Verify backend is running and reachable.',
        statusCode: 408,
      );
    }
    if (lastNetworkError is SocketException) {
      return AuthApiResult(
        success: false,
        message:
            'Network error. Tried API URLs: $attempted. '
            'Verify backend is running and reachable.',
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

  String _clipForLog(String value, [int max = 800]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}...';
  }

  Future<AuthApiResult> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required String actionName,
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final attemptedUris = <Uri>[];
    Object? lastNetworkError;

    int? lastStatusCode;
    String? lastMessage;
    Map<String, dynamic>? lastData;

    for (final candidateBaseUrl in _baseUrlCandidates) {
      final uri = _buildUri(path, baseUrlOverride: candidateBaseUrl);
      attemptedUris.add(uri);
      try {
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }..addAll(extraHeaders);

        String? encodedPayload;
        try {
          encodedPayload = jsonEncode(payload);
        } on JsonUnsupportedObjectError catch (e) {
          if (actionName == 'Food log post') {
            debugPrint(
              '[API] $actionName payload encoding failed: $e '
              'keys=${payload.keys.toList()}',
            );
          }
          return const AuthApiResult(
            success: false,
            message: 'Invalid data in request. Please try again.',
            statusCode: 400,
          );
        }

        if (actionName == 'Food log post') {
          debugPrint(
            '[API] $actionName POST $uri payloadKeys=${payload.keys.toList()}',
          );
        }

        final response = await _client
            .post(uri, headers: headers, body: encodedPayload)
            .timeout(const Duration(seconds: 12));

        if (actionName == 'Food log post') {
          debugPrint(
            '[API] $actionName status=${response.statusCode} '
            'body=${_clipForLog(response.body)}',
          );
        }

        final decoded = _safeJsonDecode(response.body);
        final ok = response.statusCode >= 200 && response.statusCode < 300;
        final message =
            _extractMessage(decoded) ??
            (ok
                ? '$actionName successful.'
                : '$actionName failed with status ${response.statusCode}.');

        if (response.statusCode == 404) {
          // Try next base URL candidate if the route is missing here.
          lastStatusCode = response.statusCode;
          lastMessage = message;
          lastData = decoded;
          continue;
        }

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
    if (lastStatusCode == 404) {
      return AuthApiResult(
        success: false,
        message:
            lastMessage ??
            'Endpoint not found. Tried API URLs: $attempted.',
        statusCode: lastStatusCode ?? 404,
        data: lastData,
      );
    }
    return _unexpectedError();
  }


  Future<AuthApiResult> _getJson({
    required String path,
    required String actionName,
    Map<String, String> extraHeaders = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
  }) async {
    final attemptedUris = <Uri>[];
    Object? lastNetworkError;

    for (final candidateBaseUrl in _baseUrlCandidates) {
      final uri = _buildUri(
        path,
        baseUrlOverride: candidateBaseUrl,
        queryParameters: queryParameters,
      );
      attemptedUris.add(uri);
      try {
        final headers = <String, String>{'Accept': 'application/json'}
          ..addAll(extraHeaders);

        final response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 12));

        final decoded = _safeJsonDecode(response.body);
        final ok = response.statusCode >= 200 && response.statusCode < 300;
        final message =
            _extractMessage(decoded) ??
            (ok
                ? '$actionName loaded.'
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
