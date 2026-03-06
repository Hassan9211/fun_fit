// ignore_for_file: unused_field

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/fitness_lvl.dart';
import '../widget/app_colors.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _kProfileName = 'profile_name';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _defaultProfileName = 'Jacob West';
  static const String _defaultProfileImageUrl =
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80';
  static const List<String> _categories = <String>[
    'Yoga',
    'Pilates',
    'Weightlifting',
    'Calisthenics',
    'Stretching & Mobility',
  ];
  static const List<_ChallengeTemplate> _challengePool = <_ChallengeTemplate>[
    _ChallengeTemplate(
      title: 'Push Up',
      subtitle: '100 Push up a day',
      duration: '5:00 min',
      imagePath: 'assets/images/pushup.jpg',
    ),
    _ChallengeTemplate(
      title: 'Sit Up',
      subtitle: '20 Sit up a day',
      duration: '5:00 min',
      imagePath: 'assets/images/situp.jpg',
    ),
    _ChallengeTemplate(
      title: 'Knee Push Up',
      subtitle: '20 reps x 3 sets',
      duration: '3:00 min',
      imagePath: 'assets/images/knee pushup.jpg',
    ),
    _ChallengeTemplate(
      title: 'Pilates Core',
      subtitle: '15 min core focus',
      duration: '6:00 min',
      imagePath: 'assets/images/pilates.jpg',
    ),
  ];

  final Random _random = Random();
  final List<_ActiveChallenge> _currentChallenges = <_ActiveChallenge>[
    _ActiveChallenge.fromTemplate(_challengePool[0], progress: 0.34),
    _ActiveChallenge.fromTemplate(_challengePool[1], progress: 0.58),
  ];

  String _profileName = _defaultProfileName;
  String _profileImagePath = '';
  String? _selectedCategory;
  bool _isPickingChallenge = false;

  @override
  void initState() {
    super.initState();
    ProfileSyncService.changes.addListener(_loadHomeData);
    _loadHomeData();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadHomeData);
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = (prefs.getString(_kProfileName) ?? '').trim();
    final imagePath = prefs.getString(_kProfileImagePath) ?? '';
    if (!mounted) return;
    setState(() {
      _profileName = savedName.isEmpty ? _defaultProfileName : savedName;
      _profileImagePath = imagePath;
    });
  }

  Future<void> _pickRandomChallenge() async {
    if (_isPickingChallenge) return;
    setState(() => _isPickingChallenge = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final template = _challengePool[_random.nextInt(_challengePool.length)];
    final existingIndex = _currentChallenges.indexWhere(
      (challenge) => challenge.title == template.title,
    );
    setState(() {
      if (existingIndex == -1) {
        _currentChallenges.insert(
          0,
          _ActiveChallenge.fromTemplate(template, progress: 0.18),
        );
      } else {
        final current = _currentChallenges[existingIndex];
        _currentChallenges[existingIndex] = current.copyWith(
          progress: (current.progress + 0.14).clamp(0.05, 1.0),
        );
      }
      _isPickingChallenge = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${template.title} selected')));
  }

  void _removeChallenge(_ActiveChallenge challenge) {
    setState(() => _currentChallenges.remove(challenge));
  }

  Future<void> _openProfile() async {
    await Get.toNamed(Routes.profile);
    await _loadHomeData();
  }

  Future<void> _openFitnessLevelSelector() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const FitnessLevelScreen(returnSelection: true),
      ),
    );

    if (selected == null || selected.isEmpty) return;
    setState(() => _selectedCategory = selected);
  }

  void _showNotificationsSheet() {
    final isDark = AppColors.isDark(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
              SizedBox(height: 12),
              _NotificationRow(
                label: 'New random challenge available',
                isDark: isDark,
              ),
              _NotificationRow(
                label: '3 workouts completed this week',
                isDark: isDark,
              ),
              _NotificationRow(label: 'Meal plan updated', isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700 && width < 1100;
    final maxContentWidth = isDesktop
        ? 520.0
        : isTablet
        ? 460.0
        : 400.0;
    final isCompact = width < 370;
    final panelColor = const Color(0xFFF5F5F5);
    const panelTextColor = Color(0xFF222222);
    const panelHintColor = Color(0xFF7A7A7A);
    const panelCardColor = Color(0xFFEFEFEF);
    final avatarImage = ProfileAvatarResolver.resolve(
      _profileImagePath,
      fallback: const NetworkImage(_defaultProfileImageUrl),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: const TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _profileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 26 : 29,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.02,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundImage: avatarImage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showNotificationsSheet,
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 17,
                                color: Colors.black,
                              ),
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D4D),
                                  border: Border.all(
                                    color: const Color(0xFF080808),
                                    width: 1.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _openFitnessLevelSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: panelCardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCategory ?? 'Select Category',
                                    style: TextStyle(
                                      fontSize: isCompact ? 15.5 : 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: panelTextColor,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 26,
                                  color: panelTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose Random Challenge',
                          style: const TextStyle(
                            color: panelHintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _isPickingChallenge
                                  ? null
                                  : _pickRandomChallenge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.black45,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: Text(
                                _isPickingChallenge
                                    ? 'Selecting...'
                                    : 'Start Random Challenge',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Challenges',
                                style: const TextStyle(
                                  color: Color(0xFF646464),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _currentChallenges.clear()),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_currentChallenges.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: panelCardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No active challenge. Start a random one.',
                              style: const TextStyle(
                                color: panelHintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ..._currentChallenges.map(_buildChallengeCard),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recommended Meal',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: panelHintColor,
                                ),
                              ),
                            ),
                            Text(
                              'View all',
                              style: const TextStyle(
                                color: Color(0xFF9B9B9B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1.63,
                                child: Image.asset(
                                  'assets/images/nutbutter.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.72),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                left: 12,
                                right: 12,
                                bottom: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nut Butter Toast With Boiled Eggs',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '164kcl',
                                      style: TextStyle(
                                        color: Color(0xFFDADADA),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      bottomNavigationBar: const HomeBottomNav(selected: 'Home'),
    );
  }

  Widget _buildChallengeCard(_ActiveChallenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 78,
              height: 78,
              child: Image.asset(
                challenge.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      challenge.duration,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8E8E8E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: challenge.progress,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF22C1CC)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _removeChallenge(challenge),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF202020),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String label;
  final bool isDark;

  const _NotificationRow({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeTemplate {
  final String title;
  final String subtitle;
  final String duration;
  final String imagePath;

  const _ChallengeTemplate({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imagePath,
  });
}

class _ActiveChallenge {
  final String title;
  final String subtitle;
  final String duration;
  final String imagePath;
  final double progress;

  const _ActiveChallenge({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imagePath,
    required this.progress,
  });

  factory _ActiveChallenge.fromTemplate(
    _ChallengeTemplate template, {
    required double progress,
  }) {
    return _ActiveChallenge(
      title: template.title,
      subtitle: template.subtitle,
      duration: template.duration,
      imagePath: template.imagePath,
      progress: progress,
    );
  }

  _ActiveChallenge copyWith({double? progress}) {
    return _ActiveChallenge(
      title: title,
      subtitle: subtitle,
      duration: duration,
      imagePath: imagePath,
      progress: progress ?? this.progress,
    );
  }
}
