import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/app_colors.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_button.dart';
import '../widget/home_bottom_nav.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  static const String _kCompletedChallenges = 'completed_challenges_count';
  static const String _kChallengePoints = 'challenge_points_count';

  final Random _random = Random();
  int? _lastChallengeIndex;
  bool _isSelectingChallenge = false;
  _RandomChallenge? _selectedChallenge;
  Timer? _challengeTimer;
  Duration _challengeTotal = Duration.zero;
  Duration _challengeRemaining = Duration.zero;
  bool _isChallengeRunning = false;
  bool _isChallengeCompleted = false;
  int _completedChallenges = 0;
  int _challengePoints = 0;

  static const List<_RandomChallenge> _randomChallenges = [
    _RandomChallenge(
      title: 'Push Up',
      subtitle: '100 push ups a day',
      durationLabel: '5:00 min',
      duration: Duration(minutes: 5),
      rewardPoints: 10,
      imagePath: 'assets/images/pushup.jpg',
    ),
    _RandomChallenge(
      title: 'Sit Up',
      subtitle: '20 sit ups a day',
      durationLabel: '4:30 min',
      duration: Duration(minutes: 4, seconds: 30),
      rewardPoints: 10,
      imagePath: 'assets/images/situp.jpg',
    ),
    _RandomChallenge(
      title: 'Knee Push Up',
      subtitle: '20 reps x 3 sets',
      durationLabel: '3:00 min',
      duration: Duration(minutes: 3),
      rewardPoints: 10,
      imagePath: 'assets/images/knee pushup.jpg',
    ),
    _RandomChallenge(
      title: 'Plank Hold',
      subtitle: '3 rounds of 60 seconds',
      durationLabel: '6:00 min',
      duration: Duration(minutes: 6),
      rewardPoints: 12,
      imagePath: 'assets/images/yoga.jpg',
    ),
    _RandomChallenge(
      title: 'Jump Squats',
      subtitle: '40 reps x 3 sets',
      durationLabel: '5:30 min',
      duration: Duration(minutes: 5, seconds: 30),
      rewardPoints: 11,
      imagePath: 'assets/images/Calisthenics.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _challengeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _completedChallenges = prefs.getInt(_kCompletedChallenges) ?? 0;
      _challengePoints = prefs.getInt(_kChallengePoints) ?? 0;
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCompletedChallenges, _completedChallenges);
    await prefs.setInt(_kChallengePoints, _challengePoints);
  }

  int _pickNextChallengeIndex() {
    if (_randomChallenges.length <= 1) return 0;
    var next = _random.nextInt(_randomChallenges.length);
    while (next == _lastChallengeIndex) {
      next = _random.nextInt(_randomChallenges.length);
    }
    return next;
  }

  Future<void> _selectRandomChallenge() async {
    if (_isSelectingChallenge) return;
    setState(() => _isSelectingChallenge = true);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Selecting random challenge...',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final index = _pickNextChallengeIndex();
    final challenge = _randomChallenges[index];
    Navigator.of(context, rootNavigator: true).pop();

    setState(() {
      _lastChallengeIndex = index;
      _selectedChallenge = challenge;
      _challengeTimer?.cancel();
      _challengeTotal = challenge.duration;
      _challengeRemaining = challenge.duration;
      _isChallengeRunning = false;
      _isChallengeCompleted = false;
      _isSelectingChallenge = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${challenge.title} - ${challenge.durationLabel}')),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startOrResumeChallengeTimer() {
    if (_selectedChallenge == null || _isChallengeCompleted || _isChallengeRunning) {
      return;
    }
    if (_challengeRemaining <= Duration.zero) {
      _challengeRemaining = _challengeTotal;
    }
    setState(() => _isChallengeRunning = true);
    _challengeTimer?.cancel();
    _challengeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_challengeRemaining <= const Duration(seconds: 1)) {
        timer.cancel();
        _completeActiveChallenge();
        return;
      }
      setState(() => _challengeRemaining -= const Duration(seconds: 1));
    });
  }

  void _pauseChallengeTimer() {
    if (!_isChallengeRunning) return;
    _challengeTimer?.cancel();
    setState(() => _isChallengeRunning = false);
  }

  void _resetChallengeTimer() {
    if (_selectedChallenge == null) return;
    _challengeTimer?.cancel();
    setState(() {
      _isChallengeRunning = false;
      _isChallengeCompleted = false;
      _challengeRemaining = _challengeTotal;
    });
  }

  Future<void> _completeActiveChallenge() async {
    final challenge = _selectedChallenge;
    if (challenge == null || _isChallengeCompleted) return;

    _challengeTimer?.cancel();
    setState(() {
      _isChallengeRunning = false;
      _isChallengeCompleted = true;
      _challengeRemaining = Duration.zero;
      _completedChallenges += 1;
      _challengePoints += challenge.rewardPoints;
    });
    await _saveStats();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${challenge.title} completed. +${challenge.rewardPoints} pts')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final hPadding = isDesktop
            ? 36.0
            : isTablet
            ? 28.0
            : 20.0;
        final contentMaxWidth = isDesktop
            ? 1040.0
            : isTablet
            ? 900.0
            : width;
        final categoryHeight = isDesktop
            ? 150.0
            : isTablet
            ? 140.0
            : 130.0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    const AnimatedReveal(
                      child: _BlueHeader(
                        title: 'Challenges',
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 24),
                        children: [
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 80),
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Random Challenge',
                          style: TextStyle(
                            color: AppColors.textSecondaryFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.asset(
                                _selectedChallenge?.imagePath ??
                                    'assets/images/yoga.jpg',
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0x990F172A),
                                        Color(0x000F172A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: AppButton(
                                  label: _isSelectingChallenge
                                      ? 'Selecting...'
                                      : 'Select Random Challenge',
                                  onPressed: _isSelectingChallenge
                                      ? null
                                      : _selectRandomChallenge,
                                  width: double.infinity,
                                  height: 36,
                                  backgroundColor: AppColors.primary,
                                  borderRadius: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedChallenge != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedChallenge!.title,
                                  style: TextStyle(
                                    color: AppColors.textPrimaryFor(context),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedChallenge!.subtitle,
                                  style: TextStyle(
                                    color: AppColors.textSecondaryFor(context),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isChallengeCompleted
                                          ? 'Completed'
                                          : _formatDuration(_challengeRemaining),
                                      style: TextStyle(
                                        color: AppColors.textPrimaryFor(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '+${_selectedChallenge!.rewardPoints} pts',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!_isChallengeCompleted)
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton(
                                          onPressed: _isChallengeRunning
                                              ? _pauseChallengeTimer
                                              : _startOrResumeChallengeTimer,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            _isChallengeRunning
                                                ? 'Pause'
                                                : (_challengeRemaining ==
                                                        _challengeTotal
                                                    ? 'Start'
                                                    : 'Resume'),
                                          ),
                                        ),
                                      ),
                                    if (!_isChallengeCompleted)
                                      SizedBox(
                                        height: 34,
                                        child: OutlinedButton(
                                          onPressed: _resetChallengeTimer,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Reset'),
                                        ),
                                      ),
                                    if (!_isChallengeCompleted)
                                      SizedBox(
                                        height: 34,
                                        child: OutlinedButton(
                                          onPressed: _completeActiveChallenge,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text('Mark Complete'),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ChallengeMiniStat(
                                  label: 'Completed',
                                  value: '$_completedChallenges',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ChallengeMiniStat(
                                  label: 'Points',
                                  value: '$_challengePoints',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedReveal(
                    delay: Duration(milliseconds: 140),
                    child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Workout Category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryFor(context),
                          ),
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedFor(context),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 180),
                    child: SizedBox(
                      height: categoryHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _CategoryCard(
                            title: 'Yoga',
                            imagePath: 'assets/images/yoga.jpg',
                          ),
                          _CategoryCard(
                            title: 'Pilates',
                            imagePath: 'assets/images/pilates.jpg',
                          ),
                          _CategoryCard(
                            title: 'Calisthenics',
                            imagePath: 'assets/images/Calisthenics.jpg',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedReveal(
                    delay: Duration(milliseconds: 220),
                    child: Text(
                      'Current Challenges',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryFor(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 260),
                    child: _ChallengeTile(
                      title: 'Push Up',
                      subtitle: '100 Push up a day',
                      time: '5:00 min',
                      progress: 0.45,
                      imagePath: 'assets/images/pushup.jpg',
                    ),
                  ),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 300),
                    child: _ChallengeTile(
                      title: 'Sit Up',
                      subtitle: '20 Sit up a day',
                      time: '4:30 min',
                      progress: 0.70,
                      imagePath: 'assets/images/situp.jpg',
                    ),
                  ),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 340),
                    child: _ChallengeTile(
                      title: 'Knee Push Up',
                      subtitle: '20 Sit up a day',
                      time: '3:00 min',
                      progress: 0.35,
                      imagePath: 'assets/images/knee pushup.jpg',
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () {},
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Challenges'),
        );
      },
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;

  const _BlueHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 34),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const _CategoryCard({required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xAA0F172A), Color(0x001D3DBB)],
          ),
        ),
        child: Center(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final double progress;
  final String imagePath;

  const _ChallengeTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.progress,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Icon(
                Icons.sync,
                size: 16,
                color: AppColors.textSecondaryFor(context),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _ChallengeMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLightFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondaryFor(context),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RandomChallenge {
  final String title;
  final String subtitle;
  final String durationLabel;
  final Duration duration;
  final int rewardPoints;
  final String imagePath;

  const _RandomChallenge({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.duration,
    required this.rewardPoints,
    required this.imagePath,
  });
}









