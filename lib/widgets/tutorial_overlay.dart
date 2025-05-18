import 'package:flutter/material.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:math_skills_game/animations/star_animation.dart';

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
  ConfettiController? _confettiController;

  int _currentStep = 0;
  bool _showGotItButton = true;
  String _currentText = "Drag the rings to rotate them!";
  bool _showFinalOptions = false;

  // Replace _prevDragPosition with this
  double? _lastRotationProgress;
  bool _isDraggingDown = false;

  @override
  void initState() {
    super.initState();

    // Animation controller for hand movement
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

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: Duration(seconds: 1));

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
      // Check if we're in the dragging down phase (between 20% and 80% of animation)
      bool isDraggingDown =
          _handController.value > 0.20 && _handController.value < 0.80;

      // Get animation progress within the drag phase
      double dragProgress = 0;
      if (isDraggingDown) {
        // Normalize the progress within the drag phase (0.20-0.80 becomes 0-1)
        dragProgress =
            (_handController.value - 0.20) / 0.60; // Scales 0.20-0.80 to 0-1

        // If we weren't dragging before, but now we are
        if (!_isDraggingDown) {
          _isDraggingDown = true;
          _lastRotationProgress = dragProgress;

          // Trigger first rotation right away
          if (widget.onRotateRing != null) {
            widget.onRotateRing!();
          }
          return;
        }

        // Only rotate when we've made enough progress
        if (_lastRotationProgress != null) {
          double progressDelta = dragProgress - _lastRotationProgress!;

          // Using 0.6 as the threshold as you previously set
          if (progressDelta >= 0.3) {
            if (widget.onRotateRing != null) {
              widget.onRotateRing!();
            }
            _lastRotationProgress = dragProgress;
          }
        }
      } else {
        // Reset when not dragging
        _isDraggingDown = false;
        _lastRotationProgress = null;
      }
    }
  }

  void _setupStepOne() {
    setState(() {
      _currentText = "Drag the rings to rotate them!";
      _showFinalOptions = false;
    });

    // Simple vertical drag on the right side of the ring
    final centerX = widget.centerX;
    final centerY = widget.centerY;
    final radius = widget.outerRingRadius * 0.8;

    // Start from twice as high (2 * radius higher than center)
    final startY = centerY - radius;
    // End position stays the same (centerY + radius)
    final endY = centerY + radius;

    // Coordinates for the top-left corner (for transition)
    final topLeft = Offset(centerX - radius, centerY - radius);

    // Start at the right side and drag down vertically
    _handPositionAnimation = TweenSequence<Offset>([
      // Start at the right side of the ring, but higher up
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, startY),
          end: Offset(centerX + radius, startY),
        ),
        weight: 15,
      ),
      // Hold briefly
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, startY),
          end: Offset(centerX + radius, startY),
        ),
        weight: 5,
      ),
      // Drag down slowly from higher position to the same end point
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, startY),
          end: Offset(centerX + radius, endY),
        ),
        weight: 60,
      ),
      // Hold at bottom
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, endY),
          end: Offset(centerX + radius, endY),
        ),
        weight: 10,
      ),
      // Move to top-left to prepare for step two (without resetting animation)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(centerX + radius, endY),
          end: topLeft, // Move to top-left corner
        ),
        weight: 10,
      ),
    ]).animate(_handController);

    _handController.forward();
  }

  void _setupStepTwo() {
    setState(() {
      _currentText = "Lock in all 4 corners to win!";
      _showFinalOptions = false;
    });

    final centerX = widget.centerX;
    final centerY = widget.centerY;
    final radius = widget.outerRingRadius * 0.8;

    // Coordinates for the four corners
    final topLeft = Offset(centerX - radius, centerY - radius);
    final topRight = Offset(centerX + radius, centerY - radius);
    final bottomRight = Offset(centerX + radius, centerY + radius);
    final bottomLeft = Offset(centerX - radius, centerY + radius);

    // DOUBLED animation time for step two (8 seconds instead of 4)
    _handController.duration = Duration(seconds: 8);

    // Visit each corner with MUCH slower movements
    // Start from the top-left (continuing from end of step one)
    _handPositionAnimation = TweenSequence<Offset>([
      // Start at top-left (already there from end of step one)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topLeft,
        ),
        weight: 20, // Increased pause
      ),
      // Tap at top-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: Offset(topLeft.dx, topLeft.dy + 15),
        ),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(topLeft.dx, topLeft.dy + 15),
          end: topLeft,
        ),
        weight: 3,
      ),
      // Hold at top-left (longer)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topLeft,
        ),
        weight: 25, // Much longer hold
      ),
      // Move to top-right (much slower)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topLeft,
          end: topRight,
        ),
        weight: 40, // Much slower movement
      ),
      // Tap at top-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: Offset(topRight.dx, topRight.dy + 15),
        ),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(topRight.dx, topRight.dy + 15),
          end: topRight,
        ),
        weight: 3,
      ),
      // Hold at top-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: topRight,
        ),
        weight: 25, // Much longer hold
      ),
      // Move to bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: topRight,
          end: bottomRight,
        ),
        weight: 40, // Much slower movement
      ),
      // Tap at bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: Offset(bottomRight.dx, bottomRight.dy + 15),
        ),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(bottomRight.dx, bottomRight.dy + 15),
          end: bottomRight,
        ),
        weight: 3,
      ),
      // Hold at bottom-right
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: bottomRight,
        ),
        weight: 25, // Much longer hold
      ),
      // Move to bottom-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomRight,
          end: bottomLeft,
        ),
        weight: 40, // Much slower movement
      ),
      // Tap at bottom-left
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: Offset(bottomLeft.dx, bottomLeft.dy + 15),
        ),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(bottomLeft.dx, bottomLeft.dy + 15),
          end: bottomLeft,
        ),
        weight: 3,
      ),
      // Hold at bottom-left - final pause (don't go back to top-left)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: bottomLeft,
        ),
        weight: 50, // Much longer final hold
      ),
    ]).animate(_handController);

    // Reset the controller before forward to ensure smooth animation
    _handController.reset();
    _handController.forward();

    // Calculate total weight - sum of all the weights above
    const double totalWeight = 20 +
        5 +
        3 +
        25 +
        40 +
        5 +
        3 +
        25 +
        40 +
        5 +
        3 +
        25 +
        40 +
        5 +
        3 +
        50; // = 297

    // Calculate millisecond timings for each corner tap
    // 8000ms is the total animation time
    double topLeftTapEnd = (20 + 5 + 3) / totalWeight * 8000;
    double topRightTapEnd = (20 + 5 + 3 + 25 + 40 + 5 + 3) / totalWeight * 8000;
    double bottomRightTapEnd =
        (20 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5 + 3) / totalWeight * 8000;
    double bottomLeftTapEnd =
        (20 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5 + 3) /
            totalWeight *
            8000;

    // Add celebrations at each corner
    List<int> celebrationTimings = [
      topLeftTapEnd.round(),
      topRightTapEnd.round(),
      bottomRightTapEnd.round(),
      bottomLeftTapEnd.round()
    ];

    // Add pulsing at each corner right before tap
    List<int> pulseTimings = [
      (topLeftTapEnd - 200).round(),
      (topRightTapEnd - 200).round(),
      (bottomRightTapEnd - 200).round(),
      (bottomLeftTapEnd - 200).round()
    ];

    for (int timing in pulseTimings) {
      Future.delayed(Duration(milliseconds: timing), () {
        if (mounted) {
          _pulseController.forward().then((_) {
            _pulseController.reverse();
          });
        }
      });
    }

    // Add celebrations at each corner
    List<Offset> cornerPositions = [topLeft, topRight, bottomRight, bottomLeft];

    for (int i = 0; i < celebrationTimings.length; i++) {
      Future.delayed(Duration(milliseconds: celebrationTimings[i]), () {
        if (mounted) {
          // Show celebration with confetti
          _showFullCelebration(cornerPositions[i]);
        }
      });
    }
  }

  void _setupFinalStep() {
    setState(() {
      _currentText = "Good luck! Ready to play?";
      _showFinalOptions = true;
    });
  }

  void _moveToNextStep() {
    setState(() {
      _currentStep++;
      if (_currentStep == 1) {
        _setupStepTwo();
      } else if (_currentStep == 2) {
        _setupFinalStep();
      } else {
        widget.onComplete();
      }
    });
  }

  void _showFullCelebration(Offset cornerPosition) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Create a star animation
    final startPosition = cornerPosition;
    final endPosition = Offset(screenWidth / 2, 100);

    // Add star animation
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? starOverlayEntry;

    starOverlayEntry = OverlayEntry(
      builder: (context) => StarAnimation(
        startPosition: startPosition,
        endPosition: endPosition,
        onComplete: () {
          // This callback will be triggered when animation completes
          starOverlayEntry?.remove();
        },
      ),
    );

    overlayState.insert(starOverlayEntry);

    // Add confetti at the corner location
    OverlayEntry? confettiOverlayEntry;

    confettiOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: startPosition.dx - 50, // Center the confetti
        top: startPosition.dy - 50,
        child: SizedBox(
          width: 100,
          height: 100,
          child: ConfettiWidget(
            confettiController:
                ConfettiController(duration: Duration(milliseconds: 800))
                  ..play(),
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.08,
            numberOfParticles: 15,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ),
    );

    // Brief delay before showing confetti
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        overlayState.insert(confettiOverlayEntry!);

        // Remove confetti overlay after animation completes
        Future.delayed(Duration(milliseconds: 1200), () {
          confettiOverlayEntry?.remove();
        });
      }
    });
  }

  @override
  void dispose() {
    _handController.dispose();
    _pulseController.dispose();
    _confettiController?.dispose();
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
          if (!_showFinalOptions)
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
          if (_showGotItButton && !_showFinalOptions)
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

          // Final options buttons
          if (_showFinalOptions)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _handController.duration = Duration(seconds: 4);
                        _setupStepOne();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text('Yes, please!'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text("I'm ready!"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
