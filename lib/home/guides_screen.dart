import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../widget/app_section_header.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

enum _GuidesMainTab { forYou, explore, chat }

enum _ChatTopic { food, challenge }

enum _DiscussionReaction { none, like, dislike }

enum _InviteNotificationStatus { pending, accepted, declined }

class _GuideVideoItem {
  final String title;
  final String videoPath;
  final String imagePath;
  final String meta;

  const _GuideVideoItem({
    required this.title,
    required this.videoPath,
    required this.imagePath,
    required this.meta,
  });
}

const List<_GuideVideoItem> _fallbackGuideVideoPlaylist = <_GuideVideoItem>[
  _GuideVideoItem(
    title: 'Lower Body Training',
    videoPath: 'assets/videos/LowerBodyTraning.mp4',
    imagePath: 'assets/images/pilates.jpg',
    meta: '5 Min',
  ),
  _GuideVideoItem(
    title: 'Hand Training',
    videoPath: 'assets/videos/HandTraning.mp4',
    imagePath: 'assets/images/weightlifting.jpg',
    meta: '4 Min',
  ),
  _GuideVideoItem(
    title: 'Challenge Tutorial',
    videoPath: 'assets/videos/ChallangeTetorial.mp4',
    imagePath: 'assets/images/yoga.jpg',
    meta: 'Tutorial',
  ),
];

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static const String _kProfileImagePath = 'profile_image_path';
  String _profileImagePath = '';
  _GuidesMainTab _activeTab = _GuidesMainTab.forYou;
  _ChatTopic _activeTopic = _ChatTopic.food;
  final AuthApiService _authApi = AuthApiService();
  List<_GuideVideoItem> _guideVideoPlaylist =
      List<_GuideVideoItem>.from(_fallbackGuideVideoPlaylist);
  final List<_InviteNotification> _inviteNotifications =
      <_InviteNotification>[
        const _InviteNotification(
          id: 'invite_1',
          senderName: 'Angelina',
          roomName: 'Body Weight',
          ago: '8h',
        ),
      ];

  final List<_DiscussionPost> _posts = <_DiscussionPost>[
    const _DiscussionPost(
      id: 'food_1',
      name: 'Marsha Fisher',
      ago: '12 min',
      message:
          'Sharing a high-protein breakfast idea: boiled eggs, avocado toast, and Greek yogurt for a clean start.',
      likes: 2,
      type: _ChatTopic.food,
      avatar: 'assets/images/nora.jpg',
    ),
    const _DiscussionPost(
      id: 'food_2',
      name: 'Dianne Russell',
      ago: '18 min',
      message:
          'If your goal is fat loss, keep dinner lighter and add more fiber, salad, and grilled protein.',
      likes: 4,
      type: _ChatTopic.food,
      avatar: 'assets/images/alina.jpg',
    ),
    const _DiscussionPost(
      id: 'challenge_1',
      name: 'Coach Nora',
      ago: '10 min',
      message:
          '7-Day Push-Up Challenge: complete 3 sets daily and post your progress in the room.',
      likes: 6,
      type: _ChatTopic.challenge,
      avatar: 'assets/images/tammana.jpg',
      isAccepted: false,
    ),
    const _DiscussionPost(
      id: 'challenge_2',
      name: 'Alex Reid',
      ago: '22 min',
      message:
          'Core Burner Challenge: hold a plank for 45 seconds x 4 rounds. Accept if you are in.',
      likes: 3,
      type: _ChatTopic.challenge,
      avatar: 'assets/images/alina.jpg',
      isAccepted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ProfileSyncService.changes.addListener(_loadProfileImage);
    _loadProfileImage();
    _loadGuides();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadProfileImage);
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = (prefs.getString(_kProfileImagePath) ?? '').trim();
    if (!mounted) return;
    setState(() => _profileImagePath = savedPath);
  }

  Future<void> _loadGuides() async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    final result = await _authApi.fetchGuides(bearerToken: token);
    if (!mounted || !result.success) return;
    final items = _parseGuides(result.data);
    if (items.isEmpty) return;
    setState(() => _guideVideoPlaylist = items);
  }

  List<_GuideVideoItem> _parseGuides(Map<String, dynamic>? response) {
    if (response == null) return const <_GuideVideoItem>[];
    final raw = response['items'] ?? response['data'] ?? response['results'];
    final list = raw is List ? raw : (raw == null ? [] : [raw]);
    return list
        .map<_GuideVideoItem?>((item) {
          if (item is! Map) return null;
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          final title = (map['title'] ?? map['name'] ?? '').toString().trim();
          final videoPath =
              (map['video_url'] ?? map['video'] ?? map['videoPath'] ?? '')
                  .toString()
                  .trim();
          final imagePath =
              (map['thumbnail_url'] ??
                      map['image_url'] ??
                      map['image'] ??
                      map['imagePath'] ??
                      '')
                  .toString()
                  .trim();
          final meta = (map['meta'] ??
                  map['duration'] ??
                  map['duration_text'] ??
                  map['durationText'] ??
                  '')
              .toString()
              .trim();
          if (title.isEmpty || videoPath.isEmpty || imagePath.isEmpty) {
            return null;
          }
          return _GuideVideoItem(
            title: title,
            videoPath: videoPath,
            imagePath: imagePath,
            meta: meta.isEmpty ? '5 Min' : meta,
          );
        })
        .whereType<_GuideVideoItem>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDark = AppColors.isDark(context);
    final contentWidth = width >= 1000
        ? 520.0
        : width >= 700
        ? 460.0
        : 400.0;
    final avatarProvider = ProfileAvatarResolver.resolve(
      _profileImagePath,
      fallback: const AssetImage('assets/images/alina.jpg'),
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050505)
          : const Color(0xFF080808),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                AppSectionHeader(
                  title: 'Guides',
                  avatarProvider: avatarProvider,
                  onTapProfile: () async {
                    await Get.toNamed(Routes.profile);
                    await _loadProfileImage();
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF121212)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: _GuidesTabs(
                            selected: _activeTab,
                            onChanged: (tab) =>
                                setState(() => _activeTab = tab),
                          ),
                        ),
                        Expanded(child: _buildBody()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 42,
        height: 42,
        child: FloatingActionButton(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 2,
          onPressed: () {},
          child: Icon(
            Icons.add,
            color: AppColors.textPrimaryFor(context),
            size: 20,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const HomeBottomNav(selected: 'Guides'),
    );
  }

  Widget _buildBody() {
    if (_activeTab == _GuidesMainTab.forYou) {
      return _ForYouTab(playlist: _guideVideoPlaylist);
    }
    if (_activeTab == _GuidesMainTab.explore) {
      return _ExploreTab(
        posts: _posts,
        onLike: _toggleLike,
        onDislike: _toggleDislike,
        onReply: _openReplyDialog,
      );
    }
    return _ChatTab(
      selectedTopic: _activeTopic,
      onTopicChanged: (topic) => setState(() => _activeTopic = topic),
      unreadInviteCount: _inviteNotifications
          .where((notification) => !notification.isRead)
          .length,
      onOpenNotifications: _openInviteNotifications,
      posts: _posts
          .where((e) => e.type == _activeTopic)
          .toList(growable: false),
      onLike: _toggleLike,
      onDislike: _toggleDislike,
      onReply: _openReplyDialog,
      onAccept: _toggleAccept,
    );
  }

  void _updatePostById(
    String id,
    _DiscussionPost Function(_DiscussionPost) updater,
  ) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index == -1) return;
    _posts[index] = updater(_posts[index]);
  }

  void _toggleLike(String id) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    final post = _posts[index];
    var likes = post.likes;
    var nextReaction = _DiscussionReaction.like;

    if (post.reaction == _DiscussionReaction.like) {
      likes = likes > 0 ? likes - 1 : 0;
      nextReaction = _DiscussionReaction.none;
    } else if (post.reaction == _DiscussionReaction.dislike) {
      nextReaction = _DiscussionReaction.like;
      likes += 1;
    } else {
      likes += 1;
    }

    setState(() {
      _updatePostById(
        id,
        (old) => old.copyWith(likes: likes, reaction: nextReaction),
      );
    });
  }

  void _toggleDislike(String id) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    final post = _posts[index];
    var likes = post.likes;
    var nextReaction = _DiscussionReaction.dislike;

    if (post.reaction == _DiscussionReaction.dislike) {
      nextReaction = _DiscussionReaction.none;
    } else if (post.reaction == _DiscussionReaction.like) {
      likes = likes > 0 ? likes - 1 : 0;
    }

    setState(() {
      _updatePostById(
        id,
        (old) => old.copyWith(likes: likes, reaction: nextReaction),
      );
    });
  }

  Future<void> _openReplyDialog(String id) async {
    final controller = TextEditingController();
    final shouldReply = await showDialog<bool>(
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

    if (shouldReply != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _updatePostById(
        id,
        (old) => old.copyWith(
          replies: <_DiscussionReply>[
            ...old.replies,
            _DiscussionReply(author: 'You', text: text),
          ],
        ),
      );
    });
  }

  void _toggleAccept(String id) {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    setState(() {
      _updatePostById(id, (old) => old.copyWith(isAccepted: !old.isAccepted));
    });
  }

  Future<void> _openInviteNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GuideInviteNotificationsScreen(
          notifications: List<_InviteNotification>.from(_inviteNotifications),
          onChanged: _syncInviteNotifications,
        ),
      ),
    );
  }

  void _syncInviteNotifications(List<_InviteNotification> notifications) {
    if (!mounted) return;
    setState(() {
      _inviteNotifications
        ..clear()
        ..addAll(notifications);
    });
  }
}

class _DiscussionPost {
  final String id;
  final String name;
  final String ago;
  final String message;
  final int likes;
  final _ChatTopic type;
  final String avatar;
  final _DiscussionReaction reaction;
  final List<_DiscussionReply> replies;
  final bool isAccepted;

  const _DiscussionPost({
    required this.id,
    required this.name,
    required this.ago,
    required this.message,
    required this.likes,
    required this.type,
    required this.avatar,
    this.reaction = _DiscussionReaction.none,
    this.replies = const <_DiscussionReply>[],
    this.isAccepted = false,
  });

  _DiscussionPost copyWith({
    int? likes,
    _DiscussionReaction? reaction,
    List<_DiscussionReply>? replies,
    bool? isAccepted,
  }) {
    return _DiscussionPost(
      id: id,
      name: name,
      ago: ago,
      message: message,
      likes: likes ?? this.likes,
      type: type,
      avatar: avatar,
      reaction: reaction ?? this.reaction,
      replies: replies ?? this.replies,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}

class _DiscussionReply {
  final String author;
  final String text;

  const _DiscussionReply({required this.author, required this.text});
}

class _InviteNotification {
  final String id;
  final String senderName;
  final String roomName;
  final String ago;
  final bool isRead;
  final _InviteNotificationStatus status;

  const _InviteNotification({
    required this.id,
    required this.senderName,
    required this.roomName,
    required this.ago,
    this.isRead = false,
    this.status = _InviteNotificationStatus.pending,
  });

  _InviteNotification copyWith({
    bool? isRead,
    _InviteNotificationStatus? status,
  }) {
    return _InviteNotification(
      id: id,
      senderName: senderName,
      roomName: roomName,
      ago: ago,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}

class _GuidesTabs extends StatelessWidget {
  final _GuidesMainTab selected;
  final ValueChanged<_GuidesMainTab> onChanged;

  const _GuidesTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'For You',
              selected: selected == _GuidesMainTab.forYou,
              onTap: () => onChanged(_GuidesMainTab.forYou),
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'Explore',
              selected: selected == _GuidesMainTab.explore,
              onTap: () => onChanged(_GuidesMainTab.explore),
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'Chat',
              selected: selected == _GuidesMainTab.chat,
              onTap: () => onChanged(_GuidesMainTab.chat),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFFF3F4F6) : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? (isDark ? Colors.black : Colors.white)
                : AppColors.textPrimaryFor(context),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _ForYouTab extends StatelessWidget {
  final List<_GuideVideoItem> playlist;

  const _ForYouTab({required this.playlist});

  void _openPlayer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GuidesVideoPlayerScreen(
          playlist: playlist.isEmpty ? _fallbackGuideVideoPlaylist : playlist,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items =
        playlist.isEmpty ? _fallbackGuideVideoPlaylist : playlist;
    final firstTwo = items.take(2).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      children: [
        const _SectionHeading(title: 'Recommended Meal'),
        const SizedBox(height: 8),
        const _MediaCard(
          imagePath: 'assets/images/nutbutter.jpg',
          title: 'Nut Butter Toast With Boiled Eggs',
          subtitle: '1648kcl',
          height: 126,
        ),
        const SizedBox(height: 14),
        const _SectionHeading(title: 'Workout Videos'),
        const SizedBox(height: 8),
        _WorkoutStrip(
          items: firstTwo,
          onOpenVideo: (index) => _openPlayer(context, index),
        ),
        const SizedBox(height: 14),
        const _MutedSectionLabel(label: 'Challenge Tutorial Guide'),
        const SizedBox(height: 8),
        if (items.length > 2)
          _MediaCard(
            imagePath: items[2].imagePath,
            videoPath: items[2].videoPath,
            title: items[2].title,
            subtitle: items[2].meta,
            height: 104,
            showPlay: true,
            onTap: () => _openPlayer(context, 2),
          )
        else
          _MediaCard(
            imagePath: 'assets/images/yoga.jpg',
            videoPath: 'assets/videos/ChallangeTetorial.mp4',
            title: 'Challenge Tutorial',
            subtitle: '',
            height: 104,
            showPlay: true,
            onTap: () => _openPlayer(context, 2),
          ),
      ],
    );
  }
}

class _MutedSectionLabel extends StatelessWidget {
  final String label;

  const _MutedSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Text(
      label,
      style: TextStyle(
        color: isDark ? const Color(0xFFB5B5B5) : const Color(0xFF707070),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFB5B5B5) : const Color(0xFF707070),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'View all',
          style: TextStyle(
            color: isDark ? const Color(0xFF8B8B8B) : const Color(0xFFA7A7A7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkoutStrip extends StatelessWidget {
  final List<_GuideVideoItem> items;
  final ValueChanged<int> onOpenVideo;

  const _WorkoutStrip({required this.items, required this.onOpenVideo});

  @override
  Widget build(BuildContext context) {
    final list = items.isEmpty ? _fallbackGuideVideoPlaylist : items;
    return SizedBox(
      height: 114,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...list.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(right: index == list.length - 1 ? 0 : 8),
              child: _WorkoutVideoCard(
                title: item.title,
                imagePath: item.imagePath,
                videoPath: item.videoPath,
                minutes: item.meta,
                kcal: '500',
                onTap: () => onOpenVideo(index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String imagePath;
  final String? videoPath;
  final String title;
  final String subtitle;
  final double height;
  final bool showPlay;
  final VoidCallback? onTap;

  const _MediaCard({
    required this.imagePath,
    this.videoPath,
    required this.title,
    required this.subtitle,
    required this.height,
    this.showPlay = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: videoPath == null
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : _AssetVideoBackdrop(
                          videoPath: videoPath!,
                          imagePath: imagePath,
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.76),
                          Colors.black.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showPlay)
                  const Positioned.fill(
                    child: Center(
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xD7000000),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE6E6E6),
                            fontSize: 10.5,
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
  }
}

class _WorkoutVideoCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String? videoPath;
  final String minutes;
  final String kcal;
  final VoidCallback? onTap;

  const _WorkoutVideoCard({
    required this.title,
    required this.imagePath,
    this.videoPath,
    required this.minutes,
    required this.kcal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return SizedBox(
      width: 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: videoPath == null
                      ? Image.asset(imagePath, fit: BoxFit.cover)
                      : _AssetVideoBackdrop(
                          videoPath: videoPath!,
                          imagePath: imagePath,
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.76),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: 8,
                  child: Text(
                    title,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      _MiniPill(label: minutes),
                      const Spacer(),
                      _MiniPill(label: kcal),
                      const SizedBox(width: 5),
                      const CircleAvatar(
                        radius: 11,
                        backgroundColor: Color(0xCC000000),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
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
    );
  }
}

class _AssetVideoBackdrop extends StatefulWidget {
  final String videoPath;
  final String imagePath;

  const _AssetVideoBackdrop({required this.videoPath, required this.imagePath});

  @override
  State<_AssetVideoBackdrop> createState() => _AssetVideoBackdropState();
}

class _AssetVideoBackdropState extends State<_AssetVideoBackdrop> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final controller = VideoPlayerController.asset(
      widget.videoPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Image.asset(widget.imagePath, fit: BoxFit.cover);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _GuidesVideoPlayerScreen extends StatefulWidget {
  final List<_GuideVideoItem> playlist;
  final int initialIndex;

  const _GuidesVideoPlayerScreen({
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<_GuidesVideoPlayerScreen> createState() =>
      _GuidesVideoPlayerScreenState();
}

class _GuidesVideoPlayerScreenState extends State<_GuidesVideoPlayerScreen> {
  VideoPlayerController? _controller;
  late int _currentIndex;
  bool _isLoading = true;
  bool _isMuted = true;
  int _loadToken = 0;

  _GuideVideoItem get _currentItem => widget.playlist[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex < 0
        ? 0
        : (widget.initialIndex >= widget.playlist.length
              ? widget.playlist.length - 1
              : widget.initialIndex);
    _loadVideo(_currentIndex);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  void _onVideoTick() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadVideo(int index) async {
    final token = ++_loadToken;
    final previous = _controller;
    final controller = VideoPlayerController.asset(
      widget.playlist[index].videoPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isLoading = true;
      });
    }

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(_isMuted ? 0 : 1);
      controller.addListener(_onVideoTick);
      await controller.play();
    } catch (_) {
      controller.removeListener(_onVideoTick);
      await controller.dispose();
      if (mounted && token == _loadToken) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (!mounted || token != _loadToken) {
      await controller.dispose();
      return;
    }

    await previous?.pause();
    previous?.removeListener(_onVideoTick);
    await previous?.dispose();

    setState(() {
      _controller = controller;
      _isLoading = false;
    });
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    _isMuted = !_isMuted;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(_isMuted ? 0 : 1);
    }
    if (mounted) setState(() {});
  }

  Future<void> _playNext() async {
    final nextIndex = (_currentIndex + 1) % widget.playlist.length;
    await _loadVideo(nextIndex);
  }

  Future<void> _playPrevious() async {
    final previousIndex =
        (_currentIndex - 1 + widget.playlist.length) % widget.playlist.length;
    await _loadVideo(previousIndex);
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final controller = _controller;
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;
    final hasVideo = controller != null && controller.value.isInitialized;
    final sliderMax = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final sliderValue = hasVideo
        ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050505) : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Media Player',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: hasVideo
                        ? controller.value.aspectRatio
                        : 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasVideo)
                          ColoredBox(
                            color: Colors.black,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: controller.value.size.width,
                                height: controller.value.size.height,
                                child: VideoPlayer(controller),
                              ),
                            ),
                          )
                        else
                          Image.asset(
                            _currentItem.imagePath,
                            fit: BoxFit.cover,
                          ),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentItem.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentItem.meta,
                  style: const TextStyle(
                    color: Color(0xFFB8B8B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.12),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 0,
                    max: sliderMax,
                    onChanged: hasVideo
                        ? (value) {
                            controller.seekTo(
                              Duration(milliseconds: value.round()),
                            );
                            setState(() {});
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PlayerControlButton(
                        icon: Icons.skip_previous_rounded,
                        onTap: _playPrevious,
                      ),
                      _PlayerControlButton(
                        icon: controller?.value.isPlaying == true
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        isPrimary: true,
                        onTap: _togglePlayback,
                      ),
                      _PlayerControlButton(
                        icon: Icons.skip_next_rounded,
                        onTap: _playNext,
                      ),
                      _PlayerControlButton(
                        icon: _isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: _toggleMute,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...List<Widget>.generate(widget.playlist.length, (index) {
                  final item = widget.playlist[index];
                  final selected = index == _currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _loadVideo(index),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.24)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 72,
                                height: 52,
                                child: Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.meta,
                                    style: const TextStyle(
                                      color: Color(0xFFB8B8B8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              selected
                                  ? Icons.equalizer_rounded
                                  : Icons.play_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _PlayerControlButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: isPrimary ? 56 : 44,
        height: isPrimary ? 56 : 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white
              : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary
                ? Colors.white
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.black : Colors.white,
          size: isPrimary ? 30 : 22,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.66)
            : Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  final List<_DiscussionPost> posts;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onDislike;
  final ValueChanged<String> onReply;

  const _ExploreTab({
    required this.posts,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      itemCount: posts.length,
      itemBuilder: (context, index) => _DiscussionCard(
        post: posts[index],
        onLike: () => onLike(posts[index].id),
        onDislike: () => onDislike(posts[index].id),
        onReply: () => onReply(posts[index].id),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final _ChatTopic selectedTopic;
  final ValueChanged<_ChatTopic> onTopicChanged;
  final int unreadInviteCount;
  final VoidCallback onOpenNotifications;
  final List<_DiscussionPost> posts;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onDislike;
  final ValueChanged<String> onReply;
  final ValueChanged<String> onAccept;

  const _ChatTab({
    required this.selectedTopic,
    required this.onTopicChanged,
    required this.unreadInviteCount,
    required this.onOpenNotifications,
    required this.posts,
    required this.onLike,
    required this.onDislike,
    required this.onReply,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _TopicChip(
                  label: 'Food',
                  selected: selectedTopic == _ChatTopic.food,
                  onTap: () => onTopicChanged(_ChatTopic.food),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TopicChip(
                  label: 'Challenge',
                  selected: selectedTopic == _ChatTopic.challenge,
                  onTap: () => onTopicChanged(_ChatTopic.challenge),
                ),
              ),
              const SizedBox(width: 10),
              _ChatNotificationButton(
                unreadCount: unreadInviteCount,
                onTap: onOpenNotifications,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
            itemCount: posts.length,
            itemBuilder: (context, index) => _DiscussionCard(
              post: posts[index],
              onLike: () => onLike(posts[index].id),
              onDislike: () => onDislike(posts[index].id),
              onReply: () => onReply(posts[index].id),
              onAccept: posts[index].type == _ChatTopic.challenge
                  ? () => onAccept(posts[index].id)
                  : null,
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _GuidesChatRoomScreen(post: posts[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatNotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatNotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLightFor(context)),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    width: 1.1,
                  ),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFFF3F4F6) : Colors.black)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.3,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.black : Colors.white)
                : AppColors.textPrimaryFor(context),
          ),
        ),
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final _DiscussionPost post;
  final VoidCallback? onOpen;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onReply;
  final VoidCallback? onAccept;

  const _DiscussionCard({
    required this.post,
    this.onOpen,
    this.onLike,
    this.onDislike,
    this.onReply,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final replyLabel = post.replies.isEmpty
        ? 'Reply'
        : '${post.replies.length} Replies';
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLightFor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: AssetImage(post.avatar),
                ),
                const SizedBox(width: 10),
                Text(
                  post.name,
                  style: TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  post.ago,
                  style: TextStyle(
                    fontSize: 10.2,
                    color: AppColors.textMutedFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: AppColors.textMutedFor(context),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              post.message,
              style: TextStyle(
                fontSize: 12.6,
                height: 1.3,
                color: AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  '${post.likes} Likes',
                  style: TextStyle(
                    fontSize: 10.2,
                    color: AppColors.textMutedFor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onReply,
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    replyLabel,
                    style: TextStyle(
                      fontSize: 10.2,
                      color: AppColors.textMutedFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onAccept != null) ...[
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: onAccept,
                    borderRadius: BorderRadius.circular(5),
                    child: Text(
                      post.isAccepted ? 'Accepted' : 'Accept',
                      style: TextStyle(
                        fontSize: 10.2,
                        color: post.isAccepted
                            ? const Color(0xFF15803D)
                            : AppColors.textMutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 14,
                    color: post.reaction == _DiscussionReaction.like
                        ? AppColors.textPrimaryFor(context)
                        : AppColors.textMutedFor(context),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDislike,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    Icons.thumb_down_alt_outlined,
                    size: 14,
                    color: post.reaction == _DiscussionReaction.dislike
                        ? const Color(0xFFB42318)
                        : AppColors.textMutedFor(context),
                  ),
                ),
              ],
            ),
            if (post.replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...post.replies.map(
                (reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 10.8,
                        color: AppColors.textSecondaryFor(context),
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: '${reply.author}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryFor(context),
                          ),
                        ),
                        TextSpan(text: reply.text),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuidesChatRoomScreen extends StatefulWidget {
  final _DiscussionPost post;

  const _GuidesChatRoomScreen({required this.post});

  @override
  State<_GuidesChatRoomScreen> createState() => _GuidesChatRoomScreenState();
}

class _GuidesChatRoomScreenState extends State<_GuidesChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AuthApiService _authApi = AuthApiService();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'Hello sir, Good Morning',
      time: '09:30 am',
      mine: true,
    ),
    const _ChatMessage(
      text: 'Morning, Can i help you ?',
      time: '09:31 am',
      mine: false,
    ),
    const _ChatMessage(
      text:
          "Sure! First, can you tell me about your daily routine and eating habits? That will help me suggest something.",
      time: '09:32 am',
      mine: true,
    ),
    const _ChatMessage(
      text: 'Oh yes, please send your body weight here',
      time: '09:33 am',
      mine: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, time: 'Now', mine: true));
      _messageController.clear();
    });
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    await _authApi.sendMessage(
      messageData: <String, dynamic>{
        'message': text,
        'text': text,
        'room': widget.post.id,
        'room_id': widget.post.id,
      },
      bearerToken: token,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101010)
          : const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        foregroundColor: AppColors.textPrimaryFor(context),
        titleSpacing: 0,
        title: Text(
          '${widget.post.name} Room',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InviteFriendScreen()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFF3F3F3),
              foregroundColor: AppColors.textPrimaryFor(context),
              minimumSize: const Size(54, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Invite',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _ChatBubble(msg: _messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D1D1D)
                          : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderLightFor(context),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Write your massage',
                        hintStyle: TextStyle(
                          color: AppColors.textMutedFor(context),
                          fontSize: 11,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textPrimaryFor(context),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFFF3F4F6)
                          : Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage msg;

  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 235),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          decoration: BoxDecoration(
            color: msg.mine
                ? (isDark ? const Color(0xFF173123) : const Color(0xFFE5F5E8))
                : (isDark ? const Color(0xFF222222) : const Color(0xFFE8E8E8)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: TextStyle(
                  fontSize: 10.2,
                  color: AppColors.textPrimaryFor(context),
                  height: 1.24,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  msg.time,
                  style: TextStyle(
                    fontSize: 8.8,
                    color: AppColors.textMutedFor(context),
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

class _ChatMessage {
  final String text;
  final String time;
  final bool mine;

  const _ChatMessage({
    required this.text,
    required this.time,
    required this.mine,
  });
}

class _GuideInviteNotificationsScreen extends StatefulWidget {
  final List<_InviteNotification> notifications;
  final ValueChanged<List<_InviteNotification>> onChanged;

  const _GuideInviteNotificationsScreen({
    required this.notifications,
    required this.onChanged,
  });

  @override
  State<_GuideInviteNotificationsScreen> createState() =>
      _GuideInviteNotificationsScreenState();
}

class _GuideInviteNotificationsScreenState
    extends State<_GuideInviteNotificationsScreen> {
  late List<_InviteNotification> _notifications;

  int get _unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  @override
  void initState() {
    super.initState();
    _notifications = List<_InviteNotification>.from(widget.notifications);
  }

  void _notifyParent() {
    widget.onChanged(List<_InviteNotification>.from(_notifications));
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList(growable: false);
    });
    _notifyParent();
  }

  void _updateStatus(String id, _InviteNotificationStatus status) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;

    setState(() {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        status: status,
      );
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Notification',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 0),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'All',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_notifications.length}',
                            style: const TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _unreadCount == 0 ? null : _markAllAsRead,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF344054),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 35,
                    height: 2.2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE4E7EC)),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 22, color: Color(0xFFE4E7EC)),
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _InviteNotificationCard(
                            notification: notification,
                            onAccept:
                                notification.status ==
                                    _InviteNotificationStatus.pending
                                ? () => _updateStatus(
                                    notification.id,
                                    _InviteNotificationStatus.accepted,
                                  )
                                : null,
                            onDecline:
                                notification.status ==
                                    _InviteNotificationStatus.pending
                                ? () => _updateStatus(
                                    notification.id,
                                    _InviteNotificationStatus.declined,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteNotificationCard extends StatelessWidget {
  final _InviteNotification notification;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _InviteNotificationCard({
    required this.notification,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final status = notification.status;
    final statusColor = status == _InviteNotificationStatus.accepted
        ? const Color(0xFF067647)
        : const Color(0xFFB42318);
    final statusLabel = status == _InviteNotificationStatus.accepted
        ? 'Invitation accepted'
        : 'Invitation declined';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? const Color(0xFFD0D5DD)
                    : const Color(0xFF101828),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Invitation',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              notification.ago,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: Color(0xFF667085),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            '${notification.senderName} invite you to join "${notification.roomName}"\nroom',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11.4,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: status == _InviteNotificationStatus.pending
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF344054),
                            side: const BorderSide(color: Color(0xFFD0D5DD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: status == _InviteNotificationStatus.accepted
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFEF3F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: status == _InviteNotificationStatus.accepted
                          ? const Color(0xFFA6F4C5)
                          : const Color(0xFFFDA29B),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class InviteFriendScreen extends StatelessWidget {
  const InviteFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101010)
          : const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Invite a Friend',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: const [
          _SearchBox(),
          SizedBox(height: 10),
          _InviteTile(name: 'Marsha Fisher'),
          _InviteTile(name: 'Marsha Fisher'),
          _InviteTile(name: 'Marsha Fisher'),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1D1D) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 16,
            color: AppColors.textMutedFor(context),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Search',
              style: TextStyle(
                color: AppColors.textMutedFor(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  final String name;

  const _InviteTile({required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 9.5,
            backgroundImage: AssetImage('assets/images/alina.jpg'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 10.8,
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            height: 24,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: AppColors.borderLightFor(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Invite',
                style: TextStyle(
                  fontSize: 9.6,
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
