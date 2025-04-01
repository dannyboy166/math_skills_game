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

  // Direct storage for locked corner numbers
  final List<int?> _lockedInnerNumbers = List.filled(4, null);
  final List<int?> _lockedOuterNumbers = List.filled(4, null);

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

  void setCornerLocked(
      int cornerIndex, int innerNumber, int outerNumber, String equation) {
    if (cornerIndex < 0 || cornerIndex >= 4) return;

    print('Setting corner $cornerIndex as locked:');
    print('  Inner number: $innerNumber, Outer number: $outerNumber');
    print('  Equation: $equation');

    _cornerStates[cornerIndex] = SolvedCorner(
        isLocked: true,
        innerNumber: innerNumber,
        outerNumber: outerNumber,
        equationString: equation);

    // Add any other locking logic here

    print('Corner $cornerIndex is now locked: ${isCornerLocked(cornerIndex)}');

    onStateChanged();
  }

  // Helper function to get the number at a position with current rotation
  int _getNumberAtPosition(
      List<int> numbers, int position, int rotationSteps, int itemCount) {
    // Check if this position is part of a locked corner
    bool isInnerRing = itemCount == innerRingModel.itemCount;
    List<int> cornerIndices = isInnerRing
        ? innerRingModel.cornerIndices
        : outerRingModel.cornerIndices;

    // Find which corner this position corresponds to (if any)
    int cornerIndex = -1;
    for (int i = 0; i < cornerIndices.length; i++) {
      if (cornerIndices[i] == position) {
        cornerIndex = i;
        break;
      }
    }

    // If this is a corner position and it's locked, return the locked number
    if (cornerIndex >= 0 && isCornerLocked(cornerIndex)) {
      if (isInnerRing && _lockedInnerNumbers[cornerIndex] != null) {
        return _lockedInnerNumbers[cornerIndex]!;
      } else if (!isInnerRing && _lockedOuterNumbers[cornerIndex] != null) {
        return _lockedOuterNumbers[cornerIndex]!;
      }
    }

    // Otherwise calculate normally
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
// Replace the checkCornerEquation method in your GameBoardController class

  void checkCornerEquation(int cornerIndex) {
    print('\nChecking corner $cornerIndex:');
    print('Already locked? ${isCornerLocked(cornerIndex)}');

    // If already locked, don't check again
    if (isCornerLocked(cornerIndex)) return;

    // Get the corner indices for both rings
    final outerCornerIndices = outerRingModel.cornerIndices;
    final innerCornerIndices = innerRingModel.cornerIndices;

    // Get the positions for this corner
    final outerCornerPos = outerCornerIndices[cornerIndex];
    final innerCornerPos = innerCornerIndices[cornerIndex];

    print(
        'Inner corner position: $innerCornerPos, Outer corner position: $outerCornerPos');

    // Print all inner ring positions and numbers to debug
    print('All inner ring positions and numbers:');
    for (int i = 0; i < innerRingModel.numbers.length; i++) {
      int num = _getNumberAtPosition(innerRingModel.numbers, i,
          innerRingModel.rotationSteps, innerRingModel.itemCount);
      print('Position $i: $num');
    }

    // Get the numbers at these positions after rotation
    final outerNumber = _getNumberAtPosition(outerRingModel.numbers,
        outerCornerPos, outerRingModel.rotationSteps, outerRingModel.itemCount);

    final innerNumber = _getNumberAtPosition(innerRingModel.numbers,
        innerCornerPos, innerRingModel.rotationSteps, innerRingModel.itemCount);

    print('Inner number: $innerNumber, Outer number: $outerNumber');
    print('Target number: $targetNumber');

    // Check each corner position and potential equation
    List<int> innerPotentialCornerPositions = [
      0,
      3,
      6,
      9
    ]; // Inner ring corners
    List<int> possibleInnerNumbers = [];

    // Get all possible inner numbers from corner positions
    for (int pos in innerPotentialCornerPositions) {
      int num = _getNumberAtPosition(innerRingModel.numbers, pos,
          innerRingModel.rotationSteps, innerRingModel.itemCount);
      possibleInnerNumbers.add(num);
      print('Potential inner corner at position $pos: $num');
    }

    // Check if any inner number would make a valid equation with this outer number
    bool isCorrect = false;
    int correctInnerNumber = innerNumber;

    for (int i = 0; i < possibleInnerNumbers.length; i++) {
      int potentialInnerNumber = possibleInnerNumbers[i];
      bool potentialCorrect =
          potentialInnerNumber * targetNumber == outerNumber;
      print(
          'Testing: $potentialInnerNumber × $targetNumber = ${potentialInnerNumber * targetNumber}, Expected: $outerNumber, Result: $potentialCorrect');

      if (potentialCorrect) {
        isCorrect = true;
        correctInnerNumber = potentialInnerNumber;
        print('Found matching inner number: $correctInnerNumber');
        break;
      }
    }

    print('Equation correct? $isCorrect');

    if (isCorrect) {
      // Save the solved equation details
      String equation = '$correctInnerNumber × $targetNumber = $outerNumber';

      print('Setting corner locked with equation: $equation');

      // Store the actual numbers that should remain at these corners
      _lockedInnerNumbers[cornerIndex] = correctInnerNumber;
      _lockedOuterNumbers[cornerIndex] = outerNumber;

      // Mark this corner as solved
      _cornerStates[cornerIndex] = SolvedCorner(
          isLocked: true,
          innerNumber: correctInnerNumber,
          outerNumber: outerNumber,
          equationString: equation);

      print('After locking - Is corner locked? ${isCornerLocked(cornerIndex)}');

      // Play celebration
      _confettiControllers[cornerIndex].play();
      _playBurstAnimation(cornerIndex);

      try {
        _audioManager.playCorrectFeedback();
      } catch (e) {
        print('Audio error: $e');
      }

      // Check if all corners are solved
      if (solvedCorners.every((solved) => solved)) {
        print('All corners solved!');
        // Slightly delay the completion celebration
        Future.delayed(const Duration(milliseconds: 1000), () {
          _showCelebration();
        });
      }

      // Notify listeners
      onStateChanged();
    } else {
      // Play incorrect feedback
      try {
        _audioManager.playWrongFeedback();
      } catch (e) {
        print('Audio error: $e');
      }
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

  void debugPrintState(String label) {
    print('\n===== $label =====');
    print('Target Number: $targetNumber');
    print('Inner Ring Rotation: ${innerRingModel.rotationSteps}');
    print('Outer Ring Rotation: ${outerRingModel.rotationSteps}');

    for (int i = 0; i < 4; i++) {
      print('Corner $i locked: ${isCornerLocked(i)}');

      // Get the corner positions
      final innerCornerPos = innerRingModel.cornerIndices[i];
      final outerCornerPos = outerRingModel.cornerIndices[i];

      // Get the numbers currently at these positions
      final innerNumber = _getNumberAtPosition(
          innerRingModel.numbers,
          innerCornerPos,
          innerRingModel.rotationSteps,
          innerRingModel.itemCount);

      final outerNumber = _getNumberAtPosition(
          outerRingModel.numbers,
          outerCornerPos,
          outerRingModel.rotationSteps,
          outerRingModel.itemCount);

      print('  Inner number: $innerNumber, Outer number: $outerNumber');
      print(
          '  Equation correct: ${operation.checkEquation(innerNumber: innerNumber, outerNumber: outerNumber, targetNumber: targetNumber)}');
    }
    print('====================\n');
  }
}
