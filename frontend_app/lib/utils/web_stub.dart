import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void registerGlobalWaveformView() {
  // Stub
}

void registerSpecificWaveformView(String viewType, String divId) {
  // Stub
}

void callJsMethod(String method, List<dynamic> args) {
  // Stub
}

final AudioRecorder _audioRecorder = AudioRecorder();
Function(Uint8List bytes, String url)? _onStopCallback;

void startWebRecording({
  required Function(Uint8List bytes, String url) onStop,
  required Function(String error) onError,
  required Function() onStart,
}) async {
  _onStopCallback = onStop;
  try {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/my_audio.m4a';
      
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      onStart();
    } else {
      onError("Microphone permission denied");
    }
  } catch (e) {
    onError(e.toString());
  }
}

void stopWebRecording() async {
  try {
    final path = await _audioRecorder.stop();
    if (path != null && _onStopCallback != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      _onStopCallback!(bytes, path);
    }
  } catch (e) {
    print("Error stopping recorder: $e");
  }
}
