import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/getx.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChallengesFeed();
  }
}

enum _ChallengesTab { publicPosts, myPosts }
enum _Reaction { none, like, dislike }
enum _MediaType { none, image, video }

class _ChallengesFeed extends StatefulWidget {
  const _ChallengesFeed();

  @override
  State<_ChallengesFeed> createState() => _ChallengesFeedState();
}

class _ChallengesFeedState extends State<_ChallengesFeed> {
  static const String _kProfileName = 'profile_name';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _defaultProfileName = 'Jacob West';

  _ChallengesTab _selectedTab = _ChallengesTab.publicPosts;
  String _profileName = _defaultProfileName;
  String _profileImagePath = '';

  final List<_ChallengePost> _publicPosts = <_ChallengePost>[
    const _ChallengePost(
      id: 'public_1',
      author: 'Maude Hall',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      title: 'Push-Up Challenge',
      category: 'Medium',
      fitnessLevel: 'Beginner',
      description: 'Do 100 push-ups in 1 minute',
      likes: 2,
    ),
    const _ChallengePost(
      id: 'public_2',
      author: 'Maude Hall',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      title: 'Push-Up Challenge',
      category: 'Medium',
      fitnessLevel: 'Beginner',
      description: 'Do 100 push-ups in 1 minute',
      likes: 2,
    ),
    const _ChallengePost(
      id: 'public_3',
      author: 'Maude Hall',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      title: 'Push-Up Challenge',
      category: 'Medium',
      fitnessLevel: 'Beginner',
      description: 'Do 100 push-ups in 1 minute',
      likes: 2,
    ),
  ];

  final List<_ChallengePost> _myPosts = <_ChallengePost>[
    const _ChallengePost(
      id: 'my_1',
      author: 'Maude Hall',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      title: 'Push-Up Challenge',
      category: 'Medium',
      fitnessLevel: 'Beginner',
      description: 'Do 100 push-ups in 1 minute',
      likes: 2,
      isMine: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  String get _profileDisplayName {
    final value = _profileName.trim();
    return value.isEmpty ? _defaultProfileName : value;
  }

  List<_ChallengePost> get _visiblePosts =>
      _selectedTab == _ChallengesTab.publicPosts ? _publicPosts : _myPosts;

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = (prefs.getString(_kProfileName) ?? '').trim();
    final savedImagePath = (prefs.getString(_kProfileImagePath) ?? '').trim();
    if (!mounted) return;

    final resolvedName = savedName.isEmpty ? _defaultProfileName : savedName;
    final resolvedImagePath = savedImagePath.isEmpty ? null : savedImagePath;

    setState(() {
      _profileName = resolvedName;
      _profileImagePath = savedImagePath;
      for (var i = 0; i < _myPosts.length; i++) {
        final post = _myPosts[i];
        _myPosts[i] = post.copyWith(
          author: resolvedName,
          avatarFilePath: resolvedImagePath ?? post.avatarFilePath,
        );
      }
    });
  }

  void _handleBack() {
    Get.offNamed(Routes.home);
  }

  void _updatePostById(
    String id,
    _ChallengePost Function(_ChallengePost) updater,
  ) {
    final publicIndex = _publicPosts.indexWhere((post) => post.id == id);
    if (publicIndex != -1) {
      _publicPosts[publicIndex] = updater(_publicPosts[publicIndex]);
    }

    final myIndex = _myPosts.indexWhere((post) => post.id == id);
    if (myIndex != -1) {
      _myPosts[myIndex] = updater(_myPosts[myIndex]);
    }
  }

  void _toggleLike(String id) {
    final index = _publicPosts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    final post = _publicPosts[index];
    var likes = post.likes;
    _Reaction nextReaction = _Reaction.like;

    if (post.reaction == _Reaction.like) {
      nextReaction = _Reaction.none;
      likes = likes > 0 ? likes - 1 : 0;
    } else {
      likes += 1;
    }

    setState(() {
      _updatePostById(
        id,
        (oldPost) => oldPost.copyWith(
          likes: likes,
          reaction: nextReaction,
        ),
      );
    });
  }

  void _toggleDislike(String id) {
    final index = _publicPosts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    final post = _publicPosts[index];
    var likes = post.likes;
    _Reaction nextReaction = _Reaction.dislike;

    if (post.reaction == _Reaction.dislike) {
      nextReaction = _Reaction.none;
    } else if (post.reaction == _Reaction.like) {
      likes = likes > 0 ? likes - 1 : 0;
    }

    setState(() {
      _updatePostById(
        id,
        (oldPost) => oldPost.copyWith(
          likes: likes,
          reaction: nextReaction,
        ),
      );
    });
  }

  void _toggleAccept(String id) {
    setState(() {
      _updatePostById(
        id,
        (post) => post.copyWith(isAccepted: !post.isAccepted),
      );
    });
  }

  Future<void> _openReplyDialog(String id) async {
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write your reply'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final reply = _PostReply(
      author: _profileDisplayName,
      minutesAgo: 0,
      text: text,
      avatarFilePath: _profileImagePath.trim().isEmpty ? null : _profileImagePath,
    );

    setState(() {
      _updatePostById(
        id,
        (post) => post.copyWith(
          replies: <_PostReply>[...post.replies, reply],
        ),
      );
    });
  }

  Future<void> _openAddChallenge() async {
    final draft = await Navigator.of(context).push<_DraftChallenge>(
      MaterialPageRoute(builder: (_) => const AddChallengeScreen()),
    );
    if (draft == null || !mounted) return;

    final newPost = _ChallengePost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: _profileDisplayName,
      minutesAgo: 0,
      avatarFilePath: _profileImagePath.trim().isEmpty ? null : _profileImagePath,
      title: draft.name,
      category: draft.category,
      fitnessLevel: draft.fitnessLevel,
      description: draft.description,
      mediaPath: draft.mediaPath,
      mediaType: draft.mediaType,
      likes: 0,
      isMine: true,
    );

    setState(() {
      _myPosts.insert(0, newPost);
      _publicPosts.insert(0, newPost);
      _selectedTab = _ChallengesTab.myPosts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              title: 'Challenges',
              onBack: _handleBack,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _tabButton(
                                  title: 'Public',
                                  selected: _selectedTab == _ChallengesTab.publicPosts,
                                  onTap: () => setState(
                                    () => _selectedTab = _ChallengesTab.publicPosts,
                                  ),
                                ),
                                _tabButton(
                                  title: 'My Post',
                                  selected: _selectedTab == _ChallengesTab.myPosts,
                                  onTap: () => setState(
                                    () => _selectedTab = _ChallengesTab.myPosts,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 70),
                                itemCount: _visiblePosts.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final post = _visiblePosts[index];
                                  final isPublic =
                                      _selectedTab == _ChallengesTab.publicPosts;
                                  return _ChallengePostTile(
                                    post: post,
                                    onLike: isPublic ? () => _toggleLike(post.id) : null,
                                    onDislike: isPublic
                                        ? () => _toggleDislike(post.id)
                                        : null,
                                    onReply: () => _openReplyDialog(post.id),
                                    onAccept: () => _toggleAccept(post.id),
                                  );
                                },
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: InkWell(
                                  onTap: _openAddChallenge,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class AddChallengeScreen extends StatefulWidget {
  const AddChallengeScreen({super.key});

  @override
  State<AddChallengeScreen> createState() => _AddChallengeScreenState();
}

class _AddChallengeScreenState extends State<AddChallengeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String? _selectedFitnessLevel;
  String _selectedMediaPath = '';
  _MediaType _selectedMediaType = _MediaType.none;

  static const List<String> _categories = <String>[
    'Beginner',
    'Medium',
    'Advanced',
  ];
  static const List<String> _fitnessLevels = <String>[
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Capture Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureFromCamera(isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Capture Video'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureFromCamera(isVideo: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Pick Image from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromGallery(isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Pick Video from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromGallery(isVideo: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureFromCamera({required bool isVideo}) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.camera)
          : await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
            );
      if (file == null || !mounted) return;
      setState(() {
        _selectedMediaPath = file.path;
        _selectedMediaType = isVideo ? _MediaType.video : _MediaType.image;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera access failed.')),
      );
    }
  }

  Future<void> _pickFromGallery({required bool isVideo}) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            );
      if (file == null || !mounted) return;
      setState(() {
        _selectedMediaPath = file.path;
        _selectedMediaType = isVideo ? _MediaType.video : _MediaType.image;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery access failed.')),
      );
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _selectedCategory;
    final fitnessLevel = _selectedFitnessLevel;

    if (name.isEmpty ||
        time.isEmpty ||
        description.isEmpty ||
        category == null ||
        fitnessLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _DraftChallenge(
        name: name,
        time: time,
        category: category,
        fitnessLevel: fitnessLevel,
        mediaPath: _selectedMediaPath,
        mediaType: _selectedMediaType,
        description: description,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              title: 'Add Challenge',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration('Challenge Name'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _timeController,
                            decoration: _inputDecoration('Time'),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            decoration: _inputDecoration('Select Category'),
                            items: _categories
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFitnessLevel,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            decoration: _inputDecoration('Fitness Level'),
                            items: _fitnessLevels
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFitnessLevel = value;
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickMedia,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.borderLight),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: Text(
                              _selectedMediaPath.isEmpty
                                  ? 'Upload Image / Video'
                                  : (_selectedMediaType == _MediaType.video
                                      ? 'Video Selected'
                                      : 'Image Selected'),
                            ),
                          ),
                          if (_selectedMediaPath.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _selectedMediaPath.split(RegExp(r'[\\/]')).last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: _inputDecoration('Discription'),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Post',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _PageHeader({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(18),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengePostTile extends StatelessWidget {
  final _ChallengePost post;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onReply;
  final VoidCallback? onAccept;

  const _ChallengePostTile({
    required this.post,
    this.onLike,
    this.onDislike,
    this.onReply,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final initials = post.author.trim().isEmpty ? 'U' : post.author[0];
    final timeText = post.minutesAgo == 0 ? 'now' : '${post.minutesAgo} min';
    final likeLabel = post.likes == 1 ? '1 Like' : '${post.likes} Likes';
    final filePath = post.avatarFilePath?.trim() ?? '';
    final hasLocalAvatar = filePath.isNotEmpty && File(filePath).existsSync();
    final ImageProvider? avatarImage = hasLocalAvatar
        ? FileImage(File(filePath))
        : (post.avatarAsset != null ? AssetImage(post.avatarAsset!) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12.5,
              backgroundColor: const Color(0xFFF4D1D8),
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              post.author,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeText,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          post.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _DetailChip(label: 'Category: ${post.category}'),
            _DetailChip(label: 'Fitness level: ${post.fitnessLevel}'),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          post.description,
          style: const TextStyle(
            color: Colors.black87,
            height: 1.32,
            fontSize: 13,
          ),
        ),
        if (post.mediaPath != null && post.mediaPath!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _AttachedMediaView(
            mediaPath: post.mediaPath!,
            mediaType: post.mediaType,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              likeLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onReply,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  'Reply',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onAccept,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  post.isAccepted ? 'Accepted' : 'Accept',
                  style: TextStyle(
                    color: post.isAccepted ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onLike,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 14,
                  color: post.reaction == _Reaction.like
                      ? Colors.black
                      : Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onDislike,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.thumb_down_alt_outlined,
                  size: 14,
                  color: post.reaction == _Reaction.dislike
                      ? Colors.black
                      : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
        if (post.replies.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...post.replies.map(
            (reply) => Padding(
              padding: const EdgeInsets.only(top: 6, left: 18),
              child: _ReplyTile(reply: reply),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;

  const _DetailChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF9F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
          fontSize: 9.6,
        ),
      ),
    );
  }
}

class _AttachedMediaView extends StatelessWidget {
  final String mediaPath;
  final _MediaType mediaType;

  const _AttachedMediaView({
    required this.mediaPath,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == _MediaType.image) {
      final file = File(mediaPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: double.infinity,
            height: 160,
            fit: BoxFit.cover,
          ),
        );
      }
      return _missingMediaLabel();
    }

    if (mediaType == _MediaType.video) {
      final fileName = mediaPath.split(RegExp(r'[\\/]')).last;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _missingMediaLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Text(
        'Media attached',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final _PostReply reply;

  const _ReplyTile({required this.reply});

  @override
  Widget build(BuildContext context) {
    final filePath = reply.avatarFilePath?.trim() ?? '';
    final hasLocalAvatar = filePath.isNotEmpty && File(filePath).existsSync();
    final ImageProvider? avatar = hasLocalAvatar ? FileImage(File(filePath)) : null;
    final initials = reply.author.trim().isEmpty ? 'U' : reply.author[0];
    final timeText = reply.minutesAgo == 0 ? 'now' : '${reply.minutesAgo} min';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: const Color(0xFFF3F4F6),
          backgroundImage: avatar,
          child: avatar == null
              ? Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.author,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reply.text,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChallengePost {
  final String id;
  final String author;
  final int minutesAgo;
  final String? avatarAsset;
  final String? avatarFilePath;
  final String? mediaPath;
  final _MediaType mediaType;
  final String title;
  final String category;
  final String fitnessLevel;
  final String description;
  final int likes;
  final bool isMine;
  final bool isAccepted;
  final _Reaction reaction;
  final List<_PostReply> replies;

  const _ChallengePost({
    required this.id,
    required this.author,
    required this.minutesAgo,
    this.avatarAsset,
    this.avatarFilePath,
    this.mediaPath,
    this.mediaType = _MediaType.none,
    required this.title,
    required this.category,
    required this.fitnessLevel,
    required this.description,
    required this.likes,
    this.isMine = false,
    this.isAccepted = false,
    this.reaction = _Reaction.none,
    this.replies = const <_PostReply>[],
  });

  _ChallengePost copyWith({
    String? id,
    String? author,
    int? minutesAgo,
    String? avatarAsset,
    String? avatarFilePath,
    String? mediaPath,
    _MediaType? mediaType,
    String? title,
    String? category,
    String? fitnessLevel,
    String? description,
    int? likes,
    bool? isMine,
    bool? isAccepted,
    _Reaction? reaction,
    List<_PostReply>? replies,
  }) {
    return _ChallengePost(
      id: id ?? this.id,
      author: author ?? this.author,
      minutesAgo: minutesAgo ?? this.minutesAgo,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      avatarFilePath: avatarFilePath ?? this.avatarFilePath,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      category: category ?? this.category,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      description: description ?? this.description,
      likes: likes ?? this.likes,
      isMine: isMine ?? this.isMine,
      isAccepted: isAccepted ?? this.isAccepted,
      reaction: reaction ?? this.reaction,
      replies: replies ?? this.replies,
    );
  }
}

class _PostReply {
  final String author;
  final int minutesAgo;
  final String text;
  final String? avatarFilePath;

  const _PostReply({
    required this.author,
    required this.minutesAgo,
    required this.text,
    this.avatarFilePath,
  });
}

class _DraftChallenge {
  final String name;
  final String time;
  final String category;
  final String fitnessLevel;
  final String mediaPath;
  final _MediaType mediaType;
  final String description;

  const _DraftChallenge({
    required this.name,
    required this.time,
    required this.category,
    required this.fitnessLevel,
    required this.mediaPath,
    required this.mediaType,
    required this.description,
  });
}
