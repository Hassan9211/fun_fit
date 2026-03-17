// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/app_section_header.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/getx.dart';
import '../widget/app_pull_to_refresh.dart';
import '../widget/record_with_audio_screen.dart';

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
  static const String _kLocalChallenges = 'local_challenges';
  static const String _kRandomChallenges = 'random_challenges';
  static const String _kChallengeReels = 'challenge_reels_items';
  static const String _kProfileUsername = 'profile_username';

  _ChallengesTab _selectedTab = _ChallengesTab.publicPosts;
  String _profileName = _defaultProfileName;
  String _profileUsername = '';
  String _profileImagePath = '';
  final AuthApiService _authApi = AuthApiService();

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
    ProfileSyncService.changes.addListener(_loadProfileData);
    _loadProfileData();
    _loadChallengesFromApi();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadProfileData);
    super.dispose();
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
    final savedUsername = (prefs.getString(_kProfileUsername) ?? '').trim();
    if (!mounted) return;

    final resolvedName = savedName.isEmpty ? _defaultProfileName : savedName;
    final resolvedImagePath = savedImagePath.isEmpty ? null : savedImagePath;

    setState(() {
      _profileName = resolvedName;
      _profileImagePath = savedImagePath;
      _profileUsername = savedUsername;
      for (var i = 0; i < _myPosts.length; i++) {
        final post = _myPosts[i];
        _myPosts[i] = post.copyWith(
          author: resolvedName,
          avatarFilePath: resolvedImagePath ?? post.avatarFilePath,
        );
      }
    });
  }

  Future<void> _loadChallengesFromApi() async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    final result = await _authApi.fetchChallenges(bearerToken: token);
    if (!mounted || !result.success) return;

    final parsed = _parseChallengesResponse(result.data);
    if (parsed.isEmpty) return;

    final mine = parsed.where((post) => post.isMine).toList();
    setState(() {
      _publicPosts
        ..clear()
        ..addAll(parsed);
      if (mine.isNotEmpty) {
        _myPosts
          ..clear()
          ..addAll(mine);
      }
    });
  }

  List<_ChallengePost> _parseChallengesResponse(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return const <_ChallengePost>[];
    final raw =
        response['items'] ??
        response['data'] ??
        response['results'] ??
        response['challenges'] ??
        response['list'];
    final list = _extractList(raw);
    if (list.isEmpty) return const <_ChallengePost>[];

    final currentName = _profileName.trim().toLowerCase();
    final currentUsername = _normalizeUsername(_profileUsername);

    final parsed = <_ChallengePost>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) continue;
      final map = item.map((k, v) => MapEntry(k.toString(), v));

      final author = _firstNonEmptyString(
        map,
        const <String>[
          'author',
          'user',
          'name',
          'uploader_name',
          'username',
          'user_name',
        ],
      );
      final username = _firstNonEmptyString(
        map,
        const <String>['username', 'user_name', 'handle'],
      );
      final title = _firstNonEmptyString(
        map,
        const <String>['title', 'challenge_name', 'name'],
      );
      final description = _firstNonEmptyString(
        map,
        const <String>['description', 'details', 'body', 'text'],
      );
      final category = _firstNonEmptyString(
        map,
        const <String>['category', 'difficulty', 'level'],
      );
      final fitnessLevel = _firstNonEmptyString(
        map,
        const <String>['fitness_level', 'fitnessLevel', 'level'],
      );
      final mediaPath = _firstNonEmptyString(
        map,
        const <String>[
          'media',
          'media_path',
          'image',
          'image_url',
          'video',
          'video_url',
        ],
      );
      final avatar = _firstNonEmptyString(
        map,
        const <String>[
          'avatar',
          'avatar_url',
          'avatarUrl',
          'profile_image',
          'profileImage',
          'user_avatar',
        ],
      );
      final minutesAgo = _parseInt(
        map['minutes_ago'] ?? map['minutesAgo'] ?? map['time_ago'],
      );
      final likes = _parseInt(
        map['likes'] ??
            map['like_count'] ??
            map['likes_count'] ??
            map['likeCount'],
      );
      final isAccepted = _parseBool(
        map['is_accepted'] ?? map['accepted'] ?? map['isAccepted'],
      );

      final normalizedAuthor = author.toLowerCase();
      final normalizedUsername = _normalizeUsername(username);
      final isMine =
          (currentName.isNotEmpty && normalizedAuthor == currentName) ||
          (currentUsername.isNotEmpty &&
              normalizedUsername == currentUsername) ||
          _parseBool(map['is_mine'] ?? map['isMine'] ?? map['me']);

      final mediaType = _inferMediaType(
        _firstNonEmptyString(map, const <String>['media_type', 'type']),
        mediaPath,
      );

      final idRaw =
          _firstNonEmptyString(map, const <String>['id', 'challenge_id']);
      final id = idRaw.isEmpty ? 'challenge_${i + 1}' : idRaw;

      final replies = _parseReplies(map['comments'] ?? map['replies']);

      final avatarAsset = avatar.startsWith('assets/') ? avatar : null;
      final avatarFilePath = avatarAsset == null && avatar.isNotEmpty
          ? avatar
          : null;

      if (title.trim().isEmpty && description.trim().isEmpty) {
        continue;
      }

      parsed.add(
        _ChallengePost(
          id: id,
          author: author.isEmpty ? _defaultProfileName : author,
          minutesAgo: minutesAgo,
          avatarAsset: avatarAsset,
          avatarFilePath: avatarFilePath,
          title: title.isEmpty ? 'Challenge' : title,
          category: category.isEmpty ? 'General' : category,
          fitnessLevel: fitnessLevel.isEmpty ? 'Beginner' : fitnessLevel,
          description: description.isEmpty ? 'Join this challenge.' : description,
          mediaPath: mediaPath.isEmpty ? null : mediaPath,
          mediaType: mediaType,
          likes: likes,
          isMine: isMine,
          isAccepted: isAccepted,
          replies: replies,
        ),
      );
    }

    return parsed;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final key in const <String>['data', 'items', 'results', 'list']) {
        final nested = raw[key];
        if (nested is List) return nested;
      }
    }
    return const <dynamic>[];
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase().replaceAll('@', '');
  }

  String _firstNonEmptyString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes';
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  _MediaType _inferMediaType(String rawType, String rawPath) {
    final type = rawType.toLowerCase();
    final path = rawPath.toLowerCase();
    if (type.contains('video') ||
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm')) {
      return _MediaType.video;
    }
    if (type.contains('image') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp')) {
      return _MediaType.image;
    }
    return _MediaType.none;
  }

  List<_PostReply> _parseReplies(dynamic raw) {
    if (raw is! List) return const <_PostReply>[];
    final replies = <_PostReply>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.map((k, v) => MapEntry(k.toString(), v));
      final author = _firstNonEmptyString(
        map,
        const <String>['author', 'name', 'user', 'username'],
      );
      final text = _firstNonEmptyString(
        map,
        const <String>['comment', 'text', 'body'],
      );
      if (text.isEmpty) continue;
      final minutesAgo =
          _parseInt(map['minutes_ago'] ?? map['minutesAgo'] ?? map['time_ago']);
      final avatar = _firstNonEmptyString(
        map,
        const <String>['avatar', 'avatar_url', 'avatarUrl'],
      );
      replies.add(
        _PostReply(
          author: author.isEmpty ? 'User' : author,
          minutesAgo: minutesAgo,
          text: text,
          avatarFilePath: avatar.isEmpty ? null : avatar,
        ),
      );
    }
    return replies;
  }

  Future<void> _openProfile() async {
    await Get.toNamed(Routes.profile);
    await _loadProfileData();
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

  Future<void> _toggleLike(String id) async {
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
        (oldPost) => oldPost.copyWith(likes: likes, reaction: nextReaction),
      );
    });
    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      await _authApi.likeChallenge(
        likeData: <String, dynamic>{'challenge_id': id},
        bearerToken: token,
      );
    }
  }

  Future<void> _toggleDislike(String id) async {
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
        (oldPost) => oldPost.copyWith(likes: likes, reaction: nextReaction),
      );
    });
  }

  Future<void> _toggleAccept(String id) async {
    final publicIndex = _publicPosts.indexWhere((post) => post.id == id);
    final myIndex = _myPosts.indexWhere((post) => post.id == id);
    final post =
        publicIndex != -1 ? _publicPosts[publicIndex] : (myIndex != -1 ? _myPosts[myIndex] : null);
    if (post == null) return;

    if (post.isMine || post.author == _profileDisplayName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot accept your own challenge.'),
        ),
      );
      return;
    }

    final willAccept = !post.isAccepted;
    setState(() {
      _updatePostById(
        id,
        (oldPost) => oldPost.copyWith(isAccepted: !oldPost.isAccepted),
      );
    });
    if (willAccept) {
      await _saveAcceptedChallengeToRandom(post);
    }
    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      await _authApi.acceptChallenge(
        data: _buildAcceptChallengePayload(post),
        bearerToken: token,
      );
    }
  }

  Future<void> _openReplyDialog(String id) async {
    final controller = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
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
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
    );

    setState(() {
      _updatePostById(
        id,
        (post) => post.copyWith(replies: <_PostReply>[...post.replies, reply]),
      );
    });
    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      await _authApi.commentOnChallenge(
        commentData: <String, dynamic>{
          'challenge_id': id,
          'comment': text,
        },
        bearerToken: token,
      );
    }
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
      avatarFilePath: _profileImagePath.trim().isEmpty
          ? null
          : _profileImagePath,
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
    await _saveLocalChallenge(draft, includeInRandom: true);
    final token = await AuthSessionStorage.readToken();
    if (token.isNotEmpty) {
      await _authApi.createChallenge(
        data: <String, dynamic>{
          'title': draft.name,
          'description': draft.description,
          'category': draft.category,
          'fitness_level': draft.fitnessLevel,
          'duration': draft.time,
        },
        bearerToken: token,
      );
    }
  }

  Future<void> _saveLocalChallenge(
    _DraftChallenge draft, {
    bool includeInRandom = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (includeInRandom) {
      final payload = <String, dynamic>{
        'title': draft.name,
        'subtitle': draft.description,
        'duration': draft.time,
        'difficulty': draft.category,
        'fitness_level': draft.category,
        'image': draft.mediaPath.isNotEmpty
            ? draft.mediaPath
            : 'assets/images/pushup.jpg',
        'image_url': draft.mediaPath.isNotEmpty
            ? draft.mediaPath
            : 'assets/images/pushup.jpg',
        'progress': 0.0,
      };
      final existing = prefs.getStringList(_kLocalChallenges) ?? <String>[];
      existing.insert(0, jsonEncode(payload));
      await prefs.setStringList(_kLocalChallenges, existing);

      final randomExisting =
          prefs.getStringList(_kRandomChallenges) ?? <String>[];
      randomExisting.removeWhere((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded is Map && decoded['title'] == draft.name;
        } catch (_) {
          return false;
        }
      });
      randomExisting.insert(0, jsonEncode(payload));
      await prefs.setStringList(_kRandomChallenges, randomExisting);
      ProfileSyncService.notifyChanged();
    }

    if (draft.mediaType == _MediaType.video && draft.mediaPath.isNotEmpty) {
      final mediaRaw = prefs.getStringList(_kChallengeReels) ?? <String>[];
      final name = (prefs.getString(_kProfileName) ?? '').trim();
      final username = (prefs.getString(_kProfileUsername) ?? '').trim();
      final mediaPayload = <String, dynamic>{
        'path': draft.mediaPath,
        'type': 'video',
        'likes': 0,
        'dislikes': 0,
        'shares': 0,
        'is_saved': false,
        'is_liked': false,
        'is_disliked': false,
        'uploader_name': name.isEmpty ? _defaultProfileName : name,
        'uploader_username': username,
        'visibility': 'public',
        'source': 'challenge',
      };
      mediaRaw.insert(0, jsonEncode(mediaPayload));
      await prefs.setStringList(_kChallengeReels, mediaRaw);
      ProfileSyncService.notifyChanged();
    }
  }

  String _inferDuration(String description) {
    final match = RegExp(
      r'(\d+)\s*(min|mins|minute|minutes)',
      caseSensitive: false,
    ).firstMatch(description);
    if (match != null) {
      return '${match.group(1)} mins';
    }
    return '10 mins';
  }

  Map<String, dynamic> _buildAcceptChallengePayload(_ChallengePost post) {
    final duration = _inferDuration(post.description);
    final media = (post.mediaPath ?? '').trim();
    final payload = <String, dynamic>{
      'challenge_id': post.id,
      'challengeId': post.id,
      'challenge_name': post.title,
      'title': post.title,
      'name': post.title,
      'level': post.fitnessLevel,
      'fitness_level': post.fitnessLevel,
      'category': post.category,
      'difficulty': post.category,
      'description': post.description,
      'time': duration,
      'duration': duration,
      'media': media.isEmpty ? null : media,
      'media_path': media.isEmpty ? null : media,
      'media_url': media.isEmpty ? null : media,
      'type': 'public',
      'status': 'active',
    };
    payload.removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );
    return payload;
  }

  Future<void> _saveAcceptedChallengeToRandom(_ChallengePost post) async {
    final prefs = await SharedPreferences.getInstance();
    final randomExisting = prefs.getStringList(_kRandomChallenges) ?? <String>[];
    randomExisting.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded is Map && decoded['title'] == post.title;
      } catch (_) {
        return false;
      }
    });

    final payload = <String, dynamic>{
      'title': post.title,
      'subtitle': post.description,
      'duration': _inferDuration(post.description),
      'difficulty': post.category,
      'fitness_level': post.fitnessLevel,
      'image': (post.mediaPath != null && post.mediaPath!.trim().isNotEmpty)
          ? post.mediaPath
          : 'assets/images/pushup.jpg',
      'image_url': (post.mediaPath != null && post.mediaPath!.trim().isNotEmpty)
          ? post.mediaPath
          : 'assets/images/pushup.jpg',
      'progress': 0.0,
    };
    randomExisting.insert(0, jsonEncode(payload));
    await prefs.setStringList(_kRandomChallenges, randomExisting);
    ProfileSyncService.notifyChanged();
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
            ? AppColors.cFF171717
            : AppColors.cFFF2F2F2;
        final avatarProvider = ProfileAvatarResolver.resolve(
          _profileImagePath,
          fallback: const AssetImage('assets/images/alina.jpg'),
        );
        return Scaffold(
          backgroundColor: AppColors.cFF080808,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          floatingActionButton: SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              elevation: 2,
              onPressed: _openAddChallenge,
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const HomeBottomNav(selected: 'Challenges'),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    AppSectionHeader(
                      title: 'Challenges',
                      avatarProvider: avatarProvider,
                      onTapProfile: _openProfile,
                      showAvatar: false,
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
                                              _ChallengesTab.publicPosts,
                                          onTap: () => setState(
                                            () => _selectedTab =
                                                _ChallengesTab.publicPosts,
                                          ),
                                        ),
                                        _tabButton(
                                          title: 'My Post',
                                          selected:
                                              _selectedTab ==
                                              _ChallengesTab.myPosts,
                                          onTap: () => setState(
                                            () => _selectedTab =
                                                _ChallengesTab.myPosts,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    AppPullToRefresh(
                                      onRefresh: () async {
                                        await _loadProfileData();
                                        await _loadChallengesFromApi();
                                      },
                                      child: ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          6,
                                          12,
                                          92,
                                        ),
                                        itemCount: _visiblePosts.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final post = _visiblePosts[index];
                                          final isPublic =
                                              _selectedTab ==
                                              _ChallengesTab.publicPosts;
                                          return AnimatedReveal(
                                            delay: Duration(
                                              milliseconds:
                                                  130 + ((index % 8) * 32),
                                            ),
                                            child: _ChallengePostTile(
                                              post: post,
                                              onLike: isPublic
                                                  ? () => _toggleLike(post.id)
                                                  : null,
                                              onDislike: isPublic
                                                  ? () => _toggleDislike(post.id)
                                                  : null,
                                              onReply: () =>
                                                  _openReplyDialog(post.id),
                                              onAccept: () =>
                                                  _toggleAccept(post.id),
                                            ),
                                          );
                                        },
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
      barrierColor: Colors.transparent,
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
      if (!mounted) return;
      final nav = Navigator.of(context);
      final XFile? file = isVideo
          ? null
          : await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 85,
            );
        final videoPath = isVideo
            ? await nav.push<String>(
                MaterialPageRoute(
                  builder: (_) =>
                      RecordWithAudioScreen(challengeName: _nameController.text),
                ),
              )
            : null;
      if (!mounted) return;
      if (!isVideo && file == null) return;
      if (isVideo && (videoPath == null || videoPath.isEmpty)) return;
      setState(() {
        _selectedMediaPath = isVideo ? videoPath! : file!.path;
        _selectedMediaType = isVideo ? _MediaType.video : _MediaType.image;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textMutedFor(context),
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppColors.surfaceMuted(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: AppColors.borderLightFor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.1),
      ),
    );
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
        final cardMargin = isCompact ? 6.0 : 8.0;

        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    _PageHeader(
                      title: 'Add Challenge',
                      onBack: () => Navigator.of(context).pop(),
                      topPadding: headerTopPadding,
                      bottomPadding: headerBottomPadding,
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
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                            child: AnimatedReveal(
                              delay: const Duration(milliseconds: 120),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    decoration: _inputDecoration(
                                      context,
                                      'Challenge Name',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _timeController,
                                    decoration: _inputDecoration(
                                      context,
                                      'Time',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    decoration: _inputDecoration(
                                      context,
                                      'Select Category',
                                    ),
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
                                    decoration: _inputDecoration(
                                      context,
                                      'Fitness Level',
                                    ),
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
                                      foregroundColor:
                                          AppColors.textSecondaryFor(context),
                                      side: BorderSide(
                                        color: AppColors.borderLightFor(
                                          context,
                                        ),
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.file_upload_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _selectedMediaPath.isEmpty
                                          ? 'Upload Image / Video'
                                          : (_selectedMediaType ==
                                                    _MediaType.video
                                                ? 'Video Selected'
                                                : 'Image Selected'),
                                    ),
                                  ),
                                  if (_selectedMediaPath.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedMediaPath
                                          .split(RegExp(r'[\\/]'))
                                          .last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondaryFor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _descriptionController,
                                    maxLines: 4,
                                    decoration: _inputDecoration(
                                      context,
                                      'Discription',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final double topPadding;
  final double bottomPadding;

  const _PageHeader({
    required this.title,
    required this.onBack,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 360;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(18),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surface(context),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 17 : 17,
                ),
              ),
            ),
            SizedBox(width: isCompact ? 20 : 28),
          ],
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
              backgroundColor: AppColors.cFFF4D1D8,
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
            post.title.trim().isEmpty ? 'Challenge' : post.title,
            style: TextStyle(
              color: AppColors.textPrimaryFor(context),
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
          style: TextStyle(
            color: AppColors.textPrimaryFor(context),
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
            const SizedBox(width: 8),
            InkWell(
              onTap: onAccept,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Text(
                  post.isAccepted ? 'Accepted' : 'Accept',
                  style: TextStyle(
                    color: post.isAccepted
                        ? colorScheme.primary
                        : AppColors.textSecondaryFor(context),
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

class _DetailChip extends StatelessWidget {
  final String label;

  const _DetailChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cFFEBF9F0,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cFF2E7D32,
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

  const _AttachedMediaView({required this.mediaPath, required this.mediaType});

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
      return _missingMediaLabel(context);
    }

    if (mediaType == _MediaType.video) {
      final fileName = mediaPath.split(RegExp(r'[\\/]')).last;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 24,
              color: AppColors.textSecondaryFor(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryFor(context),
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

  Widget _missingMediaLabel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Text(
        'Media attached',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondaryFor(context),
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
