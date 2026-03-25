import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

mixin VideoPlaybackLifecycleMixin<T extends StatefulWidget> on State<T> {
  bool _resumeOnForeground = false;
  AppLifecycleListener? _lifecycleListener;

  VideoPlayerController? get lifecycleVideoController;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: _resumePlaybackIfNeeded,
      onInactive: _pausePlaybackForLifecycle,
      onHide: _pausePlaybackForLifecycle,
      onPause: _pausePlaybackForLifecycle,
    );
  }

  Future<void> _pausePlaybackForLifecycle() async {
    final controller = lifecycleVideoController;
    if (controller == null || !controller.value.isInitialized) return;
    _resumeOnForeground = controller.value.isPlaying;
    if (!_resumeOnForeground) return;
    await controller.pause();
    if (mounted) setState(() {});
  }

  Future<void> _resumePlaybackIfNeeded() async {
    final controller = lifecycleVideoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_resumeOnForeground) return;
    _resumeOnForeground = false;
    await controller.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }
}
