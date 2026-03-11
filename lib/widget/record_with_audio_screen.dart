import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart' as ca;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RecordWithAudioScreen extends StatefulWidget {
  const RecordWithAudioScreen({super.key});

  @override
  State<RecordWithAudioScreen> createState() => _RecordWithAudioScreenState();
}

class _RecordWithAudioScreenState extends State<RecordWithAudioScreen> {
  bool _returned = false;

  void _returnMedia(String? path) {
    if (_returned || path == null || path.isEmpty || !mounted) return;
    _returned = true;
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
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
          videoOptions: ca.VideoOptions(enableAudio: true),
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
      ),
    );
  }
}
