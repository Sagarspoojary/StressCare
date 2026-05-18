import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import '../ml/services/face_detector_service.dart';
import '../ml/services/emotion_classifier_service.dart';
import '../ml/overlays/face_detector_painter.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({Key? key}) : super(key: key);

  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  final EmotionClassifierService _emotionClassifierService = EmotionClassifierService();
  
  List<Face> _faces = [];
  Rect? _smoothedRect;
  String _detectedEmotion = "Detecting...";
  Size? _imageSize;
  InputImageRotation? _rotation;
  
  bool _isProcessing = false;

  int _frameSkipFactor = 2; // Process more frames for smoother detection
  int _consecutiveSlowFrames = 0;
  
  // Debug UI Toggle (Keep false for production feel)
  final bool _showDebugUI = false;

  // FPS Tracking
  int _totalFrameCount = 0;
  double _fps = 0;
  DateTime? _lastFpsCalc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController!.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _startCameraStream();
      }
    }
  }

  Future<void> _initialize() async {
    print("🎬 Starting Face Detection Screen Initialization...");
    _faceDetectorService.initialize();
    print("⏳ Initializing Emotion Classifier...");
    await _emotionClassifierService.initialize();
    print("✅ Emotion Classifier Status: ${_emotionClassifierService.isLoaded ? 'LOADED' : 'FAILED'}");
    
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Use front camera if available
        final frontCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
        
        _emotionClassifierService.sensorOrientation = frontCamera.sensorOrientation;
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium, // Increased for better accuracy
          enableAudio: false,
          imageFormatGroup: io.Platform.isAndroid 
              ? ImageFormatGroup.nv21 
              : ImageFormatGroup.bgra8888,
        );
        
        await _cameraController!.initialize();
        
        _startCameraStream();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _startCameraStream() {
    int frameCount = 0;
    _cameraController!.startImageStream((image) {
      frameCount++;
      
      // Adaptive FPS: process based on current skip factor
      if (frameCount % _frameSkipFactor == 0) {
        if (!_isProcessing) {
          _isProcessing = true;
          _processCameraImage(image);
        }
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final sw = Stopwatch()..start();
    try {
      final faces = await _faceDetectorService.detectFacesFromCameraImage(
        image, 
        _cameraController!, 
        _cameras
      );
      
      if (faces.isNotEmpty) {
        print("👤 Detected ${faces.length} face(s)");
      }
      
      Rect? targetRect;
      String emotion = "Neutral";
      if (faces.isNotEmpty) {
        targetRect = faces.first.boundingBox;
        // Run emotion classification on the first face
        emotion = await _emotionClassifierService.classifyEmotion(faces.first, image);
      }
      
      if (mounted) {
        setState(() {
          _faces = faces;
          _detectedEmotion = emotion;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _rotation = InputImageRotationValue.fromRawValue(_cameraController!.description.sensorOrientation);
          
          if (targetRect != null) {
            if (_smoothedRect == null) {
              _smoothedRect = targetRect;
            } else {
              // Exponential Moving Average for box stabilization
              const double alpha = 0.3; // Lower = smoother but laggy, Higher = jittery but fast
              _smoothedRect = Rect.fromLTRB(
                _smoothedRect!.left * (1 - alpha) + targetRect.left * alpha,
                _smoothedRect!.top * (1 - alpha) + targetRect.top * alpha,
                _smoothedRect!.right * (1 - alpha) + targetRect.right * alpha,
                _smoothedRect!.bottom * (1 - alpha) + targetRect.bottom * alpha,
              );
            }
          } else {
            _smoothedRect = null;
          }

          // FPS Calculation
          _totalFrameCount++;
          final now = DateTime.now();
          if (_lastFpsCalc == null) {
            _lastFpsCalc = now;
          } else {
            final diff = now.difference(_lastFpsCalc!).inMilliseconds;
            if (diff >= 1000) {
              _fps = (_totalFrameCount * 1000) / diff;
              _totalFrameCount = 0;
              _lastFpsCalc = now;
            }
          }
        });
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      sw.stop();
      print("⏱️ Frame Total Time: ${sw.elapsedMilliseconds}ms");
      
      // Adaptive FPS logic
      if (sw.elapsedMilliseconds > 150) {
        _consecutiveSlowFrames++;
        if (_consecutiveSlowFrames > 5 && _frameSkipFactor < 10) {
          _frameSkipFactor++;
          print("⚠️ CPU too slow, increased frame skip to $_frameSkipFactor");
          _consecutiveSlowFrames = 0;
        }
      } else {
        _consecutiveSlowFrames = 0;
        if (_frameSkipFactor > 3) {
           _frameSkipFactor--; // Slowly recover to better FPS
        }
      }
      
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceDetectorService.dispose();
    _emotionClassifierService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emotion Detection"),
        backgroundColor: Colors.black,
        actions: [
          if (_showDebugUI && kDebugMode)
            DropdownButton<int>(
              dropdownColor: Colors.black,
              value: EmotionClassifierService.availableConfigs.indexOf(_emotionClassifierService.currentConfig),
              items: EmotionClassifierService.availableConfigs.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  setState(() {
                    _isCameraInitialized = false; // Show loader while switching
                  });
                  await _emotionClassifierService.switchModel(val);
                  setState(() {
                    _isCameraInitialized = true;
                  });
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_cameraController!),
          ),
          // Overlay
          if (_imageSize != null && _rotation != null)
            CustomPaint(
              painter: FaceDetectorPainter(
                _smoothedRect, 
                _imageSize!, 
                _rotation!, 
                _detectedEmotion,
                cropPadding: _emotionClassifierService.cropPadding,
                showContextBox: _showDebugUI,
              ),
              child: Container(),
            ),
          
          // Debug Overlay (Visible only if _showDebugUI is true)
          if (_showDebugUI && kDebugMode)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Model: ${_emotionClassifierService.lastModelName}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    Text("Input: ${_emotionClassifierService.lastInputShape}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    Text("Inference: ${_emotionClassifierService.lastInferenceTime}ms", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    Text("FPS: ${_fps.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    Text("Conf: ${(_emotionClassifierService.lastConfidence * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 10)),
                    const SizedBox(height: 4),
                    const Text("Crop Padding:", style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                    Row(
                      children: [0.1, 0.2, 0.3, 0.4].map((p) {
                        bool isSelected = _emotionClassifierService.cropPadding == p;
                        return GestureDetector(
                          onTap: () => setState(() => _emotionClassifierService.cropPadding = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.yellow : Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text("${(p * 100).toInt()}%", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 8)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // Control Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context, "Live Emotion Detected: $_detectedEmotion");
                },
                child: const Text("Use This Emotion", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
