import 'package:flutter/material.dart';
import 'dart:typed_data';



void registerGlobalWaveformView() {
  // Stub
}

void registerSpecificWaveformView(String viewType, String divId) {
  // Stub
}

void callJsMethod(String method, List<dynamic> args) {
  // Stub
}

void startWebRecording({
  required Function(Uint8List bytes, String url) onStop,
  required Function(String error) onError,
  required Function() onStart,
}) {
  onError("Voice recording with waveform is only supported on Web for now.");
}

void stopWebRecording() {
  // Stub
}
