import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/home_bottom_nav.dart';

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

  bool _loading = true;
  String _name = '';
  String _username = '';
  String _bio = '';
  String _socialLink = '';
  String _profileImagePath = '';
  int _followers = 0;
  List<_ProfileMediaItem> _media = <_ProfileMediaItem>[];

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

  Future<void> _saveMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _media.map((e) => jsonEncode(e.toStorageMap())).toList();
    await prefs.setStringList(_kProfileMedia, encoded);
  }

  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileImagePath, path);
  }

  String get _displayName => _name.isEmpty ? _defaultName : _name;

  String get _displayUsername {
    final value = _username.isNotEmpty ? _username : _usernameFromName(_displayName);
    return value.startsWith('@') ? value : '@$value';
  }

  String _usernameFromName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '_');

  Future<void> _pickProfileImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null || !mounted) return;
    await _saveProfileImagePath(file.path);
    setState(() => _profileImagePath = file.path);
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

    final item = _ProfileMediaItem(
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
    );

    setState(() => _media.insert(0, item));
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

    if (result == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, result['name'] ?? '');
    await prefs.setString(_kProfileUsername, result['username'] ?? '');
    await prefs.setString(_kProfileBio, result['bio'] ?? '');
    await prefs.setString(_kProfileSocial, result['social'] ?? '');

    if (!mounted) return;
    setState(() {
      _name = result['name'] ?? '';
      _username = result['username'] ?? '';
      _bio = result['bio'] ?? '';
      _socialLink = result['social'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final posts = _media.length;
    final likes = _media.fold<int>(0, (sum, item) => sum + item.likes);
    final ImageProvider avatar = _profileImagePath.isNotEmpty
        ? FileImage(File(_profileImagePath))
        : const NetworkImage(_defaultImageUrl);

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
                final contentMaxWidth =
                    isDesktop ? 900.0 : (isTablet ? 760.0 : double.infinity);
                final horizontalPadding =
                    isDesktop ? width * 0.14 : (isTablet ? 28.0 : 8.0);
                final avatarRadius = isDesktop ? 56.0 : (isTablet ? 50.0 : 42.0);
                final nameSize = isDesktop ? 22.0 : (isTablet ? 19.0 : 16.0);
                final statSpacing = isDesktop ? 48.0 : (isTablet ? 36.0 : 28.0);
                final gridCount = isDesktop ? 5 : (isTablet ? 4 : 3);

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                                            borderRadius: BorderRadius.circular(14),
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
                                        color: AppColors.textPrimaryFor(context),
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
                                  icon: const Icon(Icons.edit_outlined, size: 16),
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
                              ],
                            ),
                          ),
                          Expanded(
                            child: AnimatedReveal(
                              delay: const Duration(milliseconds: 140),
                              child: _media.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No captured media yet.\nTap + to shoot photo/video.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textSecondaryFor(context),
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
                                      itemCount: _media.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: gridCount,
                                            crossAxisSpacing: 4,
                                            mainAxisSpacing: 4,
                                          ),
                                      itemBuilder: (context, index) {
                                        final item = _media[index];
                                        return GestureDetector(
                                          onTap: () => _openMedia(item),
                                          onLongPress: () => _confirmDeleteMedia(index),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: item.type == 'image'
                                                ? Image.file(
                                                    File(item.path),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: Colors.black87,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.play_circle_fill,
                                                        color: Colors.white,
                                                        size: 34,
                                                      ),
                                                    ),
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
        Text(label, style: TextStyle(color: AppColors.textSecondaryFor(context), fontSize: 12)),
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
                    icon: _item.isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
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
                    icon: _item.isSaved ? Icons.bookmark : Icons.bookmark_border,
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
