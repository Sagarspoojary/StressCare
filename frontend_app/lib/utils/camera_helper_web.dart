import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';

/// Main entry point for web camera handling with LIVE EMOTION DETECTION
Future<void> openWebCamera(BuildContext context, Function(String) onSuccess) async {
  try {
    // Call the JS function defined in index.html
    js.context.callMethod('openCamera', [
      js.allowInterop((String emotion) {
        onSuccess("Live Emotion Detected: $emotion");
      })
    ]);
  } catch (e) {
    print("Camera Error: $e");
    // Fallback to standard file picker if JS fails
    openFilePicker(context, onSuccess);
  }
}

/// Helper to request camera directly (In-App style for web) - DEPRECATED for Live Detection
void _openInAppCamera(BuildContext context, Function(String) onSuccess) {
  openWebCamera(context, onSuccess);
}

/// Standard file picker fallback
void openFilePicker(BuildContext context, Function(String) onSuccess) {
  final html.FileUploadInputElement input = html.FileUploadInputElement();
  input.accept = 'image/*';
  
  input.click();

  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file != null) {
      onSuccess("Image selected");
    }
  });
}
