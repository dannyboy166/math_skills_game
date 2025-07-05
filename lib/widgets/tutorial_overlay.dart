import 'package:flutter/material.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:number_ninja/animations/star_animation.dart';
import 'package:number_ninja/services/haptic_service.dart';
import 'package:number_ninja/services/sound_service.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Size gameSize;
  final double innerRingRadius;
  final double outerRingRadius;
  final double centerX;
  final double centerY;
  final Function()? onRotateRing;

  const TutorialOverlay({
    Key? key,
    required this.onComplete,
    required this.gameSize,
    required this.innerRingRadius,
    required this.outerRingRadius,
    required this.centerX,
    required this.centerY,
    this.onRotateRing,
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
  String _currentText = "Drag the inner and outter ring to rotate them!";
  bool _showFinalOptions = false;

  // Replace _prevDragPosition with this
  double? _lastRotationProgress;
  bool _isDraggingDown = false;

  // Position tracking
  Offset _currentPosition = Offset.zero;

  // Services
  final SoundService _soundService = SoundService();
  final HapticService _hapticService = HapticService();

  // Toast overlay entry
  OverlayEntry? _toastOverlayEntry;

  // Flag to track if we're in dragging phase
  bool _inDraggingPhase = false;

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
        // Don't immediately reset animation - wait until we're sure we've rendered the final frame
        Timer(Duration(milliseconds: 100), () {
          if (mounted) {
            // Only proceed to next step after a delay to ensure the final position is shown
            Timer(Duration(milliseconds: 700), () {
              if (mounted) {
                _moveToNextStep();
              }
            });
          }
        });
      }
    });

    // Add listener to check for ring rotation and track position
    _handController.addListener(_checkForRingRotation);
    _handController.addListener(_checkDraggingPhase);

    // Add listener to track finger position
    _handController.addListener(() {
      _currentPosition = _handPositionAnimation.value;
    });
  }

  // Check if we're in the dragging phase and show/hide instructions accordingly
  void _checkDraggingPhase() {
    if (_currentStep == 0) {
      // For step 1, we want to show instructions only during actual dragging
      // Check if we're in the dragging down phase (between 20% and 80% of animation)
      bool isDraggingNow =
          _handController.value > 0.25 && _handController.value < 0.75;

      if (isDraggingNow && !_inDraggingPhase) {
        // We just entered the dragging phase
        _inDraggingPhase = true;
        // Show the instruction
        _showInstructionToast("Drag down like this to rotate the rings!");
      } else if (!isDraggingNow && _inDraggingPhase) {
        // We just exited the dragging phase
        _inDraggingPhase = false;
        // Hide the instruction
        _hideInstructionToast();
      }
    }
  }

  // Method to show kid-friendly instruction toast
  void _showInstructionToast(String message,
      {int durationMs = 5000, bool forceShow = false}) {
    // If there's already a toast and we're not forcing a new one, don't show it
    if (_toastOverlayEntry != null && !forceShow) {
      return;
    }

    // Remove existing toast if any
    _toastOverlayEntry?.remove();
    _toastOverlayEntry = null;

    // Get overlay state
    final overlayState = Overlay.of(context);

    // Create new toast overlay
    _toastOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120,
        left: 20,
        right: 20,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(25),
          color: Colors.purple.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow.shade700, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the toast
    overlayState.insert(_toastOverlayEntry!);

    // Only auto-remove if a positive duration is provided
    if (durationMs > 0) {
      Future.delayed(Duration(milliseconds: durationMs), () {
        // Only remove if this is still the current toast
        if (_toastOverlayEntry != null) {
          _toastOverlayEntry?.remove();
          _toastOverlayEntry = null;
        }
      });
    }
  }

  // Method to hide the instruction toast
  void _hideInstructionToast() {
    _toastOverlayEntry?.remove();
    _toastOverlayEntry = null;
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
            // Light haptic impact for rotation
            _hapticService.lightImpact();
            widget.onRotateRing!();
          }
          return;
        }

        // Only rotate when we've made enough progress
        if (_lastRotationProgress != null) {
          double progressDelta = dragProgress - _lastRotationProgress!;

          // Using 0.27 as the threshold as previously set
          if (progressDelta >= 0.27) {
            if (widget.onRotateRing != null) {
              // Light haptic impact for rotation
              _hapticService.lightImpact();
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
      _currentText = "Drag the inner and outter ring to rotate them!";
      _showFinalOptions = false;
      _showGotItButton =
          true; // Make sure the "Got it!" button is visible again
      _inDraggingPhase = false; // Reset the dragging phase flag
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

    // Show an initial instruction just before starting, which will disappear when the dragging starts
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _showInstructionToast("Drag the rings to rotate them.",
            durationMs: 2500);
      }
    });
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

    // Save current position to ensure continuity
    Offset currentPos = _currentPosition;

    // If the current position is not at top left, use explicit top left position
    if ((currentPos - topLeft).distance > 20) {
      currentPos = topLeft;
    }

    // Visit each corner with MUCH slower movements
    // Start from the top-left (continuing from end of step one)
    _handPositionAnimation = TweenSequence<Offset>([
      // Start explicitly at top-left (to ensure correct starting position)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: currentPos,
          end: topLeft,
        ),
        weight: 5, // Small weight to ensure smooth transition
      ),
      // Hold at top-left
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
      // Hold at bottom-left - final pause (don't go back to any other corner)
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: bottomLeft,
          end: bottomLeft,
        ),
        weight: 50, // Much longer final hold
      ),
    ]).animate(_handController);

    // Don't reset the controller here - it causes the position to jump
    _handController.forward(from: 0.0);

    // Add just ONE instruction for the entire corner tapping phase
    // and ensure it stays visible for most of the corner demonstration
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _showInstructionToast(
            "If the corner equations are correct, tap them to lock them in!",
            durationMs: 6000); // Keep visible for a longer time (6 seconds)
      }
    });

    // Calculate total weight - sum of all the weights above
    const double totalWeight = 5 +
        20 +
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
        50; // = 302

    // Calculate millisecond timings for each corner tap
    // 8000ms is the total animation time
    double topLeftTapEnd = (5 + 20 + 5) / totalWeight * 8000;
    double topRightTapEnd = (5 + 20 + 5 + 3 + 25 + 40 + 5) / totalWeight * 8000;
    double bottomRightTapEnd =
        (5 + 20 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5) / totalWeight * 8000;
    double bottomLeftTapEnd =
        (5 + 20 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5 + 3 + 25 + 40 + 5) /
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

    for (int i = 0; i < pulseTimings.length; i++) {
      Future.delayed(Duration(milliseconds: pulseTimings[i]), () {
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
          _showFullCelebration(cornerPositions[i], i);
        }
      });
    }

    // Add a check at the end of animation
    Future.delayed(Duration(milliseconds: 8000), () {
      if (mounted) {
        // Final celebration
        _soundService.playCelebrationByStar(3);
        _hapticService.celebration();
      }
    });
  }

  void _setupFinalStep() {
    setState(() {
      _currentText = "Good luck! Ready to play?";
      _showFinalOptions = true;
    });

    // Give a friendly, encouraging message for the final step
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _showInstructionToast("Amazing job! You're ready to play the game!");
      }
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
        // Clean up before complete
        _toastOverlayEntry?.remove();
        _toastOverlayEntry = null;
        widget.onComplete();
      }
    });
  }

  void _showFullCelebration(Offset cornerPosition, int cornerIndex) {
    // Play correct sound for the corner
    _soundService.playCorrect();

    // Add haptic feedback
    if (cornerIndex < 3) {
      _hapticService.success();

      // Only show message for first corner
      if (cornerIndex == 0) {
        _showInstructionToast("Great! Keep finding the rest of the equations!",
            durationMs: 2500); // Show briefly for first corner
      }
    } else {
      // Final corner gets stronger haptic
      _hapticService.celebration();

      // Special message for the final corner with longer display time
      _showInstructionToast(
          "If you find 4 correct equations, YOU ARE A WINNER!",
          durationMs: 4500,
          forceShow: true);
    }

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
    _toastOverlayEntry?.remove();
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
            color: Colors.black.withValues(alpha: 0.4),
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
                onPressed: () {
                  // Haptic feedback
                  _hapticService.mediumImpact();
                  // Clean up before complete
                  _toastOverlayEntry?.remove();
                  _toastOverlayEntry = null;
                  widget.onComplete();
                },
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
                      // Haptic feedback
                      _hapticService.mediumImpact();

                      // Clean up existing toast
                      _toastOverlayEntry?.remove();
                      _toastOverlayEntry = null;

                      setState(() {
                        _currentStep = 0;
                        _handController.duration = Duration(seconds: 4);

                        // Need to stop and reset the animation controller properly
                        _handController.stop();
                        // Use value instead of forward(0.0) to ensure it's fully reset
                        _handController.value = 0.0;

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
                    child: Text('Repeat Tutorial!'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Haptic feedback
                      _hapticService.mediumImpact();
                      // Clean up before complete
                      _toastOverlayEntry?.remove();
                      _toastOverlayEntry = null;
                      widget.onComplete();
                    },
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
