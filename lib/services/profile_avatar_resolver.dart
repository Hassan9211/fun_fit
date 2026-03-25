import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'media_source_resolver.dart';

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

    final resolved = MediaSourceResolver.resolve(value);
    if (resolved.isEmpty) return null;

    if (_isNetworkLike(resolved) || kIsWeb) {
      return NetworkImage(resolved);
    }

    if (MediaSourceResolver.existsLocally(resolved)) {
      return FileImage(File(MediaSourceResolver.localFilePath(resolved)));
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
