// ignore_for_file: unused_field

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/fitness_lvl.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
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
  static const String _kLocalChallenges = 'local_challenges';
  static const String _defaultProfileName = 'Jacob West';
  static const String _defaultProfileImageUrl =
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80';
  static const List<String> _defaultNotifications = <String>[
    'New random challenge available',
    '3 workouts completed this week',
    'Meal plan updated',
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
  bool _isSavingHomeData = false;
  final AuthApiService _authApi = AuthApiService();
  List<String> _notifications = List<String>.from(_defaultNotifications);
  _RecommendedMealCardData _recommendedMeal = const _RecommendedMealCardData(
    title: 'Nut Butter Toast With Boiled Eggs',
    caloriesText: '164kcl',
    imagePath: 'assets/images/nutbutter.jpg',
  );

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
    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    final prefs = await SharedPreferences.getInstance();
    final localChallenges = _readLocalChallenges(prefs);
    final savedName = (prefs.getString(_kProfileName) ?? '').trim();
    final imagePath = prefs.getString(_kProfileImagePath) ?? '';
    if (!mounted) return;
    setState(() {
      _profileName = savedName.isEmpty ? _defaultProfileName : savedName;
      _profileImagePath = imagePath;
      _mergeLocalChallenges(localChallenges);
    });

    final result = await _authApi.fetchHomeData(
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    if (!mounted || !result.success) return;

    final payload = _HomeApiPayload.fromResponse(result.data);
    setState(() {
      if (payload.profileName != null && payload.profileName!.isNotEmpty) {
        _profileName = payload.profileName!;
      }
      if (payload.selectedCategory != null &&
          payload.selectedCategory!.isNotEmpty) {
        _selectedCategory = payload.selectedCategory!;
      }
      if (payload.notifications != null) {
        _notifications = payload.notifications!;
      }
      if (payload.recommendedMeal != null) {
        _recommendedMeal = payload.recommendedMeal!;
      }
      if (payload.challenges != null) {
        _currentChallenges
          ..clear()
          ..addAll(payload.challenges!);
      }
      _mergeLocalChallenges(localChallenges);
    });
  }

  List<_ActiveChallenge> _readLocalChallenges(SharedPreferences prefs) {
    final raw = prefs.getStringList(_kLocalChallenges) ?? <String>[];
    return raw
        .map<_ActiveChallenge?>((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is! Map<String, dynamic>) return null;
            return _ActiveChallenge.fromApi(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<_ActiveChallenge>()
        .toList(growable: false);
  }

  void _mergeLocalChallenges(List<_ActiveChallenge> locals) {
    if (locals.isEmpty) return;
    for (final local in locals) {
      final exists = _currentChallenges.any(
        (challenge) => challenge.title == local.title,
      );
      if (!exists) {
        _currentChallenges.add(local);
      }
    }
  }

  Future<void> _pickRandomChallenge() async {
    if (_isPickingChallenge) return;
    setState(() => _isPickingChallenge = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final localChallenges = _readLocalChallenges(prefs);
    final candidates = <_ActiveChallenge>[
      ..._challengePool.map(
        (template) =>
            _ActiveChallenge.fromTemplate(template, progress: 0.18),
      ),
      ...localChallenges.map((challenge) => challenge.copyWith(progress: 0.18)),
    ];

    if (candidates.isEmpty) {
      if (mounted) {
        setState(() => _isPickingChallenge = false);
      }
      return;
    }

    final picked = candidates[_random.nextInt(candidates.length)];
    final existingIndex = _currentChallenges.indexWhere(
      (challenge) => challenge.title == picked.title,
    );
    setState(() {
      if (existingIndex == -1) {
        _currentChallenges.insert(0, picked);
      } else {
        final current = _currentChallenges[existingIndex];
        _currentChallenges[existingIndex] = current.copyWith(
          progress: (current.progress + 0.14).clamp(0.05, 1.0),
        );
      }
      _isPickingChallenge = false;
    });
    await _saveHomeData();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${picked.title} selected')));
  }

  Future<void> _openRandomChallengeScreen() async {
    final current = _currentChallenges.isNotEmpty
        ? _currentChallenges.first
        : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RandomChallengeScreen(
          challenge: current,
          onStartRandom: () async {
            await _pickRandomChallenge();
            if (!mounted) return null;
            return _currentChallenges.isNotEmpty
                ? _currentChallenges.first
                : null;
          },
          onDiscard: current == null
              ? null
              : () async {
                  await _removeChallenge(current);
                },
        ),
      ),
    );
  }

  Future<void> _removeChallenge(_ActiveChallenge challenge) async {
    setState(() => _currentChallenges.remove(challenge));
    await _saveHomeData();
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

    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() => _selectedCategory = selected);
    await _saveHomeData();
  }

  Future<void> _clearChallenges() async {
    setState(() => _currentChallenges.clear());
    await _saveHomeData();
  }

  Future<void> _saveHomeData() async {
    if (_isSavingHomeData) return;

    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    if (email.isEmpty && token.isEmpty) return;

    _isSavingHomeData = true;
    final result = await _authApi.saveHomeData(
      homeData: _serializeHomeData(),
      email: email.isEmpty ? null : email,
      bearerToken: token.isEmpty ? null : token,
    );
    _isSavingHomeData = false;

    if (!mounted || result.success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Map<String, dynamic> _serializeHomeData() {
    final serializedChallenges = _currentChallenges
        .map((challenge) => challenge.toApiJson())
        .toList(growable: false);

    return <String, dynamic>{
      if (_selectedCategory != null && _selectedCategory!.trim().isNotEmpty) ...{
        'selected_category': _selectedCategory,
        'selectedCategory': _selectedCategory,
        'category': _selectedCategory,
        'fitness_level': _selectedCategory,
        'fitnessLevel': _selectedCategory,
      },
      'current_challenges': serializedChallenges,
      'currentChallenges': serializedChallenges,
      'active_challenges': serializedChallenges,
      'activeChallenges': serializedChallenges,
      'challenges': serializedChallenges,
    };
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
              const SizedBox(height: 12),
              if (_notifications.isEmpty)
                Text(
                  'No notifications available',
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ..._notifications.map(
                  (label) => _NotificationRow(label: label, isDark: isDark),
                ),
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
                              child: _notifications.isEmpty
                                  ? const SizedBox.shrink()
                                  : Container(
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
                                  : _openRandomChallengeScreen,
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
                              onTap: _clearChallenges,
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
                                child: _RemoteAwareImage(
                                  path: _recommendedMeal.imagePath,
                                  fallbackAssetPath:
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
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _recommendedMeal.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _recommendedMeal.caloriesText,
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
              child: _RemoteAwareImage(
                path: challenge.imagePath,
                fallbackAssetPath: 'assets/images/pushup.jpg',
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

class _RandomChallengeScreen extends StatefulWidget {
  final _ActiveChallenge? challenge;
  final Future<_ActiveChallenge?> Function() onStartRandom;
  final Future<void> Function()? onDiscard;

  const _RandomChallengeScreen({
    required this.challenge,
    required this.onStartRandom,
    this.onDiscard,
  });

  @override
  State<_RandomChallengeScreen> createState() => _RandomChallengeScreenState();
}

class _RandomChallengeScreenState extends State<_RandomChallengeScreen> {
  bool _isPicking = false;
  late _ActiveChallenge? _current;

  @override
  void initState() {
    super.initState();
    _current = widget.challenge;
  }

  Future<void> _showDiscardDialog(BuildContext context) async {
    if (widget.onDiscard == null) return;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Challenge'),
        content: const Text('Are you sure you want to discard this challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (shouldDiscard == true) {
      await widget.onDiscard!();
      if (!mounted) return;
      setState(() => _current = null);
    }
  }

  Future<void> _handleStartRandom() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    final next = await widget.onStartRandom();
    if (!mounted) return;
    setState(() {
      _current = next;
      _isPicking = false;
    });
  }

  Future<void> _recordChallenge(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.camera);
    if (!context.mounted || file == null) return;
    final fileName = file.path.split(RegExp(r'[\\\\/]')).last;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video selected: $fileName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xFFF5F5F5);
    const panelTextColor = Color(0xFF222222);
    const panelHintColor = Color(0xFF7A7A7A);
    const panelCardColor = Color(0xFFEFEFEF);
    final data = _current;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Challenges',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 96),
            children: [
              const Text(
                'Choose Random Challenge',
                style: TextStyle(
                  color: panelHintColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isPicking ? null : _handleStartRandom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black45,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Start Random Challenge',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Current Challenges',
                style: TextStyle(
                  color: Color(0xFF646464),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (data == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: panelCardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No active challenge. Start a random one.',
                    style: TextStyle(color: panelHintColor),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: panelCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 78,
                          height: 78,
                          child: _RemoteAwareImage(
                            path: data.imagePath,
                            fallbackAssetPath: 'assets/images/pushup.jpg',
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
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: panelTextColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  data.duration,
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
                              data.subtitle,
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
                                value: data.progress,
                                backgroundColor: const Color(0xFFE0E0E0),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF22C1CC),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              const Text(
                'Challenges Discription',
                style: TextStyle(
                  color: panelHintColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  data == null
                      ? 'Select a random challenge to see details here.'
                      : 'Perform ${data.title} with proper form. '
                          'Keep your body straight, lower until your chest '
                          'nearly touches the ground, then push back up. '
                          'Upload a video for verification.',
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _recordChallenge(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.videocam_outlined, size: 18),
                  label: const Text(
                    'Record Challenge',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: widget.onDiscard == null
                      ? null
                      : () => _showDiscardDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Discard',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeBottomNav(selected: 'Challenges'),
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

class _RemoteAwareImage extends StatelessWidget {
  final String path;
  final String fallbackAssetPath;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;

  const _RemoteAwareImage({
    required this.path,
    required this.fallbackAssetPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.gaplessPlayback = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPath = path.trim();
    final provider = _resolveImageProvider(normalizedPath);
    return Image(
      image: provider,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          fallbackAssetPath,
          fit: fit,
          alignment: alignment,
          filterQuality: filterQuality,
          gaplessPlayback: gaplessPlayback,
        );
      },
    );
  }

  ImageProvider _resolveImageProvider(String value) {
    if (value.isEmpty) {
      return AssetImage(fallbackAssetPath);
    }
    if (value.startsWith('assets/')) {
      return AssetImage(value);
    }
    return ProfileAvatarResolver.resolveNullable(value) ??
        AssetImage(fallbackAssetPath);
  }
}

class _RecommendedMealCardData {
  final String title;
  final String caloriesText;
  final String imagePath;

  const _RecommendedMealCardData({
    required this.title,
    required this.caloriesText,
    required this.imagePath,
  });

  factory _RecommendedMealCardData.fromApi(Map<String, dynamic> json) {
    final title =
        _HomeApiPayload.firstNonEmptyString(json, const <String>[
          'title',
          'name',
          'meal_name',
          'mealName',
        ]) ??
        'Recommended Meal';
    final rawCalories = _HomeApiPayload.firstRawValue(json, const <String>[
      'calories',
      'kcal',
      'calorie',
      'energy',
      'calories_text',
      'caloriesText',
    ]);
    final imagePath =
        _HomeApiPayload.firstNonEmptyString(json, const <String>[
          'image',
          'image_url',
          'imageUrl',
          'photo',
          'thumbnail',
        ]) ??
        'assets/images/nutbutter.jpg';

    return _RecommendedMealCardData(
      title: title,
      caloriesText: _HomeApiPayload.formatCalories(rawCalories),
      imagePath: imagePath,
    );
  }
}

class _HomeApiPayload {
  final String? profileName;
  final String? selectedCategory;
  final List<String>? notifications;
  final List<_ActiveChallenge>? challenges;
  final _RecommendedMealCardData? recommendedMeal;

  const _HomeApiPayload({
    this.profileName,
    this.selectedCategory,
    this.notifications,
    this.challenges,
    this.recommendedMeal,
  });

  factory _HomeApiPayload.fromResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return const _HomeApiPayload();
    }

    final containerMaps = collectCandidateMaps(response);
    final userMap = firstNestedMap(containerMaps, const <String>[
      'user',
      'profile',
      'account',
    ]);
    final profileName = firstNonEmptyString(
      <Map<String, dynamic>>[?userMap, ...containerMaps],
      const <String>['name', 'full_name', 'fullName', 'username'],
    );
    final selectedCategory = firstNonEmptyString(containerMaps, const <String>[
      'selected_category',
      'selectedCategory',
      'category',
      'fitness_level',
      'fitnessLevel',
    ]);

    return _HomeApiPayload(
      profileName: profileName,
      selectedCategory: selectedCategory,
      notifications: _extractNotifications(containerMaps),
      challenges: _extractChallenges(containerMaps),
      recommendedMeal: _extractRecommendedMeal(containerMaps),
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
      'home',
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

  static List<String>? _extractNotifications(
    List<Map<String, dynamic>> containers,
  ) {
    final raw = firstRawValueAcrossMaps(containers, const <String>[
      'notifications',
      'alerts',
      'notification_list',
    ]);
    if (raw == null) return null;

    final items = asList(raw) ?? const <dynamic>[];
    final labels = items
        .map<String?>((item) {
          if (item is String && item.trim().isNotEmpty) {
            return item.trim();
          }
          final map = asMap(item);
          if (map == null) return null;
          return firstNonEmptyString(map, const <String>[
            'message',
            'label',
            'title',
            'text',
            'body',
          ]);
        })
        .whereType<String>()
        .toList(growable: false);

    return labels;
  }

  static List<_ActiveChallenge>? _extractChallenges(
    List<Map<String, dynamic>> containers,
  ) {
    final raw = firstRawValueAcrossMaps(containers, const <String>[
      'current_challenges',
      'currentChallenges',
      'active_challenges',
      'activeChallenges',
      'challenges',
    ]);
    if (raw == null) return null;

    final items = asList(raw) ?? const <dynamic>[];
    return items
        .map<_ActiveChallenge?>((item) {
          final map = asMap(item);
          if (map == null) return null;
          return _ActiveChallenge.fromApi(map);
        })
        .whereType<_ActiveChallenge>()
        .toList(growable: false);
  }

  static _RecommendedMealCardData? _extractRecommendedMeal(
    List<Map<String, dynamic>> containers,
  ) {
    final raw = firstRawValueAcrossMaps(containers, const <String>[
      'recommended_meal',
      'recommendedMeal',
      'featured_meal',
      'featuredMeal',
      'meal',
    ]);
    final map = asMap(raw);
    if (map != null) {
      return _RecommendedMealCardData.fromApi(map);
    }

    final directTitle = firstNonEmptyString(containers, const <String>[
      'meal_title',
      'mealTitle',
      'recommended_meal_title',
      'recommendedMealTitle',
    ]);
    if (directTitle == null) return null;

    return _RecommendedMealCardData(
      title: directTitle,
      caloriesText: formatCalories(
        firstRawValueAcrossMaps(containers, const <String>[
          'meal_calories',
          'mealCalories',
          'recommended_meal_calories',
          'recommendedMealCalories',
        ]),
      ),
      imagePath:
          firstNonEmptyString(containers, const <String>[
            'meal_image',
            'mealImage',
            'recommended_meal_image',
            'recommendedMealImage',
          ]) ??
          'assets/images/nutbutter.jpg',
    );
  }

  static String formatCalories(dynamic rawCalories) {
    if (rawCalories == null) {
      return '0 kcal';
    }
    if (rawCalories is num) {
      return '${rawCalories.toString()} kcal';
    }

    final text = rawCalories.toString().trim();
    if (text.isEmpty) {
      return '0 kcal';
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(text)) {
      return text;
    }
    return '$text kcal';
  }

  static String formatDuration(dynamic rawDuration) {
    if (rawDuration == null) {
      return '0 min';
    }
    if (rawDuration is num) {
      return '${rawDuration.toString()} min';
    }

    final text = rawDuration.toString().trim();
    if (text.isEmpty) {
      return '0 min';
    }
    if (RegExp(r'[a-zA-Z:]').hasMatch(text)) {
      return text;
    }
    return '$text min';
  }

  static double parseProgress(dynamic rawProgress) {
    if (rawProgress == null) {
      return 0;
    }
    if (rawProgress is num) {
      final value = rawProgress.toDouble();
      return value > 1 ? (value / 100).clamp(0.0, 1.0) : value.clamp(0.0, 1.0);
    }

    final text = rawProgress.toString().trim().replaceAll('%', '');
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return 0;
    }
    return parsed > 1 ? (parsed / 100).clamp(0.0, 1.0) : parsed.clamp(0.0, 1.0);
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

  factory _ActiveChallenge.fromApi(Map<String, dynamic> json) {
    return _ActiveChallenge(
      title:
          _HomeApiPayload.firstNonEmptyString(json, const <String>[
            'title',
            'name',
            'challenge_name',
            'challengeName',
          ]) ??
          'Challenge',
      subtitle:
          _HomeApiPayload.firstNonEmptyString(json, const <String>[
            'subtitle',
            'description',
            'details',
            'summary',
          ]) ??
          '',
      duration: _HomeApiPayload.formatDuration(
        _HomeApiPayload.firstRawValue(json, const <String>[
          'duration',
          'duration_text',
          'durationText',
          'time',
          'length',
        ]),
      ),
      imagePath:
          _HomeApiPayload.firstNonEmptyString(json, const <String>[
            'image',
            'image_url',
            'imageUrl',
            'thumbnail',
            'photo',
          ]) ??
          'assets/images/pushup.jpg',
      progress: _HomeApiPayload.parseProgress(
        _HomeApiPayload.firstRawValue(json, const <String>[
          'progress',
          'completion',
          'percentage',
          'completed_percentage',
          'completedPercentage',
        ]),
      ),
    );
  }

  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'title': title,
      'name': title,
      'challenge_name': title,
      'challengeName': title,
      'subtitle': subtitle,
      'description': subtitle,
      'duration': duration,
      'duration_text': duration,
      'durationText': duration,
      'image': imagePath,
      'image_url': imagePath,
      'imageUrl': imagePath,
      'progress': progress,
      'completion': progress,
      'percentage': (progress * 100).round(),
      'completed_percentage': (progress * 100).round(),
      'completedPercentage': (progress * 100).round(),
    };
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
