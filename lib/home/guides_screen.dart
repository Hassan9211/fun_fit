// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../widget/app_colors.dart';
import '../widget/animated_reveal.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  static const String _kProfileImagePath = 'profile_image_path';
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
    final hasLocalProfileImage =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();
    final ImageProvider headerAvatar = hasLocalProfileImage
        ? FileImage(File(_profileImagePath))
        : const AssetImage('assets/images/situp.jpg');

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
        final mediaHeight = isDesktop
            ? 175.0
            : isTablet
            ? 165.0
            : 155.0;

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          extendBody: true,
          body: Center(
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      headerTopPadding,
                      16,
                      headerBottomPadding,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _goProfile,
                          borderRadius: BorderRadius.circular(18),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 13,
                              backgroundImage: headerAvatar,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Guides',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: isCompact ? 20 : 28),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
                        children: [
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 90),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Recommened Meal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondaryFor(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'View all',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textMutedFor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        Image.asset(
                                          'assets/images/healthy bowl.jpg',
                                          height: mediaHeight - 8,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight,
                                                colors: [Color(0xB3000000), Color(0x20000000)],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          left: 12,
                                          bottom: 12,
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
                                                '1648kcl',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
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
                            const SizedBox(height: 16),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 170),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Workout Videos',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondaryFor(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'View all',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textMutedFor(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: mediaHeight + 4,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: const [
                                        _AssetVideoCard(
                                          title: 'Lower Body Training',
                                          kcal: '500 Kcal',
                                          minutes: '50 Min',
                                          videoPath: 'assets/videos/LowerBodyTraning.mp4',
                                        ),
                                        _AssetVideoCard(
                                          title: 'Hand Training',
                                          kcal: '600 Kcal',
                                          minutes: '40 Min',
                                          videoPath: 'assets/videos/HandTraning.mp4',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 250),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Challenge Tutorial Guide',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryFor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const _ChallengeVideoCard(
                                    title: 'Challenge Tutorial',
                                    videoPath: 'assets/videos/ChallangeTetorial.mp4',
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
          bottomNavigationBar: const HomeBottomNav(selected: 'Guides'),
        );
      },
    );
  }
}

class _AssetVideoCard extends StatelessWidget {
  final String title;
  final String kcal;
  final String minutes;
  final String videoPath;

  const _AssetVideoCard({
    required this.title,
    required this.kcal,
    required this.minutes,
    required this.videoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 195,
      margin: const EdgeInsets.only(right: 12),
      child: _GuidesInlineVideoPlayer(
        videoPath: videoPath,
        fullscreenTitle: title,
        borderRadius: BorderRadius.circular(12),
        gradientColors: const [Color(0xB8000000), Color(0x12000000)],
        overlayBuilder: (bottomInset) {
          return Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Pill(label: kcal, icon: Icons.local_fire_department_outlined),
                        const SizedBox(height: 6),
                        _Pill(label: minutes, icon: Icons.alarm_outlined),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeVideoCard extends StatelessWidget {
  final String title;
  final String videoPath;

  const _ChallengeVideoCard({required this.title, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: _GuidesInlineVideoPlayer(
        videoPath: videoPath,
        fullscreenTitle: title,
        borderRadius: BorderRadius.circular(12),
        gradientColors: const [Color(0x66000000), Color(0x08000000)],
        overlayBuilder: (bottomInset) {
          return Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuidesInlineVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String fullscreenTitle;
  final BorderRadius borderRadius;
  final List<Color> gradientColors;
  final Widget Function(double bottomInset)? overlayBuilder;

  const _GuidesInlineVideoPlayer({
    required this.videoPath,
    required this.fullscreenTitle,
    required this.borderRadius,
    required this.gradientColors,
    this.overlayBuilder,
  });

  @override
  State<_GuidesInlineVideoPlayer> createState() =>
      _GuidesInlineVideoPlayerState();
}

class _GuidesInlineVideoPlayerState extends State<_GuidesInlineVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initFuture;
  Timer? _controlsTimer;
  bool _showControls = true;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setLooping(true)
      ..addListener(_handleVideoTick);
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller
      ..removeListener(_handleVideoTick)
      ..dispose();
    super.dispose();
  }

  void _handleVideoTick() {
    if (!mounted) return;
    final isPlaying = _controller.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      if (isPlaying) {
        _startAutoHideTimer();
      } else {
        _controlsTimer?.cancel();
        _showControls = true;
      }
    }
    setState(() {});
  }

  void _startAutoHideTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_controller.value.isPlaying) return;
      setState(() => _showControls = false);
    });
  }

  void _onSurfaceTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _controller.value.isPlaying) {
      _startAutoHideTimer();
    }
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
      _controlsTimer?.cancel();
      setState(() => _showControls = true);
      return;
    }
    _controller.play();
    setState(() => _showControls = true);
    _startAutoHideTimer();
  }

  void _seekBy(int seconds) {
    if (!_controller.value.isInitialized) return;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final target = position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    _controller.seekTo(clamped);
  }

  Future<void> _openFullscreen() async {
    if (!_controller.value.isInitialized) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GuidesFullscreenVideoScreen(
          controller: _controller,
          title: widget.fullscreenTitle,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _showControls = true);
    if (_controller.value.isPlaying) _startAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _controller.value.duration;
    final position = _controller.value.position > duration
        ? duration
        : _controller.value.position;
    final maxMs = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentMs = position.inMilliseconds
        .clamp(0, maxMs.toInt())
        .toDouble();

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ColoredBox(
                    color: Color(0xFF0F172A),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }
                return _VideoCover(controller: _controller);
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: widget.gradientColors,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onSurfaceTap,
            ),
          ),
          if (widget.overlayBuilder != null)
            Positioned.fill(
              child: IgnorePointer(
                child: widget.overlayBuilder!(60),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
              color: Colors.black.withOpacity(0.32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        onPressed: _controller.value.isInitialized
                            ? () => _seekBy(-10)
                            : null,
                        icon: const Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        onPressed: _controller.value.isInitialized
                            ? () => _seekBy(10)
                            : null,
                        icon: const Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 10,
                            ),
                          ),
                          child: Slider(
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.35),
                            value: currentMs,
                            min: 0,
                            max: maxMs,
                            onChanged: (value) {
                              _controller.seekTo(
                                Duration(milliseconds: value.round()),
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        onPressed: _openFullscreen,
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showControls)
            Positioned.fill(
              child: Center(
                child: _ControlCircle(
                  icon: _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  onTap: _togglePlayPause,
                  size: 44,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuidesFullscreenVideoScreen extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;

  const _GuidesFullscreenVideoScreen({
    required this.controller,
    required this.title,
  });

  @override
  State<_GuidesFullscreenVideoScreen> createState() =>
      _GuidesFullscreenVideoScreenState();
}

class _GuidesFullscreenVideoScreenState
    extends State<_GuidesFullscreenVideoScreen> {
  Timer? _controlsTimer;
  bool _showControls = true;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleVideoTick);
    if (widget.controller.value.isPlaying) _startAutoHideTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    widget.controller.removeListener(_handleVideoTick);
    super.dispose();
  }

  void _handleVideoTick() {
    if (!mounted) return;
    final isPlaying = widget.controller.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      if (isPlaying) {
        _startAutoHideTimer();
      } else {
        _controlsTimer?.cancel();
        _showControls = true;
      }
    }
    setState(() {});
  }

  void _startAutoHideTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !widget.controller.value.isPlaying) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleSurface() {
    setState(() => _showControls = !_showControls);
    if (_showControls && widget.controller.value.isPlaying) {
      _startAutoHideTimer();
    }
  }

  void _togglePlayPause() {
    if (!widget.controller.value.isInitialized) return;
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      _controlsTimer?.cancel();
      setState(() => _showControls = true);
      return;
    }
    widget.controller.play();
    setState(() => _showControls = true);
    _startAutoHideTimer();
  }

  void _seekBy(int seconds) {
    if (!widget.controller.value.isInitialized) return;
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    final target = position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    widget.controller.seekTo(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(top: false, bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSurface,
                child: controller.value.isInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            if (_showControls || !controller.value.isPlaying)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    _ControlCircle(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _ControlCircle(
                      icon: Icons.fullscreen_exit,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            if (_showControls || !controller.value.isPlaying)
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ControlCircle(
                          icon: Icons.replay_10,
                          onTap: () => _seekBy(-10),
                        ),
                        const SizedBox(width: 16),
                        _ControlCircle(
                          icon: controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          onTap: _togglePlayPause,
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        _ControlCircle(
                          icon: Icons.forward_10,
                          onTap: () => _seekBy(10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _VideoTimeline(
                      controller: controller,
                      onSeek: (value) => controller.seekTo(
                        Duration(milliseconds: value.round()),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlCircle({
    required this.icon,
    required this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

class _VideoTimeline extends StatelessWidget {
  final VideoPlayerController controller;
  final ValueChanged<double> onSeek;

  const _VideoTimeline({
    required this.controller,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final duration = controller.value.duration;
    final position = controller.value.position > duration
        ? duration
        : controller.value.position;
    final maxMs = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentMs = position.inMilliseconds
        .clamp(0, maxMs.toInt())
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      color: Colors.black.withOpacity(0.22),
      child: Row(
        children: [
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                value: currentMs,
                min: 0,
                max: maxMs,
                onChanged: onSeek,
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _VideoCover extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoCover({required this.controller});

  @override
  Widget build(BuildContext context) {
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

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}







