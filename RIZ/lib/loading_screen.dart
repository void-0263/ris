import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Beautiful animated loading screen
class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoadingComplete;

  const LoadingScreen({super.key, required this.onLoadingComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _outerController;
  late AnimationController _middleController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();

    _outerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _middleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    // ✅ FIX: Stop all controllers BEFORE calling onLoadingComplete
    // so they don't keep painting after the screen is gone
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _outerController.stop();
        _middleController.stop();
        _textController.stop();
        widget.onLoadingComplete();
      }
    });
  }

  @override
  void dispose() {
    _outerController.dispose();
    _middleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Circle
                    AnimatedBuilder(
                      animation: _outerController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(86, 86),
                          painter: CirclePainter(
                            progress: _outerController.value,
                            strokeWidth: 6,
                            color: const Color(0xFFc3c8de),
                            frontColor: const Color(0xFFef4d86),
                            radius: 40,
                            type: 'outer',
                          ),
                        );
                      },
                    ),
                    // Middle Circle
                    AnimatedBuilder(
                      animation: _middleController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(60, 60),
                          painter: CirclePainter(
                            progress: _middleController.value,
                            strokeWidth: 6,
                            color: const Color(0xFFc3c8de),
                            frontColor: const Color(0xFFfbb216),
                            radius: 27,
                            type: 'middle',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getTextProgress(_textController.value),
                      child: const Text(
                        'patience...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFfbb216),
                          fontFamily: 'Ubuntu',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getTextProgress(double value) {
    if (value < 0.5) {
      return value * 2;
    } else {
      return 2 - (value * 2);
    }
  }
}

class CirclePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color frontColor;
  final double radius;
  final String type;

  CirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.frontColor,
    required this.radius,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final backPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backPaint);

    final frontPaint = Paint()
      ..color = frontColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double dashOffset = 0;
    double dashArray = 0;

    if (type == 'outer') {
      dashArray = 62.75;
      if (progress < 0.25) {
        dashOffset = 25 - (progress * 100);
      } else if (progress < 0.65) {
        dashOffset = -276 + ((progress - 0.25) * 755);
      } else {
        dashOffset = 25;
      }
    } else {
      dashArray = 42.5;
      if (progress < 0.25) {
        dashOffset = 17 - (progress * 68);
      } else if (progress < 0.65) {
        dashOffset = -187 + ((progress - 0.25) * 510);
      } else {
        dashOffset = 17;
      }
    }

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
    );

    canvas.drawPath(_createDashedPath(path, dashArray, dashOffset), frontPaint);
  }

  Path _createDashedPath(Path source, double dashLength, double dashOffset) {
    final dashedPath = Path();
    final metricsIterator = source.computeMetrics().iterator;

    while (metricsIterator.moveNext()) {
      final metric = metricsIterator.current;
      final totalLength = metric.length;
      double distance = dashOffset;

      while (distance < totalLength) {
        final nextDistance = distance + dashLength;
        final extractPath = metric.extractPath(
          distance < 0 ? 0 : distance,
          nextDistance > totalLength ? totalLength : nextDistance,
        );
        dashedPath.addPath(extractPath, Offset.zero);
        distance = nextDistance + (totalLength - dashLength);
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
