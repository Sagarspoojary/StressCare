import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

enum NormalizationMode {
  zeroToOne,        // [0, 1]
  negativeOneToOne, // [-1, 1]
  meanStd,          // (x - mean) / std
}

class EmotionModelConfig {
  final String name;
  final String assetPath;
  final List<String> labels;
  final NormalizationMode normalization;
  final double mean;
  final double std;

  EmotionModelConfig({
    required this.name,
    required this.assetPath,
    required this.labels,
    this.normalization = NormalizationMode.zeroToOne,
    this.mean = 127.5,
    this.std = 127.5,
  });
}

class EmotionClassifierService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  /// Sensor orientation from front camera (usually 270 for front cam on Android)
  int sensorOrientation = 270;

  /// Percentage to expand the face bounding box (0.2 = 20%)
  double cropPadding = 0.2;

  // ── Available Models ──────────────────────────────────────────────────────
  static final List<EmotionModelConfig> availableConfigs = [
    EmotionModelConfig(
      name: "MobileNetV2",
      assetPath: "assets/ml/mobilenet_model.tflite",
      labels: ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"],
      normalization: NormalizationMode.negativeOneToOne,
    ),
    EmotionModelConfig(
      name: "MiniXception",
      assetPath: "assets/ml/emotion_model.tflite",
      labels: ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"],
      normalization: NormalizationMode.zeroToOne,
    ),
  ];

  int _currentConfigIndex = 0;
  EmotionModelConfig get currentConfig => availableConfigs[_currentConfigIndex];

  // ── Performance Metadata ─────────────────────────────────────────────────
  String lastModelName   = "None";
  String lastInputShape  = "None";
  String lastOutputShape = "None";
  int    lastInferenceTime = 0;
  double lastConfidence    = 0.0;

  bool get isLoaded => _isLoaded;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize({int index = 0}) async {
    _currentConfigIndex = index;
    _isLoaded = false;
    if (kDebugMode) print("⏳ Loading: ${currentConfig.name}...");

    try {
      _interpreter?.close();
      _interpreter = await Interpreter.fromAsset(currentConfig.assetPath);
      _isLoaded = true;
      lastModelName = currentConfig.name;
      if (kDebugMode) print("🚀 Loaded ${currentConfig.name}!");
    } catch (e) {
      if (kDebugMode) print("❌ Load failed: $e");
      _isLoaded = false;
    }
  }

  Future<void> switchModel(int index) async {
    await initialize(index: index);
  }

  // ── Main Classification Entry ─────────────────────────────────────────────
  Future<String> classifyEmotion(Face face, CameraImage image) async {
    if (!_isLoaded || _interpreter == null) return "Model Not Loaded";

    try {
      // STEP 1 ─ Convert the ENTIRE frame to grayscale (correct pixel order)
      //           We must rotate the FULL image first so that ML Kit's bounding
      //           box coordinates (which are in display/rotated space) align.
      img.Image? fullGray = _yuvToGray(image);
      if (fullGray == null) return "Neutral";

      // STEP 2 ─ Rotate full frame so it matches display orientation
      //           Front cam on Android is typically 270° rotated.
      fullGray = _rotateImage(fullGray, sensorOrientation);

      // STEP 3 ─ Crop face with padding (now coordinates match)
      final rect = face.boundingBox;
      final double padW = rect.width  * cropPadding;
      final double padH = rect.height * cropPadding;

      final int x = (rect.left   - padW).toInt().clamp(0, fullGray.width  - 1);
      final int y = (rect.top    - padH).toInt().clamp(0, fullGray.height - 1);
      final int w = (rect.width  + 2 * padW).toInt().clamp(1, fullGray.width  - x);
      final int h = (rect.height + 2 * padH).toInt().clamp(1, fullGray.height - y);

      if (w < 30 || h < 30) return "Face too small";

      img.Image faceCrop = img.copyCrop(fullGray, x: x, y: y, width: w, height: h);

      // STEP 4 ─ Histogram equalization for lighting robustness
      faceCrop = _equalizeHistogram(faceCrop);

      // STEP 5 ─ Resize to model input size
      final inputTensor  = _interpreter!.getInputTensor(0);
      lastInputShape     = inputTensor.shape.toString();
      final int tW       = inputTensor.shape[1];
      final int tH       = inputTensor.shape[2];
      final int tC       = inputTensor.shape[3]; // 1 = gray, 3 = rgb

      final resized = img.copyResize(faceCrop, width: tW, height: tH,
          interpolation: img.Interpolation.linear);

      // STEP 6 ─ Build input tensor
      final input = List.filled(tW * tH * tC, 0.0).reshape([1, tH, tW, tC]);
      for (int py = 0; py < tH; py++) {
        for (int px = 0; px < tW; px++) {
          final pixel = resized.getPixel(px, py);
          final double raw = pixel.r.toDouble(); // gray so r=g=b
          final double norm = _normalize(raw);
          if (tC == 1) {
            input[0][py][px][0] = norm;
          } else {
            input[0][py][px][0] = norm;
            input[0][py][px][1] = norm;
            input[0][py][px][2] = norm;
          }
        }
      }

      // STEP 7 ─ Run inference
      final outputTensor = _interpreter!.getOutputTensor(0);
      lastOutputShape    = outputTensor.shape.toString();
      final int numClasses = outputTensor.shape[1];
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

      final sw = Stopwatch()..start();
      _interpreter!.run(input, output);
      sw.stop();
      lastInferenceTime = sw.elapsedMilliseconds;

      return _interpretOutput(output[0].cast<double>());
    } catch (e) {
      if (kDebugMode) print("Inference error: $e");
      return "Neutral";
    }
  }

  // ── Normalize a single pixel value ───────────────────────────────────────
  double _normalize(double raw) {
    switch (currentConfig.normalization) {
      case NormalizationMode.negativeOneToOne:
        return (raw - 127.5) / 127.5;
      case NormalizationMode.meanStd:
        return (raw - currentConfig.mean) / currentConfig.std;
      case NormalizationMode.zeroToOne:
      default:
        return raw / 255.0;
    }
  }

  // ── YUV/NV21 → Grayscale ─────────────────────────────────────────────────
  img.Image? _yuvToGray(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        // Web/iOS: convert from BGRA and extract luma
        final raw = image.planes[0].bytes;
        final result = img.Image(width: image.width, height: image.height);
        for (int py = 0; py < image.height; py++) {
          for (int px = 0; px < image.width; px++) {
            final idx  = (py * image.width + px) * 4;
            // BGRA order: B=0, G=1, R=2, A=3
            final luma = (0.299 * raw[idx + 2] + 0.587 * raw[idx + 1] + 0.114 * raw[idx]).toInt().clamp(0, 255);
            result.setPixelRgb(px, py, luma, luma, luma);
          }
        }
        return result;
      }

      // Android NV21 / YUV420: Y-plane is already luma
      final yPlane    = image.planes[0];
      final yBytes    = yPlane.bytes;
      final rowStride = yPlane.bytesPerRow;
      final result    = img.Image(width: image.width, height: image.height);

      for (int py = 0; py < image.height; py++) {
        for (int px = 0; px < image.width; px++) {
          final luma = yBytes[py * rowStride + px];
          result.setPixelRgb(px, py, luma, luma, luma);
        }
      }
      return result;
    } catch (e) {
      if (kDebugMode) print("YUV conversion error: $e");
      return null;
    }
  }

  // ── Rotate image by sensor orientation degrees ───────────────────────────
  img.Image _rotateImage(img.Image src, int degrees) {
    switch (degrees) {
      case 90:  return img.copyRotate(src, angle: 90);
      case 180: return img.copyRotate(src, angle: 180);
      case 270: return img.copyRotate(src, angle: 270);
      default:  return src;
    }
  }

  // ── Simple histogram equalization for low-light robustness ───────────────
  img.Image _equalizeHistogram(img.Image src) {
    // Build histogram
    final List<int> hist = List.filled(256, 0);
    for (int py = 0; py < src.height; py++) {
      for (int px = 0; px < src.width; px++) {
        final v = src.getPixel(px, py).r.toInt().clamp(0, 255);
        hist[v]++;
      }
    }
    // Cumulative distribution
    final int total = src.width * src.height;
    final List<int> cdf = List.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) cdf[i] = cdf[i - 1] + hist[i];
    final int cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => 0);

    // Build lookup table
    final List<int> lut = List.generate(256, (i) {
      return (((cdf[i] - cdfMin) / (total - cdfMin)) * 255).round().clamp(0, 255);
    });

    // Apply LUT
    final result = img.Image(width: src.width, height: src.height);
    for (int py = 0; py < src.height; py++) {
      for (int px = 0; px < src.width; px++) {
        final v = src.getPixel(px, py).r.toInt().clamp(0, 255);
        final eq = lut[v];
        result.setPixelRgb(px, py, eq, eq, eq);
      }
    }
    return result;
  }

  // ── Smoothing ─────────────────────────────────────────────────────────────
  final List<String> _recentEmotions = [];
  final int _smoothingWindow = 5;

  String _interpretOutput(List<double> probabilities) {
    int maxIndex = 0;
    double maxProb = -1.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }
    lastConfidence = maxProb;

    if (kDebugMode) {
      print("\n--- 🧠 [${currentConfig.name}] ---");
      for (int i = 0; i < probabilities.length; i++) {
        final lbl = i < currentConfig.labels.length ? currentConfig.labels[i] : "?";
        final bar = "█" * (probabilities[i] * 20).toInt();
        print("${lbl.padRight(10)} | ${probabilities[i].toStringAsFixed(3)} | $bar ${i == maxIndex ? "🔥" : ""}");
      }
    }

    // Always return the top emotion (no "Analyzing..." dead-zone)
    final rawLabel = maxIndex < currentConfig.labels.length
        ? currentConfig.labels[maxIndex]
        : "Neutral";

    // Majority-vote smoothing
    _recentEmotions.add(rawLabel);
    if (_recentEmotions.length > _smoothingWindow) _recentEmotions.removeAt(0);

    final Map<String, int> counts = {};
    for (final e in _recentEmotions) counts[e] = (counts[e] ?? 0) + 1;

    String winner = rawLabel;
    int best = 0;
    counts.forEach((k, v) { if (v > best) { best = v; winner = k; } });

    return "$winner (${(maxProb * 100).toStringAsFixed(0)}%)";
  }

  void dispose() {
    _interpreter?.close();
  }
}
