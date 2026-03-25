import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart';

import 'auth_api_service.dart';

class MediaSourceResolver {
  MediaSourceResolver._();

  static final AuthApiService _authApi = AuthApiService();

  static bool isNetworkLike(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed);
    final scheme = uri?.scheme.toLowerCase();
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'blob' ||
        scheme == 'data';
  }

  static bool existsLocally(String? value) {
    if (kIsWeb) return false;
    final path = localFilePath(value);
    if (path.isEmpty) return false;

    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  static String localFilePath(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.toLowerCase() == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return '';
      }
    }

    return trimmed;
  }

  static String resolve(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    if (isNetworkLike(trimmed)) return trimmed;
    if (existsLocally(trimmed)) return localFilePath(trimmed);

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.toLowerCase() == 'file') {
      return localFilePath(trimmed);
    }
    if (uri != null && uri.scheme.isNotEmpty) {
      return trimmed;
    }
    if (_looksLikeAbsoluteLocalPath(trimmed)) {
      return localFilePath(trimmed);
    }

    return _resolveAgainstApi(trimmed);
  }

  static ImageProvider? resolveImageProvider(String? value) {
    final resolved = resolve(value);
    if (resolved.isEmpty) return null;
    if (isNetworkLike(resolved) || kIsWeb) {
      return NetworkImage(resolved);
    }
    if (!existsLocally(resolved)) return null;
    return FileImage(File(localFilePath(resolved)));
  }

  static String _resolveAgainstApi(String value) {
    final baseUrl = _authApi.baseUrl.trim();
    if (baseUrl.isEmpty) return value;

    final baseUri = Uri.parse(
      baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
    );
    final segments = baseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: true);
    if (segments.isNotEmpty && segments.last.toLowerCase() == 'api') {
      segments.removeLast();
    }

    final rootUri = baseUri.replace(
      pathSegments: segments,
      query: null,
      fragment: null,
    );
    final normalized = value.startsWith('/') ? value.substring(1) : value;
    return rootUri.resolve(normalized).toString();
  }

  static bool _looksLikeAbsoluteLocalPath(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;

    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(normalized) ||
        normalized.startsWith('\\\\') ||
        normalized.contains('\\')) {
      return true;
    }

    final lower = normalized.toLowerCase();
    return lower.startsWith('/data/') ||
        lower.startsWith('/storage/emulated/') ||
        lower.startsWith('/storage/self/') ||
        lower.startsWith('/var/') ||
        lower.startsWith('/private/') ||
        lower.startsWith('/users/') ||
        lower.startsWith('/home/');
  }
}
