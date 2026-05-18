import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPainter extends CustomPainter {
  final Rect? smoothedRect;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final String detectedEmotion;
  final double cropPadding;
  final bool showContextBox;

  FaceDetectorPainter(
    this.smoothedRect, 
    this.absoluteImageSize, 
    this.rotation, 
    this.detectedEmotion, 
    {this.cropPadding = 0.0, this.showContextBox = false}
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (smoothedRect == null || absoluteImageSize.width == 0 || absoluteImageSize.height == 0) return;

    try {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.greenAccent;

      final Paint contextPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.yellow.withOpacity(0.5);

      // ML Kit returns size in landscape mode often, so we might need to swap width and height!
      final bool isRotated = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
      final double correctedWidth = isRotated ? absoluteImageSize.height : absoluteImageSize.width;
      final double correctedHeight = isRotated ? absoluteImageSize.width : absoluteImageSize.height;

      if (correctedWidth == 0 || correctedHeight == 0) return;

      final double scaleX = size.width / correctedWidth;
      final double scaleY = size.height / correctedHeight;

      // Scale coordinates
      final scaledRect = Rect.fromLTRB(
        smoothedRect!.left * scaleX,
        smoothedRect!.top * scaleY,
        smoothedRect!.right * scaleX,
        smoothedRect!.bottom * scaleY,
      );

      if (scaledRect.hasNaN || scaledRect.isInfinite) return;

      // Draw expanded context box (Yellow) - Only if enabled
      if (showContextBox && cropPadding > 0) {
        double padW = scaledRect.width * cropPadding;
        double padH = scaledRect.height * cropPadding;
        final expandedRect = Rect.fromLTRB(
          scaledRect.left - padW,
          scaledRect.top - padH,
          scaledRect.right + padW,
          scaledRect.bottom + padH,
        );
        canvas.drawRect(expandedRect, contextPaint);
      }

      // Draw bounding box
      canvas.drawRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(12)), paint);
      
      // Draw emotion label
      final textSpan = TextSpan(
        text: detectedEmotion,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black45
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - 25));
    } catch (e) {
      print("Painter error: $e");
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.smoothedRect != smoothedRect || oldDelegate.detectedEmotion != detectedEmotion;
  }
}
