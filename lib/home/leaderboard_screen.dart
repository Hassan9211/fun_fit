import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/app_section_header.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _kProfileName = 'profile_name';
  static const String _kProfileUsername = 'profile_username';
  static const String _kUserPoints = 'leaderboard_points';

  int _tab = 0;
  String _profileImagePath = '';
  String _profileName = '';
  String _profileUsername = '';
  int _userPoints = 34;

  final AuthApiService _authApi = AuthApiService();
  List<_Leader> _all = List<_Leader>.from(_defaultLeaders);

  static const List<_Leader> _defaultLeaders = [
    _Leader(
      'Bryan',
      43,
      'assets/images/yoga.jpg',
      gender: _Gender.men,
      badge: _Badge.star,
    ),
    _Leader(
      'Meghan',
      40,
      'assets/images/nora.jpg',
      gender: _Gender.women,
      badge: _Badge.star,
    ),
    _Leader(
      'Alex',
      38,
      'assets/images/alina.jpg',
      gender: _Gender.men,
      badge: _Badge.medal,
    ),
    _Leader(
      'Marsha Fisher',
      36,
      'assets/images/tammana.jpg',
      gender: _Gender.women,
      badge: _Badge.diamond,
    ),
    _Leader(
      'Juanita Cormier',
      35,
      'assets/images/pilates.jpg',
      gender: _Gender.women,
      badge: _Badge.sword,
    ),
    _Leader(
      'You',
      34,
      'assets/images/situp.jpg',
      gender: _Gender.men,
      me: true,
      badge: _Badge.cloud,
    ),
    _Leader(
      'Tamara Schmidt',
      33,
      'assets/images/weightlifting.jpg',
      gender: _Gender.women,
      badge: _Badge.spark,
    ),
    _Leader(
      'Ricardo Veum',
      32,
      'assets/images/Calisthenics.jpg',
      gender: _Gender.men,
      badge: _Badge.diamond,
    ),
    _Leader(
      'Gary Sanford',
      31,
      'assets/images/pushup.jpg',
      gender: _Gender.men,
      badge: _Badge.sword,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ProfileSyncService.changes.addListener(_loadProfileIdentity);
    _loadProfileIdentity();
    _loadUserPoints();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadProfileIdentity);
    super.dispose();
  }

  List<_Leader> get _current {
    List<_Leader> list;
    if (_tab == 1) {
      list = _all.where((e) => e.gender == _Gender.men).toList();
    } else if (_tab == 2) {
      list = _all.where((e) => e.gender == _Gender.women).toList();
    } else {
      list = _all.toList();
    }
    final hydrated = list
        .map(
          (leader) => leader.me
              ? _Leader(
                  leader.name,
                  _userPoints,
                  leader.image,
                  gender: leader.gender,
                  me: leader.me,
                  badge: leader.badge,
                )
              : leader,
        )
        .toList();
    hydrated.sort((a, b) => b.points.compareTo(a.points));
    return hydrated;
  }

  Future<void> _loadProfileIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = (prefs.getString(_kProfileImagePath) ?? '').trim();
    final savedName = (prefs.getString(_kProfileName) ?? '').trim();
    final savedUsername = (prefs.getString(_kProfileUsername) ?? '').trim();
    if (!mounted) return;
    setState(() {
      _profileImagePath = savedPath;
      _profileName = savedName;
      _profileUsername = savedUsername;
    });
  }

  Future<void> _loadUserPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_kUserPoints) ?? _userPoints;
    if (!mounted) return;
    setState(() => _userPoints = points);
  }

  Future<void> _loadLeaderboard() async {
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    final result = await _authApi.fetchLeaderboard(bearerToken: token);
    if (!mounted || !result.success) return;
    final parsed = _parseLeaderboard(result.data);
    if (parsed.isEmpty) return;
    setState(() => _all = parsed);
  }

  List<_Leader> _parseLeaderboard(Map<String, dynamic>? response) {
    if (response == null) return const <_Leader>[];
    final raw = response['items'] ?? response['data'] ?? response['results'];
    final list = raw is List ? raw : (raw == null ? [] : [raw]);
    final currentName = _profileName.trim().toLowerCase();
    final currentUsername =
        _profileUsername.trim().toLowerCase().replaceAll('@', '');
    return list
        .map<_Leader?>((item) {
          if (item is! Map) return null;
          final map = item.map((k, v) => MapEntry(k.toString(), v));
          final name = (map['name'] ?? map['user'] ?? '').toString().trim();
          final username =
              (map['username'] ?? map['user_name'] ?? map['handle'] ?? '')
                  .toString()
                  .trim();
          final pointsRaw = map['points'] ?? map['score'] ?? map['value'];
          final points = int.tryParse(pointsRaw?.toString() ?? '') ?? 0;
          final image =
              (map['avatar'] ?? map['image'] ?? 'assets/images/yoga.jpg')
                  .toString()
                  .trim();
          final gender = _parseGender(map['gender'] ?? map['sex']);
          final rawMe = map['me'] ?? map['is_me'] ?? map['isMe'] ?? map['self'];
          final normalizedName = name.toLowerCase();
          final normalizedUsername =
              username.toLowerCase().replaceAll('@', '');
          final inferredMe =
              rawMe == true ||
              rawMe == 1 ||
              rawMe?.toString().toLowerCase() == 'true' ||
              normalizedName == 'you' ||
              (currentName.isNotEmpty && normalizedName == currentName) ||
              (currentUsername.isNotEmpty &&
                  normalizedUsername == currentUsername);
          if (name.isEmpty) return null;
          return _Leader(
            name,
            points,
            inferredMe && _profileImagePath.trim().isNotEmpty
                ? _profileImagePath.trim()
                : image,
            gender: gender,
            me: inferredMe,
          );
        })
        .whereType<_Leader>()
        .toList(growable: false);
  }

  _Gender _parseGender(dynamic raw) {
    final value = raw?.toString().toLowerCase().trim() ?? '';
    if (value == 'female' || value == 'women' || value == 'woman' || value == 'f') {
      return _Gender.women;
    }
    return _Gender.men;
  }

  Future<void> _goProfile() async {
    await Get.toNamed(Routes.profile);
    await _loadProfileIdentity();
  }

  ImageProvider _avatarForLeader(
    _Leader leader,
    ImageProvider currentUserAvatar,
  ) {
    if (leader.me) return currentUserAvatar;
    final raw = leader.image.trim();
    final resolved = ProfileAvatarResolver.resolveNullable(raw);
    if (resolved != null) return resolved;
    if (raw.startsWith('assets/')) return AssetImage(raw);
    return const AssetImage('assets/images/yoga.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final data = _current;
    if (data.length < 3) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final top1 = data[0];
    final top2 = data[1];
    final top3 = data[2];
    final rest = data.skip(3).toList();

    final ImageProvider headerAvatar = ProfileAvatarResolver.resolve(
      _profileImagePath,
      fallback: const AssetImage('assets/images/situp.jpg'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final contentMaxWidth = isDesktop
            ? 520.0
            : isTablet
            ? 460.0
            : 420.0;
        final panelColor = AppColors.isDark(context)
            ? const Color(0xFF171717)
            : const Color(0xFFF2F2F2);
        return Scaffold(
          backgroundColor: const Color(0xFF080808),
          extendBody: true,
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Leaderboard'),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    AppSectionHeader(
                      title: 'Leaderboard',
                      avatarProvider: headerAvatar,
                      onTapProfile: _goProfile,
                    ),
                    Expanded(
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 70),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
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
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.borderLightFor(
                                          context,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        _tabButton(0, 'All'),
                                        _tabButton(1, 'Men'),
                                        _tabButton(2, 'Women'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedReveal(
                                delay: const Duration(milliseconds: 170),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    10,
                                    14,
                                    8,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _TopCard(
                                            leader: top2,
                                            rank: 2,
                                            avatarRadius: 21,
                                            avatarProvider:
                                                _avatarForLeader(top2, headerAvatar),
                                          ),
                                          const SizedBox(width: 10),
                                          _TopCard(
                                            leader: top1,
                                            rank: 1,
                                            avatarRadius: 26,
                                            isFirst: true,
                                            avatarProvider:
                                                _avatarForLeader(top1, headerAvatar),
                                          ),
                                          const SizedBox(width: 10),
                                          _TopCard(
                                            leader: top3,
                                            rank: 3,
                                            avatarRadius: 21,
                                            avatarProvider:
                                                _avatarForLeader(top3, headerAvatar),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.fromLTRB(
                                    10,
                                    8,
                                    10,
                                    10,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted(context),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      78,
                                    ),
                                    itemCount: rest.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final leader = rest[index];
                                      final rank = index + 4;
                                      return AnimatedReveal(
                                        delay: Duration(
                                          milliseconds:
                                              120 + ((index % 7) * 30),
                                        ),
                                        child: _RankRow(
                                          leader: leader,
                                          rank: rank,
                                          avatarProvider:
                                              _avatarForLeader(leader, headerAvatar),
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

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimary
                  : AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final _Leader leader;
  final int rank;
  final double avatarRadius;
  final bool isFirst;
  final ImageProvider avatarProvider;

  const _TopCard({
    required this.leader,
    required this.rank,
    required this.avatarRadius,
    required this.avatarProvider,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: isFirst ? 108 : 92,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textPrimaryFor(context),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: avatarProvider,
                ),
              ),
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  leader.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ),
              if (leader.badge != _Badge.none) ...[
                const SizedBox(width: 3),
                Icon(
                  _badgeIcon(leader.badge),
                  size: 11,
                  color: _badgeColor(leader.badge),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 10,
                color: Color(0xFF1EA7A4),
              ),
              const SizedBox(width: 2),
              Text(
                '${leader.points} pts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _badgeIcon(_Badge badge) {
    switch (badge) {
      case _Badge.star:
        return Icons.star;
      case _Badge.medal:
        return Icons.military_tech;
      case _Badge.diamond:
        return Icons.diamond;
      case _Badge.sword:
        return Icons.gavel;
      case _Badge.spark:
        return Icons.auto_awesome;
      case _Badge.cloud:
        return Icons.cloud_queue;
      case _Badge.none:
        return Icons.circle;
    }
  }

  Color _badgeColor(_Badge badge) {
    switch (badge) {
      case _Badge.star:
      case _Badge.medal:
      case _Badge.spark:
        return const Color(0xFFF3C623);
      case _Badge.diamond:
        return const Color(0xFF73B8F3);
      case _Badge.sword:
        return const Color(0xFF8E8E8E);
      case _Badge.cloud:
        return const Color(0xFFE5E7EB);
      case _Badge.none:
        return Colors.transparent;
    }
  }
}

class _RankRow extends StatelessWidget {
  final _Leader leader;
  final int rank;
  final ImageProvider avatarProvider;

  const _RankRow({
    required this.leader,
    required this.rank,
    required this.avatarProvider,
  });

  @override
  Widget build(BuildContext context) {
    final selected = leader.me;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: TextStyle(
                color: selected
                    ? colorScheme.onPrimary
                    : AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          CircleAvatar(
            radius: 12,
            backgroundImage: avatarProvider,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selected ? 'You' : leader.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? colorScheme.onPrimary
                    : AppColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (leader.badge != _Badge.none) ...[
            Icon(
              _badgeIcon(leader.badge),
              size: 11,
              color: selected
                  ? colorScheme.onPrimary
                  : _badgeColor(leader.badge),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${leader.points} pts',
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimary
                  : AppColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _badgeIcon(_Badge badge) {
    switch (badge) {
      case _Badge.star:
        return Icons.star;
      case _Badge.medal:
        return Icons.military_tech;
      case _Badge.diamond:
        return Icons.diamond;
      case _Badge.sword:
        return Icons.gavel;
      case _Badge.spark:
        return Icons.auto_awesome;
      case _Badge.cloud:
        return Icons.cloud_queue;
      case _Badge.none:
        return Icons.circle;
    }
  }

  Color _badgeColor(_Badge badge) {
    switch (badge) {
      case _Badge.star:
      case _Badge.medal:
      case _Badge.spark:
        return const Color(0xFFF3C623);
      case _Badge.diamond:
        return const Color(0xFF73B8F3);
      case _Badge.sword:
        return const Color(0xFF8E8E8E);
      case _Badge.cloud:
        return const Color(0xFFE5E7EB);
      case _Badge.none:
        return Colors.transparent;
    }
  }
}

enum _Gender { men, women }

enum _Badge { none, star, medal, diamond, sword, spark, cloud }

class _Leader {
  final String name;
  final int points;
  final String image;
  final _Gender gender;
  final bool me;
  final _Badge badge;

  const _Leader(
    this.name,
    this.points,
    this.image, {
    required this.gender,
    this.me = false,
    this.badge = _Badge.none,
  });
}
