import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorder {
  final _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  DateTime? _startTime;
  String? _recordingPath;

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) return;

    final tempDir = await getTemporaryDirectory();
    _recordingPath =
        '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    _startTime = DateTime.now();

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized || _recordingPath == null) return null;

    await _recorder.stopRecorder();
    final duration = DateTime.now().difference(_startTime!);

    // Only return the recording if it's longer than 1 second
    if (duration.inSeconds < 1) {
      File(_recordingPath!).deleteSync();
      return null;
    }

    return _recordingPath;
  }

  Future<void> dispose() async {
    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
  }
}
