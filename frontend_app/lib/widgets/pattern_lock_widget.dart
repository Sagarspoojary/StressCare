import 'dart:math' as math;
import 'package:flutter/material.dart';

class PatternLockWidget extends StatefulWidget {
  final Function(String pattern) onPatternComplete;
  final String? correctPattern;
  final Color activeColor;
  final Color dotColor;
  final String instructionText;

  const PatternLockWidget({
    super.key,
    required this.onPatternComplete,
    this.correctPattern,
    this.activeColor = const Color(0xFF00C9A7), // Teal
    this.dotColor = Colors.white54,
    this.instructionText = "Draw a pattern to connect the dots",
  });

  @override
  State<PatternLockWidget> createState() => _PatternLockWidgetState();
}

class _PatternLockWidgetState extends State<PatternLockWidget> {
  final List<int> _selectedIndices = [];
  Offset? _currentTouchPosition;
  final List<Offset> _dotPositions = List.filled(9, Offset.zero);
  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            widget.instructionText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              if (!_isInit) {
                // Initialize dot positions on a 3x3 grid
                final step = size / 4;
                for (int row = 0; row < 3; row++) {
                  for (int col = 0; col < 3; col++) {
                    final index = row * 3 + col;
                    _dotPositions[index] = Offset(
                      (col + 1) * step,
                      (row + 1) * step,
                    );
                  }
                }
                _isInit = true;
              }

              return GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _PatternPainter(
                    dotPositions: _dotPositions,
                    selectedIndices: _selectedIndices,
                    currentTouchPosition: _currentTouchPosition,
                    activeColor: widget.activeColor,
                    dotColor: widget.dotColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIndices.clear();
              _currentTouchPosition = null;
            });
          },
          child: Text(
            "Clear Pattern",
            style: TextStyle(color: widget.activeColor.withOpacity(0.8), fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _selectedIndices.clear();
      _currentTouchPosition = details.localPosition;
      _checkCollision(details.localPosition);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentTouchPosition = details.localPosition;
      _checkCollision(details.localPosition);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_selectedIndices.isNotEmpty) {
      final patternString = _selectedIndices.join('-');
      widget.onPatternComplete(patternString);
    }
    setState(() {
      _currentTouchPosition = null;
    });
  }

  void _checkCollision(Offset localPosition) {
    // Collision radius around dots
    const collisionRadius = 28.0;

    for (int i = 0; i < 9; i++) {
      if (_selectedIndices.contains(i)) continue;

      final dotPos = _dotPositions[i];
      final distance = (localPosition - dotPos).distance;

      if (distance <= collisionRadius) {
        // Add middle dot if skipped
        if (_selectedIndices.isNotEmpty) {
          final lastIdx = _selectedIndices.last;
          final int middleIdx = _getMiddleDot(lastIdx, i);
          if (middleIdx != -1 && !_selectedIndices.contains(middleIdx)) {
            _selectedIndices.add(middleIdx);
          }
        }
        _selectedIndices.add(i);
        break;
      }
    }
  }

  // Get index of the dot exactly between direct lines (e.g. 0 to 2 passes 1)
  int _getMiddleDot(int lastIdx, int nextIdx) {
    final int r1 = lastIdx ~/ 3, c1 = lastIdx % 3;
    final int r2 = nextIdx ~/ 3, c2 = nextIdx % 3;

    if ((r1 + r2) % 2 == 0 && (c1 + c2) % 2 == 0) {
      final int mr = (r1 + r2) ~/ 2;
      final int mc = (c1 + c2) ~/ 2;
      return mr * 3 + mc;
    }
    return -1;
  }
}

class _PatternPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> selectedIndices;
  final Offset? currentTouchPosition;
  final Color activeColor;
  final Color dotColor;

  _PatternPainter({
    required this.dotPositions,
    required this.selectedIndices,
    required this.currentTouchPosition,
    required this.activeColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = activeColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = activeColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw connecting lines
    if (selectedIndices.isNotEmpty) {
      final path = Path();
      path.moveTo(dotPositions[selectedIndices.first].dx, dotPositions[selectedIndices.first].dy);
      for (int i = 1; i < selectedIndices.length; i++) {
        final pos = dotPositions[selectedIndices[i]];
        path.lineTo(pos.dx, pos.dy);
      }

      // Draw the glow path
      canvas.drawPath(path, glowPaint);
      // Draw the core line path
      canvas.drawPath(path, linePaint);

      // Draw line to current touch point for dynamic feel
      if (currentTouchPosition != null) {
        final lastPos = dotPositions[selectedIndices.last];
        canvas.drawLine(lastPos, currentTouchPosition!, linePaint);
      }
    }

    // Draw dots
    for (int i = 0; i < 9; i++) {
      final pos = dotPositions[i];
      final isSelected = selectedIndices.contains(i);

      if (isSelected) {
        // Outer pulsing ring
        final outerPaint = Paint()
          ..color = activeColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 16.0, outerPaint);

        // Core dot
        final innerPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 8.0, innerPaint);
      } else {
        // Unselected dot
        final dotPaint = Paint()
          ..color = dotColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 8.0, dotPaint);

        // Subtle outer boundary circle
        final ringPaint = Paint()
          ..color = dotColor.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, 14.0, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.currentTouchPosition != currentTouchPosition ||
        oldDelegate.selectedIndices.length != selectedIndices.length;
  }
}
