import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart' as ca;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_colors.dart';
import 'responsive_layout.dart';

class RecordWithAudioScreen extends StatefulWidget {
  final String? challengeName;

  const RecordWithAudioScreen({super.key, this.challengeName});

  @override
  State<RecordWithAudioScreen> createState() => _RecordWithAudioScreenState();
}

class _RecordWithAudioScreenState extends State<RecordWithAudioScreen> {
  bool _returned = false;
  bool _showGrid = false;
  bool _audioEnabled = true;
  DateTime? _recordingStartedAt;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTicker;
  late final Future<bool> _permissionFuture;

  Future<bool> _ensurePermissions() async {
    final micStatus = await Permission.microphone.status;
    final camStatus = await Permission.camera.status;
    final micGranted =
        micStatus.isGranted ? micStatus : await Permission.microphone.request();
    final camGranted =
        camStatus.isGranted ? camStatus : await Permission.camera.request();
    return micGranted.isGranted && camGranted.isGranted;
  }

  @override
  void initState() {
    super.initState();
    _permissionFuture = _ensurePermissions();
  }

  void _returnMedia(String? path) {
    if (_returned || path == null || path.isEmpty || !mounted) return;
    _returned = true;
    Navigator.of(context).pop(path);
  }

  void _startRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingStartedAt = DateTime.now();
    _recordingElapsed = Duration.zero;
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordingStartedAt == null) return;
      setState(() {
        _recordingElapsed = DateTime.now().difference(_recordingStartedAt!);
      });
    });
  }

  void _stopRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStartedAt = null;
    if (!mounted) return;
    setState(() => _recordingElapsed = Duration.zero);
  }

  Future<void> _toggleAudio(CameraState state) async {
    if (state is VideoRecordingCameraState) return;
    final next = !_audioEnabled;
    if (!mounted) return;
    setState(() => _audioEnabled = next);
    state.when(onVideoMode: (videoState) => videoState.enableAudio(next));
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ResponsiveInfo.fromContext(context);
    final cameraTheme = AwesomeTheme(
      bottomActionsBackgroundColor: AppColors.cD7000000,
      buttonTheme: AwesomeButtonTheme(
        backgroundColor: AppColors.cCC000000,
        foregroundColor: AppColors.cFFFFFFFF,
        iconSize: 20,
        padding: const EdgeInsets.all(10),
        buttonBuilder: (child, onTap) {
          return ClipOval(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: AppColors.cD91F2937,
                highlightColor: AppColors.c8A000000,
                child: child,
              ),
            ),
          );
        },
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.cFF000000,
      body: FutureBuilder<bool>(
        future: _permissionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final allowed = snapshot.data == true;
          if (!allowed) {
            return SafeArea(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 420,
                tabletMaxWidth: 480,
                desktopMaxWidth: 520,
                padding: info.pagePadding(
                  mobileHorizontal: 18,
                  tabletHorizontal: 24,
                  desktopHorizontal: 28,
                  mobileVertical: 20,
                  tabletVertical: 24,
                  desktopVertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_off, color: Colors.white, size: 42),
                    const SizedBox(height: 10),
                    const Text(
                      'Camera and microphone permissions are required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please enable permissions in settings and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await openAppSettings();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Open settings'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return CameraAwesomeBuilder.awesome(
            theme: cameraTheme,
            previewFit: CameraPreviewFit.cover,
            enablePhysicalButton: true,
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(SensorPosition.back),
              flashMode: FlashMode.auto,
              aspectRatio: CameraAspectRatios.ratio_16_9,
            ),
            saveConfig: SaveConfig.video(
              pathBuilder: (sensors) async {
                final dir = await getTemporaryDirectory();
                final folder = Directory('${dir.path}/camerawesome');
                if (!await folder.exists()) {
                  await folder.create(recursive: true);
                }
                final filePath =
                    '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
                final sensor = sensors.isNotEmpty
                    ? sensors.first
                    : Sensor.position(SensorPosition.back);
                return SingleCaptureRequest(filePath, sensor);
              },
              videoOptions: ca.VideoOptions(
                enableAudio: true,
                quality: ca.VideoRecordingQuality.hd,
                android: ca.AndroidVideoOptions(
                  fallbackStrategy: ca.QualityFallbackStrategy.lower,
                ),
              ),
            ),
            onMediaCaptureEvent: (event) {
              if (event.isRecordingVideo &&
                  event.status == MediaCaptureStatus.capturing) {
                if (_recordingStartedAt == null) {
                  _startRecordingTicker();
                }
              } else if (_recordingStartedAt != null) {
                _stopRecordingTicker();
              }
              switch ((event.status, event.isPicture, event.isVideo)) {
                case (MediaCaptureStatus.success, false, true):
                  event.captureRequest.when(
                    single: (single) => _returnMedia(single.file?.path),
                    multiple: (multiple) {
                      for (final value in multiple.fileBySensor.values) {
                        if (value?.path != null) {
                          _returnMedia(value!.path);
                          break;
                        }
                      }
                    },
                  );
                default:
                  break;
              }
            },
            previewDecoratorBuilder: (state, preview) {
              return IgnorePointer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _CameraGradientOverlay(),
                    AnimatedOpacity(
                      opacity: _showGrid ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: CustomPaint(
                        painter: const _CameraGridPainter(
                          color: AppColors.cD9FFFFFF,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            topActionsBuilder: (state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _CameraActionButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RecordTitlePill(
                        state: state,
                        elapsed: _recordingElapsed,
                        challengeName: widget.challengeName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AwesomeFlashButton(state: state),
                    const SizedBox(width: 8),
                    _CameraActionButton(
                      icon: _showGrid ? Icons.grid_on : Icons.grid_off,
                      onTap: () {
                        setState(() => _showGrid = !_showGrid);
                      },
                    ),
                    const SizedBox(width: 8),
                    _CameraActionButton(
                      icon: _audioEnabled ? Icons.mic : Icons.mic_off,
                      onTap: state is VideoRecordingCameraState
                          ? null
                          : () => _toggleAudio(state),
                    ),
                  ],
                ),
              );
            },
            middleContentBuilder: (state) {
              return Column(
                children: [
                  const Spacer(),
                  AwesomeFilterWidget(
                    state: state,
                    filterListPosition: FilterListPosition.aboveButton,
                    filterListPadding: const EdgeInsets.only(bottom: 8),
                  ),
                  Builder(
                    builder: (context) {
                      final background = AwesomeThemeProvider.of(context)
                          .theme
                          .bottomActionsBackgroundColor;
                      return Container(
                        color: background,
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: _RecordHintLabel(state: state),
                      );
                    },
                  ),
                ],
              );
            },
            bottomActionsBuilder: (state) => AwesomeBottomActions(
              state: state,
              left: state is VideoRecordingCameraState
                  ? AwesomePauseResumeButton(state: state)
                  : AwesomeCameraSwitchButton(state: state, scale: 1.05),
              right: _CameraMediaPreview(state: state),
            ),
          );
        },
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CameraActionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    final idleTheme = theme.copyWith(
      buttonTheme: theme.buttonTheme.copyWith(
        foregroundColor: AppColors.cFF8A8A8A,
      ),
    );
    final buttonTheme = onTap == null ? idleTheme : theme;
    final child = AwesomeCircleWidget.icon(
      icon: icon,
      theme: buttonTheme,
      scale: 0.95,
    );
    if (onTap == null) {
      return Opacity(opacity: 0.6, child: child);
    }
    return theme.buttonTheme.buttonBuilder(child, onTap!);
  }
}

class _RecordTitlePill extends StatelessWidget {
  final CameraState state;
  final Duration elapsed;
  final String? challengeName;

  const _RecordTitlePill({
    required this.state,
    required this.elapsed,
    this.challengeName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaCapture?>(
      stream: state.captureState$,
      builder: (context, snapshot) {
        final recording = snapshot.data?.isRecordingVideo == true;
        final minutes =
            elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds =
            elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
        final timeLabel = '$minutes:$seconds';
        final trimmedName = (challengeName ?? '').trim();
        final hasName = trimmedName.isNotEmpty;
        return Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cCC000000,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cD9FFFFFF),
            ),
            child: hasName
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trimmedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.cFFFFFFFF,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (recording) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.cFFFF4D4D,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            recording ? 'Recording $timeLabel' : 'Ready to record',
                            style: const TextStyle(
                              color: AppColors.cFFD1D5DB,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (recording) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.cFFFF4D4D,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        recording ? 'Recording $timeLabel' : 'Record Challenge',
                        style: const TextStyle(
                          color: AppColors.cFFFFFFFF,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _RecordHintLabel extends StatelessWidget {
  final CameraState state;

  const _RecordHintLabel({required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaCapture?>(
      stream: state.captureState$,
      builder: (context, snapshot) {
        final recording = snapshot.data?.isRecordingVideo == true;
        return Text(
          recording ? 'Tap again to stop' : 'Tap to start recording',
          style: const TextStyle(
            color: AppColors.cFFD1D5DB,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

class _CameraMediaPreview extends StatelessWidget {
  final CameraState state;

  const _CameraMediaPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaCapture?>(
      stream: state.captureState$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 60, height: 60);
        }
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cD9FFFFFF, width: 1),
            color: AppColors.cCC000000,
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AwesomeMediaPreview(
              mediaCapture: snapshot.requireData,
              onMediaTap: null,
            ),
          ),
        );
      },
    );
  }
}

class _CameraGradientOverlay extends StatelessWidget {
  const _CameraGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cD7000000,
                AppColors.c00111111,
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.c00111111,
                AppColors.cD7000000,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraGridPainter extends CustomPainter {
  final Color color;

  const _CameraGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CameraGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
