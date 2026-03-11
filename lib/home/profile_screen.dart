import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/file_video_preview.dart';
import '../widget/home_bottom_nav.dart';

enum _ProfileVisibilityTab { publicItems, privateItems }

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
  static const String _kProfileName = 'profile_name';
  static const String _kProfileUsername = 'profile_username';
  static const String _kProfileBio = 'profile_bio';
  static const String _kProfileSocial = 'profile_social_link';
  static const String _kProfileImagePath = 'profile_image_path';
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
  _ProfileVisibilityTab _selectedVisibilityTab =
      _ProfileVisibilityTab.publicItems;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
        _followers = prefs.getInt(_kFollowers) ?? 0;
        _media = _readMedia(prefs.getStringList(_kProfileMedia) ?? <String>[]);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }

    await _refreshProfileFromApi();
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
        .where((item) => File(item.path).existsSync())
        .toList();
  }

  Future<void> _saveProfileLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, _name);
    await prefs.setString(_kProfileUsername, _username);
    await prefs.setString(_kProfileBio, _bio);
    await prefs.setString(_kProfileSocial, _socialLink);
    await prefs.setString(_kProfileImagePath, _profileImagePath);
    await prefs.setInt(_kFollowers, _followers);
    final encoded = _media.map((e) => jsonEncode(e.toStorageMap())).toList();
    await prefs.setStringList(_kProfileMedia, encoded);
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
    if (!mounted || !result.success) return;

    final payload = _ProfileApiPayload.fromResponse(result.data);
    if (!payload.hasAnyValue) return;

    setState(() {
      if (payload.name != null) {
        _name = payload.name!;
      }
      if (payload.username != null) {
        _username = payload.username!;
      }
      if (payload.bio != null) {
        _bio = payload.bio!;
      }
      if (payload.socialLink != null) {
        _socialLink = payload.socialLink!;
      }
      if (payload.profileImagePath != null) {
        _profileImagePath = payload.profileImagePath!;
      }
      if (payload.followers != null) {
        _followers = payload.followers!;
      }
      if (payload.media != null && payload.media!.isNotEmpty) {
        _media = payload.media!;
      }
    });

    await _saveProfileLocally();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _saveMedia() async {
    await _saveProfileLocally();
    await _syncProfileToBackend();
  }

  Future<void> _saveProfileImagePath(String path) async {
    _profileImagePath = path;
    await _saveProfileLocally();
    await _syncProfileToBackend(showError: true);
  }

  String get _displayName => _name.isEmpty ? _defaultName : _name;

  String get _displayUsername {
    final value = _username.isNotEmpty
        ? _username
        : _usernameFromName(_displayName);
    return value.startsWith('@') ? value : '@$value';
  }

  List<_ProfileMediaItem> get _visibleMedia => _media
      .where(
        (item) => _selectedVisibilityTab == _ProfileVisibilityTab.publicItems
            ? item.visibility == _ProfileMediaVisibility.public
            : item.visibility == _ProfileMediaVisibility.private,
      )
      .toList(growable: false);

  String _usernameFromName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '_');

  Future<void> _pickProfileImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null || !mounted) return;
    setState(() => _profileImagePath = file.path);
    await _saveProfileImagePath(file.path);
  }

  Future<void> _showProfileImageOptions() async {
    await _showSourceSheet(
      cameraLabel: 'Take Photo',
      galleryLabel: 'Choose From Gallery',
      onCamera: () => _pickProfileImage(ImageSource.camera),
      onGallery: () => _pickProfileImage(ImageSource.gallery),
    );
  }

  Future<void> _showSourceSheet({
    required String cameraLabel,
    required String galleryLabel,
    required Future<void> Function() onCamera,
    required Future<void> Function() onGallery,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCapturedMedia({required bool isVideo}) async {
    final file = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);
    if (file == null || !mounted) return;

    final draft = _ProfileMediaItem(
      path: file.path,
      type: isVideo ? 'video' : 'image',
      likes: 0,
      dislikes: 0,
      shares: 0,
      isSaved: false,
      isLiked: false,
      isDisliked: false,
      uploaderName: _displayName,
      uploaderUsername: _displayUsername,
      visibility: _ProfileMediaVisibility.public,
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
  }

  Future<void> _showCreateMediaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
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
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Record Video'),
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await _addCapturedMedia(isVideo: true);
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
    final file = File(item.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media file not found on device')),
      );
      return;
    }

    if (item.type == 'image') {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.file(file, fit: BoxFit.contain),
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
    final index = _media.indexWhere((e) => e.path == item.path);
    if (index == -1) return;
    setState(() => _media[index] = updated);
    await _saveMedia();
  }

  Future<void> _confirmDeleteMedia(int index) async {
    final item = _media[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _media.removeAt(index));
    await _saveMedia();

    final file = File(item.path);
    if (file.existsSync()) {
      try {
        await file.delete();
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
    final visibleMedia = _visibleMedia;
    final ImageProvider avatar = ProfileAvatarResolver.resolve(
      _profileImagePath,
      fallback: const NetworkImage(_defaultImageUrl),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                final width = constraints.maxWidth;
                final isDesktop = width >= 1100;
                final isTablet = width >= 700 && width < 1100;
                final contentMaxWidth = isDesktop
                    ? 900.0
                    : (isTablet ? 760.0 : double.infinity);
                final horizontalPadding = isDesktop
                    ? width * 0.14
                    : (isTablet ? 28.0 : 8.0);
                final avatarRadius = isDesktop
                    ? 56.0
                    : (isTablet ? 50.0 : 42.0);
                final nameSize = isDesktop ? 22.0 : (isTablet ? 19.0 : 16.0);
                final statSpacing = isDesktop ? 48.0 : (isTablet ? 36.0 : 28.0);
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
                              ],
                            ),
                          ),
                          Expanded(
                            child: AnimatedReveal(
                              delay: const Duration(milliseconds: 140),
                              child: visibleMedia.isEmpty
                                  ? Center(
                                      child: Text(
                                        _selectedVisibilityTab ==
                                                _ProfileVisibilityTab
                                                    .publicItems
                                            ? 'No public media yet.\nTap + to shoot photo/video.'
                                            : 'No private media yet.\nTap + to shoot photo/video.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textSecondaryFor(
                                            context,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        8,
                                        8,
                                        90,
                                      ),
                                      itemCount: visibleMedia.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: gridCount,
                                            crossAxisSpacing: 4,
                                            mainAxisSpacing: 4,
                                          ),
                                      itemBuilder: (context, index) {
                                        final item = visibleMedia[index];
                                        return GestureDetector(
                                          onTap: () => _openMedia(item),
                                          onLongPress: () {
                                            final mediaIndex = _media.indexOf(
                                              item,
                                            );
                                            if (mediaIndex < 0) return;
                                            _confirmDeleteMedia(mediaIndex);
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                item.type == 'image'
                                                    ? Image.file(
                                                        File(item.path),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : FileVideoPreview(
                                                        path: item.path,
                                                        fit: BoxFit.cover,
                                                        playIconSize: 26,
                                                      ),
                                                Positioned(
                                                  left: 6,
                                                  bottom: 6,
                                                  child: _VisibilityBadge(
                                                    visibility: item.visibility,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
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
    final valueMaps = <Map<String, dynamic>>[
      ?profileMap,
      ...containers,
    ];

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
    ]);
    if (path == null || path.isEmpty) return null;

    // Profile grid currently renders local file media only.
    if (!File(path).existsSync()) return null;

    final type =
        firstNonEmptyString(json, const <String>[
          'type',
          'media_type',
          'mediaType',
        ]) ??
        _guessMediaType(path);

    return _ProfileMediaItem(
      path: path,
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
    final lower = path.toLowerCase();
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
        color: isPrivate ? const Color(0xCC7C2D12) : const Color(0xCC166534),
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
  final String visibility;

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
      visibility: _ProfileMediaVisibility.normalize(
        (json['visibility'] ?? '').toString(),
      ),
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
      'visibility': visibility,
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
    String? visibility,
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
      visibility: _ProfileMediaVisibility.normalize(
        visibility ?? this.visibility,
      ),
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
    extends State<_CapturedMediaReviewScreen> {
  VideoPlayerController? _controller;
  late _ProfileMediaItem _item;
  bool _loadingVideo = false;

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
                            ? const Color(0xFF111111)
                            : const Color(0xFFF2F2F2),
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

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _VideoPreviewScreen extends StatefulWidget {
  final _ProfileMediaItem item;

  const _VideoPreviewScreen({required this.item});

  @override
  State<_VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  late _ProfileMediaItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(File(_item.path));
    await controller.initialize();
    controller.setLooping(true);
    await controller.play();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _loading = false;
    });
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
    final file = File(_item.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found for sharing')),
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(_item.path)],
      text: 'Check out this workout post from Fun Fit',
      subject: 'Fun Fit Media',
    );

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _doubleTapLike,
                onTap: _togglePlayPause,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
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
              left: 12,
              top: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(_item),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 100,
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
              left: 14,
              right: 90,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisibilityBadge(visibility: _item.visibility),
                  const SizedBox(height: 8),
                  Text(
                    _item.uploaderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _item.uploaderUsername,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
