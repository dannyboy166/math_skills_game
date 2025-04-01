import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:math_skills_game/models/game_operation.dart';
import 'package:math_skills_game/models/ring_model.dart';
import 'package:math_skills_game/models/solved_corner.dart'; 
import 'package:math_skills_game/widgets/celebrations/animated_border.dart';
import 'package:math_skills_game/widgets/celebrations/audio_manager.dart';
import 'package:math_skills_game/widgets/celebrations/burst_animation.dart';
import 'package:math_skills_game/widgets/celebrations/candy_crush_explosion.dart';

class GameBoardController {
  // Models for our rings
  late RingModel outerRingModel;
  late RingModel innerRingModel;

  // Game state
  final int targetNumber;
  final GameOperation operation;
  final VoidCallback onStateChanged;
  final GlobalKey<State<StatefulWidget>> innerRingKey;

  // Centralized corner state management
  final List<SolvedCorner> _cornerStates = List.generate(
    4, 
    (index) => SolvedCorner(
      isLocked: false, 
      innerNumber: 0, 
      outerNumber: 0, 
      equationString: ""
    )
  );

  // Audio manager for sound effects
  final AudioManager _audioManager = AudioManager();

  // Celebration controllers
  late List<ConfettiController> _confettiControllers;
  bool _showingCelebration = false;

  // Keys for burst animations
  final List<GlobalKey<State<BurstAnimation>>> _burstKeys = List.generate(
    4,
    (index) => GlobalKey<State<BurstAnimation>>(),
  );

  GameBoardController({
    required this.targetNumber,
    required this.operation,
    required this.onStateChanged,
    required this.innerRingKey,
  }) {
    // Initialize ring models with empty lists (will be populated by generateGameNumbers)
    outerRingModel = RingModel(
      numbers: [],
      itemColor: Colors.teal,
      squareSize: 360,
      rotationSteps: 0,
    );

    innerRingModel = RingModel(
      numbers: [],
      itemColor: Colors.lightGreen,
      squareSize: 240,
      rotationSteps: 0,
    );

    // Generate game numbers using the operation strategy
    generateGameNumbers();

    // Initialize confetti controllers for each corner
    _confettiControllers = List.generate(
        4, (index) => ConfettiController(duration: const Duration(seconds: 2)));
  }

  bool get isShowingCelebration => _showingCelebration;

  // Get a list of which corners are solved (for widget consistency)
  List<bool> get solvedCorners =>
      List.generate(4, (index) => _cornerStates[index].isLocked);

  // Get if a specific corner is locked/solved
  bool isCornerLocked(int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= 4) return false;
    return _cornerStates[cornerIndex].isLocked;
  }

  // Get the equation string for a corner
  String getCornerEquation(int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= 4) return "";
    return _cornerStates[cornerIndex].equationString;
  }

  GlobalKey<State<BurstAnimation>> getBurstKey(int index) => _burstKeys[index];

  void dispose() {
    // Dispose of all controllers
    for (var controller in _confettiControllers) {
      controller.dispose();
    }
  }

  void generateGameNumbers() {
    // Delegate to the operation strategy
    operation.generateGameNumbers(
        outerRingModel: outerRingModel,
        innerRingModel: innerRingModel,
        targetNumber: targetNumber);
  }

  // Update ring models with new sizes
  void updateRingModels(double outerRingSize, double innerRingSize) {
    // Create new models with the same data but updated sizes
    RingModel newOuterRingModel = RingModel(
      numbers: outerRingModel.numbers,
      itemColor: outerRingModel.itemColor,
      squareSize: outerRingSize,
      rotationSteps: outerRingModel.rotationSteps,
    );

    RingModel newInnerRingModel = RingModel(
      numbers: innerRingModel.numbers,
      itemColor: innerRingModel.itemColor,
      squareSize: innerRingSize,
      rotationSteps: innerRingModel.rotationSteps,
    );

    // We don't need to copy corner states anymore as they're stored in _cornerStates

    outerRingModel = newOuterRingModel;
    innerRingModel = newInnerRingModel;

    onStateChanged();
  }

  // Handles rotation of the outer ring
  void rotateOuterRing(int steps) {
    outerRingModel = outerRingModel.copyWith(rotationSteps: steps);
    onStateChanged();
  }

  // Handles rotation of the inner ring
  void rotateInnerRing(int steps) {
    innerRingModel = innerRingModel.copyWith(rotationSteps: steps);
    onStateChanged();
  }

  // Hide celebration overlay
  void hideCelebration() {
    _showingCelebration = false;
    onStateChanged();
  }

  // Play burst animation for a specific corner
  void _playBurstAnimation(int cornerIndex) {
    final state = _burstKeys[cornerIndex].currentState;
    if (state != null) {
      // Use dynamic to access a method that isn't part of the public API
      (state as dynamic).play();
    }
  }

  // Get the rotated number at a specific position
  int getNumberAtPosition(
      List<int> numbers, int position, int rotationSteps, int itemCount) {
    if (rotationSteps == 0) return numbers[position];

    final actualSteps = rotationSteps % itemCount;

    // Calculate the original position before rotation
    int originalPos;
    if (actualSteps > 0) {
      // Clockwise rotation
      originalPos = (position + actualSteps) % itemCount;
    } else {
      // Counter-clockwise rotation
      originalPos = (position - actualSteps) % itemCount;
    }

    return numbers[originalPos];
  }

  // Get the corner indices for a specific ring
  List<int> getCornerIndices(bool isInner) {
    return isInner 
      ? innerRingModel.cornerIndices 
      : outerRingModel.cornerIndices;
  }

  // Centralized method to set a corner as locked/solved
  void setCornerLocked(int cornerIndex, int innerNumber, int outerNumber, String equation) {
    if (cornerIndex < 0 || cornerIndex >= 4) return;
    
    _cornerStates[cornerIndex] = SolvedCorner(
      isLocked: true,
      innerNumber: innerNumber,
      outerNumber: outerNumber,
      equationString: equation
    );
    
    onStateChanged();
  }

  // Centralized method to clear a corner's locked/solved status
  void clearCornerLocked(int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= 4) return;
    
    _cornerStates[cornerIndex] = SolvedCorner(
      isLocked: false,
      innerNumber: 0,
      outerNumber: 0,
      equationString: ""
    );
    
    onStateChanged();
  }

  // Check if a corner equation is correct
  void checkCornerEquation(int cornerIndex) {
    // Get the corner indices
    final outerCornerIndices = outerRingModel.cornerIndices;
    final innerCornerIndices = innerRingModel.cornerIndices;

    // Get the actual outer and inner corner positions
    final outerCornerPos = outerCornerIndices[cornerIndex];
    final innerCornerPos = innerCornerIndices[cornerIndex];

    // Get the numbers at these positions after rotation
    final outerNumber = getNumberAtPosition(outerRingModel.numbers,
        outerCornerPos, outerRingModel.rotationSteps, outerRingModel.itemCount);

    final innerNumber = getNumberAtPosition(innerRingModel.numbers,
        innerCornerPos, innerRingModel.rotationSteps, innerRingModel.itemCount);

    // Check if the equation is correct using the operation strategy
    bool isCorrect = operation.checkEquation(
      innerNumber: innerNumber,
      outerNumber: outerNumber,
      targetNumber: targetNumber,
    );

    if (isCorrect && !isCornerLocked(cornerIndex)) {
      // Save the solved equation details
      String equation = operation.getEquationString(
          innerNumber: innerNumber,
          targetNumber: targetNumber,
          outerNumber: outerNumber);

      // Mark this corner as solved with the current numbers
      setCornerLocked(cornerIndex, innerNumber, outerNumber, equation);

      // Play the enhanced corner celebration
      _playEnhancedCornerCelebration(cornerIndex);

      // Check if all corners are solved
      if (solvedCorners.every((solved) => solved)) {
        // Slightly delay the completion dialog to allow for celebration effects
        Future.delayed(const Duration(milliseconds: 1000), () {
          showLevelCompleteDialog();
        });
      }
    } else if (!isCorrect) {
      // Clear solved state for this corner if it was previously solved
      if (isCornerLocked(cornerIndex)) {
        clearCornerLocked(cornerIndex);
      }

      // Play incorrect feedback
      _audioManager.playWrongFeedback();
    }
  }

  // Handle swipes on corner tiles
  void handleCornerSwipe(
      DragEndDetails details, int cornerIndex, bool isHorizontal) {
    // Ensure there's meaningful velocity
    if (details.primaryVelocity == null || details.primaryVelocity!.abs() < 50)
      return;

    // Determine rotation direction for inner ring
    bool rotateClockwise;

    if (isHorizontal) {
      // For horizontal swipes
      switch (cornerIndex) {
        case 0: // Top-left
          rotateClockwise = details.primaryVelocity! > 0; // Right = clockwise
          break;
        case 1: // Top-right
          rotateClockwise = details.primaryVelocity! > 0; // Right = clockwise
          break;
        case 2: // Bottom-right
          rotateClockwise = details.primaryVelocity! < 0; // Left = clockwise
          break;
        case 3: // Bottom-left
          rotateClockwise = details.primaryVelocity! < 0; // Left = clockwise
          break;
        default:
          return;
      }
    } else {
      // For vertical swipes
      switch (cornerIndex) {
        case 0: // Top-left
          rotateClockwise = details.primaryVelocity! < 0; // Up = clockwise
          break;
        case 1: // Top-right
          rotateClockwise = details.primaryVelocity! > 0; // Down = clockwise
          break;
        case 2: // Bottom-right
          rotateClockwise = details.primaryVelocity! > 0; // Down = clockwise
          break;
        case 3: // Bottom-left
          rotateClockwise = details.primaryVelocity! < 0; // Up = clockwise
          break;
        default:
          return;
      }
    }

    final innerRingState = innerRingKey.currentState;
    if (innerRingState != null) {
      (innerRingState as dynamic).startRotationAnimation(rotateClockwise);
    }
  }

  // Create animated border widget
  Widget buildAnimatedBorder({required Widget child}) {
    return AnimatedBorder(
      // Only activate the border when all corners are solved
      isActive: solvedCorners.every((solved) => solved),
      child: child,
    );
  }

  // Build confetti widgets for all corners
  List<Widget> buildConfettiWidgets(double boardSize) {
    return List.generate(
        4, (index) => _buildConfettiWidget(index, boardSize: boardSize));
  }

  // Helper method to build confetti widget at a specific corner
  Widget _buildConfettiWidget(int cornerIndex, {required double boardSize}) {
    // Corner offset (distance from edge)
    final cornerOffset = boardSize * 0.15;

    // Determine the alignment and direction based on corner
    double blastDirection;

    switch (cornerIndex) {
      case 0: // Top-left
        blastDirection = 0.785; // 45 degrees (π/4)
        break;
      case 1: // Top-right
        blastDirection = 2.356; // 135 degrees (3π/4)
        break;
      case 2: // Bottom-right
        blastDirection = 3.927; // 225 degrees (5π/4)
        break;
      case 3: // Bottom-left
        blastDirection = 5.498; // 315 degrees (7π/4)
        break;
      default:
        blastDirection = 0;
    }

    return Positioned(
      left: cornerIndex == 0 || cornerIndex == 3 ? cornerOffset : null,
      right: cornerIndex == 1 || cornerIndex == 2 ? cornerOffset : null,
      top: cornerIndex == 0 || cornerIndex == 1 ? cornerOffset : null,
      bottom: cornerIndex == 2 || cornerIndex == 3 ? cornerOffset : null,
      child: ConfettiWidget(
        confettiController: _confettiControllers[cornerIndex],
        blastDirection: blastDirection,
        particleDrag: 0.05,
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        gravity: 0.2,
        shouldLoop: false,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.yellow,
        ],
        // Make particles shoot from the correct position outward
        createParticlePath: (size) {
          final path = Path();
          path.addOval(Rect.fromCircle(
            center: Offset(0, 0),
            radius: 10,
          ));
          return path;
        },
      ),
    );
  }

  // Play an enhanced celebration effect for a corner
  void _playEnhancedCornerCelebration(int cornerIndex) {
    // 1. Play the existing burst animation
    _playBurstAnimation(cornerIndex);

    // 2. Play the confetti controller
    _confettiControllers[cornerIndex].play();

    // 3. Play sound effect
    _audioManager.playCorrectFeedback();
  }

  // Show level complete dialog
  void showLevelCompleteDialog() {
    // Play all confetti controllers for individual corners
    for (var controller in _confettiControllers) {
      controller.play();
    }

    // Play completion sound
    _audioManager.playCompletionFeedback();

    // Show the full-screen celebration overlay
    _showingCelebration = true;
    onStateChanged();
  }

  // Play explosion animation for a corner
  void playCornerExplosion(int cornerIndex, BuildContext context) {
    // Get corner position
    final cornerOffset = MediaQuery.of(context).size.width * 0.95 * 0.15;
    Offset position;

    switch (cornerIndex) {
      case 0: // Top-left
        position = Offset(cornerOffset, cornerOffset);
        break;
      case 1: // Top-right
        position = Offset(
            MediaQuery.of(context).size.width - cornerOffset, cornerOffset);
        break;
      case 2: // Bottom-right
        position = Offset(MediaQuery.of(context).size.width - cornerOffset,
            MediaQuery.of(context).size.width - cornerOffset);
        break;
      case 3: // Bottom-left
        position = Offset(
            cornerOffset, MediaQuery.of(context).size.width - cornerOffset);
        break;
      default:
        position = Offset.zero;
    }

    // Declare the entry variable first (without assigning)
    late OverlayEntry entry;

    // Then assign it, now with a properly declared variable we can reference
    entry = OverlayEntry(
        builder: (context) => Positioned(
              left: position.dx - 40,
              top: position.dy - 40,
              child: SizedBox(
                width: 80,
                height: 80,
                child: CandyCrushExplosion(
                  color: operation.color,
                  onComplete: () {
                    // Now we can safely reference entry
                    entry.remove();
                  },
                ),
              ),
            ));

    // Show the overlay
    Overlay.of(context).insert(entry);
  }
}