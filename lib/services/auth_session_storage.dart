import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStorage {
  static const String emailKey = 'auth_email';
  static const String tokenKey = 'auth_token';
  static const String loggedInKey = 'is_logged_in';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> savePendingEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email.trim());
  }

  static Future<void> markLoggedIn({
    required String email,
    Map<String, dynamic>? responseData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email.trim());
    await prefs.setBool(loggedInKey, true);

    final token = extractToken(responseData);
    if (token != null) {
      await _secureStorage.write(key: tokenKey, value: token);
    }
  }

  static String? extractToken(Map<String, dynamic>? responseData) {
    if (responseData == null) return null;
    final directToken = _extractTokenFromMap(responseData);
    if (directToken != null) return directToken;

    const nestedContainers = <String>['data', 'result', 'payload'];
    for (final key in nestedContainers) {
      final nested = responseData[key];
      if (nested is Map<String, dynamic>) {
        final nestedToken = _extractTokenFromMap(nested);
        if (nestedToken != null) return nestedToken;
      } else if (nested is Map) {
        final nestedToken = _extractTokenFromMap(
          nested.map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );
        if (nestedToken != null) return nestedToken;
      }
    }

    return null;
  }

  static String? _extractTokenFromMap(Map<String, dynamic> source) {
    const tokenKeys = <String>[
      'token',
      'plain_text_token',
      'plainTextToken',
      'access_token',
      'accessToken',
      'jwt',
      'id_token',
    ];
    for (final key in tokenKeys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static Future<String> readEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(emailKey) ?? '').trim();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(loggedInKey) ?? false;
    if (!isLoggedIn) return false;
    final email = (prefs.getString(emailKey) ?? '').trim();
    return email.isNotEmpty;
  }

  static Future<String> readToken() async {
    return (await _secureStorage.read(key: tokenKey) ?? '').trim();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(emailKey);
    await prefs.remove(loggedInKey);
    await _secureStorage.delete(key: tokenKey);
  }
}
