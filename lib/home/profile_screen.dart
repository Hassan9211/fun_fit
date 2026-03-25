import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_api_service.dart';
import '../services/media_source_resolver.dart';
import '../services/auth_session_storage.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/file_video_preview.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/record_with_audio_screen.dart';
import '../widget/app_pull_to_refresh.dart';
import '../widget/responsive_layout.dart';
import '../widget/video_playback_lifecycle.dart';

enum _ProfileVisibilityTab { publicItems, privateItems, savedItems }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _defaultName = 'Jacob West';
  static const String _defaultImageUrl =
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36';

  static const String _kProfileMedia = 'profile_media_items';
  static const String _kChallengeReels = 'challenge_reels_items';
  static const String _kProfileName = 'profile_name';
  static const String _kProfileUsername = 'profile_username';
  static const String _kProfileBio = 'profile_bio';
  static const String _kProfileSocial = 'profile_social_link';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _kProfileFavorites = 'profile_favorite_videos';
  static const String _kDeletedMedia = 'profile_deleted_media_paths';
  static const String _kReelLikes = 'profile_reel_likes';
  static const String _kReelLiked = 'profile_reel_liked_set';
  static const String _kReelComments = 'profile_reel_comments';
  static const String _kReelShares = 'profile_reel_shares';
  static const String _kReelFollows = 'profile_reel_followed';
  static const String _kFollowers = 'profile_followers_count';

  final ImagePicker _picker = ImagePicker();
  final AuthApiService _authApi = AuthApiService();

  bool _loading = true;
  bool _isSavingProfile = false;
  String _name = '';
  String _username = '';
  String _bio = '';
  String _socialLink = '';
  String _profileImagePath = '';
  int _followers = 0;
  List<_ProfileMediaItem> _media = <_ProfileMediaItem>[];
  List<_ProfileMediaItem> _challengeReels = <_ProfileMediaItem>[];
  _ProfileVisibilityTab _selectedVisibilityTab =
      _ProfileVisibilityTab.publicItems;
  final Set<String> _followedCreators = <String>{};
  final Set<String> _likedReels = <String>{};
  final Set<String> _savedReels = <String>{};
  final Set<String> _deletedMediaPaths = <String>{};
  final Map<String, int> _reelLikeCounts = <String, int>{};
  final Map<String, List<String>> _reelComments = <String, List<String>>{};
  final Map<String, int> _reelShareCounts = <String, int>{};
  Timer? _reelLikeRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _reelLikeRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _name = prefs.getString(_kProfileName) ?? '';
        _username = prefs.getString(_kProfileUsername) ?? '';
        _bio = prefs.getString(_kProfileBio) ?? '';
        _socialLink = prefs.getString(_kProfileSocial) ?? '';
        _profileImagePath = prefs.getString(_kProfileImagePath) ?? '';
        _savedReels
          ..clear()
          ..addAll(prefs.getStringList(_kProfileFavorites) ?? const <String>[]);
        _deletedMediaPaths
          ..clear()
          ..addAll(prefs.getStringList(_kDeletedMedia) ?? const <String>[]);
        _followedCreators
          ..clear()
          ..addAll(prefs.getStringList(_kReelFollows) ?? const <String>[]);
        _loadReelState(prefs);
        final savedFollowers = prefs.getInt(_kFollowers) ?? 0;
        _followers = savedFollowers;
        if (_followedCreators.length > _followers) {
          _followers = _followedCreators.length;
        }
        _media = _readMedia(prefs.getStringList(_kProfileMedia) ?? <String>[])
            .where((item) => !_isDeletedPath(item.path))
            .toList(growable: true);
        _challengeReels = _readMedia(
          prefs.getStringList(_kChallengeReels) ?? <String>[],
        ).toList(growable: true);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }

    await _refreshProfileFromApi();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      ),
    );
  }

  void _showPermissionError(String message) => _showSnack(message);

  void _showStatusMessage(String message) => _showSnack(message);

  Future<bool> _ensureCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _ensureGalleryPermission({required bool isVideo}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final statuses = await <Permission>[
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();

    final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
    final videosGranted = statuses[Permission.videos]?.isGranted ?? false;
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

    if (isVideo) {
      return videosGranted || storageGranted || photosGranted;
    }
    return photosGranted || storageGranted;
  }

  List<_ProfileMediaItem> _readMedia(List<String> raw) {
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is! Map<String, dynamic>) return null;
            return _ProfileMediaItem.fromStorage(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<_ProfileMediaItem>()
        .toList();
  }

  Future<String> _persistCapturedFile(
    String sourcePath, {
    required bool isVideo,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) return sourcePath;
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/profile_media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final dotIndex = sourcePath.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? sourcePath.substring(dotIndex)
          : (isVideo ? '.mp4' : '.jpg');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final prefix = isVideo ? 'vid' : 'img';
      final targetPath = '${mediaDir.path}/$prefix$timestamp$extension';
      final copied = await sourceFile.copy(targetPath);
      return copied.path;
    } catch (_) {
      return sourcePath;
    }
  }

  Future<String> _persistPickedFile(
    XFile file, {
    required bool isVideo,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/profile_media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final dotIndex = file.path.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? file.path.substring(dotIndex)
          : (isVideo ? '.mp4' : '.jpg');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final prefix = isVideo ? 'vid' : 'img';
      final targetPath = '${mediaDir.path}/$prefix$timestamp$extension';

      try {
        final sourceFile = File(file.path);
        if (sourceFile.existsSync()) {
          final copied = await sourceFile.copy(targetPath);
          return copied.path;
        }
      } catch (_) {}

      final bytes = await file.readAsBytes();
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile.path;
    } catch (_) {
      return file.path;
    }
  }

  List<_ProfileMediaItem> _mergeProfileMedia({
    required List<_ProfileMediaItem> remote,
    required List<_ProfileMediaItem> local,
  }) {
    final merged = <_ProfileMediaItem>[];
    final seen = <String>{};

    for (final remoteItem in remote) {
      _ProfileMediaItem? localItem;
      for (final item in local) {
        if (_sameMediaPath(item.path, remoteItem.path)) {
          localItem = item;
          break;
        }
      }

      if (localItem != null &&
          localItem.visibility == _ProfileMediaVisibility.private) {
        merged.add(localItem);
      } else {
        merged.add(remoteItem);
      }
      seen.add(_normalizeMediaPath(remoteItem.path));
    }

    for (final localItem in local) {
      final normalized = _normalizeMediaPath(localItem.path);
      if (normalized.isEmpty || !seen.contains(normalized)) {
        merged.add(localItem);
      }
    }

    return merged;
  }

  List<_ProfileMediaItem> _mergeDistinctMedia(
    Iterable<_ProfileMediaItem> primary,
    Iterable<_ProfileMediaItem> secondary,
  ) {
    final merged = <_ProfileMediaItem>[];
    for (final item in <_ProfileMediaItem>[...primary, ...secondary]) {
      final alreadyAdded = merged.any(
        (existing) => _sameMediaPath(existing.path, item.path),
      );
      if (!alreadyAdded) {
        merged.add(item);
      }
    }
    return merged;
  }

  Future<List<_ProfileMediaItem>> _fetchMyReelsFromApi(String token) async {
    if (token.trim().isEmpty) return const <_ProfileMediaItem>[];

    final result = await _authApi.fetchMyReels(bearerToken: token);
    if (!result.success || result.data == null) {
      return const <_ProfileMediaItem>[];
    }

    final containers = _ProfileApiPayload.collectCandidateMaps(result.data!);
    final parsed = _ProfileApiPayload._extractMedia(containers);
    if (parsed != null && parsed.isNotEmpty) {
      return parsed
          .map(
            (item) => item.copyWith(
              source: item.source.isEmpty ? 'reel' : item.source,
            ),
          )
          .toList(growable: false);
    }

    final direct = _ProfileApiPayload._mediaFromApiMap(result.data!);
    if (direct == null) return const <_ProfileMediaItem>[];
    return <_ProfileMediaItem>[
      direct.copyWith(source: direct.source.isEmpty ? 'reel' : direct.source),
    ];
  }

  Widget _buildMissingMediaCard({double iconSize = 26}) {
    return ColoredBox(
      color: AppColors.cFF111111,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: iconSize,
        ),
      ),
    );
  }

  _ProfileMediaItem? _uploadedMediaFromResponse(Map<String, dynamic>? response) {
    if (response == null) return null;

    final containers = _ProfileApiPayload.collectCandidateMaps(response);
    final listItems = _ProfileApiPayload._extractMedia(containers);
    if (listItems != null && listItems.isNotEmpty) {
      return listItems.first;
    }

    return _ProfileApiPayload._mediaFromApiMap(response);
  }

  String? _uploadedProfileImageFromResponse(Map<String, dynamic>? response) {
    if (response == null) return null;

    final containers = _ProfileApiPayload.collectCandidateMaps(response);
    final imagePath = _ProfileApiPayload.firstNonEmptyString(
      containers,
      const <String>[
        'profile_image',
        'profileImage',
        'avatar',
        'avatar_url',
        'avatarUrl',
        'image',
        'image_url',
        'imageUrl',
        'photo',
      ],
    );
    if (imagePath == null || imagePath.trim().isEmpty) return null;

    final resolved = MediaSourceResolver.resolve(imagePath);
    return resolved.trim().isEmpty ? null : resolved;
  }

  _ProfileMediaItem _mergeUploadedMediaItem(
    _ProfileMediaItem original,
    _ProfileMediaItem uploaded,
  ) {
    final uploaderName = uploaded.uploaderName.trim();
    final uploaderUsername = uploaded.uploaderUsername.trim();

    return uploaded.copyWith(
      type: original.type,
      isSaved: uploaded.isSaved || original.isSaved,
      isLiked: uploaded.isLiked || original.isLiked,
      isDisliked: uploaded.isDisliked || original.isDisliked,
      uploaderName: uploaderName.isEmpty || uploaderName == 'User'
          ? original.uploaderName
          : uploaderName,
      uploaderUsername:
          uploaderUsername.isEmpty || uploaderUsername == '@user'
          ? original.uploaderUsername
          : uploaderUsername,
      caption: uploaded.caption.trim().isEmpty ? original.caption : uploaded.caption,
      visibility: original.visibility,
      source: uploaded.source.isEmpty ? original.source : uploaded.source,
    );
  }

  Future<void> _replaceMediaAfterUpload(
    _ProfileMediaItem original,
    _ProfileMediaItem uploaded,
  ) async {
    final index = _media.indexWhere(
      (entry) => _sameMediaPath(entry.path, original.path),
    );
    if (index == -1) return;

    final merged = _mergeUploadedMediaItem(original, uploaded);
    if (!mounted) return;
    setState(() {
      _media[index] = merged;
    });
    await _saveProfileLocally();
  }

  Future<void> _saveProfileLocally() async {
    final prefs = await SharedPreferences.getInstance();
    _media = _media
        .map(
          (item) => item.copyWith(
            uploaderName: _displayName,
            uploaderUsername: _displayUsername,
          ),
        )
        .toList(growable: true);
    await prefs.setString(_kProfileName, _name);
    await prefs.setString(_kProfileUsername, _username);
    await prefs.setString(_kProfileBio, _bio);
    await prefs.setString(_kProfileSocial, _socialLink);
    await prefs.setString(_kProfileImagePath, _profileImagePath);
    await prefs.setInt(_kFollowers, _followers);
    final encoded = _media.map((e) => jsonEncode(e.toStorageMap())).toList();
    await prefs.setStringList(_kProfileMedia, encoded);
    await prefs.setStringList(_kDeletedMedia, _deletedMediaPaths.toList());
    ProfileSyncService.notifyChanged();
  }

  Future<void> _refreshProfileFromApi() async {
    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    if (email.isEmpty && token.isEmpty) return;

    final result = await _authApi.fetchProfileData(
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted) return;

    final payload = result.success
        ? _ProfileApiPayload.fromResponse(result.data)
        : const _ProfileApiPayload();
    final remoteReels = await _fetchMyReelsFromApi(token);
    if (!payload.hasAnyValue && remoteReels.isEmpty) return;

    final localMediaSnapshot = List<_ProfileMediaItem>.from(_media);
    final remoteMedia = _mergeDistinctMedia(
      payload.media ?? const <_ProfileMediaItem>[],
      remoteReels,
    );

    setState(() {
      if (payload.name != null && payload.name!.trim().isNotEmpty) {
        _name = payload.name!;
      }
      if (payload.username != null && payload.username!.trim().isNotEmpty) {
        _username = payload.username!;
      }
      if (payload.bio != null) {
        _bio = payload.bio!;
      }
      if (payload.socialLink != null) {
        _socialLink = payload.socialLink!;
      }
      if (payload.profileImagePath != null &&
          payload.profileImagePath!.trim().isNotEmpty) {
        _profileImagePath = payload.profileImagePath!;
      }
      if (payload.followers != null) {
        _followers = payload.followers!;
      }
      if (remoteMedia.isNotEmpty) {
        _media = _mergeProfileMedia(
          remote: remoteMedia
              .where((item) => !_isDeletedPath(item.path))
              .toList(growable: true),
          local: localMediaSnapshot,
        ).where((item) => !_isDeletedPath(item.path)).toList(growable: true);
        for (final item in _media) {
          _reelLikeCounts[item.path] = item.likes;
          if (item.isLiked) {
            _likedReels.add(item.path);
          } else {
            _likedReels.remove(item.path);
          }
        }
      }
    });

    await _saveProfileLocally();
    await _persistReelState();
  }

  Map<String, dynamic> _serializeProfileForApi() {
    final normalizedName = _name.trim();
    final normalizedUsername = _username.trim().replaceAll('@', '');
    final normalizedBio = _bio.trim();
    final normalizedSocial = _socialLink.trim();
    final normalizedImage = _profileImagePath.trim();
    final mediaItems = _media
        .map((item) => item.toStorageMap())
        .toList(growable: false);
    final likesCount = _media.fold<int>(0, (sum, item) => sum + item.likes);

    final profile = <String, dynamic>{
      if (normalizedName.isNotEmpty) ...{
        'name': normalizedName,
        'full_name': normalizedName,
        'fullName': normalizedName,
      },
      if (normalizedUsername.isNotEmpty) ...{
        'username': normalizedUsername,
        'handle': normalizedUsername,
      },
      'bio': normalizedBio,
      'social_link': normalizedSocial,
      'socialLink': normalizedSocial,
      if (normalizedImage.isNotEmpty) ...{
        'profile_image': normalizedImage,
        'profileImage': normalizedImage,
        'avatar': normalizedImage,
        'avatar_url': normalizedImage,
        'avatarUrl': normalizedImage,
      },
      'followers': _followers,
      'followers_count': _followers,
      'followersCount': _followers,
      'posts_count': _media.length,
      'postsCount': _media.length,
      'likes_count': likesCount,
      'likesCount': likesCount,
      'media': mediaItems,
      'media_items': mediaItems,
      'profile_media': mediaItems,
    };

    return <String, dynamic>{
      ...profile,
      'profile': profile,
      'profile_data': profile,
      'profileData': profile,
      'user': profile,
    };
  }

  Future<void> _syncProfileToBackend({bool showError = false}) async {
    if (_isSavingProfile) return;

    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    if (email.isEmpty && token.isEmpty) return;

    _isSavingProfile = true;
    final result = await _authApi.saveProfileData(
      profileData: _serializeProfileForApi(),
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    _isSavingProfile = false;

    if (!mounted || result.success || !showError) return;
    _showStatusMessage(result.message);
  }

  Future<void> _saveMedia() async {
    await _saveProfileLocally();
    await _syncProfileToBackend();
  }

  Future<void> _saveChallengeReels() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _challengeReels
        .map((e) => jsonEncode(e.toStorageMap()))
        .toList(growable: false);
    await prefs.setStringList(_kChallengeReels, encoded);
  }

  Future<void> _saveProfileImagePath(String path) async {
    _profileImagePath = path;
    await _saveProfileLocally();
    await _syncProfileToBackend(showError: true);
    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      await _authApi.updateProfileImage(
        imagePath: path,
        bearerToken: token,
      );
    }
  }

  String get _displayName => _name.isEmpty ? _defaultName : _name;

  String get _displayUsername {
    final value = _username.isNotEmpty
        ? _username
        : _usernameFromName(_displayName);
    return value.startsWith('@') ? value : '@$value';
  }

  String _usernameFromName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '_');

  String _normalizeMediaPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final withoutQuery = uri.replace(query: '', fragment: '');
        if (withoutQuery.pathSegments.isNotEmpty) {
          return withoutQuery.pathSegments.last.toLowerCase();
        }
        return withoutQuery.path.toLowerCase();
      }
      if (uri.scheme == 'file') {
        return uri.toFilePath().toLowerCase();
      }
    }
    return trimmed.replaceAll('\\', '/').toLowerCase();
  }

  bool _sameMediaPath(String a, String b) {
    if (a == b) return true;
    final keyA = _normalizeMediaPath(a);
    final keyB = _normalizeMediaPath(b);
    if (keyA.isEmpty || keyB.isEmpty) return false;
    return keyA == keyB;
  }

  bool _isDeletedPath(String path) {
    if (_deletedMediaPaths.contains(path)) return true;
    final key = _normalizeMediaPath(path);
    if (key.isEmpty) return false;
    return _deletedMediaPaths.contains(key);
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await _ensureCameraPermission();
      if (!ok) {
        _showPermissionError('Camera permission is required.');
        return;
      }
    } else {
      final ok = await _ensureGalleryPermission(isVideo: false);
      if (!ok) {
        _showPermissionError('Gallery permission is required.');
        return;
      }
    }
    final file = await _picker.pickImage(source: source);
    if (!mounted) return;
    if (file == null) return;
    setState(() => _profileImagePath = file.path);
    await _saveProfileImagePath(file.path);
  }

  Future<void> _showProfileImageOptions() async {
    await _showSourceSheet(
      cameraLabel: 'Take Photo',
      galleryLabel: 'Choose From Gallery',
      onCamera: () => _pickProfileImage(ImageSource.camera),
      onGallery: () => _pickProfileImage(ImageSource.gallery),
      viewLabel: 'View Profile Photo',
      onView: _viewProfilePhoto,
    );
  }

  Future<void> _viewProfilePhoto() async {
    final path = _profileImagePath.trim();
    if (path.isEmpty) {
      _showStatusMessage('No profile photo set');
      return;
    }
    final provider = ProfileAvatarResolver.resolve(
      path,
      fallback: const NetworkImage(_defaultImageUrl),
    );
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        final info = ResponsiveInfo.fromContext(dialogContext);
        final avatarSize = info.value(
          mobile: 220,
          tablet: 280,
          desktop: 340,
        );
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    image: DecorationImage(
                      image: provider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: info.value(mobile: 46, tablet: 52, desktop: 58),
                right: info.value(mobile: 18, tablet: 24, desktop: 28),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.28),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSourceSheet({
    required String cameraLabel,
    required String galleryLabel,
    required Future<void> Function() onCamera,
    required Future<void> Function() onGallery,
    String? viewLabel,
    Future<void> Function()? onView,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (sheet) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(cameraLabel),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await onCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(galleryLabel),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await onGallery();
                  },
                ),
                if (onView != null && viewLabel != null)
                  ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(viewLabel),
                    onTap: () async {
                      Navigator.of(sheet).pop();
                      await onView();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCapturedMedia({required bool isVideo}) async {
    final nav = Navigator.of(context);
    final ok = await _ensureCameraPermission();
    if (!ok) {
      _showPermissionError('Camera permission is required.');
      return;
    }
    final file =
        isVideo ? null : await _picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    final videoPath = isVideo
        ? await nav.push<String>(
            MaterialPageRoute(builder: (_) => const RecordWithAudioScreen()),
          )
        : null;
    if (!mounted) return;
    if (!isVideo && file == null) return;
    if (isVideo && (videoPath == null || videoPath.isEmpty)) return;

    final persistedPath = isVideo
        ? await _persistCapturedFile(videoPath!, isVideo: true)
        : await _persistPickedFile(file!, isVideo: false);
    if (!mounted) return;

    final defaultVisibility =
        _selectedVisibilityTab == _ProfileVisibilityTab.privateItems
            ? _ProfileMediaVisibility.private
            : _ProfileMediaVisibility.public;
    final draft = _ProfileMediaItem(
      path: persistedPath,
      type: isVideo ? 'video' : 'image',
      likes: 0,
      dislikes: 0,
      shares: 0,
      isSaved: false,
      isLiked: false,
      isDisliked: false,
      uploaderName: _displayName,
      uploaderUsername: _displayUsername,
      visibility: defaultVisibility,
    );

    if (!mounted) return;
    final reviewed = await Navigator.of(context).push<_ProfileMediaItem>(
      MaterialPageRoute(
        builder: (_) => _CapturedMediaReviewScreen(item: draft),
      ),
    );
    if (reviewed == null || !mounted) return;

    setState(() {
      _media.insert(0, reviewed);
      _selectedVisibilityTab =
          reviewed.visibility == _ProfileMediaVisibility.private
          ? _ProfileVisibilityTab.privateItems
          : _ProfileVisibilityTab.publicItems;
    });
    await _saveMedia();
    await _uploadProfileMedia(reviewed);
  }

  Future<void> _addGalleryMedia({required bool isVideo}) async {
    final ok = await _ensureGalleryPermission(isVideo: isVideo);
    if (!ok) {
      _showPermissionError('Gallery permission is required.');
      return;
    }
    final file = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) return;

    final persistedPath = await _persistPickedFile(
      file,
      isVideo: isVideo,
    );
    if (!mounted) return;

    final defaultVisibility =
        _selectedVisibilityTab == _ProfileVisibilityTab.privateItems
            ? _ProfileMediaVisibility.private
            : _ProfileMediaVisibility.public;
    final draft = _ProfileMediaItem(
      path: persistedPath,
      type: isVideo ? 'video' : 'image',
      likes: 0,
      dislikes: 0,
      shares: 0,
      isSaved: false,
      isLiked: false,
      isDisliked: false,
      uploaderName: _displayName,
      uploaderUsername: _displayUsername,
      visibility: defaultVisibility,
    );

    final reviewed = await Navigator.of(context).push<_ProfileMediaItem>(
      MaterialPageRoute(
        builder: (_) => _CapturedMediaReviewScreen(item: draft),
      ),
    );
    if (reviewed == null || !mounted) return;

    setState(() {
      _media.insert(0, reviewed);
      _selectedVisibilityTab =
          reviewed.visibility == _ProfileMediaVisibility.private
              ? _ProfileVisibilityTab.privateItems
              : _ProfileVisibilityTab.publicItems;
    });
    await _saveMedia();
    await _uploadProfileMedia(reviewed);
  }

  Future<void> _deleteMedia(_ProfileMediaItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Do you want to delete this photo/video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    await _performDeleteMedia(item);
    if (!mounted) return;
    _showStatusMessage('Media deleted');
  }

  Future<void> _uploadProfileMedia(_ProfileMediaItem item) async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    if (item.type == 'video') {
      final result = await _authApi.createReel(
        videoPath: item.path,
        caption: item.caption.trim().isEmpty ? null : item.caption,
        privacy: item.visibility == _ProfileMediaVisibility.private
            ? 'private'
            : 'public',
        bearerToken: token,
      );
      if (!result.success) return;

      final uploaded = _uploadedMediaFromResponse(result.data);
      if (uploaded != null) {
        await _replaceMediaAfterUpload(item, uploaded.copyWith(source: 'reel'));
      }
    } else {
      final result = await _authApi.updateProfileImage(
        imagePath: item.path,
        bearerToken: token,
      );
      if (!result.success) return;

      final uploadedPath = _uploadedProfileImageFromResponse(result.data);
      if (uploadedPath != null && mounted) {
        setState(() => _profileImagePath = uploadedPath);
        await _saveProfileLocally();
      }
    }
  }

  Future<void> _showCreateMediaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (sheet) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Capture Photo'),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addCapturedMedia(isVideo: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose Photo'),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addGalleryMedia(isVideo: false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Record Video'),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addCapturedMedia(isVideo: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Choose Video'),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addGalleryMedia(isVideo: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMedia(_ProfileMediaItem item) async {
    if (item.type == 'image') {
      final provider = MediaSourceResolver.resolveImageProvider(item.path);
      if (provider == null) {
        _showStatusMessage('Media could not be loaded');
        return;
      }

      await showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image(
                  image: provider,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      _buildMissingMediaCard(iconSize: 42),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: _VisibilityBadge(visibility: item.visibility),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final updated = await Navigator.of(context).push<_ProfileMediaItem>(
      MaterialPageRoute(builder: (_) => _VideoPreviewScreen(item: item)),
    );
    if (updated == null || !mounted) return;
    final index = _media.indexWhere((e) => _sameMediaPath(e.path, item.path));
    if (index == -1) return;
    setState(() => _media[index] = updated);
    await _saveMedia();
  }

  void _toggleFollow(String username) {
    setState(() {
      if (_followedCreators.contains(username)) {
        _followedCreators.remove(username);
      } else {
        _followedCreators.add(username);
      }
      _followers = _followedCreators.length;
    });
    _persistFollows();
    _syncFollow(username);
  }

  Future<void> _syncFollow(String username) async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    await _authApi.followUser(
      followData: <String, dynamic>{
        'username': username,
        'user': username,
        'handle': username,
      },
      bearerToken: token,
    );
  }

  void _toggleReelLike(_ProfileMediaItem item) {
    final key = item.path;
    final current = _reelLikeCounts[key] ?? item.likes;
    final isCurrentlyLiked = _likedReels.contains(key);
    final nextLikes = isCurrentlyLiked ? (current - 1).clamp(0, 1 << 30) : current + 1;
    setState(() {
      if (isCurrentlyLiked) {
        _likedReels.remove(key);
      } else {
        _likedReels.add(key);
      }
      _reelLikeCounts[key] = nextLikes;
      _media = _updateReelLikesInList(_media, key, nextLikes, !isCurrentlyLiked);
      _challengeReels = _updateReelLikesInList(
        _challengeReels,
        key,
        nextLikes,
        !isCurrentlyLiked,
      );
    });
    _persistReelState();
    _syncReelLike(item);
    _scheduleReelLikeRefresh();
  }

  void _scheduleReelLikeRefresh() {
    _reelLikeRefreshTimer?.cancel();
    _reelLikeRefreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _refreshProfileFromApi();
    });
  }

  List<_ProfileMediaItem> _updateReelLikesInList(
    List<_ProfileMediaItem> items,
    String key,
    int likes,
    bool isLiked,
  ) {
    var touched = false;
    final updated = items.map((item) {
      if (item.path != key) return item;
      touched = true;
      return item.copyWith(likes: likes, isLiked: isLiked);
    }).toList(growable: false);
    return touched ? updated : items;
  }

  Future<void> _syncReelLike(_ProfileMediaItem item) async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    await _authApi.likeReel(
      likeData: <String, dynamic>{
        'reel_id': item.path,
        'id': item.path,
        'path': item.path,
      },
      bearerToken: token,
    );
  }

  Future<void> _syncReelComment(_ProfileMediaItem item, String text) async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    await _authApi.commentReel(
      commentData: <String, dynamic>{
        'reel_id': item.path,
        'id': item.path,
        'path': item.path,
        'comment': text,
        'message': text,
        'text': text,
      },
      bearerToken: token,
    );
  }

  void _toggleReelSave(_ProfileMediaItem item) {
    final key = item.path;
    setState(() {
      if (_savedReels.contains(key)) {
        _savedReels.remove(key);
      } else {
        _savedReels.add(key);
      }
    });
    _persistFavorites();
  }

  void _addReelShare(_ProfileMediaItem item) {
    final key = item.path;
    final current = _reelShareCounts[key] ?? 0;
    setState(() {
      _reelShareCounts[key] = current + 1;
    });
    _persistReelState();
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kProfileFavorites, _savedReels.toList());
  }

  Future<void> _persistFollows() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReelFollows, _followedCreators.toList());
    await prefs.setInt(_kFollowers, _followers);
  }

  void _loadReelState(SharedPreferences prefs) {
    final liked = prefs.getStringList(_kReelLiked) ?? const <String>[];
    _likedReels
      ..clear()
      ..addAll(liked);

    final likesJson = prefs.getString(_kReelLikes);
    final commentsJson = prefs.getString(_kReelComments);
    final sharesJson = prefs.getString(_kReelShares);
    _reelLikeCounts
      ..clear()
      ..addAll(_decodeIntMap(likesJson));
    _reelShareCounts
      ..clear()
      ..addAll(_decodeIntMap(sharesJson));
    _reelComments
      ..clear()
      ..addAll(_decodeStringListMap(commentsJson));
  }

  Future<void> _persistReelState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kReelLiked, _likedReels.toList());
    await prefs.setString(_kReelLikes, jsonEncode(_reelLikeCounts));
    await prefs.setString(_kReelShares, jsonEncode(_reelShareCounts));
    await prefs.setString(_kReelComments, jsonEncode(_reelComments));
  }

  Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0,
        ),
      );
    } catch (_) {
      return <String, int>{};
    }
  }

  Map<String, List<String>> _decodeStringListMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, List<String>>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, List<String>>{};
      return decoded.map((key, value) {
        final list = value is List
            ? value.map((item) => item.toString()).toList()
            : <String>[];
        return MapEntry(key.toString(), list);
      });
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  Future<void> _openReels(List<_ProfileMediaItem> reels) async {
    if (reels.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReelsScreen(
          reels: reels,
          isFollowed: (username) => _followedCreators.contains(username),
          isLiked: (path) => _likedReels.contains(path),
          isSaved: (path) => _savedReels.contains(path),
          likeCountFor: (path, fallback) => _reelLikeCounts[path] ?? fallback,
          commentCountFor: (path) => _reelComments[path]?.length ?? 0,
          commentsFor: (path) => _reelComments[path] ?? const <String>[],
          shareCountFor: (path) => _reelShareCounts[path] ?? 0,
          onToggleFollow: (username) {
            _toggleFollow(username);
          },
          onToggleLike: (item) {
            _toggleReelLike(item);
          },
          onToggleSave: (item) {
            _toggleReelSave(item);
          },
          onAddComment: (item, text) {
            setState(() {
              _reelComments.putIfAbsent(item.path, () => <String>[]);
              _reelComments[item.path]!.add(text);
            });
            _persistReelState();
            _syncReelComment(item, text);
          },
          onAddShare: (item) {
            _addReelShare(item);
          },
        ),
      ),
    );
  }

  void _showFollowersSheet() {
    final followers = _followedCreators.toList()..sort();
    showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Following',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (followers.isEmpty)
                Text(
                  'No followed users yet.',
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontSize: 13,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: followers.length,
                    separatorBuilder: (_, _) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      final username = followers[index];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.surfaceMuted(context),
                            child: Text(
                              username.isEmpty
                                  ? 'U'
                                  : username[0].toUpperCase(),
                              style: TextStyle(
                                color: AppColors.textPrimaryFor(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              username.isEmpty ? 'user' : '@$username',
                              style: TextStyle(
                                color: AppColors.textPrimaryFor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              _toggleFollow(username);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Unfollow'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaGrid(
    List<_ProfileMediaItem> items,
    int gridCount, {
    required String emptyMessage,
    bool muted = true,
    bool showPlayOverlay = true,
  }) {
    if (items.isEmpty) {
      return AppPullToRefresh(
        onRefresh: _loadProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 24, 8, 90),
          children: [
            Center(
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryFor(context),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return AppPullToRefresh(
      onRefresh: _loadProfile,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => _openMedia(item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.type == 'image')
                    Builder(
                      builder: (context) {
                        final provider =
                            MediaSourceResolver.resolveImageProvider(item.path);
                        if (provider == null) {
                          return _buildMissingMediaCard();
                        }
                        return Image(
                          image: provider,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildMissingMediaCard(),
                        );
                      },
                    )
                  else
                    FileVideoPreview(
                      path: item.path,
                      fit: BoxFit.cover,
                      playIconSize: 26,
                      muted: muted,
                      showPlayOverlay: showPlayOverlay,
                      enablePlayback: false,
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      onPressed: () => _deleteMedia(item),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: _VisibilityBadge(visibility: item.visibility),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _performDeleteMedia(_ProfileMediaItem item) async {
    final removedChallenge =
        _challengeReels.any((entry) => _sameMediaPath(entry.path, item.path));
    _challengeReels.removeWhere((entry) => _sameMediaPath(entry.path, item.path));
    final normalizedPath = _normalizeMediaPath(item.path);
    setState(() {
      _media.removeWhere((e) => _sameMediaPath(e.path, item.path));
      _savedReels.removeWhere((entry) => _sameMediaPath(entry, item.path));
      _likedReels.removeWhere((entry) => _sameMediaPath(entry, item.path));
      _reelLikeCounts.removeWhere(
        (key, _) => _sameMediaPath(key, item.path),
      );
      _reelShareCounts.removeWhere(
        (key, _) => _sameMediaPath(key, item.path),
      );
      _reelComments.removeWhere(
        (key, _) => _sameMediaPath(key, item.path),
      );
      _deletedMediaPaths.add(item.path);
      if (normalizedPath.isNotEmpty) {
        _deletedMediaPaths.add(normalizedPath);
      }
    });
    await _saveMedia();
    if (removedChallenge) {
      await _saveChallengeReels();
    }

    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      final payload = <String, dynamic>{
        'path': item.path,
        'media_path': item.path,
        'file_path': item.path,
        'media': item.path,
        'type': item.type,
        'visibility': item.visibility,
      };
      if (item.type == 'video') {
        await _authApi.deleteReel(
          deleteData: payload,
          bearerToken: token,
        );
      } else {
        await _authApi.deleteProfileMedia(
          deleteData: payload,
          bearerToken: token,
        );
      }
    }

    if (MediaSourceResolver.existsLocally(item.path)) {
      try {
        await File(MediaSourceResolver.localFilePath(item.path)).delete();
      } catch (_) {}
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _displayName);
    final usernameCtrl = TextEditingController(
      text: _username.isNotEmpty ? _username : _usernameFromName(_displayName),
    );
    final bioCtrl = TextEditingController(text: _bio);
    final socialCtrl = TextEditingController(text: _socialLink);

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileInput(controller: nameCtrl, label: 'Name'),
                const SizedBox(height: 10),
                _ProfileInput(
                  controller: usernameCtrl,
                  label: 'Username',
                  hint: 'your_username',
                ),
                const SizedBox(height: 10),
                _ProfileInput(
                  controller: bioCtrl,
                  label: 'Bio',
                  hint: 'Write something about yourself',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _ProfileInput(
                  controller: socialCtrl,
                  label: 'Social Media Link',
                  hint: 'https://instagram.com/yourprofile',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'name': nameCtrl.text.trim(),
              'username': usernameCtrl.text.trim().replaceAll('@', ''),
              'bio': bioCtrl.text.trim(),
              'social': socialCtrl.text.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _name = result['name'] ?? '';
      _username = result['username'] ?? '';
      _bio = result['bio'] ?? '';
      _socialLink = result['social'] ?? '';
    });
    await _saveProfileLocally();
    await _syncProfileToBackend(showError: true);
  }

  @override
  Widget build(BuildContext context) {
    final posts = _media.length;
    final likes = _media.fold<int>(0, (sum, item) => sum + item.likes);
    final effectiveMedia = _media
        .where((item) => item.source != 'challenge')
        .map(
          (item) => item.copyWith(
            uploaderName: _displayName,
            uploaderUsername: _displayUsername,
          ),
        )
        .toList(growable: false);
    final publicMedia = effectiveMedia
        .where((item) => item.visibility == 'public')
        .toList();
    final reels = <_ProfileMediaItem>[
      ..._challengeReels.where((item) => !_isDeletedPath(item.path)),
      ...publicMedia.where((item) => item.type == 'video'),
    ];
    final privateMedia = effectiveMedia
        .where((item) => item.visibility == 'private')
        .toList();
    final savedMedia = effectiveMedia
        .where((item) => _savedReels.contains(item.path))
        .toList();
    final ImageProvider avatar = ProfileAvatarResolver.resolve(
      _profileImagePath,
      fallback: const NetworkImage(_defaultImageUrl),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'User Profile',
          style: TextStyle(
            color: AppColors.textTitleFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final info = ResponsiveInfo.fromConstraints(constraints);
                final isDesktop = info.isDesktop;
                final isTablet = info.isTablet;
                final contentMaxWidth = isDesktop
                    ? info.maxWidth(mobile: info.width, tablet: 760, desktop: 900)
                    : (isTablet
                        ? info.maxWidth(
                            mobile: info.width,
                            tablet: 760,
                            desktop: 900,
                          )
                        : double.infinity);
                final horizontalPadding = isDesktop
                    ? info.width * 0.14
                    : (isTablet ? 28.0 : 8.0);
                final avatarRadius = info.value(
                  mobile: 42,
                  tablet: 50,
                  desktop: 56,
                );
                final nameSize = info.value(
                  mobile: 16,
                  tablet: 19,
                  desktop: 22,
                );
                final statSpacing = info.value(
                  mobile: 28,
                  tablet: 36,
                  desktop: 48,
                );
                final gridCount = isDesktop ? 5 : (isTablet ? 4 : 3);
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 70),
                            child: Column(
                              children: [
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _showProfileImageOptions,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundImage: avatar,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _editProfile,
                                  child: Text(
                                    _displayName,
                                    style: TextStyle(
                                      color: AppColors.textTitleFor(context),
                                      fontWeight: FontWeight.w700,
                                      fontSize: nameSize,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _displayUsername,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryFor(context),
                                    fontSize: isDesktop ? 14 : 12,
                                  ),
                                ),
                                if (_bio.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 52 : 24,
                                    ),
                                    child: Text(
                                      _bio,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textPrimaryFor(
                                          context,
                                        ),
                                        fontSize: isDesktop ? 13 : 12,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_socialLink.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _socialLink,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: isDesktop ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: _StatItem(
                                          label: 'Posts',
                                          value: posts.toString(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: statSpacing * 0.35),
                                    Expanded(
                                      child: Center(
                                        child: _StatItem(
                                          label: 'Followers',
                                          value: _followers.toString(),
                                          onTap: _showFollowersSheet,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: statSpacing * 0.35),
                                    Expanded(
                                      child: Center(
                                        child: _StatItem(
                                          label: 'Likes',
                                          value: likes.toString(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _editProfile,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Edit profile'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: BorderSide(
                                      color: AppColors.borderLightFor(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Divider(
                                  color: AppColors.borderLightFor(context),
                                  height: 1,
                                ),
                                const SizedBox(height: 12),
                                _VisibilityTabs(
                                  selected: _selectedVisibilityTab,
                                  onChanged: (tab) => setState(
                                    () => _selectedVisibilityTab = tab,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 38,
                                  child: OutlinedButton(
                                    onPressed: () => _openReels(reels),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimaryFor(
                                        context,
                                      ),
                                      side: BorderSide(
                                        color: AppColors.borderLightFor(
                                          context,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Reels',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: AnimatedReveal(
                              delay: const Duration(milliseconds: 140),
                              child: _buildMediaGrid(
                                _selectedVisibilityTab ==
                                        _ProfileVisibilityTab.savedItems
                                    ? savedMedia
                                    : (_selectedVisibilityTab ==
                                              _ProfileVisibilityTab.privateItems
                                          ? privateMedia
                                          : publicMedia),
                                gridCount,
                                emptyMessage:
                                    _selectedVisibilityTab ==
                                        _ProfileVisibilityTab.savedItems
                                    ? 'No saved videos yet.'
                                    : (_selectedVisibilityTab ==
                                              _ProfileVisibilityTab.privateItems
                                          ? 'No private videos yet.'
                                          : 'No public videos yet.\nTap + to upload a video.'),
                                muted:
                                    _selectedVisibilityTab !=
                                    _ProfileVisibilityTab.privateItems,
                                showPlayOverlay:
                                    _selectedVisibilityTab !=
                                    _ProfileVisibilityTab.privateItems,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showCreateMediaSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const HomeBottomNav(selected: ''),
    );
  }
}

class _ProfileApiPayload {
  final String? name;
  final String? username;
  final String? bio;
  final String? socialLink;
  final String? profileImagePath;
  final int? followers;
  final List<_ProfileMediaItem>? media;

  const _ProfileApiPayload({
    this.name,
    this.username,
    this.bio,
    this.socialLink,
    this.profileImagePath,
    this.followers,
    this.media,
  });

  bool get hasAnyValue {
    return name != null ||
        username != null ||
        bio != null ||
        socialLink != null ||
        profileImagePath != null ||
        followers != null ||
        (media != null && media!.isNotEmpty);
  }

  factory _ProfileApiPayload.fromResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return const _ProfileApiPayload();
    }

    final containers = collectCandidateMaps(response);
    final profileMap = firstNestedMap(containers, const <String>[
      'profile',
      'user',
      'account',
    ]);
    final valueMaps = <Map<String, dynamic>>[?profileMap, ...containers];

    return _ProfileApiPayload(
      name: firstNonEmptyString(valueMaps, const <String>[
        'name',
        'full_name',
        'fullName',
        'display_name',
        'displayName',
      ]),
      username: firstNonEmptyString(valueMaps, const <String>[
        'username',
        'user_name',
        'userName',
        'handle',
      ]),
      bio: firstNonEmptyString(valueMaps, const <String>[
        'bio',
        'about',
        'description',
      ]),
      socialLink: firstNonEmptyString(valueMaps, const <String>[
        'social_link',
        'socialLink',
        'social',
        'social_url',
        'socialUrl',
        'instagram',
        'website',
      ]),
      profileImagePath: firstNonEmptyString(valueMaps, const <String>[
        'profile_image',
        'profileImage',
        'avatar',
        'avatar_url',
        'avatarUrl',
        'image',
        'image_url',
        'imageUrl',
        'photo',
      ]),
      followers: asInt(
        firstRawValueAcrossMaps(valueMaps, const <String>[
          'followers',
          'followers_count',
          'followersCount',
          'follower_count',
          'followerCount',
        ]),
      ),
      media: _extractMedia(valueMaps),
    );
  }

  static List<Map<String, dynamic>> collectCandidateMaps(
    Map<String, dynamic> root,
  ) {
    final result = <Map<String, dynamic>>[root];
    final queue = <Map<String, dynamic>>[root];
    const nestedKeys = <String>[
      'data',
      'result',
      'payload',
      'profile',
      'user',
      'account',
      'attributes',
    ];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final key in nestedKeys) {
        final nested = asMap(current[key]);
        if (nested == null) continue;
        result.add(nested);
        queue.add(nested);
      }
    }

    return result;
  }

  static Map<String, dynamic>? firstNestedMap(
    List<Map<String, dynamic>> containers,
    List<String> keys,
  ) {
    for (final container in containers) {
      for (final key in keys) {
        final nested = asMap(container[key]);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }

  static String? firstNonEmptyString(dynamic source, List<String> keys) {
    final maps = source is List<Map<String, dynamic>>
        ? source
        : <Map<String, dynamic>>[if (source is Map<String, dynamic>) source];
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  static dynamic firstRawValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static dynamic firstRawValueAcrossMaps(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      final value = firstRawValue(map, keys);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<dynamic>? asList(dynamic value) {
    if (value is List) {
      return value;
    }
    final map = asMap(value);
    if (map == null) return null;
    for (final key in const <String>['data', 'items', 'results', 'list']) {
      final nested = map[key];
      if (nested is List) {
        return nested;
      }
    }
    return <dynamic>[map];
  }

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'y';
    }
    return false;
  }

  static List<_ProfileMediaItem>? _extractMedia(
    List<Map<String, dynamic>> containers,
  ) {
    final raw = firstRawValueAcrossMaps(containers, const <String>[
      'media',
      'media_items',
      'mediaItems',
      'profile_media',
      'profileMedia',
      'reels',
      'my_reels',
      'myReels',
      'shorts',
      'videos',
      'posts',
      'items',
    ]);
    if (raw == null) return null;

    final items = asList(raw) ?? const <dynamic>[];
    final parsed = items
        .map<_ProfileMediaItem?>((item) {
          final map = asMap(item);
          if (map == null) return null;
          return _mediaFromApiMap(map);
        })
        .whereType<_ProfileMediaItem>()
        .toList(growable: false);

    return parsed;
  }

  static _ProfileMediaItem? _mediaFromApiMap(Map<String, dynamic> json) {
    final path = firstNonEmptyString(json, const <String>[
      'path',
      'file_path',
      'filePath',
      'local_path',
      'localPath',
      'uri',
      'url',
      'media_url',
      'mediaUrl',
      'image',
      'image_url',
      'imageUrl',
      'video_url',
      'videoUrl',
      'video',
      'thumbnail_url',
      'thumbnailUrl',
    ]);
    if (path == null || path.isEmpty) return null;

    final resolvedPath = MediaSourceResolver.resolve(path);
    if (resolvedPath.isEmpty) return null;

    final type =
        firstNonEmptyString(json, const <String>[
          'type',
          'media_type',
          'mediaType',
        ]) ??
        _guessMediaType(resolvedPath);
    final caption = firstNonEmptyString(json, const <String>[
      'caption',
      'description',
      'title',
      'challenge_name',
      'challengeName',
      'text',
    ]);

    return _ProfileMediaItem(
      path: resolvedPath,
      type: type == 'video' ? 'video' : 'image',
      likes:
          asInt(
            firstRawValue(json, const <String>[
              'likes',
              'like_count',
              'likeCount',
            ]),
          ) ??
          0,
      dislikes:
          asInt(
            firstRawValue(json, const <String>[
              'dislikes',
              'dislike_count',
              'dislikeCount',
            ]),
          ) ??
          0,
      shares:
          asInt(
            firstRawValue(json, const <String>[
              'shares',
              'share_count',
              'shareCount',
            ]),
          ) ??
          0,
      isSaved: _asBool(
        firstRawValue(json, const <String>['is_saved', 'isSaved', 'saved']),
      ),
      isLiked: _asBool(
        firstRawValue(json, const <String>['is_liked', 'isLiked', 'liked']),
      ),
      isDisliked: _asBool(
        firstRawValue(json, const <String>[
          'is_disliked',
          'isDisliked',
          'disliked',
        ]),
      ),
      uploaderName:
          firstNonEmptyString(json, const <String>[
            'uploader_name',
            'uploaderName',
            'author',
            'name',
          ]) ??
          'User',
      uploaderUsername:
          firstNonEmptyString(json, const <String>[
            'uploader_username',
            'uploaderUsername',
            'username',
            'handle',
          ]) ??
          '@user',
      caption: caption ?? '',
      visibility: _ProfileMediaVisibility.normalize(
        firstNonEmptyString(json, const <String>[
              'visibility',
              'privacy',
              'scope',
            ]) ??
            _ProfileMediaVisibility.public,
      ),
    );
  }

  static String _guessMediaType(String path) {
    final uri = Uri.tryParse(path);
    final lower = (uri?.path ?? path).toLowerCase();
    const videoExtensions = <String>[
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.m4v',
    ];
    for (final ext in videoExtensions) {
      if (lower.endsWith(ext)) return 'video';
    }
    return 'image';
  }
}

class _ProfileInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;

  const _ProfileInput({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _VisibilityTabs extends StatelessWidget {
  final _ProfileVisibilityTab selected;
  final ValueChanged<_ProfileVisibilityTab> onChanged;

  const _VisibilityTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border.all(color: AppColors.borderLightFor(context)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _VisibilityTabButton(
            title: 'Public',
            selected: selected == _ProfileVisibilityTab.publicItems,
            onTap: () => onChanged(_ProfileVisibilityTab.publicItems),
          ),
          _VisibilityTabButton(
            title: 'Private',
            selected: selected == _ProfileVisibilityTab.privateItems,
            onTap: () => onChanged(_ProfileVisibilityTab.privateItems),
          ),
          _VisibilityTabButton(
            title: 'Saved',
            selected: selected == _ProfileVisibilityTab.savedItems,
            onTap: () => onChanged(_ProfileVisibilityTab.savedItems),
          ),
        ],
      ),
    );
  }
}

class _VisibilityTabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : AppColors.textPrimaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final String visibility;

  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == _ProfileMediaVisibility.private;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrivate ? AppColors.cCC7C2D12 : AppColors.cCC166534,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPrivate ? 'Private' : 'Public',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelsScreen extends StatefulWidget {
  final List<_ProfileMediaItem> reels;
  final bool Function(String username) isFollowed;
  final bool Function(String path) isLiked;
  final bool Function(String path) isSaved;
  final int Function(String path, int fallback) likeCountFor;
  final int Function(String path) commentCountFor;
  final List<String> Function(String path) commentsFor;
  final int Function(String path) shareCountFor;
  final ValueChanged<String> onToggleFollow;
  final ValueChanged<_ProfileMediaItem> onToggleLike;
  final ValueChanged<_ProfileMediaItem> onToggleSave;
  final void Function(_ProfileMediaItem, String text) onAddComment;
  final ValueChanged<_ProfileMediaItem> onAddShare;

  const _ReelsScreen({
    required this.reels,
    required this.isFollowed,
    required this.isLiked,
    required this.isSaved,
    required this.likeCountFor,
    required this.commentCountFor,
    required this.commentsFor,
    required this.shareCountFor,
    required this.onToggleFollow,
    required this.onToggleLike,
    required this.onToggleSave,
    required this.onAddComment,
    required this.onAddShare,
  });

  @override
  State<_ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<_ReelsScreen> {
  late final PageController _controller;
  bool _showHeart = false;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _activeIndex = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCommentSheet(_ProfileMediaItem item) async {
    final controller = TextEditingController();
    final existing = widget.commentsFor(item.path);
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Comment',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              if (existing.isNotEmpty) ...[
                ...existing.map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      comment,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Post'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (submitted == true && controller.text.trim().isNotEmpty) {
      widget.onAddComment(item, controller.text.trim());
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final playerWidth = info.maxWidth(
          mobile: info.width,
          tablet: 520,
          desktop: 560,
        );
        final horizontalPadding = info.value(
          mobile: 14,
          tablet: 18,
          desktop: 22,
        );

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Reels',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: widget.reels.isEmpty
              ? const Center(
                  child: Text(
                    'No reels yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : Center(
                  child: SizedBox(
                    width: playerWidth,
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _controller,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _activeIndex = index),
                      itemCount: widget.reels.length,
                      itemBuilder: (context, index) {
                        final item = widget.reels[index];
                        final key = item.path;
                        final followKey = item.uploaderUsername.isEmpty
                            ? item.uploaderName
                            : item.uploaderUsername;
                        final likeCount = widget.likeCountFor(key, item.likes);
                        final commentCount = widget.commentCountFor(key);
                        final shareCount = widget.shareCountFor(key);
                        final isFollow = widget.isFollowed(followKey);
                        final liked = widget.isLiked(key);
                        final saved = widget.isSaved(key);
                        final isActive = index == _activeIndex;

                        return RepaintBoundary(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onDoubleTap: () {
                                  widget.onToggleLike(item);
                                  setState(() => _showHeart = true);
                                  Future<void>.delayed(
                                    const Duration(milliseconds: 420),
                                  ).then((_) {
                                    if (mounted) {
                                      setState(() => _showHeart = false);
                                    }
                                  });
                                },
                                child: FileVideoPreview(
                                  path: item.path,
                                  fit: BoxFit.cover,
                                  autoplay: isActive,
                                  showPlayOverlay: false,
                                  playIconSize: 42,
                                  muted: false,
                                  enablePlayback: isActive,
                                ),
                              ),
                              if (_showHeart)
                                Center(
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: info.value(
                                      mobile: 86,
                                      tablet: 96,
                                      desktop: 104,
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: horizontalPadding,
                                right: horizontalPadding,
                                bottom: info.value(
                                  mobile: 18,
                                  tablet: 22,
                                  desktop: 26,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.uploaderName.isEmpty
                                                      ? 'User'
                                                      : item.uploaderName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: info.value(
                                                      mobile: 15,
                                                      tablet: 16,
                                                      desktop: 17,
                                                    ),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () {
                                                  widget.onToggleFollow(
                                                    followKey,
                                                  );
                                                  setState(() {});
                                                },
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      999,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  isFollow
                                                      ? 'Following'
                                                      : 'Follow',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.uploaderUsername.isEmpty
                                                ? '@user'
                                                : '@${item.uploaderUsername}',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: info.value(
                                                mobile: 12,
                                                tablet: 12.5,
                                                desktop: 13,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (item.caption.trim().isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              item.caption.trim(),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: info.value(
                                                  mobile: 12,
                                                  tablet: 12.5,
                                                  desktop: 13,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: info.value(
                                        mobile: 66,
                                        tablet: 70,
                                        desktop: 74,
                                      ),
                                      child: Column(
                                        children: [
                                          _ReelActionButton(
                                            icon: liked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            label: '$likeCount',
                                            onTap: () {
                                              widget.onToggleLike(item);
                                              setState(() {});
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          _ReelActionButton(
                                            icon: Icons.comment,
                                            label: '$commentCount',
                                            onTap: () =>
                                                _openCommentSheet(item),
                                          ),
                                          const SizedBox(height: 12),
                                          _ReelActionButton(
                                            icon: saved
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            label: 'Save',
                                            onTap: () {
                                              widget.onToggleSave(item);
                                              setState(() {});
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    saved
                                                        ? 'Removed from favorites'
                                                        : 'Saved to favorites',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          _ReelActionButton(
                                            icon: Icons.share,
                                            label: '$shareCount',
                                            onTap: () async {
                                              widget.onAddShare(item);
                                              setState(() {});
                                              await Share.share(
                                                item.path,
                                                subject: 'Watch this reel',
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}

abstract class _ProfileMediaVisibility {
  static const String public = 'public';
  static const String private = 'private';

  static String normalize(String value) {
    return value == private ? private : public;
  }
}

class _ProfileMediaItem {
  final String path;
  final String type;
  final int likes;
  final int dislikes;
  final int shares;
  final bool isSaved;
  final bool isLiked;
  final bool isDisliked;
  final String uploaderName;
  final String uploaderUsername;
  final String caption;
  final String visibility;
  final String source;

  const _ProfileMediaItem({
    required this.path,
    required this.type,
    required this.likes,
    required this.dislikes,
    required this.shares,
    required this.isSaved,
    required this.isLiked,
    required this.isDisliked,
    required this.uploaderName,
    required this.uploaderUsername,
    required this.visibility,
    this.caption = '',
    this.source = '',
  });

  factory _ProfileMediaItem.fromStorage(Map<String, dynamic> json) {
    return _ProfileMediaItem(
      path: (json['path'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      isSaved: (json['is_saved'] as bool?) ?? false,
      isLiked: (json['is_liked'] as bool?) ?? false,
      isDisliked: (json['is_disliked'] as bool?) ?? false,
      uploaderName: (json['uploader_name'] ?? '').toString(),
      uploaderUsername: (json['uploader_username'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      visibility: _ProfileMediaVisibility.normalize(
        (json['visibility'] ?? '').toString(),
      ),
      source: (json['source'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'path': path,
      'type': type,
      'likes': likes,
      'dislikes': dislikes,
      'shares': shares,
      'is_saved': isSaved,
      'is_liked': isLiked,
      'is_disliked': isDisliked,
      'uploader_name': uploaderName,
      'uploader_username': uploaderUsername,
      'caption': caption,
      'visibility': visibility,
      'source': source,
    };
  }

  _ProfileMediaItem copyWith({
    String? path,
    String? type,
    int? likes,
    int? dislikes,
    int? shares,
    bool? isSaved,
    bool? isLiked,
    bool? isDisliked,
    String? uploaderName,
    String? uploaderUsername,
    String? caption,
    String? visibility,
    String? source,
  }) {
    return _ProfileMediaItem(
      path: path ?? this.path,
      type: type ?? this.type,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      shares: shares ?? this.shares,
      isSaved: isSaved ?? this.isSaved,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderUsername: uploaderUsername ?? this.uploaderUsername,
      caption: caption ?? this.caption,
      visibility: _ProfileMediaVisibility.normalize(
        visibility ?? this.visibility,
      ),
      source: source ?? this.source,
    );
  }
}

class _CapturedMediaReviewScreen extends StatefulWidget {
  final _ProfileMediaItem item;

  const _CapturedMediaReviewScreen({required this.item});

  @override
  State<_CapturedMediaReviewScreen> createState() =>
      _CapturedMediaReviewScreenState();
}

class _CapturedMediaReviewScreenState
    extends State<_CapturedMediaReviewScreen>
    with VideoPlaybackLifecycleMixin<_CapturedMediaReviewScreen> {
  VideoPlayerController? _controller;
  late _ProfileMediaItem _item;
  bool _loadingVideo = false;

  @override
  VideoPlayerController? get lifecycleVideoController => _controller;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    if (_item.type == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(File(_item.path));
    setState(() => _loadingVideo = true);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loadingVideo = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _loadingVideo = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final selectedTab = _item.visibility == _ProfileMediaVisibility.private
        ? _ProfileVisibilityTab.privateItems
        : _ProfileVisibilityTab.publicItems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Review Upload',
          style: TextStyle(
            color: AppColors.textTitleFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: isDark
                            ? AppColors.cFF111111
                            : AppColors.cFFF2F2F2,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_item.type == 'image')
                              Image.file(File(_item.path), fit: BoxFit.contain)
                            else if (_controller != null &&
                                _controller!.value.isInitialized)
                              GestureDetector(
                                onTap: _togglePlayback,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              )
                            else if (_loadingVideo)
                              const Center(child: CircularProgressIndicator())
                            else
                              Center(
                                child: Text(
                                  'Unable to preview video',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryFor(context),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: _VisibilityBadge(
                                visibility: _item.visibility,
                              ),
                            ),
                            if (_item.type == 'video' && _controller != null)
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: _togglePlayback,
                                    icon: Icon(
                                      _controller!.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Who can see this media?',
                    style: TextStyle(
                      color: AppColors.textTitleFor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select visibility before uploading this photo or video.',
                    style: TextStyle(
                      color: AppColors.textSecondaryFor(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _VisibilityTabs(
                    selected: selectedTab,
                    onChanged: (tab) {
                      setState(() {
                        _item = _item.copyWith(
                          visibility: tab == _ProfileVisibilityTab.privateItems
                              ? _ProfileMediaVisibility.private
                              : _ProfileMediaVisibility.public,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(_item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text(
                        'Upload',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: AppColors.textTitleFor(context),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreviewScreen extends StatefulWidget {
  final _ProfileMediaItem item;

  const _VideoPreviewScreen({required this.item});

  @override
  State<_VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen>
    with VideoPlaybackLifecycleMixin<_VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _failed = false;
  late _ProfileMediaItem _item;

  @override
  VideoPlayerController? get lifecycleVideoController => _controller;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _init();
  }

  Future<void> _init() async {
    final source = MediaSourceResolver.resolve(_item.path);
    if (source.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    late final VideoPlayerController controller;
    if (MediaSourceResolver.isNetworkLike(source)) {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(source),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
    } else {
      if (!MediaSourceResolver.existsLocally(source)) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      controller = VideoPlayerController.file(
        File(MediaSourceResolver.localFilePath(source)),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
    }

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
        _failed = false;
      });
      await controller.setVolume(1);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _doubleTapLike() {
    if (_item.isLiked) return;
    _toggleLike(forceLike: true);
  }

  void _toggleLike({bool forceLike = false}) {
    var likes = _item.likes;
    var dislikes = _item.dislikes;
    var isLiked = _item.isLiked;
    var isDisliked = _item.isDisliked;

    if (forceLike || !isLiked) {
      likes += 1;
      isLiked = true;
      if (isDisliked && dislikes > 0) dislikes -= 1;
      isDisliked = false;
    } else {
      if (likes > 0) likes -= 1;
      isLiked = false;
    }

    setState(() {
      _item = _item.copyWith(
        likes: likes,
        dislikes: dislikes,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );
    });
  }

  void _toggleDislike() {
    var likes = _item.likes;
    var dislikes = _item.dislikes;
    var isLiked = _item.isLiked;
    var isDisliked = _item.isDisliked;

    if (!isDisliked) {
      dislikes += 1;
      isDisliked = true;
      if (isLiked && likes > 0) likes -= 1;
      isLiked = false;
    } else {
      if (dislikes > 0) dislikes -= 1;
      isDisliked = false;
    }

    setState(() {
      _item = _item.copyWith(
        likes: likes,
        dislikes: dislikes,
        isLiked: isLiked,
        isDisliked: isDisliked,
      );
    });
  }

  void _toggleSave() {
    setState(() => _item = _item.copyWith(isSaved: !_item.isSaved));
  }

  Future<void> _share() async {
    final source = MediaSourceResolver.resolve(_item.path);
    if (MediaSourceResolver.isNetworkLike(source)) {
      await Share.share(
        source,
        subject: 'Fun Fit Media',
      );
    } else if (MediaSourceResolver.existsLocally(source)) {
      await Share.shareXFiles(
        [XFile(MediaSourceResolver.localFilePath(source))],
        text: 'Check out this workout post from Fun Fit',
        subject: 'Fun Fit Media',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media not available for sharing')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _item = _item.copyWith(shares: _item.shares + 1));
  }

  Widget _actionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final playerWidth = info.maxWidth(
          mobile: info.width,
          tablet: 520,
          desktop: 560,
        );

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: playerWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onDoubleTap: _doubleTapLike,
                        onTap: _togglePlayPause,
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _failed || _controller == null
                            ? const Center(
                                child: Text(
                                  'Unable to load video',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      left: info.value(mobile: 12, tablet: 16, desktop: 18),
                      top: info.value(mobile: 12, tablet: 16, desktop: 18),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(_item),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      right: info.value(mobile: 12, tablet: 16, desktop: 18),
                      bottom: info.value(
                        mobile: 100,
                        tablet: 112,
                        desktop: 120,
                      ),
                      child: Column(
                        children: [
                          _actionIcon(
                            icon: _item.isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            label: _item.likes.toString(),
                            onTap: _toggleLike,
                          ),
                          const SizedBox(height: 14),
                          _actionIcon(
                            icon: _item.isDisliked
                                ? Icons.thumb_down_alt
                                : Icons.thumb_down_alt_outlined,
                            label: _item.dislikes.toString(),
                            onTap: _toggleDislike,
                          ),
                          const SizedBox(height: 14),
                          _actionIcon(
                            icon: _item.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: 'Save',
                            onTap: _toggleSave,
                          ),
                          const SizedBox(height: 14),
                          _actionIcon(
                            icon: Icons.share,
                            label: _item.shares.toString(),
                            onTap: _share,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: info.value(mobile: 14, tablet: 18, desktop: 20),
                      right: info.value(mobile: 90, tablet: 96, desktop: 104),
                      bottom: info.value(mobile: 20, tablet: 24, desktop: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _VisibilityBadge(visibility: _item.visibility),
                          const SizedBox(height: 8),
                          Text(
                            _item.uploaderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: info.value(
                                mobile: 15,
                                tablet: 16,
                                desktop: 17,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _item.uploaderUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: info.value(
                                mobile: 13,
                                tablet: 13.5,
                                desktop: 14,
                              ),
                            ),
                          ),
                          if (_item.caption.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _item.caption.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: info.value(
                                  mobile: 12,
                                  tablet: 12.5,
                                  desktop: 13,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
