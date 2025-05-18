import 'package:flutter/material.dart';
import 'dart:async';

/* 
 * Hand pointer icon by Stockio from www.flaticon.com
 * Used under Flaticon Free License
 */

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Size gameSize;
  final double innerRingRadius;
  final double outerRingRadius;

  const TutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.gameSize,
    required this.innerRingRadius,
    required this.outerRingRadius,
  }) : super(key: key);

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _handController;
  late Animation<Offset> _handPositionAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  bool _showDragLine = false;

  @override
  void initState() {
    super.initState();
    // Animation controller for hand movement
    _handController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Animation for pulsing effect on tap
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _setupStepOne();

    // Listen for animation completion
    _handController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(Duration(milliseconds: 500), () {
          setState(() {
            _showDragLine = false;
          });
          _moveToNextStep();
        });
      }
    });
  }

  void _setupStepOne() {
    // Center points of the game area
    final centerX = widget.gameSize.width / 2;
    final centerY = widget.gameSize.height / 2;
    final radius = widget.outerRingRadius * 0.7;

    // Animation for rotating the outer ring
    setState(() {
      _showDragLine = true;
    });

    _handPositionAnimation = TweenSequence<Offset>([
      // Move to starting position
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX - 20, centerY - radius),
          end: Offset(centerX - 20, centerY - radius),
        ),
        weight: 10,
      ),
      // Perform drag motion in a curve to simulate ring rotation
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX - 20, centerY - radius),
          end: Offset(centerX + radius - 20, centerY),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius - 20, centerY),
          end: Offset(centerX - 20, centerY + radius),
        ),
        weight: 45,
      ),
    ]).animate(_handController);

    _handController.forward(from: 0.0);
  }

  void _setupStepTwo() {
    // Reset controller
    _handController.reset();

    // Get corner position (top left corner)
    final cornerX = widget.gameSize.width * 0.2;
    final cornerY = widget.gameSize.height * 0.2;

    // Animation for tapping a corner to lock an equation
    _handPositionAnimation = TweenSequence<Offset>([
      // Move to corner position
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(cornerX + 100, cornerY + 100),
          end: Offset(cornerX, cornerY),
        ),
        weight: 30,
      ),
      // Hold at corner
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(cornerX, cornerY),
          end: Offset(cornerX, cornerY),
        ),
        weight: 40,
      ),
      // Move down slightly to simulate tap
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(cornerX, cornerY),
          end: Offset(cornerX, cornerY),
        ),
        weight: 30,
      ),
    ]).animate(_handController);

    // Add a pulsing animation for the tap
    _handController.forward(from: 0.0);

    // Add pulsing during the tap
    Future.delayed(Duration(milliseconds: 1500), () {
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    });
  }

  void _setupStepThree() {
    // Reset controller
    _handController.reset();

    // Get center and corner positions
    final centerX = widget.gameSize.width / 2;
    final centerY = widget.gameSize.height / 2;

    // Points to visit all four corners
    final cornerTL =
        Offset(widget.gameSize.width * 0.2, widget.gameSize.height * 0.2);
    final cornerTR =
        Offset(widget.gameSize.width * 0.8, widget.gameSize.height * 0.2);
    final cornerBR =
        Offset(widget.gameSize.width * 0.8, widget.gameSize.height * 0.8);
    final cornerBL =
        Offset(widget.gameSize.width * 0.2, widget.gameSize.height * 0.8);

    // Animation to indicate completing all four corners
    _handPositionAnimation = TweenSequence<Offset>([
      // Visit top-left corner
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(centerX, centerY), end: cornerTL),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerTL, end: cornerTL),
        weight: 10,
      ),
      // Visit top-right corner
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerTL, end: cornerTR),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerTR, end: cornerTR),
        weight: 10,
      ),
      // Visit bottom-right corner
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerTR, end: cornerBR),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerBR, end: cornerBR),
        weight: 10,
      ),
      // Visit bottom-left corner
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerBR, end: cornerBL),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: cornerBL, end: cornerBL),
        weight: 10,
      ),
    ]).animate(_handController);

    _handController.forward(from: 0.0);

    // Add pulsing at each corner
    List<int> pulseTimings = [900, 1800, 2700, 3600]; // milliseconds
    for (int timing in pulseTimings) {
      Future.delayed(Duration(milliseconds: timing), () {
        if (mounted) {
          _pulseController.forward().then((_) {
            _pulseController.reverse();
          });
        }
      });
    }
  }

  void _moveToNextStep() {
    setState(() {
      _currentStep++;
      if (_currentStep == 1) {
        _setupStepTwo();
      } else if (_currentStep == 2) {
        _setupStepThree();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _handController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay
        Container(
          color: Colors.black.withOpacity(0.2),
        ),

        // Simple text hint at top
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Text(
              _getStepHint(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        if (_showDragLine)
          AnimatedBuilder(
            animation: _handController,
            builder: (context, child) {
              // Only show the line during the drag part of the animation
              if (_handController.value > 0.1 && _handController.value < 0.9) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: SimpleDragLinePainter(
                    currentPoint: _handPositionAnimation.value,
                    progress: _handController.value,
                    radius: widget.outerRingRadius,
                    centerX: widget.gameSize.width / 2,
                    centerY: widget.gameSize.height / 2,
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),

        // Animated hand cursor
        AnimatedBuilder(
          animation: _handController,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Positioned(
                  left: _handPositionAnimation.value.dx -
                      20, // Center hand on the point
                  top: _handPositionAnimation.value.dy - 20,
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Image.asset(
                      'assets/images/point.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Skip button
        Positioned(
          bottom: 40,
          right: 40,
          child: ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Got it!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStepHint() {
    switch (_currentStep) {
      case 0:
        return "Drag the rings to rotate them!";
      case 1:
        return "Tap to lock a correct equation!";
      case 2:
        return "Complete all 4 corners to win!";
      default:
        return "";
    }
  }
}

// Custom painter for showing drag motion
class DragLinePainter extends CustomPainter {
  final Offset startPoint;
  final List<Offset> previousPoints;

  DragLinePainter({required this.startPoint, required this.previousPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (previousPoints.isEmpty) return;

    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    for (var point in previousPoints) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DragLinePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.previousPoints != previousPoints;
  }
}

class SimpleDragLinePainter extends CustomPainter {
  final Offset currentPoint;
  final double progress;
  final double radius;
  final double centerX;
  final double centerY;

  SimpleDragLinePainter({
    required this.currentPoint,
    required this.progress,
    required this.radius,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw an arc instead of trying to track previous points
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: radius * 2,
      height: radius * 2,
    );

    // Calculate the arc angle based on progress
    // Start from top (270°) and go clockwise
    final startAngle = 3 * 3.14159 / 2; // 270 degrees in radians
    final sweepAngle =
        progress * 3.14159; // Up to 180 degrees based on progress

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(SimpleDragLinePainter oldDelegate) {
    return oldDelegate.currentPoint != currentPoint ||
        oldDelegate.progress != progress;
  }
}
