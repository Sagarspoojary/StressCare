import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'dart:typed_data';


void registerGlobalWaveformView() {
  ui_web.platformViewRegistry.registerViewFactory(
    'waveform-view',
    (int viewId) => html.DivElement()
      ..id = 'waveform-$viewId'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#dcf8c6'
  );
}

void registerSpecificWaveformView(String viewType, String divId) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => html.DivElement()
      ..id = divId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent'
      ..style.borderRadius = '12px'
      ..style.display = 'flex'
      ..style.alignItems = 'center',
  );
}

void callJsMethod(String method, List<dynamic> args) {
  js.context.callMethod(method, args);
}

html.MediaRecorder? _mediaRecorder;
List<html.Blob> _audioChunks = [];

void startWebRecording({
  required Function(Uint8List bytes, String url) onStop,
  required Function(String error) onError,
  required Function() onStart,
}) async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      onError("Media devices not supported in this browser");
      return;
    }
    
    final stream = await mediaDevices.getUserMedia({'audio': true});
    _mediaRecorder = html.MediaRecorder(stream);
    _audioChunks = [];

    _mediaRecorder?.addEventListener('dataavailable', (event) {
      final html.Blob blob = (event as dynamic).data;
      if (blob.size > 0) {
        _audioChunks.add(blob);
      }
    });

    _mediaRecorder?.addEventListener('stop', (event) async {
      if (_audioChunks.isEmpty) {
        onError("No audio chunks captured");
        return;
      }
      
      final audioBlob = html.Blob(_audioChunks, 'audio/webm;codecs=opus');
      final audioUrl = html.Url.createObjectUrlFromBlob(audioBlob);
      
      // Convert Blob to bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(audioBlob);
      await reader.onLoad.first;
      final Uint8List bytes = reader.result as Uint8List;
      
      onStop(bytes, audioUrl);
    });

    _mediaRecorder?.start();
    onStart();
    
  } catch (e) {
    onError(e.toString());
  }
}

void stopWebRecording() {
  _mediaRecorder?.stop();
}
