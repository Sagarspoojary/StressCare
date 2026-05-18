import 'package:flutter/material.dart';
import '../utils/web_helper.dart';

Widget buildWaveformPlayer(String audioUrl, Color primaryColor, Color surfaceColor) {
  final String divId = 'waveform-${audioUrl.hashCode}';
  final String viewType = 'waveform-view-$divId';
  
  // Register the factory for this unique view
  registerSpecificWaveformView(viewType, divId);

  // Initialise waveform after build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    callJsMethod('initWaveform', [divId, audioUrl]);
  });

  return Container(
    width: 280,
    height: 65,
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: surfaceColor.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: primaryColor.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Play/Pause Toggle Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => callJsMethod('toggleWaveform', [divId]),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: primaryColor,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // HTML Element View for WaveSurfer.js
        Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.centerLeft,
            child: HtmlElementView(viewType: viewType),
          ),
        ),
      ],
    ),
  );
}
