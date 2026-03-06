import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ProfileAvatarResolver {
  ProfileAvatarResolver._();

  static ImageProvider resolve(
    String? path, {
    required ImageProvider fallback,
  }) {
    return resolveNullable(path) ?? fallback;
  }

  static ImageProvider? resolveNullable(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;

    if (_isNetworkLike(value) || kIsWeb) {
      return NetworkImage(value);
    }

    if (File(value).existsSync()) {
      return FileImage(File(value));
    }

    return null;
  }

  static bool _isNetworkLike(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:') ||
        value.startsWith('data:');
  }
}
