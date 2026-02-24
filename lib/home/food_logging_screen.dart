import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/getx.dart';
import '../widget/app_shell_controller.dart';
import '../widget/home_bottom_nav.dart';

class FoodLoggingScreen extends StatelessWidget {
  const FoodLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FoodLogFeed();
  }
}

class AddMealScreen extends StatelessWidget {
  const AddMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FoodLoggingScreen();
  }
}

enum _FeedTab { publicPosts, myPosts }
enum _Reaction { none, like, dislike }

class _FoodLogFeed extends StatefulWidget {
  const _FoodLogFeed();

  @override
  State<_FoodLogFeed> createState() => _FoodLogFeedState();
}

class _FoodLogFeedState extends State<_FoodLogFeed> {
  static const String _kProfileName = 'profile_name';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _defaultProfileName = 'Jacob West';
  final TextEditingController _composerController = TextEditingController();
  _FeedTab _selectedTab = _FeedTab.publicPosts;
  String _profileName = _defaultProfileName;
  String _profileImagePath = '';

  final List<_FeedPost> _publicPosts = <_FeedPost>[
    const _FeedPost(
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
    ),
    const _FeedPost(
      author: 'Dianne Russell',
      minutesAgo: 24,
      avatarAsset: 'assets/images/nora.jpg',
      content:
          'Sure! First, can you tell me about your daily routine and eating habits? That will help me suggest something suitable.',
      likes: 1,
    ),
    const _FeedPost(
      author: 'Esther Howard',
      minutesAgo: 26,
      avatarAsset: 'assets/images/alina.jpg',
      content:
          'I mostly sit all day due to work, and my diet includes a lot of carbs and snacks.',
      likes: 1,
    ),
  ];

  final List<_FeedPost> _myPosts = <_FeedPost>[
    const _FeedPost(
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
      isMine: true,
    ),
    const _FeedPost(
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
      isMine: true,
    ),
    const _FeedPost(
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
      isMine: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  String get _profileDisplayName {
    final value = _profileName.trim();
    return value.isEmpty ? _defaultProfileName : value;
  }

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

  List<_FeedPost> get _visiblePosts =>
      _selectedTab == _FeedTab.publicPosts ? _publicPosts : _myPosts;

  void _goHome() {
    final shellController = AppShellController.maybeFind();
    if (shellController != null) {
      shellController.setIndex(0);
      return;
    }
    Get.offNamed(Routes.home);
  }

  void _submitPost() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    final newPost = _FeedPost(
      author: _profileDisplayName,
      minutesAgo: 0,
      avatarFilePath: _profileImagePath.trim().isEmpty ? null : _profileImagePath,
      content: text,
      likes: 0,
      isMine: true,
    );

    setState(() {
      _myPosts.insert(0, newPost);
      _publicPosts.insert(0, newPost);
      _composerController.clear();
      _selectedTab = _FeedTab.myPosts;
    });
  }

  void _toggleLike(int index) {
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
      _publicPosts[index] = post.copyWith(
        likes: likes,
        reaction: nextReaction,
      );
    });
  }

  void _toggleDislike(int index) {
    final post = _publicPosts[index];
    var likes = post.likes;
    _Reaction nextReaction = _Reaction.dislike;

    if (post.reaction == _Reaction.dislike) {
      nextReaction = _Reaction.none;
    } else if (post.reaction == _Reaction.like) {
      likes = likes > 0 ? likes - 1 : 0;
    }

    setState(() {
      _publicPosts[index] = post.copyWith(
        likes: likes,
        reaction: nextReaction,
      );
    });
  }

  Future<void> _openReplyDialog({
    required bool isPublic,
    required int index,
  }) async {
    final controller = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write your reply',
            ),
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

    if (submit != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final reply = _PostReply(
      author: _profileDisplayName,
      minutesAgo: 0,
      text: text,
      avatarFilePath: _profileImagePath.trim().isEmpty ? null : _profileImagePath,
    );

    setState(() {
      if (isPublic) {
        final post = _publicPosts[index];
        _publicPosts[index] = post.copyWith(
          replies: <_PostReply>[...post.replies, reply],
        );
      } else {
        final post = _myPosts[index];
        _myPosts[index] = post.copyWith(
          replies: <_PostReply>[...post.replies, reply],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 360;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final contentMaxWidth = isDesktop
            ? 520.0
            : isTablet
            ? 460.0
            : 400.0;
        final headerTopPadding = isDesktop
            ? 30.0
            : isTablet
            ? 34.0
            : 36.0;
        final headerBottomPadding = isDesktop
            ? 24.0
            : isTablet
            ? 27.0
            : 30.0;
        final sideGap = isCompact ? 20.0 : 28.0;
        final cardMargin = isCompact ? 6.0 : 8.0;

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          floatingActionButton: SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 2,
              onPressed: () {},
              child: const Icon(Icons.add, color: Colors.black, size: 20),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Food Log'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(22),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          headerTopPadding,
                          16,
                          headerBottomPadding,
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _goHome,
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
                            const Expanded(
                              child: Text(
                                'FoodLog',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            SizedBox(width: sideGap),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 70),
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                            cardMargin,
                            cardMargin,
                            cardMargin,
                            10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 120),
                                child: Padding(
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
                                          selected: _selectedTab == _FeedTab.publicPosts,
                                          onTap: () => setState(
                                            () => _selectedTab = _FeedTab.publicPosts,
                                          ),
                                        ),
                                        _tabButton(
                                          title: 'My Post',
                                          selected: _selectedTab == _FeedTab.myPosts,
                                          onTap: () => setState(
                                            () => _selectedTab = _FeedTab.myPosts,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                                  itemCount: _visiblePosts.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final isPublic = _selectedTab == _FeedTab.publicPosts;
                                    return AnimatedReveal(
                                      delay: Duration(
                                        milliseconds: 130 + ((index % 8) * 30),
                                      ),
                                      child: _PostTile(
                                        post: _visiblePosts[index],
                                        onLike: isPublic ? () => _toggleLike(index) : null,
                                        onDislike: isPublic
                                            ? () => _toggleDislike(index)
                                            : null,
                                        onReply: () => _openReplyDialog(
                                          isPublic: isPublic,
                                          index: index,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 180),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _composerController,
                                          decoration: InputDecoration(
                                            hintText: "What's in your mind",
                                            hintStyle: const TextStyle(fontSize: 13),
                                            filled: true,
                                            fillColor: AppColors.surfaceSoft,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: AppColors.borderLight,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: AppColors.borderLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 28,
                                        child: ElevatedButton(
                                          onPressed: _submitPost,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text(
                                            'Post',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _PostTile extends StatelessWidget {
  final _FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onReply;

  const _PostTile({
    required this.post,
    this.onLike,
    this.onDislike,
    this.onReply,
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
          post.content,
          style: const TextStyle(
            color: Colors.black87,
            height: 1.32,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
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
            const Text(
              '>',
              style: TextStyle(
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

class _FeedPost {
  final String author;
  final int minutesAgo;
  final String? avatarAsset;
  final String? avatarFilePath;
  final String content;
  final int likes;
  final bool isMine;
  final _Reaction reaction;
  final List<_PostReply> replies;

  const _FeedPost({
    required this.author,
    required this.minutesAgo,
    this.avatarAsset,
    this.avatarFilePath,
    required this.content,
    required this.likes,
    this.isMine = false,
    this.reaction = _Reaction.none,
    this.replies = const <_PostReply>[],
  });

  _FeedPost copyWith({
    String? author,
    int? minutesAgo,
    String? avatarAsset,
    String? avatarFilePath,
    String? content,
    int? likes,
    bool? isMine,
    _Reaction? reaction,
    List<_PostReply>? replies,
  }) {
    return _FeedPost(
      author: author ?? this.author,
      minutesAgo: minutesAgo ?? this.minutesAgo,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      avatarFilePath: avatarFilePath ?? this.avatarFilePath,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      isMine: isMine ?? this.isMine,
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
