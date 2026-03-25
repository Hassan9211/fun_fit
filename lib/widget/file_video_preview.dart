import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fun_fit/widget/app_colors.dart';
import 'package:video_player/video_player.dart';

import '../services/media_source_resolver.dart';

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
  bool _initStarted = false;
  Timer? _deferredInitTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeInit();
  }

  @override
  void didUpdateWidget(covariant FileVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pathChanged = oldWidget.path != widget.path;
    if (pathChanged) {
      _deferredInitTimer?.cancel();
      _disposeController();
      _failed = false;
      _initStarted = false;
      _maybeInit();
      return;
    }
    if (oldWidget.enablePlayback != widget.enablePlayback ||
        oldWidget.autoplay != widget.autoplay ||
        oldWidget.muted != widget.muted) {
      if (!_initStarted) {
        _maybeInit();
        return;
      }
      _syncPlayback();
    }
  }

  void _maybeInit() {
    if (_initStarted || _failed) return;
    if (!widget.enablePlayback &&
        Scrollable.recommendDeferredLoadingForContext(context)) {
      _deferredInitTimer?.cancel();
      _deferredInitTimer = Timer(
        const Duration(milliseconds: 180),
        () {
          if (mounted) _maybeInit();
        },
      );
      return;
    }
    _initStarted = true;
    _init();
  }

  Future<void> _init() async {
    final source = MediaSourceResolver.resolve(widget.path);
    if (source.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    late final VideoPlayerController controller;
    if (MediaSourceResolver.isNetworkLike(source)) {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(source),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: widget.muted),
      );
    } else {
      if (!MediaSourceResolver.existsLocally(source)) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      controller = VideoPlayerController.file(
        File(MediaSourceResolver.localFilePath(source)),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: widget.muted),
      );
    }

    try {
      await _VideoPreviewTaskQueue.run(
        () async {
          await controller.initialize();
          await _applyPlayback(controller);
        },
        highPriority: widget.enablePlayback,
      );
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

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await _applyPlayback(controller);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _applyPlayback(VideoPlayerController controller) async {
    await controller.setLooping(widget.enablePlayback);
    await controller.setVolume(
      widget.enablePlayback && !widget.muted ? 1 : 0,
    );
    if (widget.enablePlayback && widget.autoplay) {
      await controller.play();
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    }
    await controller.seekTo(Duration.zero);
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _deferredInitTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final fallback =
        widget.fallback ??
        ColoredBox(
          color: AppColors.cFF111111,
          child: Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: widget.playIconSize,
            ),
          ),
        );

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

class _VideoPreviewTaskQueue {
  static const int _maxConcurrentTasks = 2;
  static final Queue<_VideoPreviewTask<dynamic>> _pendingTasks =
      Queue<_VideoPreviewTask<dynamic>>();
  static int _runningTasks = 0;

  static Future<T> run<T>(
    Future<T> Function() task, {
    bool highPriority = false,
  }) {
    final completer = Completer<T>();
    final queuedTask = _VideoPreviewTask<T>(
      task: task,
      completer: completer,
    );
    if (highPriority) {
      _pendingTasks.addFirst(queuedTask);
    } else {
      _pendingTasks.addLast(queuedTask);
    }
    _drain();
    return completer.future;
  }

  static void _drain() {
    if (_runningTasks >= _maxConcurrentTasks || _pendingTasks.isEmpty) {
      return;
    }

    final task = _pendingTasks.removeFirst();
    _runningTasks += 1;
    Future<void>.sync(() async {
      try {
        final result = await task.task();
        task.completer.complete(result);
      } catch (error, stackTrace) {
        task.completer.completeError(error, stackTrace);
      } finally {
        _runningTasks -= 1;
        scheduleMicrotask(_drain);
      }
    });
  }
}

class _VideoPreviewTask<T> {
  final Future<T> Function() task;
  final Completer<T> completer;

  const _VideoPreviewTask({
    required this.task,
    required this.completer,
  });
}
