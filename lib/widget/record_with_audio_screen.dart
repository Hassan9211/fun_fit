import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart' as ca;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordWithAudioScreen extends StatefulWidget {
  const RecordWithAudioScreen({super.key});

  @override
  State<RecordWithAudioScreen> createState() => _RecordWithAudioScreenState();
}

class _RecordWithAudioScreenState extends State<RecordWithAudioScreen> {
  bool _returned = false;

  Future<bool> _ensurePermissions() async {
    final micStatus = await Permission.microphone.status;
    final camStatus = await Permission.camera.status;
    final micGranted =
        micStatus.isGranted ? micStatus : await Permission.microphone.request();
    final camGranted =
        camStatus.isGranted ? camStatus : await Permission.camera.request();
    return micGranted.isGranted && camGranted.isGranted;
  }

  void _returnMedia(String? path) {
    if (_returned || path == null || path.isEmpty || !mounted) return;
    _returned = true;
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<bool>(
        future: _ensurePermissions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final allowed = snapshot.data == true;
          if (!allowed) {
            return SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
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
              ),
            );
          }

          return CameraAwesomeBuilder.awesome(
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
            topActionsBuilder: (state) => Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
