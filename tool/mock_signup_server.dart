import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8000);
  final usersByEmail = <String, Map<String, dynamic>>{};
  final pendingOtps = <String, String>{};

  stdout.writeln('Mock API running on http://127.0.0.1:8000');
  stdout.writeln('POST /auth/signup');
  stdout.writeln('POST /auth/login');
  stdout.writeln('POST /auth/request-otp');
  stdout.writeln('POST /auth/verify-otp');
  stdout.writeln('GET  /health');

  await for (final request in server) {
    _addCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    if (request.method == 'GET' && request.uri.path == '/health') {
      _sendJson(request.response, HttpStatus.ok, {'message': 'Server is up'});
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/auth/signup') {
      await _handleSignup(request, usersByEmail, pendingOtps);
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/auth/login') {
      await _handleLogin(request, usersByEmail, pendingOtps);
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/auth/request-otp') {
      await _handleRequestOtp(request, usersByEmail, pendingOtps);
      continue;
    }

    if (request.method == 'POST' && request.uri.path == '/auth/verify-otp') {
      await _handleVerifyOtp(request, usersByEmail, pendingOtps);
      continue;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write(
      jsonEncode({
        'message': 'Route not found',
        'path': request.uri.path,
        'method': request.method,
      }),
    );
    await request.response.close();
  }
}

Future<void> _handleSignup(
  HttpRequest request,
  Map<String, Map<String, dynamic>> usersByEmail,
  Map<String, String> pendingOtps,
) async {
  try {
    final json = await _readJsonBody(request);
    if (json == null) return _badJson(request.response);

    final fullName =
        (json['name'] ?? json['full_name'] ?? '').toString().trim();
    final email = (json['email'] ?? '').toString().trim().toLowerCase();
    final password = (json['password'] ?? '').toString();
    final phone = (json['phone'] ?? json['phone_number'] ?? '').toString();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {
          'message': 'name/email/password/phone are required',
          'required': ['name', 'email', 'password', 'phone'],
        },
      );
      return;
    }

    if (!email.contains('@')) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {'message': 'Invalid email format'},
      );
      return;
    }

    if (password.length < 6) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {'message': 'Password must be at least 6 characters'},
      );
      return;
    }

    if (usersByEmail.containsKey(email)) {
      _sendJson(
        request.response,
        HttpStatus.conflict,
        {'message': 'Email already exists'},
      );
      return;
    }

    usersByEmail[email] = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'is_verified': false,
    };

    const otp = '1234';
    pendingOtps[_otpKey('signup', email)] = otp;

    _sendJson(
      request.response,
      HttpStatus.created,
      {
        'success': true,
        'message': 'Signup successful. OTP sent.',
        'user': {
          'id': usersByEmail[email]!['id'],
          'name': fullName,
          'email': email,
          'phone': phone,
        },
        'otp': otp,
        'purpose': 'signup',
      },
    );
  } catch (_) {
    _badJson(request.response);
  }
}

Future<void> _handleLogin(
  HttpRequest request,
  Map<String, Map<String, dynamic>> usersByEmail,
  Map<String, String> pendingOtps,
) async {
  try {
    final json = await _readJsonBody(request);
    if (json == null) return _badJson(request.response);

    final email = (json['email'] ?? '').toString().trim().toLowerCase();
    final password = (json['password'] ?? '').toString();

    if (email.isEmpty || password.isEmpty) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {'message': 'email and password are required'},
      );
      return;
    }

    final user = usersByEmail[email];
    if (user == null || user['password'] != password) {
      _sendJson(
        request.response,
        HttpStatus.unauthorized,
        {'message': 'Invalid email or password'},
      );
      return;
    }

    const otp = '1234';
    pendingOtps[_otpKey('signin', email)] = otp;
    _sendJson(request.response, HttpStatus.ok, {
      'success': true,
      'message': 'Login OTP sent',
      'purpose': 'signin',
      'otp': otp,
    });
  } catch (_) {
    _badJson(request.response);
  }
}

Future<void> _handleRequestOtp(
  HttpRequest request,
  Map<String, Map<String, dynamic>> usersByEmail,
  Map<String, String> pendingOtps,
) async {
  try {
    final json = await _readJsonBody(request);
    if (json == null) return _badJson(request.response);

    final email = (json['email'] ?? '').toString().trim().toLowerCase();
    final purposeRaw = (json['purpose'] ?? 'forgotPassword').toString().trim();
    final purpose = _normalizePurpose(purposeRaw);

    if (email.isEmpty) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {'message': 'email is required'},
      );
      return;
    }

    if (!usersByEmail.containsKey(email)) {
      _sendJson(
        request.response,
        HttpStatus.notFound,
        {'message': 'User not found'},
      );
      return;
    }

    const otp = '1234';
    pendingOtps[_otpKey(purpose, email)] = otp;
    _sendJson(request.response, HttpStatus.ok, {
      'success': true,
      'message': 'OTP sent',
      'purpose': purpose,
      'otp': otp,
    });
  } catch (_) {
    _badJson(request.response);
  }
}

Future<void> _handleVerifyOtp(
  HttpRequest request,
  Map<String, Map<String, dynamic>> usersByEmail,
  Map<String, String> pendingOtps,
) async {
  try {
    final json = await _readJsonBody(request);
    if (json == null) return _badJson(request.response);

    final email = (json['email'] ?? '').toString().trim().toLowerCase();
    final otp = (json['otp'] ?? '').toString().trim();
    final purposeRaw = (json['purpose'] ?? '').toString().trim();
    final purpose = _normalizePurpose(purposeRaw);

    if (email.isEmpty || otp.isEmpty || purpose.isEmpty) {
      _sendJson(
        request.response,
        HttpStatus.badRequest,
        {'message': 'email, otp, purpose are required'},
      );
      return;
    }

    final key = _otpKey(purpose, email);
    if (pendingOtps[key] != otp) {
      _sendJson(
        request.response,
        HttpStatus.unauthorized,
        {'message': 'Invalid OTP'},
      );
      return;
    }

    pendingOtps.remove(key);

    final user = usersByEmail[email];
    if (purpose == 'signup' && user != null) {
      user['is_verified'] = true;
    }

    _sendJson(request.response, HttpStatus.ok, {
      'success': true,
      'message': 'OTP verified',
      'purpose': purpose,
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': user == null
          ? null
          : {
              'id': user['id'],
              'name': user['name'],
              'email': user['email'],
              'phone': user['phone'],
              'is_verified': user['is_verified'],
            },
    });
  } catch (_) {
    _badJson(request.response);
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers.contentType = ContentType.json;
  response.headers.add('Access-Control-Allow-Origin', '*');
  response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.add(
    'Access-Control-Allow-Headers',
    'Origin, Content-Type, Accept, Authorization',
  );
}

Future<Map<String, dynamic>?> _readJsonBody(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  final decoded = jsonDecode(body);
  return decoded is Map<String, dynamic> ? decoded : null;
}

void _badJson(HttpResponse response) {
  _sendJson(response, HttpStatus.badRequest, {'message': 'Malformed request'});
}

String _otpKey(String purpose, String email) => '$purpose::$email';

String _normalizePurpose(String purposeRaw) {
  if (purposeRaw == 'forgot_password') return 'forgotPassword';
  return purposeRaw;
}

void _sendJson(HttpResponse response, int statusCode, Map<String, dynamic> json) {
  response.statusCode = statusCode;
  response.write(jsonEncode(json));
  response.close();
}
