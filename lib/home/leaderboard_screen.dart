import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const String _kProfileImagePath = 'profile_image_path';

  int _tab = 0;
  String _profileImagePath = '';

  final List<_Leader> _all = const [
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
    _loadProfileImage();
  }

  List<_Leader> get _current {
    if (_tab == 1) {
      return _all.where((e) => e.gender == _Gender.men).toList();
    }
    if (_tab == 2) {
      return _all.where((e) => e.gender == _Gender.women).toList();
    }
    return _all;
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = (prefs.getString(_kProfileImagePath) ?? '').trim();
    if (!mounted) return;
    setState(() => _profileImagePath = savedPath);
  }

  void _goProfile() => Get.toNamed(Routes.profile);

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

    final hasLocalProfileImage =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();
    final ImageProvider headerAvatar = hasLocalProfileImage
        ? FileImage(File(_profileImagePath))
        : const AssetImage('assets/images/situp.jpg');

    return Scaffold(
      backgroundColor: Colors.black,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const HomeBottomNav(selected: 'Leaderboard'),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: EdgeInsets.fromLTRB(
              10,
              MediaQuery.of(context).padding.top + 10,
              10,
              12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _goProfile,
                      borderRadius: BorderRadius.circular(18),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: headerAvatar,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Leaderboard',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _TopCard(
                              leader: top2,
                              rank: 2,
                              avatarRadius: 21,
                            ),
                            _TopCard(
                              leader: top1,
                              rank: 1,
                              avatarRadius: 26,
                              isFirst: true,
                            ),
                            _TopCard(
                              leader: top3,
                              rank: 3,
                              avatarRadius: 21,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3EA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 78),
                            itemCount: rest.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final leader = rest[index];
                              final rank = index + 4;
                              return _RankRow(leader: leader, rank: rank);
                            },
                          ),
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
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
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

  const _TopCard({
    required this.leader,
    required this.rank,
    required this.avatarRadius,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
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
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: AssetImage(leader.image),
                ),
              ),
              Positioned(
                bottom: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
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

  const _RankRow({
    required this.leader,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final selected = leader.me;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          CircleAvatar(
            radius: 12,
            backgroundImage: AssetImage(leader.image),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selected ? 'You' : leader.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (leader.badge != _Badge.none) ...[
            Icon(
              _badgeIcon(leader.badge),
              size: 11,
              color: selected ? Colors.white : _badgeColor(leader.badge),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${leader.points} pts',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
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
