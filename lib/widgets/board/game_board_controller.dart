import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:math_skills_game/models/game_operation.dart';
import 'package:math_skills_game/models/ring_model.dart';
import 'package:math_skills_game/models/solved_corner.dart';
import 'package:math_skills_game/widgets/celebrations/audio_manager.dart';
import 'package:math_skills_game/widgets/celebrations/burst_animation.dart';

class GameBoardController {
  // Models for our rings
  late RingModel outerRingModel;
  late RingModel innerRingModel;

  // Game state
  final int targetNumber;
  final GameOperation operation;
  final VoidCallback onStateChanged;
  final GlobalKey<State<StatefulWidget>> innerRingKey;

  // Centralized corner state management - single source of truth
  final List<SolvedCorner> _cornerStates = List.generate(
      4,
      (index) => SolvedCorner(
          isLocked: false, innerNumber: 0, outerNumber: 0, equationString: ""));

  // Audio manager for sound effects
  final AudioManager _audioManager = AudioManager();

  // Keys for burst animations
  final List<GlobalKey<State<BurstAnimation>>> _burstKeys = List.generate(
    4,
    (index) => GlobalKey<State<BurstAnimation>>(),
  );

  // Confetti controllers for celebrations
  late final List<ConfettiController> _confettiControllers;
  bool _showingCelebration = false;

  GameBoardController({
    required this.targetNumber,
    required this.operation,
    required this.onStateChanged,
    required this.innerRingKey,
  }) {
    // Initialize ring models with empty lists
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

    // Initialize confetti controllers
    _confettiControllers = List.generate(
        4, (index) => ConfettiController(duration: const Duration(seconds: 2)));
  }

  bool get isShowingCelebration => _showingCelebration;

  // Get a list of which corners are solved (for widget consistency)
  List<bool> get solvedCorners => _cornerStates.map((c) => c.isLocked).toList();

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

  // Get the burst key for a corner
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
    outerRingModel = RingModel(
      numbers: outerRingModel.numbers,
      itemColor: outerRingModel.itemColor,
      squareSize: outerRingSize,
      rotationSteps: outerRingModel.rotationSteps,
    );

    innerRingModel = RingModel(
      numbers: innerRingModel.numbers,
      itemColor: innerRingModel.itemColor,
      squareSize: innerRingSize,
      rotationSteps: innerRingModel.rotationSteps,
    );

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

  // Get the corner indices for a specific ring
  List<int> getCornerIndices(bool isInner) {
    return isInner
        ? innerRingModel.cornerIndices
        : outerRingModel.cornerIndices;
  }

  // Set a corner as locked/solved
  void setCornerLocked(
      int cornerIndex, int innerNumber, int outerNumber, String equation) {
    if (cornerIndex < 0 || cornerIndex >= 4) return;

    _cornerStates[cornerIndex] = SolvedCorner(
        isLocked: true,
        innerNumber: innerNumber,
        outerNumber: outerNumber,
        equationString: equation);

    onStateChanged();
  }

  // Clear a corner's locked/solved status
  void clearCornerLocked(int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= 4) return;

    _cornerStates[cornerIndex] = SolvedCorner(
        isLocked: false, innerNumber: 0, outerNumber: 0, equationString: "");

    onStateChanged();
  }

  // Helper function to get the number at a position with current rotation
  int _getNumberAtPosition(
      List<int> numbers, int position, int rotationSteps, int itemCount) {
    if (rotationSteps == 0) return numbers[position];

    final actualSteps = rotationSteps % itemCount;

    // Calculate the original position before rotation
    int originalPos;
    if (actualSteps > 0) {
      // Counterclockwise rotation
      originalPos = (position - actualSteps + itemCount) % itemCount;
    } else {
      // Clockwise rotation
      originalPos = (position + (-actualSteps) + itemCount) % itemCount;
    }

    return numbers[originalPos];
  }

  // Check if a corner equation is correct
  void checkCornerEquation(int cornerIndex) {
    // If already locked, don't check again
    if (isCornerLocked(cornerIndex)) return;

    // Get the corner indices
    final outerCornerIndices = outerRingModel.cornerIndices;
    final innerCornerIndices = innerRingModel.cornerIndices;

    // Get the actual outer and inner corner positions
    final outerCornerPos = outerCornerIndices[cornerIndex];
    final innerCornerPos = innerCornerIndices[cornerIndex];

    // Get the numbers at these positions after rotation
    final outerNumber = _getNumberAtPosition(outerRingModel.numbers,
        outerCornerPos, outerRingModel.rotationSteps, outerRingModel.itemCount);

    final innerNumber = _getNumberAtPosition(innerRingModel.numbers,
        innerCornerPos, innerRingModel.rotationSteps, innerRingModel.itemCount);

    // Check if the equation is correct using the operation strategy
    bool isCorrect = operation.checkEquation(
      innerNumber: innerNumber,
      outerNumber: outerNumber,
      targetNumber: targetNumber,
    );

    if (isCorrect) {
      // Save the solved equation details
      String equation = operation.getEquationString(
          innerNumber: innerNumber,
          targetNumber: targetNumber,
          outerNumber: outerNumber);

      // Mark this corner as solved with the current numbers
      setCornerLocked(cornerIndex, innerNumber, outerNumber, equation);

      // Play celebration
      _confettiControllers[cornerIndex].play();
      _playBurstAnimation(cornerIndex);
      _audioManager.playCorrectFeedback();

      // Check if all corners are solved
      if (solvedCorners.every((solved) => solved)) {
        // Slightly delay the completion celebration
        Future.delayed(const Duration(milliseconds: 1000), () {
          _showCelebration();
        });
      }
    } else {
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

  // Show celebration when all corners are solved
  void _showCelebration() {
    // Play all confetti controllers
    for (var controller in _confettiControllers) {
      controller.play();
    }

    // Play completion sound
    _audioManager.playCompletionFeedback();

    // Show the celebration overlay
    _showingCelebration = true;
    onStateChanged();
  }

  // Build confetti widgets for all corners
  List<Widget> buildConfettiWidgets(double boardSize) {
    return List.generate(4, (index) {
      // Corner offset (distance from edge)
      final cornerOffset = boardSize * 0.15;

      // Determine the alignment and direction based on corner
      double blastDirection;
      switch (index) {
        case 0: // Top-left
          blastDirection = 0.785; // 45 degrees
          break;
        case 1: // Top-right
          blastDirection = 2.356; // 135 degrees
          break;
        case 2: // Bottom-right
          blastDirection = 3.927; // 225 degrees
          break;
        case 3: // Bottom-left
          blastDirection = 5.498; // 315 degrees
          break;
        default:
          blastDirection = 0;
      }

      return Positioned(
        left: index == 0 || index == 3 ? cornerOffset : null,
        right: index == 1 || index == 2 ? cornerOffset : null,
        top: index == 0 || index == 1 ? cornerOffset : null,
        bottom: index == 2 || index == 3 ? cornerOffset : null,
        child: ConfettiWidget(
          confettiController: _confettiControllers[index],
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
        ),
      );
    });
  }
}
