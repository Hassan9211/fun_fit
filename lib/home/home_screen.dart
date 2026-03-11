// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/fitness_lvl.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';
import '../services/profile_avatar_resolver.dart';
import '../services/profile_sync_service.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/record_with_audio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _kProfileName = 'profile_name';
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _kLocalChallenges = 'local_challenges';
  static const String _kRandomChallenges = 'random_challenges';
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
  final List<_ActiveChallenge> _randomChallenges = <_ActiveChallenge>[];

  String _profileName = _defaultProfileName;
  String _profileImagePath = '';
  String? _selectedCategory;
  bool _isPickingChallenge = false;
  bool _isSavingHomeData = false;
  final AuthApiService _authApi = AuthApiService();
  Timer? _ticker;
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
    _startTicker();
  }

  @override
  void dispose() {
    ProfileSyncService.changes.removeListener(_loadHomeData);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    final email = await AuthSessionStorage.readEmail();
    final token = await AuthSessionStorage.readToken();
    final prefs = await SharedPreferences.getInstance();
    final randomChallenges = _readLocalChallenges(prefs, _kRandomChallenges);
    final savedName = (prefs.getString(_kProfileName) ?? '').trim();
    final imagePath = prefs.getString(_kProfileImagePath) ?? '';
    if (!mounted) return;
    setState(() {
      _profileName = savedName.isEmpty ? _defaultProfileName : savedName;
      _profileImagePath = imagePath;
      _randomChallenges
        ..clear()
        ..addAll(randomChallenges);
    });
    await _ensureMinimumRandomChallenges();
    _tickChallenges();

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
    });
  }

  List<_ActiveChallenge> _readLocalChallenges(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getStringList(key) ?? <String>[];
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


  Future<void> _pickRandomChallenge() async {
    if (_isPickingChallenge) return;
    setState(() => _isPickingChallenge = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final localChallenges = _readLocalChallenges(prefs, _kLocalChallenges);
    final candidates = <_ActiveChallenge>[
      ..._challengePool.map(
        (template) => _ActiveChallenge.fromTemplate(template, progress: 0.18),
      ),
      ...localChallenges.map((challenge) => challenge.copyWith(progress: 0.18)),
    ];

    if (candidates.isEmpty) {
      if (mounted) {
        setState(() => _isPickingChallenge = false);
      }
      return;
    }

    final picked = _startChallenge(
      candidates[_random.nextInt(candidates.length)],
    );
    final existingIndex = _randomChallenges.indexWhere(
      (challenge) => challenge.title == picked.title,
    );
    setState(() {
      if (existingIndex == -1) {
        _randomChallenges.insert(0, picked);
      } else {
        final current = _randomChallenges[existingIndex];
        _randomChallenges[existingIndex] = current.copyWith(
          progress: (current.progress + 0.14).clamp(0.05, 1.0),
        );
      }
      _upsertHomeChallenge(picked);
      _isPickingChallenge = false;
    });
    await _ensureMinimumRandomChallenges();
    await _saveRandomChallenges();
    await _saveHomeData();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${picked.title} selected')));
  }

  Future<void> _openRandomChallengeScreen() async {
    await _ensureMinimumRandomChallenges();
    if (!mounted) return;
    final current = _randomChallenges.isNotEmpty
        ? _randomChallenges.first
        : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RandomChallengeScreen(
          challenge: current,
          initialChallenges: List<_ActiveChallenge>.from(_randomChallenges),
          getChallenges: () => List<_ActiveChallenge>.from(_randomChallenges),
          onStartRandom: () async {
            await _pickRandomChallenge();
            if (!mounted) return null;
            return _randomChallenges.isNotEmpty
                ? _randomChallenges.first
                : null;
          },
          onSelect: (selected) async {
            await _setRandomCurrent(selected);
          },
          onTogglePause: (selected) async {
            await _togglePause(selected);
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
    setState(() => _randomChallenges.remove(challenge));
    await _saveRandomChallenges();
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

  Future<void> _saveRandomChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _randomChallenges
        .map((challenge) => jsonEncode(challenge.toApiJson()))
        .toList(growable: false);
    await prefs.setStringList(_kRandomChallenges, serialized);
  }

  void _upsertHomeChallenge(_ActiveChallenge challenge) {
    final existingIndex = _currentChallenges.indexWhere(
      (item) => item.title == challenge.title,
    );
    if (existingIndex == -1) {
      _currentChallenges.insert(0, challenge);
    } else {
      final existing = _currentChallenges[existingIndex];
      _currentChallenges.removeAt(existingIndex);
      _currentChallenges.insert(
        0,
        existing.copyWith(
          progress: challenge.progress,
          startedAtMs: challenge.startedAtMs,
          remainingSeconds: challenge.remainingSeconds,
          isCompleted: challenge.isCompleted,
        ),
      );
    }
  }

  Future<void> _setRandomCurrent(_ActiveChallenge challenge) async {
    final started = _startChallenge(challenge);
    final existingIndex = _randomChallenges.indexWhere(
      (item) => item.title == challenge.title,
    );
    if (existingIndex == -1) return;
    setState(() {
      _randomChallenges.removeAt(existingIndex);
      _randomChallenges.insert(0, started);
      _upsertHomeChallenge(started);
    });
    await _saveRandomChallenges();
    await _saveHomeData();
  }

  Future<void> _togglePause(_ActiveChallenge challenge) async {
    final updated = challenge.isRunning
        ? _pauseChallenge(challenge)
        : _resumeChallenge(challenge);
    final randomIndex = _randomChallenges.indexWhere(
      (item) => item.title == challenge.title,
    );
    if (randomIndex == -1) return;
    setState(() {
      _randomChallenges[randomIndex] = updated;
      _upsertHomeChallenge(updated);
    });
    await _saveRandomChallenges();
    await _saveHomeData();
  }

  _ActiveChallenge _startChallenge(_ActiveChallenge challenge) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return challenge.copyWith(
      startedAtMs: now,
      remainingSeconds: challenge.remainingSeconds ?? challenge.totalSeconds,
      isCompleted: false,
    );
  }

  _ActiveChallenge _pauseChallenge(_ActiveChallenge challenge) {
    final remaining = challenge.remainingSecondsNow;
    return challenge.copyWith(startedAtMs: null, remainingSeconds: remaining);
  }

  _ActiveChallenge _resumeChallenge(_ActiveChallenge challenge) {
    return challenge.copyWith(
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      remainingSeconds: challenge.remainingSeconds ?? challenge.totalSeconds,
      isCompleted: false,
    );
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickChallenges(),
    );
  }

  void _tickChallenges() {
    if (!mounted) return;
    final completed = <_ActiveChallenge>[];
    bool changed = false;

    for (var i = 0; i < _currentChallenges.length; i++) {
      final challenge = _currentChallenges[i];
      if (!challenge.isRunning) continue;
      final remaining = challenge.remainingSecondsNow;
      if (remaining == 0 && !challenge.isCompleted) {
        _currentChallenges[i] = challenge.copyWith(
          isCompleted: true,
          startedAtMs: null,
          progress: 1,
        );
        completed.add(_currentChallenges[i]);
        changed = true;
      } else {
        final progress = challenge.totalSeconds == 0
            ? 1.0
            : (1 - (remaining / challenge.totalSeconds)).clamp(0.0, 1.0);
        if ((progress - challenge.progress).abs() > 0.001) {
          _currentChallenges[i] = challenge.copyWith(progress: progress);
          changed = true;
        }
      }
    }

    for (var i = 0; i < _randomChallenges.length; i++) {
      final challenge = _randomChallenges[i];
      if (!challenge.isRunning) continue;
      final remaining = challenge.remainingSecondsNow;
      if (remaining == 0 && !challenge.isCompleted) {
        _randomChallenges[i] = challenge.copyWith(
          isCompleted: true,
          startedAtMs: null,
          progress: 1,
        );
        completed.add(_randomChallenges[i]);
        changed = true;
      } else {
        final progress = challenge.totalSeconds == 0
            ? 1.0
            : (1 - (remaining / challenge.totalSeconds)).clamp(0.0, 1.0);
        if ((progress - challenge.progress).abs() > 0.001) {
          _randomChallenges[i] = challenge.copyWith(progress: progress);
          changed = true;
        }
      }
    }

    if (changed) {
      if (completed.isNotEmpty) {
        final completedTitles = completed
            .map((challenge) => challenge.title)
            .toSet();
        _currentChallenges.removeWhere(
          (challenge) => completedTitles.contains(challenge.title),
        );
        _randomChallenges.removeWhere(
          (challenge) => completedTitles.contains(challenge.title),
        );
      }
      setState(() {});
      if (completed.isNotEmpty) {
        _saveRandomChallenges();
        _saveHomeData();
      }
      for (final challenge in completed) {
        _awardPoints(challenge);
      }
    }
  }

  Future<void> _awardPoints(_ActiveChallenge challenge) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('leaderboard_points') ?? 34;
    final earned = challenge.totalSeconds > 5 * 60 ? 3 : 2;
    await prefs.setInt('leaderboard_points', current + earned);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${challenge.title} completed (+$earned pts)')),
    );
  }

  Future<void> _ensureMinimumRandomChallenges({int minCount = 3}) async {
    if (_randomChallenges.length >= minCount) return;

    final prefs = await SharedPreferences.getInstance();
    final localChallenges = _readLocalChallenges(prefs, _kLocalChallenges);
    final candidates = <_ActiveChallenge>[
      ..._challengePool.map(
        (template) => _ActiveChallenge.fromTemplate(template, progress: 0.18),
      ),
      ...localChallenges.map((challenge) => challenge.copyWith(progress: 0.18)),
    ];
    final existingTitles = _randomChallenges
        .map((challenge) => challenge.title)
        .toSet();
    final available = candidates
        .where((challenge) => !existingTitles.contains(challenge.title))
        .toList(growable: true);

    if (available.isEmpty) return;

    final additions = <_ActiveChallenge>[];
    while (_randomChallenges.length + additions.length < minCount &&
        available.isNotEmpty) {
      final next = available.removeAt(_random.nextInt(available.length));
      additions.add(next);
    }

    if (additions.isEmpty || !mounted) return;
    setState(() {
      _randomChallenges.addAll(additions);
    });
    await _saveRandomChallenges();
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
      if (_selectedCategory != null &&
          _selectedCategory!.trim().isNotEmpty) ...{
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
                if (challenge.hasCountdown) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ${challenge.formatRemainingTime()}',
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
  final List<_ActiveChallenge> initialChallenges;
  final List<_ActiveChallenge> Function() getChallenges;
  final Future<_ActiveChallenge?> Function() onStartRandom;
  final Future<void> Function(_ActiveChallenge) onSelect;
  final Future<void> Function(_ActiveChallenge) onTogglePause;
  final Future<void> Function()? onDiscard;

  const _RandomChallengeScreen({
    required this.challenge,
    required this.initialChallenges,
    required this.getChallenges,
    required this.onStartRandom,
    required this.onSelect,
    required this.onTogglePause,
    this.onDiscard,
  });

  @override
  State<_RandomChallengeScreen> createState() => _RandomChallengeScreenState();
}

class _RandomChallengeScreenState extends State<_RandomChallengeScreen> {
  static const String _kChallengeReels = 'challenge_reels_items';
  static const String _kProfileName = 'profile_name';
  static const String _kProfileUsername = 'profile_username';
  static const String _defaultProfileName = 'Jacob West';

  bool _isPicking = false;
  late _ActiveChallenge? _current;
  late List<_ActiveChallenge> _challengeList;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _challengeList = List<_ActiveChallenge>.from(widget.initialChallenges);
    _current =
        widget.challenge ??
        (_challengeList.isNotEmpty ? _challengeList.first : null);
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshFromParent(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refreshFromParent() {
    if (!mounted) return;
    final refreshed = widget.getChallenges();
    if (refreshed.isEmpty) return;
    setState(() {
      _challengeList = refreshed;
      if (_current != null) {
        _current = refreshed.firstWhere(
          (item) => item.title == _current!.title,
          orElse: () => _current!,
        );
      } else {
        _current = refreshed.first;
      }
    });
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
      _challengeList = widget.getChallenges();
      _isPicking = false;
    });
  }

  Future<void> _startExistingChallenge(_ActiveChallenge challenge) async {
    await widget.onSelect(challenge);
    if (!mounted) return;
    setState(() {
      _current = widget.getChallenges().firstWhere(
        (item) => item.title == challenge.title,
        orElse: () => challenge,
      );
      _challengeList = widget.getChallenges();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${challenge.title} started')));
  }

  Future<void> _recordChallenge(BuildContext context) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RecordWithAudioScreen()),
    );
    if (!context.mounted || path == null || path.isEmpty) return;
    await _saveChallengeVideoToReels(path);
    if (!context.mounted) return;
    final fileName = path.split(RegExp(r'[\\\\/]')).last;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Video selected: $fileName')));
  }

  Future<void> _saveChallengeVideoToReels(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final mediaRaw = prefs.getStringList(_kChallengeReels) ?? <String>[];
    final name = (prefs.getString(_kProfileName) ?? '').trim();
    final username = (prefs.getString(_kProfileUsername) ?? '').trim();

    final payload = <String, dynamic>{
      'path': path,
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

    mediaRaw.insert(0, jsonEncode(payload));
    await prefs.setStringList(_kChallengeReels, mediaRaw);
    ProfileSyncService.notifyChanged();
  }

  Future<void> _handleTogglePause() async {
    final current = _current;
    if (current == null) return;
    await widget.onTogglePause(current);
    if (!mounted) return;
    final refreshed = widget.getChallenges();
    setState(() {
      _challengeList = refreshed;
      _current = refreshed.firstWhere(
        (item) => item.title == current.title,
        orElse: () => current,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xFFF5F5F5);
    const panelTextColor = Color(0xFF222222);
    const panelHintColor = Color(0xFF7A7A7A);
    const panelCardColor = Color(0xFFEFEFEF);
    final data = _current;
    final remaining = data?.formatRemainingTime();
    final canStop = data != null && data.isRunning;
    final canResume = data != null && data.isPaused;
    final isCompleted = data != null && data.isCompleted;

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
              if (remaining != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Color(0xFF1EA7A4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Remaining: $remaining',
                        style: const TextStyle(
                          color: panelTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ..._challengeList.map(
                (challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _startExistingChallenge(challenge),
                    borderRadius: BorderRadius.circular(12),
                    child: _RandomChallengeTile(
                      challenge: challenge,
                      isActive: data?.title == challenge.title,
                    ),
                  ),
                ),
              ),
              if (_challengeList.isNotEmpty) const SizedBox(height: 8),
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
                InkWell(
                  onTap: () => _startExistingChallenge(data),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: data == null || isCompleted
                      ? null
                      : _handleTogglePause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isCompleted
                        ? 'Completed'
                        : (canStop ? 'Stop' : (canResume ? 'Resume' : 'Stop')),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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

class _RandomChallengeTile extends StatelessWidget {
  final _ActiveChallenge challenge;
  final bool isActive;

  const _RandomChallengeTile({required this.challenge, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final background = isActive ? const Color(0xFFE6F7FA) : Colors.white;
    final border = isActive ? const Color(0xFF22C1CC) : const Color(0xFFE2E2E2);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 68,
              height: 68,
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
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
              ],
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

  static int parseDurationSeconds(dynamic rawDuration) {
    if (rawDuration == null) return 0;
    if (rawDuration is num) {
      return (rawDuration * 60).round();
    }

    final text = rawDuration.toString().trim().toLowerCase();
    if (text.isEmpty) return 0;

    final matchColon = RegExp(r'(\d+)\s*:\s*(\d+)').firstMatch(text);
    if (matchColon != null) {
      final minutes = int.tryParse(matchColon.group(1)!) ?? 0;
      final seconds = int.tryParse(matchColon.group(2)!) ?? 0;
      return (minutes * 60) + seconds;
    }

    final matchNumber = RegExp(r'(\d+)').firstMatch(text);
    final value = int.tryParse(matchNumber?.group(1) ?? '') ?? 0;
    if (text.contains('sec')) return value;
    return value * 60;
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
  final int totalSeconds;
  final int? startedAtMs;
  final int? remainingSeconds;
  final bool isCompleted;

  const _ActiveChallenge({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imagePath,
    required this.progress,
    required this.totalSeconds,
    this.startedAtMs,
    this.remainingSeconds,
    this.isCompleted = false,
  });

  static const Object _unset = Object();

  factory _ActiveChallenge.fromTemplate(
    _ChallengeTemplate template, {
    required double progress,
  }) {
    final totalSeconds = _HomeApiPayload.parseDurationSeconds(
      template.duration,
    );
    return _ActiveChallenge(
      title: template.title,
      subtitle: template.subtitle,
      duration: template.duration,
      imagePath: template.imagePath,
      progress: progress,
      totalSeconds: totalSeconds,
    );
  }

  factory _ActiveChallenge.fromApi(Map<String, dynamic> json) {
    final durationRaw = _HomeApiPayload.firstRawValue(json, const <String>[
      'duration',
      'duration_text',
      'durationText',
      'time',
      'length',
    ]);
    final durationText = _HomeApiPayload.formatDuration(durationRaw);
    final totalSecondsRaw =
        _HomeApiPayload.firstRawValue(json, const <String>[
          'duration_seconds',
          'durationSeconds',
          'total_seconds',
          'totalSeconds',
        ]) ??
        _HomeApiPayload.parseDurationSeconds(durationRaw);
    final totalSeconds = totalSecondsRaw is num
        ? totalSecondsRaw.toInt()
        : int.tryParse(totalSecondsRaw.toString());

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

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
      duration: durationText,
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
      totalSeconds: totalSeconds ?? 0,
      startedAtMs: parseInt(
        _HomeApiPayload.firstRawValue(json, const <String>[
          'started_at_ms',
          'startedAtMs',
          'started_at',
          'startedAt',
        ]),
      ),
      remainingSeconds: parseInt(
        _HomeApiPayload.firstRawValue(json, const <String>[
          'remaining_seconds',
          'remainingSeconds',
        ]),
      ),
      isCompleted:
          _HomeApiPayload.firstRawValue(json, const <String>[
            'is_completed',
            'isCompleted',
            'completed',
          ]) ==
          true,
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
      'duration_seconds': totalSeconds,
      'durationSeconds': totalSeconds,
      'started_at_ms': startedAtMs,
      'startedAtMs': startedAtMs,
      'remaining_seconds': remainingSeconds,
      'remainingSeconds': remainingSeconds,
      'is_completed': isCompleted,
      'isCompleted': isCompleted,
    };
  }

  _ActiveChallenge copyWith({
    double? progress,
    int? totalSeconds,
    Object? startedAtMs = _unset,
    Object? remainingSeconds = _unset,
    bool? isCompleted,
  }) {
    return _ActiveChallenge(
      title: title,
      subtitle: subtitle,
      duration: duration,
      imagePath: imagePath,
      progress: progress ?? this.progress,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      startedAtMs: startedAtMs == _unset
          ? this.startedAtMs
          : startedAtMs as int?,
      remainingSeconds: remainingSeconds == _unset
          ? this.remainingSeconds
          : remainingSeconds as int?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isRunning => startedAtMs != null && !isCompleted;

  bool get isPaused =>
      startedAtMs == null && remainingSeconds != null && !isCompleted;

  bool get hasCountdown =>
      totalSeconds > 0 &&
      (startedAtMs != null || remainingSeconds != null || isCompleted);

  int get remainingSecondsNow {
    if (isCompleted) return 0;
    if (startedAtMs == null) {
      return remainingSeconds ?? totalSeconds;
    }
    final elapsed =
        ((DateTime.now().millisecondsSinceEpoch - startedAtMs!) / 1000).floor();
    final base = remainingSeconds ?? totalSeconds;
    final remaining = base - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  String formatRemainingTime() {
    final remaining = remainingSecondsNow;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
