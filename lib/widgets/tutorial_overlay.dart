import 'package:flutter/material.dart';
import 'dart:async';

// Hand pointer icon by Stockio from www.flaticon.com
// Used under Flaticon Free License

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Size gameSize;
  final double innerRingRadius;
  final double outerRingRadius;
  final double centerX;
  final double centerY;
  final Function()? onRotateRing; // Add callback for ring rotation

  const TutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.gameSize,
    required this.innerRingRadius,
    required this.outerRingRadius,
    required this.centerX,
    required this.centerY,
    this.onRotateRing, // Optional callback to rotate the ring
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
  bool _showGotItButton = true;
  String _currentText = "Drag the rings to rotate them!";

  // For tracking rotation timing
  double? _prevDragPosition;
  bool _isDraggingDown = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for hand movement - slower animation (4 seconds)
    _handController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Animation for pulsing effect on tap
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Initial setup
    _setupStepOne();

    // Listen for animation completion
    _handController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handController.reset();
        Timer(Duration(milliseconds: 800), () {
          if (mounted) {
            _moveToNextStep();
          }
        });
      }
    });

    // Add listener to check for ring rotation
    _handController.addListener(_checkForRingRotation);
  }

  void _checkForRingRotation() {
    if (_currentStep == 0) {
      // Get current hand position
      final handPos = _handPositionAnimation.value;

      // Track if we're in the dragging down phase (between 25% and 75% of animation)
      bool isDraggingDown =
          _handController.value > 0.25 && _handController.value < 0.75;

      if (isDraggingDown) {
        // If we just started dragging down
        if (!_isDraggingDown) {
          _isDraggingDown = true;
          _prevDragPosition = handPos.dy;
          return;
        }

        // Check if we've moved down enough to trigger a rotation
        if (_prevDragPosition != null) {
          double dragDistance = handPos.dy - _prevDragPosition!;

          // If dragged down at least 15% of the radius, trigger a rotation
          if (dragDistance > widget.outerRingRadius * 0.15) {
            // Call the rotation callback
            if (widget.onRotateRing != null) {
              widget.onRotateRing!();
            }

            // Update the previous position
            _prevDragPosition = handPos.dy;
          }
        }
      } else {
        // Reset tracking when not in dragging phase
        _isDraggingDown = false;
        _prevDragPosition = null;
      }
    }
  }

  void _setupStepOne() {
    setState(() {
      _currentText = "Drag the rings to rotate them!";
    });

    // Simple vertical drag on the right side of the ring
    final centerX = widget.centerX;
    final centerY = widget.centerY;
    final radius = widget.outerRingRadius * 0.8;

    // Start at the right side and drag down vertically
    _handPositionAnimation = TweenSequence<Offset>([
      // Start at the right side of the ring
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, centerY),
          end: Offset(centerX + radius, centerY),
        ),
        weight: 15,
      ),
      // Hold briefly
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, centerY),
          end: Offset(centerX + radius, centerY),
        ),
        weight: 5,
      ),
      // Drag down slowly
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, centerY),
          end: Offset(centerX + radius, centerY + radius),
        ),
        weight: 60,
      ),
      // Hold at bottom
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, centerY + radius),
          end: Offset(centerX + radius, centerY + radius),
        ),
        weight: 20,
      ),
    ]).animate(_handController);

    _handController.forward();
  }

  void _setupStepTwo() {
    setState(() {
      _currentText = "Lock in all 4 corners to win!";
    });

    final centerX = widget.centerX;
    final centerY = widget.centerY;
    // Increase this radius to make the corners larger
    final radius = widget.outerRingRadius * 0.8; // Increased from 0.7 to 0.85

    // Coordinates for the four corners
    final topLeft = Offset(centerX - radius, centerY - radius);
    final topRight = Offset(centerX + radius, centerY - radius);
    final bottomRight = Offset(centerX + radius, centerY + radius);
    final bottomLeft = Offset(centerX - radius, centerY + radius);

    // Visit each corner slowly with pauses at each corner
    _handPositionAnimation = TweenSequence<Offset>([
      // Start at top-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topLeft,
        ),
        weight: 10,
      ),
      // Tap at top-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: Offset(topLeft.dx, topLeft.dy + 15), // Increased from 10 to 15
        ),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(topLeft.dx, topLeft.dy + 15), // Increased from 10 to 15
          end: topLeft,
        ),
        weight: 2,
      ),
      // Hold at top-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topLeft,
        ),
        weight: 5,
      ),
      // Move to top-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topRight,
        ),
        weight: 10,
      ),
      // Tap at top-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: Offset(topRight.dx, topRight.dy + 15), // Increased from 10 to 15
        ),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin:
              Offset(topRight.dx, topRight.dy + 15), // Increased from 10 to 15
          end: topRight,
        ),
        weight: 2,
      ),
      // Hold at top-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: topRight,
        ),
        weight: 5,
      ),
      // Move to bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: bottomRight,
        ),
        weight: 10,
      ),
      // Tap at bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: Offset(
              bottomRight.dx, bottomRight.dy + 15), // Increased from 10 to 15
        ),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(
              bottomRight.dx, bottomRight.dy + 15), // Increased from 10 to 15
          end: bottomRight,
        ),
        weight: 2,
      ),
      // Hold at bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: bottomRight,
        ),
        weight: 5,
      ),
      // Move to bottom-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: bottomLeft,
        ),
        weight: 10,
      ),
      // Tap at bottom-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: Offset(
              bottomLeft.dx, bottomLeft.dy + 15), // Increased from 10 to 15
        ),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(
              bottomLeft.dx, bottomLeft.dy + 15), // Increased from 10 to 15
          end: bottomLeft,
        ),
        weight: 2,
      ),
      // Hold at bottom-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: bottomLeft,
        ),
        weight: 5,
      ),
      // Move back to top-left to complete the circuit
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: topLeft,
        ),
        weight: 10,
      ),
      // Final pause
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topLeft,
        ),
        weight: 5,
      ),
    ]).animate(_handController);

    _handController.forward();

    // Add pulsing at each corner
    List<int> pulseTimings = [600, 1600, 2600, 3600];
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
    return Material(
      // Add Material widget as parent to provide proper text styling
      type: MaterialType
          .transparency, // Make it transparent to not affect the overlay
      child: Stack(
        children: [
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Tutorial step text - Moved higher up and properly styled
          Positioned(
            top: 140, // Moved higher up
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: DefaultTextStyle(
                // Add DefaultTextStyle to ensure proper text styling
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  decoration: TextDecoration
                      .none, // Explicitly remove underline decoration
                ),
                child: Text(
                  _currentText,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Hand pointer
          AnimatedBuilder(
            animation: _handController,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Positioned(
                    left: _handPositionAnimation.value.dx - 20,
                    top: _handPositionAnimation.value.dy - 30,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Image.asset(
                        'assets/images/point.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // "Got it!" button
          if (_showGotItButton)
            Positioned(
              bottom: 40,
              right: 30,
              child: ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: DefaultTextStyle(
                  // Also ensure proper text styling for button
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    decoration: TextDecoration.none,
                  ),
                  child: Text('Got it!'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
