import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FileVideoPreview extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final bool autoplay;
  final bool showPlayOverlay;
  final double playIconSize;
  final Widget? fallback;
  final bool muted;
  final bool enablePlayback;

  const FileVideoPreview({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.autoplay = true,
    this.showPlayOverlay = true,
    this.playIconSize = 36,
    this.fallback,
    this.muted = true,
    this.enablePlayback = true,
  });

  @override
  State<FileVideoPreview> createState() => _FileVideoPreviewState();
}

class _FileVideoPreviewState extends State<FileVideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.enablePlayback) {
      _init();
    }
  }

  @override
  void didUpdateWidget(covariant FileVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enablePlayback && !widget.enablePlayback) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
    } else if (!oldWidget.enablePlayback && widget.enablePlayback) {
      _init();
    }
  }

  Future<void> _init() async {
    final file = File(widget.path);
    if (!file.existsSync()) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.file(
      file,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: widget.muted),
    );
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (widget.autoplay) {
        await controller.play();
      }
      if (!widget.muted) {
        await controller.setVolume(1);
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _failed = true);
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
    final fallback =
        widget.fallback ??
        ColoredBox(
          color: const Color(0xFF111111),
          child: Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: widget.playIconSize,
            ),
          ),
        );

    if (!widget.enablePlayback) {
      return fallback;
    }

    if (_failed || controller == null || !controller.value.isInitialized) {
      return fallback;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        if (widget.showPlayOverlay)
          Center(
            child: IgnorePointer(
              child: Container(
                width: widget.playIconSize + 14,
                height: widget.playIconSize + 14,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: widget.playIconSize,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
