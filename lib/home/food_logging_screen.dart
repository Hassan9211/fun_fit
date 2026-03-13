import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/file_video_preview.dart';

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

abstract class _FeedMediaType {
  static const String none = 'none';
  static const String image = 'image';
}

class _FoodLogFeed extends StatefulWidget {
  const _FoodLogFeed();

  @override
  State<_FoodLogFeed> createState() => _FoodLogFeedState();
}

class _FoodLogFeedState extends State<_FoodLogFeed> {
  static const String _kProfileName = 'profile_name';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _kProfileMedia = 'profile_media_items';
  static const String _defaultProfileName = 'Jacob West';
  final AuthApiService _authApi = AuthApiService();
  final TextEditingController _composerController = TextEditingController();
  _FeedTab _selectedTab = _FeedTab.publicPosts;
  String _profileName = _defaultProfileName;
  String _profileImagePath = '';
  bool _isSavingPost = false;

  final List<_FeedPost> _publicPosts = <_FeedPost>[
    const _FeedPost(
      id: 'food_1',
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
    ),
    const _FeedPost(
      id: 'food_2',
      author: 'Dianne Russell',
      minutesAgo: 24,
      avatarAsset: 'assets/images/nora.jpg',
      content:
          'Sure! First, can you tell me about your daily routine and eating habits? That will help me suggest something suitable.',
      likes: 1,
    ),
    const _FeedPost(
      id: 'food_3',
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
      id: 'my_food_1',
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
      isMine: true,
    ),
    const _FeedPost(
      id: 'my_food_2',
      author: 'Maude Hal',
      minutesAgo: 14,
      avatarAsset: 'assets/images/tammana.jpg',
      content:
          "Hey! My body weight is increasing. I'm gaining weight and want some suggestions.",
      likes: 2,
      isMine: true,
    ),
    const _FeedPost(
      id: 'my_food_3',
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
    ProfileSyncService.changes.addListener(_loadProfileData);
    _loadProfileData();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadProfileData);
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
    final mediaPosts = _readPublicMediaPosts(
      prefs.getStringList(_kProfileMedia) ?? <String>[],
      author: resolvedName,
      avatarFilePath: resolvedImagePath,
    );
    setState(() {
      _profileName = resolvedName;
      _profileImagePath = savedImagePath;
      _syncProfileMediaPosts(mediaPosts);
      for (var i = 0; i < _myPosts.length; i++) {
        final post = _myPosts[i];
        _myPosts[i] = post.copyWith(
          author: resolvedName,
          avatarFilePath: resolvedImagePath ?? post.avatarFilePath,
        );
      }
    });
    await _loadFeedFromApi();
  }

  List<_FeedPost> _readPublicMediaPosts(
    List<String> raw, {
    required String author,
    required String? avatarFilePath,
  }) {
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is! Map<String, dynamic>) return null;
            final visibility = (decoded['visibility'] ?? 'public').toString();
            if (visibility == 'private') return null;
            final path = (decoded['path'] ?? '').toString().trim();
            if (path.isEmpty || !File(path).existsSync()) return null;
            final type = (decoded['type'] ?? '').toString();
            if (type != _FeedMediaType.image) return null;
            final isLiked = (decoded['is_liked'] as bool?) ?? false;
            final isDisliked = (decoded['is_disliked'] as bool?) ?? false;

            return _FeedPost(
              id: path,
              author: author,
              minutesAgo: 0,
              avatarFilePath: avatarFilePath,
              content: 'Shared a workout photo from profile.',
              likes: (decoded['likes'] as num?)?.toInt() ?? 0,
              isMine: true,
              reaction: isLiked
                  ? _Reaction.like
                  : isDisliked
                  ? _Reaction.dislike
                  : _Reaction.none,
              mediaPath: path,
              mediaType: _FeedMediaType.image,
              isProfileMedia: true,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<_FeedPost>()
        .toList(growable: false);
  }

  void _syncProfileMediaPosts(List<_FeedPost> mediaPosts) {
    final existingPublic = <String, _FeedPost>{};
    final existingMine = <String, _FeedPost>{};
    for (final post in _publicPosts.where((post) => post.isProfileMedia)) {
      if (post.mediaPath != null) existingPublic[post.mediaPath!] = post;
    }
    for (final post in _myPosts.where((post) => post.isProfileMedia)) {
      if (post.mediaPath != null) existingMine[post.mediaPath!] = post;
    }

    _publicPosts.removeWhere((post) => post.isProfileMedia);
    _myPosts.removeWhere((post) => post.isProfileMedia);

    final nextPublic = mediaPosts
        .map((post) {
          final previous = post.mediaPath == null
              ? null
              : existingPublic[post.mediaPath!];
          return previous == null
              ? post
              : post.copyWith(
                  likes: previous.likes,
                  reaction: previous.reaction,
                  replies: previous.replies,
                );
        })
        .toList(growable: false);

    final nextMine = mediaPosts
        .map((post) {
          final previous = post.mediaPath == null
              ? null
              : (existingMine[post.mediaPath!] ??
                    existingPublic[post.mediaPath!]);
          final base = previous == null
              ? post.copyWith(isMine: true)
              : post.copyWith(
                  likes: previous.likes,
                  reaction: previous.reaction,
                  replies: previous.replies,
                  isMine: true,
                );
          return base;
        })
        .toList(growable: false);

    _publicPosts.insertAll(0, nextPublic);
    _myPosts.insertAll(0, nextMine);
  }

  List<_FeedPost> get _visiblePosts =>
      _selectedTab == _FeedTab.publicPosts ? _publicPosts : _myPosts;

  Future<void> _submitPost() async {
    if (_isSavingPost) return;
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    final newPost = _FeedPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: _profileDisplayName,
      minutesAgo: 0,
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
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

    await _savePostToApi(newPost);
  }

  Future<void> _loadFeedFromApi() async {
    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();

    final result = await _authApi.fetchFoodLogData(
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted || !result.success) return;

    final payload = _FoodLogApiPayload.fromResponse(result.data);
    final hasAnyData = payload.publicPosts != null || payload.myPosts != null;
    if (!hasAnyData) return;

    final prefs = await SharedPreferences.getInstance();
    final mediaPosts = _readPublicMediaPosts(
      prefs.getStringList(_kProfileMedia) ?? <String>[],
      author: _profileDisplayName,
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
    );
    if (!mounted) return;

    setState(() {
      if (payload.publicPosts != null) {
        _publicPosts
          ..clear()
          ..addAll(payload.publicPosts!);
      }
      if (payload.myPosts != null) {
        _myPosts
          ..clear()
          ..addAll(payload.myPosts!);
      }
      _syncProfileMediaPosts(mediaPosts);
    });
  }

  Future<void> _savePostToApi(_FeedPost post) async {
    if (_isSavingPost) return;

    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    _isSavingPost = true;

    final result = await _authApi.saveFoodLogPost(
      postData: post.toApiJson(),
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    _isSavingPost = false;

    if (!mounted || result.success) return;

    final recovered = await _refreshIfPostExists(post);
    if (recovered) return;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  bool _isSamePost(_FeedPost a, _FeedPost b) {
    if (a.id.isNotEmpty && b.id.isNotEmpty && a.id == b.id) {
      return true;
    }
    final authorA = a.author.trim();
    final authorB = b.author.trim();
    final contentA = a.content.trim();
    final contentB = b.content.trim();
    if (authorA.isEmpty || authorB.isEmpty || contentA.isEmpty || contentB.isEmpty) {
      return false;
    }
    if (authorA != authorB || contentA != contentB) return false;
    final mediaA = (a.mediaPath ?? '').trim();
    final mediaB = (b.mediaPath ?? '').trim();
    if (mediaA.isEmpty && mediaB.isEmpty) return true;
    return mediaA == mediaB;
  }

  Future<bool> _refreshIfPostExists(_FeedPost post) async {
    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();

    final result = await _authApi.fetchFoodLogData(
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted || !result.success) return false;

    final payload = _FoodLogApiPayload.fromResponse(result.data);
    final posts = <_FeedPost>[
      ...?payload.publicPosts,
      ...?payload.myPosts,
    ];
    if (posts.isEmpty) return false;

    final found = posts.any((entry) => _isSamePost(entry, post));
    if (!found) return false;

    final prefs = await SharedPreferences.getInstance();
    final mediaPosts = _readPublicMediaPosts(
      prefs.getStringList(_kProfileMedia) ?? <String>[],
      author: _profileDisplayName,
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
    );
    if (!mounted) return true;

    setState(() {
      if (payload.publicPosts != null) {
        _publicPosts
          ..clear()
          ..addAll(payload.publicPosts!);
      }
      if (payload.myPosts != null) {
        _myPosts
          ..clear()
          ..addAll(payload.myPosts!);
      }
      _syncProfileMediaPosts(mediaPosts);
    });
    return true;
  }

  Future<void> _toggleLike(int index) async {
    final post = _publicPosts[index];
    var likes = post.likes;
    _Reaction nextReaction = _Reaction.like;

    if (post.reaction == _Reaction.like) {
      nextReaction = _Reaction.none;
      likes = likes > 0 ? likes - 1 : 0;
    } else {
      likes += 1;
    }

    late final _FeedPost updatedPost;
    setState(() {
      updatedPost = post.copyWith(likes: likes, reaction: nextReaction);
      _publicPosts[index] = updatedPost;
    });
    await _savePostToApi(updatedPost);
    if (post.id.isNotEmpty) {
      final token = await AuthSessionStorage.readToken();
      if (token.isNotEmpty) {
        await _authApi.likeFoodLog(
          likeData: <String, dynamic>{'food_log_id': post.id},
          bearerToken: token,
        );
      }
    }
  }

  Future<void> _toggleDislike(int index) async {
    final post = _publicPosts[index];
    var likes = post.likes;
    _Reaction nextReaction = _Reaction.dislike;

    if (post.reaction == _Reaction.dislike) {
      nextReaction = _Reaction.none;
    } else if (post.reaction == _Reaction.like) {
      likes = likes > 0 ? likes - 1 : 0;
    }

    late final _FeedPost updatedPost;
    setState(() {
      updatedPost = post.copyWith(likes: likes, reaction: nextReaction);
      _publicPosts[index] = updatedPost;
    });
    await _savePostToApi(updatedPost);
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

    if (submit != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final reply = _PostReply(
      author: _profileDisplayName,
      minutesAgo: 0,
      text: text,
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
    );

    _FeedPost? updatedPost;
    setState(() {
      if (isPublic) {
        final post = _publicPosts[index];
        updatedPost = post.copyWith(
          replies: <_PostReply>[...post.replies, reply],
        );
        _publicPosts[index] = updatedPost!;
      } else {
        final post = _myPosts[index];
        updatedPost = post.copyWith(
          replies: <_PostReply>[...post.replies, reply],
        );
        _myPosts[index] = updatedPost!;
      }
    });
    if (updatedPost != null) {
      await _savePostToApi(updatedPost!);
      if (updatedPost!.id.isNotEmpty) {
        final token = await AuthSessionStorage.readToken();
        if (token.isNotEmpty) {
          await _authApi.commentFoodLog(
            commentData: <String, dynamic>{
              'food_log_id': updatedPost!.id,
              'comment': text,
            },
            bearerToken: token,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final contentMaxWidth = isDesktop
            ? 520.0
            : isTablet
            ? 460.0
            : 400.0;
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = AppColors.isDark(context);
        final panelColor = isDark
            ? const Color(0xFF171717)
            : const Color(0xFFF2F2F2);
        return Scaffold(
          backgroundColor: const Color(0xFF080808),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'FoodLog',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 28, height: 28),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 70),
                        child: Container(
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 120),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(context),
                                      border: Border.all(
                                        color: AppColors.borderLightFor(
                                          context,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.24 : 0.08,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        _tabButton(
                                          title: 'Public',
                                          selected:
                                              _selectedTab ==
                                              _FeedTab.publicPosts,
                                          onTap: () => setState(
                                            () => _selectedTab =
                                                _FeedTab.publicPosts,
                                          ),
                                        ),
                                        _tabButton(
                                          title: 'My Post',
                                          selected:
                                              _selectedTab == _FeedTab.myPosts,
                                          onTap: () => setState(
                                            () =>
                                                _selectedTab = _FeedTab.myPosts,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    4,
                                    12,
                                    10,
                                  ),
                                  itemCount: _visiblePosts.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final isPublic =
                                        _selectedTab == _FeedTab.publicPosts;
                                    return AnimatedReveal(
                                      delay: Duration(
                                        milliseconds: 130 + ((index % 8) * 30),
                                      ),
                                      child: _PostTile(
                                        post: _visiblePosts[index],
                                        onLike: isPublic
                                            ? () => _toggleLike(index)
                                            : null,
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
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    8,
                                    10,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: AppColors.borderLightFor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _composerController,
                                          decoration: InputDecoration(
                                            hintText: "What's in your mind",
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            filled: true,
                                            fillColor: AppColors.surfaceMuted(
                                              context,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                color: AppColors.borderLightFor(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: BorderSide(
                                                color: AppColors.borderLightFor(
                                                  context,
                                                ),
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
                                            backgroundColor:
                                                colorScheme.primary,
                                            foregroundColor:
                                                colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimary
                  : AppColors.textSecondaryFor(context),
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
    final colorScheme = Theme.of(context).colorScheme;
    final ImageProvider? avatarImage =
        ProfileAvatarResolver.resolveNullable(post.avatarFilePath) ??
        (post.avatarAsset != null ? AssetImage(post.avatarAsset!) : null);

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
                      style: TextStyle(
                        color: AppColors.textPrimaryFor(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              post.author,
              style: TextStyle(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeText,
              style: TextStyle(
                color: AppColors.textMutedFor(context),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          post.content,
          style: TextStyle(
            color: AppColors.textPrimaryFor(context),
            height: 1.32,
            fontSize: 13,
          ),
        ),
        if (post.mediaPath != null && post.mediaPath!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _FeedMediaAttachment(
            mediaPath: post.mediaPath!,
            mediaType: post.mediaType,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              likeLabel,
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '>',
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onReply,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  'Reply',
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
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
                      ? colorScheme.primary
                      : AppColors.textMutedFor(context),
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
                      ? colorScheme.primary
                      : AppColors.textMutedFor(context),
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
    final ImageProvider? avatar = ProfileAvatarResolver.resolveNullable(
      reply.avatarFilePath,
    );
    final initials = reply.author.trim().isEmpty ? 'U' : reply.author[0];
    final timeText = reply.minutesAgo == 0 ? 'now' : '${reply.minutesAgo} min';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.surfaceMuted(context),
          backgroundImage: avatar,
          child: avatar == null
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
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
                    style: TextStyle(
                      color: AppColors.textPrimaryFor(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: AppColors.textMutedFor(context),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reply.text,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimaryFor(context),
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

class _FeedMediaAttachment extends StatelessWidget {
  final String mediaPath;
  final String mediaType;

  const _FeedMediaAttachment({
    required this.mediaPath,
    required this.mediaType,
  });

  Future<void> _openImage(BuildContext context) async {
    final file = File(mediaPath);
    if (!file.existsSync()) return;
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
  }

  void _openVideo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FeedVideoPreviewScreen(mediaPath: mediaPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mediaType == _FeedMediaType.image) {
      final file = File(mediaPath);
      if (!file.existsSync()) return const SizedBox.shrink();
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
      );
    }

    final fileName = mediaPath.split(RegExp(r'[\\/]')).last;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openVideo(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 158,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FileVideoPreview(
                path: mediaPath,
                fit: BoxFit.cover,
                playIconSize: 34,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedVideoPreviewScreen extends StatefulWidget {
  final String mediaPath;

  const _FeedVideoPreviewScreen({required this.mediaPath});

  @override
  State<_FeedVideoPreviewScreen> createState() =>
      _FeedVideoPreviewScreenState();
}

class _FeedVideoPreviewScreenState extends State<_FeedVideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(File(widget.mediaPath));
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
        _loading = false;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _controller == null
            ? const Text(
                'Unable to open video',
                style: TextStyle(color: Colors.white),
              )
            : GestureDetector(
                onTap: _togglePlayback,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
      ),
    );
  }
}

class _FeedPost {
  final String id;
  final String author;
  final int minutesAgo;
  final String? avatarAsset;
  final String? avatarFilePath;
  final String content;
  final int likes;
  final bool isMine;
  final _Reaction reaction;
  final List<_PostReply> replies;
  final String? mediaPath;
  final String mediaType;
  final bool isProfileMedia;

  const _FeedPost({
    required this.id,
    required this.author,
    required this.minutesAgo,
    this.avatarAsset,
    this.avatarFilePath,
    required this.content,
    required this.likes,
    this.isMine = false,
    this.reaction = _Reaction.none,
    this.replies = const <_PostReply>[],
    this.mediaPath,
    this.mediaType = _FeedMediaType.none,
    this.isProfileMedia = false,
  });

  Map<String, dynamic> toApiJson() {
    final reactionLabel = switch (reaction) {
      _Reaction.like => 'like',
      _Reaction.dislike => 'dislike',
      _Reaction.none => 'none',
    };

    return <String, dynamic>{
      'id': id,
      'food_log_id': id,
      'post_id': id,
      'author': author,
      'name': author,
      'content': content,
      'message': content,
      'text': content,
      'likes': likes,
      'like_count': likes,
      'likeCount': likes,
      'reaction': reactionLabel,
      'user_reaction': reactionLabel,
      'userReaction': reactionLabel,
      'minutes_ago': minutesAgo,
      'minutesAgo': minutesAgo,
      'is_mine': isMine,
      'isMine': isMine,
      'replies': replies.map((reply) => reply.toApiJson()).toList(growable: false),
      'visibility': 'public',
      'is_public': true,
      if (avatarFilePath != null && avatarFilePath!.trim().isNotEmpty) ...{
        'avatar': avatarFilePath,
        'avatar_url': avatarFilePath,
        'avatarUrl': avatarFilePath,
      },
      if (mediaPath != null && mediaPath!.trim().isNotEmpty) ...{
        'media': mediaPath,
        'media_path': mediaPath,
        'mediaPath': mediaPath,
        'media_type': mediaType,
        'mediaType': mediaType,
      },
    };
  }

  _FeedPost copyWith({
    String? id,
    String? author,
    int? minutesAgo,
    String? avatarAsset,
    String? avatarFilePath,
    String? content,
    int? likes,
    bool? isMine,
    _Reaction? reaction,
    List<_PostReply>? replies,
    String? mediaPath,
    String? mediaType,
    bool? isProfileMedia,
  }) {
    return _FeedPost(
      id: id ?? this.id,
      author: author ?? this.author,
      minutesAgo: minutesAgo ?? this.minutesAgo,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      avatarFilePath: avatarFilePath ?? this.avatarFilePath,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      isMine: isMine ?? this.isMine,
      reaction: reaction ?? this.reaction,
      replies: replies ?? this.replies,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      isProfileMedia: isProfileMedia ?? this.isProfileMedia,
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

  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'author': author,
      'name': author,
      'minutes_ago': minutesAgo,
      'minutesAgo': minutesAgo,
      'text': text,
      'message': text,
      if (avatarFilePath != null && avatarFilePath!.trim().isNotEmpty) ...{
        'avatar': avatarFilePath,
        'avatar_url': avatarFilePath,
        'avatarUrl': avatarFilePath,
      },
    };
  }
}

class _FoodLogApiPayload {
  final List<_FeedPost>? publicPosts;
  final List<_FeedPost>? myPosts;

  const _FoodLogApiPayload({this.publicPosts, this.myPosts});

  factory _FoodLogApiPayload.fromResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return const _FoodLogApiPayload();
    }

    final containers = _collectContainers(response);
    final publicRaw = _firstRawAcrossMaps(
      containers,
      const <String>[
        'public_posts',
        'publicPosts',
        'public_feed',
        'publicFeed',
      ],
    );
    final myRaw = _firstRawAcrossMaps(
      containers,
      const <String>['my_posts', 'myPosts', 'private_posts', 'privatePosts'],
    );
    final genericRaw = _firstRawAcrossMaps(
      containers,
      const <String>['posts', 'feed', 'foodlog', 'food_log', 'items'],
    );

    final publicPosts = _parsePosts(publicRaw ?? genericRaw);
    final myPosts = _parsePosts(myRaw);
    if (publicPosts == null && myPosts == null) {
      return const _FoodLogApiPayload();
    }

    if (myPosts != null) {
      return _FoodLogApiPayload(publicPosts: publicPosts, myPosts: myPosts);
    }

    final inferredMyPosts = publicPosts
        ?.where((post) => post.isMine)
        .toList(growable: false);
    return _FoodLogApiPayload(
      publicPosts: publicPosts,
      myPosts: inferredMyPosts,
    );
  }

  static List<Map<String, dynamic>> _collectContainers(
    Map<String, dynamic> root,
  ) {
    final result = <Map<String, dynamic>>[root];
    final queue = <Map<String, dynamic>>[root];
    const keys = <String>['data', 'result', 'payload', 'response'];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final key in keys) {
        final nested = _asMap(current[key]);
        if (nested == null) continue;
        result.add(nested);
        queue.add(nested);
      }
    }
    return result;
  }

  static dynamic _firstRawAcrossMaps(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value != null) return value;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<dynamic>? _asList(dynamic value) {
    if (value is List) return value;
    final map = _asMap(value);
    if (map == null) return null;
    for (final key in const <String>['data', 'items', 'results', 'list']) {
      final nested = map[key];
      if (nested is List) return nested;
    }
    return <dynamic>[map];
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    final value = raw?.toString().trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static _Reaction _parseReaction(Map<String, dynamic> json) {
    final liked = _parseBool(json['is_liked'] ?? json['isLiked']);
    final disliked = _parseBool(json['is_disliked'] ?? json['isDisliked']);
    if (liked) return _Reaction.like;
    if (disliked) return _Reaction.dislike;

    final raw = _firstNonEmptyString(
      json,
      const <String>['reaction', 'user_reaction', 'userReaction'],
    );
    if (raw == null) return _Reaction.none;

    final normalized = raw.toLowerCase();
    if (normalized == 'like' || normalized == 'liked') return _Reaction.like;
    if (normalized == 'dislike' || normalized == 'disliked') {
      return _Reaction.dislike;
    }
    return _Reaction.none;
  }

  static String _parseMediaType(Map<String, dynamic> json) {
    final raw = _firstNonEmptyString(
      json,
      const <String>['media_type', 'mediaType', 'type'],
    );
    if (raw == null) return _FeedMediaType.none;
    final normalized = raw.toLowerCase();
    if (normalized.contains('image') || normalized == 'photo') {
      return _FeedMediaType.image;
    }
    return _FeedMediaType.none;
  }

  static List<_FeedPost>? _parsePosts(dynamic raw) {
    final list = _asList(raw);
    if (list == null) return null;

    final posts = list
        .map<_FeedPost?>((item) {
          final json = _asMap(item);
          if (json == null) return null;

          final content = _firstNonEmptyString(
            json,
            const <String>['content', 'message', 'text', 'body', 'post'],
          );
          if (content == null || content.isEmpty) return null;

          final avatar = _firstNonEmptyString(
            json,
            const <String>['avatar', 'avatar_url', 'avatarUrl', 'profile'],
          );
          final mediaPath = _firstNonEmptyString(
            json,
            const <String>['media', 'media_path', 'mediaPath', 'path'],
          );
          final id =
              _firstNonEmptyString(
                json,
                const <String>['id', 'food_log_id', 'post_id', 'log_id'],
              ) ??
              '';

          return _FeedPost(
            id: id,
            author:
                _firstNonEmptyString(
                  json,
                  const <String>['author', 'name', 'username', 'user_name'],
                ) ??
                'User',
            minutesAgo: _parseInt(
              json['minutes_ago'] ??
                  json['minutesAgo'] ??
                  json['minutes'] ??
                  json['time'],
            ),
            avatarFilePath: avatar,
            content: content,
            likes: _parseInt(
              json['likes'] ?? json['like_count'] ?? json['likeCount'],
            ),
            isMine: _parseBool(
              json['is_mine'] ??
                  json['isMine'] ??
                  json['mine'] ??
                  json['my_post'] ??
                  json['myPost'],
            ),
            reaction: _parseReaction(json),
            mediaPath: mediaPath,
            mediaType: mediaPath == null ? _FeedMediaType.none : _parseMediaType(json),
          );
        })
        .whereType<_FeedPost>()
        .toList(growable: false);

    return posts;
  }
}
