// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../widget/home_bottom_nav.dart';
import '../widget/getx.dart';

class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

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
        final mediaHeight = isDesktop
            ? 190.0
            : isTablet
            ? 175.0
            : 160.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FB),
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    _BlueHeader(
                      title: 'Guides',
                      showBack: true,
                      onBackTap: () => Get.offNamed(Routes.home),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 24),
                        children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Recommended Meal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/healthy bowl.jpg',
                          height: mediaHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [Color(0xAA0F172A), Color(0x000F172A)],
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 16,
                          bottom: 16,
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
                              SizedBox(height: 4),
                              Text(
                                '1648kcl',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Workout Videos',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: mediaHeight,
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
                  const SizedBox(height: 18),
                  const Text(
                    'Challenge Tutorial Guide',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
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
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1D3DBB),
            onPressed: () {},
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Guides'),
        );
      },
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackTap;

  const _BlueHeader({
    required this.title,
    this.showBack = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF1D3DBB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          if (showBack)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: onBackTap ?? () => Navigator.of(context).pop(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
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
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: _GuidesInlineVideoPlayer(
        videoPath: videoPath,
        fullscreenTitle: title,
        borderRadius: BorderRadius.circular(18),
        gradientColors: const [Color(0xCC0F172A), Color(0x000F172A)],
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _Pill(label: kcal),
                    const SizedBox(width: 6),
                    _Pill(label: minutes),
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
        borderRadius: BorderRadius.circular(18),
        gradientColors: const [Color(0x770F172A), Color(0x000F172A)],
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

  void _seekToMilliseconds(double value) {
    if (!_controller.value.isInitialized) return;
    _controller.seekTo(Duration(milliseconds: value.round()));
  }

  Future<void> _openFullscreen() async {
    if (!_controller.value.isInitialized) return;
    setState(() => _showControls = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GuidesFullscreenVideoScreen(
          controller: _controller,
          title: widget.fullscreenTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: widget.overlayBuilder!(
                  (_showControls || !_controller.value.isPlaying) ? 38 : 8,
                ),
              ),
            ),
          if (_showControls || !_controller.value.isPlaying)
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
                      const SizedBox(width: 10),
                      _ControlCircle(
                        icon: _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        onTap: _togglePlayPause,
                        size: 42,
                      ),
                      const SizedBox(width: 10),
                      _ControlCircle(
                        icon: Icons.forward_10,
                        onTap: () => _seekBy(10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _VideoTimeline(
                    controller: _controller,
                    onSeek: _seekToMilliseconds,
                    onFullscreen: _openFullscreen,
                  ),
                ],
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
                      icon: Icons.arrow_back,
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
  final VoidCallback? onFullscreen;

  const _VideoTimeline({
    required this.controller,
    required this.onSeek,
    this.onFullscreen,
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
          if (onFullscreen != null)
            IconButton(
              iconSize: 18,
              padding: const EdgeInsets.only(left: 2),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white),
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

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}





