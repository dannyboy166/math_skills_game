// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/animations/star_animation.dart';
import 'package:math_skills_game/models/difficulty_level.dart';
import 'package:math_skills_game/widgets/game_screen_ui.dart';
import 'dart:math';
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../widgets/progress_stars.dart';
import '../utils/game_utils.dart';

class GameScreen extends StatefulWidget {
  final String operationName;
  final DifficultyLevel difficultyLevel;
  final int? targetNumber;

  const GameScreen({
    Key? key,
    required this.operationName,
    required this.difficultyLevel,
    this.targetNumber,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RingModel outerRingModel;
  late RingModel innerRingModel;
  late OperationConfig operation;
  late int targetNumber;

  // Track locked equations
  List<LockedEquation> lockedEquations = [];

  // List to keep track of active star animations
  List<Widget> starAnimations = [];

  // Track if the game is complete
  bool isGameComplete = false;

  // Background gradient colors based on operation
  late List<Color> backgroundGradient;

  @override
  void initState() {
    super.initState();

    // Initialize the operation configuration
    operation = OperationConfig.forOperation(widget.operationName);

    // Set the background gradient based on operation
    _setBackgroundGradient();

    // Set target number based on difficulty level
    if (widget.targetNumber != null) {
      targetNumber = widget.targetNumber!;
    } else {
      final random = Random();
      targetNumber = widget.difficultyLevel.getRandomCenterNumber(random);
    }

    // Generate game numbers
    _generateGameNumbers();
  }

  void _setBackgroundGradient() {
    switch (widget.operationName) {
      case 'addition':
        backgroundGradient = [
          Colors.green.shade100,
          Colors.green.shade50,
        ];
        break;
      case 'subtraction':
        backgroundGradient = [
          Colors.purple.shade100,
          Colors.purple.shade50,
        ];
        break;
      case 'multiplication':
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade50,
        ];
        break;
      case 'division':
        backgroundGradient = [
          Colors.orange.shade100,
          Colors.orange.shade50,
        ];
        break;
      default:
        backgroundGradient = [
          Colors.blue.shade100,
          Colors.blue.shade50,
        ];
    }
  }

  // Generate numbers for game
  void _generateGameNumbers() {
    final random = Random();

    List<int> innerNumbers;
    List<int> outerNumbers;

    // Special handling for multiplication and division
    if (widget.operationName == 'multiplication') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = GameGenerator.generateMultiplicationNumbers(
          targetNumber, widget.difficultyLevel.maxOuterNumber, random);
    } else if (widget.operationName == 'division') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = GameGenerator.generateDivisionNumbers(
          targetNumber, widget.difficultyLevel.maxOuterNumber, random);
    } else {
      // Original logic for other operations
      innerNumbers = widget.difficultyLevel.innerRingNumbers;

      switch (widget.operationName) {
        case 'addition':
          outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
        case 'subtraction':
          outerNumbers = GameGenerator.generateSubtractionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
        default:
          outerNumbers = GameGenerator.generateAdditionNumbers(innerNumbers,
              targetNumber, widget.difficultyLevel.maxOuterNumber, random);
          break;
      }
    }

    // Initialize ring models
    innerRingModel = RingModel(
      numbers: innerNumbers,
      color: _getInnerRingColor(),
      cornerIndices: [0, 3, 6, 9], // Inner ring corners
    );

    outerRingModel = RingModel(
      numbers: outerNumbers,
      color: _getOuterRingColor(),
      cornerIndices: [0, 4, 8, 12], // Outer ring corners
    );
  }

  // Get more vibrant inner ring color
  Color _getInnerRingColor() {
    switch (widget.operationName) {
      case 'addition':
        return Colors.green.shade400;
      case 'subtraction':
        return Colors.purple.shade400;
      case 'multiplication':
        return Colors.blue.shade400;
      case 'division':
        return Colors.orange.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  // Get more vibrant outer ring color
  Color _getOuterRingColor() {
    switch (widget.operationName) {
      case 'addition':
        return Colors.teal.shade400;
      case 'subtraction':
        return Colors.deepPurple.shade400;
      case 'multiplication':
        return Colors.cyan.shade400;
      case 'division':
        return Colors.amber.shade400;
      default:
        return Colors.teal.shade400;
    }
  }

  // Check if equation is correct at the given corner
  bool _checkEquation(int cornerIndex) {
    // If this corner is already locked, don't check it again
    if (lockedEquations.any((eq) => eq.cornerIndex == cornerIndex)) {
      return true;
    }

    // Get numbers at corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

    return operation.checkEquation(innerNumber, outerNumber, targetNumber);
  }

  void _updateOuterRing(int steps) {
    setState(() {
      // Create a new model with the rotation applied
      outerRingModel = outerRingModel.copyWithRotation(steps);
    });
    _checkAllEquations();
  }

  void _updateInnerRing(int steps) {
    setState(() {
      // Create a new model with the rotation applied
      innerRingModel = innerRingModel.copyWithRotation(steps);
    });
    _checkAllEquations();
  }

  // Lock an equation when it's correct
  void _lockEquation(int cornerIndex) {
    // If already locked, do nothing
    if (lockedEquations.any((eq) => eq.cornerIndex == cornerIndex)) {
      return;
    }

    // Get corner positions
    final outerCornerPos = outerRingModel.cornerIndices[cornerIndex];
    final innerCornerPos = innerRingModel.cornerIndices[cornerIndex];

    // Get current numbers at these positions
    final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
    final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

    // Create a locked equation object
    final lockedEquation = LockedEquation(
      cornerIndex: cornerIndex,
      innerNumber: innerNumber,
      targetNumber: targetNumber,
      outerNumber: outerNumber,
      innerPosition: innerCornerPos,
      outerPosition: outerCornerPos,
      operation: widget.operationName,
      equationString:
          operation.getEquationString(innerNumber, targetNumber, outerNumber),
    );

    // Update state with locked positions
    setState(() {
      // Add to locked equations list
      lockedEquations.add(lockedEquation);

      // Create new models with the positions locked
      innerRingModel =
          innerRingModel.copyWithLockedPosition(innerCornerPos, innerNumber);
      outerRingModel =
          outerRingModel.copyWithLockedPosition(outerCornerPos, outerNumber);

      // Add star animation
      _showStarAnimation(cornerIndex);

      // Check if all four corners are locked (win condition)
      if (lockedEquations.length == 4) {
        isGameComplete = true;
        Future.delayed(Duration(milliseconds: 1000), () {
          _showWinDialog();
        });
      }
    });

    // Provide visual feedback with a colorful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'Great job! ${lockedEquations.length}/4 equations complete!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: operation.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show star animation when an equation is locked
  void _showStarAnimation(int cornerIndex) {
    // Calculate the start position (from the corner)
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.9;

    Offset startPosition;
    switch (cornerIndex) {
      case 0: // Top
        startPosition = Offset(boardSize / 2, 0);
        break;
      case 1: // Right
        startPosition = Offset(boardSize, boardSize / 2);
        break;
      case 2: // Bottom
        startPosition = Offset(boardSize / 2, boardSize);
        break;
      case 3: // Left
        startPosition = Offset(0, boardSize / 2);
        break;
      default:
        startPosition = Offset(boardSize / 2, boardSize / 2);
    }

    // End position should be at the top progress bar
    // We'll position it based on the locked equation count
    final endPosition = Offset(
      (screenWidth / 5) * lockedEquations.length,
      60, // Approximate y-position of the progress stars
    );

    // Add the star animation to the list
    setState(() {
      starAnimations.add(
        StarAnimation(
          startPosition: startPosition,
          endPosition: endPosition,
          onComplete: () {
            // Remove this animation when it's complete
            setState(() {
              starAnimations.removeWhere((element) {
                if (element is StarAnimation) {
                  return element.startPosition == startPosition &&
                      element.endPosition == endPosition;
                }
                return false;
              });
            });
          },
        ),
      );
    });
  }

  // Handle tapping on an equation element (corner tiles or equals sign)
  void _handleEquationTap(int cornerIndex) {
    // Check if this equation is correct
    if (_checkEquation(cornerIndex)) {
      // If it's correct, lock it
      _lockEquation(cornerIndex);
    } else {
      // If it's not correct, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Not quite right! Rotate the rings to make a correct equation.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Handle tapping on a ring tile
  void _handleTileTap(int cornerIndex, int position) {
    // Same behavior as tapping on an equation element
    _handleEquationTap(cornerIndex);
  }

  // Check all equations and show debug information
  void _checkAllEquations() {
    for (int i = 0; i < 4; i++) {
      final isCorrect = _checkEquation(i);
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == i);
      print(
          'Corner $i equation: ${isCorrect ? "CORRECT" : "INCORRECT"} ${isLocked ? "LOCKED" : ""}');

      // Print the equation details
      final outerCornerPos = outerRingModel.cornerIndices[i];
      final innerCornerPos = innerRingModel.cornerIndices[i];
      final outerNumber = outerRingModel.getNumberAtPosition(outerCornerPos);
      final innerNumber = innerRingModel.getNumberAtPosition(innerCornerPos);

      print(
          operation.getEquationString(innerNumber, targetNumber, outerNumber));
    }
  }

  // Show hint button functionality
  void _showHint() {
    // Find an unlocked corner that could be locked with the current position
    bool foundHint = false;
    for (int i = 0; i < 4; i++) {
      if (!lockedEquations.any((eq) => eq.cornerIndex == i) &&
          _checkEquation(i)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min, // Use minimum needed space
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow),
                SizedBox(width: 10),
                Expanded(
                  // Wrap the Text in an Expanded widget
                  child: Text(
                    'There\'s a correct equation at corner ${i + 1}. Tap to lock it!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Add overflow handling
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: operation.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        foundHint = true;
        break;
      }
    }

    if (!foundHint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align items to the top
            children: [
              Icon(Icons.touch_app, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                // Add Expanded to allow the text to take available width
                child: Text(
                  'Keep rotating the rings until the equations match!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  softWrap: true, // Allow text to wrap to multiple lines
                  maxLines: 2, // Limit to 2 lines (increase if needed)
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScreenUI(
      operationName: widget.operationName,
      difficultyLevel: widget.difficultyLevel,
      targetNumber: targetNumber,
      operation: operation,
      backgroundGradient: backgroundGradient,
      innerRingModel: innerRingModel,
      outerRingModel: outerRingModel,
      lockedEquations: lockedEquations,
      starAnimations: starAnimations,
      isGameComplete: isGameComplete,
      onUpdateInnerRing: _updateInnerRing,
      onUpdateOuterRing: _updateOuterRing,
      onTileTap: _handleTileTap,
      onEquationTap: _handleEquationTap,
      onShowHint: _showHint,
      onShowHelp: _showHelpDialog,
    );
  }

  // Win dialog shown when all four corners are completed
  void _showWinDialog() {
    // Show a celebratory dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Column(
          children: [
            Text(
              '🎉 Congratulations! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: operation.color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            // Fixed: Wrap in a flexible container and reduce padding or star size
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5, // horizontal space between stars
              runSpacing: 5, // vertical space between lines
              children: List.generate(
                4,
                (index) => StarWidget(
                  size: 25, // Reduced from 30
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You solved all four equations!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Score: 4/4 Stars',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home screen
            },
            child: Text(
              'Return to Menu',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Reset the game with our new API
              setState(() {
                lockedEquations = [];
                isGameComplete = false;
                starAnimations = [];

                // Generate a new target number
                final random = Random();
                targetNumber =
                    widget.difficultyLevel.getRandomCenterNumber(random);

                // Recreate the ring models from scratch
                _generateGameNumbers();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: operation.color,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Play Again! 🎮',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Help dialog with game instructions
  void _showHelpDialog() {
    String equationFormat;
    String additionalInfo = '';

    switch (widget.operationName) {
      case 'addition':
        equationFormat = 'inner + $targetNumber = outer';
        break;
      case 'subtraction':
        equationFormat = 'outer - inner = $targetNumber';
        break;
      case 'multiplication':
        equationFormat = 'inner × $targetNumber = outer';
        additionalInfo =
            'For multiplication, find numbers from the inner ring (1-12) that, when multiplied by $targetNumber, match values in the outer ring. There are at least 4 valid solutions to find!';
        break;
      case 'division':
        equationFormat = 'outer ÷ inner = $targetNumber';
        additionalInfo =
            'For division, find pairs of numbers where an outer ring number divided by an inner ring number (1-12) equals $targetNumber exactly (no remainder). There are at least 4 valid solutions to find!';
        break;
      default:
        equationFormat = 'inner × $targetNumber = outer';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Icon(Icons.info_outline, color: operation.color),
            SizedBox(width: 10),
            Flexible(child: Text('How to Play')), // Added Flexible
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1',
                'Rotate the rings to form correct equations at the four corners.'),
            _buildHelpItem('2', 'Each corner should satisfy: $equationFormat'),
            _buildHelpItem('3',
                'When a corner has a correct equation, tap any part of it to lock it.'),
            _buildHelpItem('4',
                'Locked equations stay in place while you continue rotating to solve the remaining corners.'),
            _buildHelpItem('5', 'Complete all four corners to win!'),
            if (additionalInfo.isNotEmpty) ...[
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: operation.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(additionalInfo),
              ),
            ],
            SizedBox(height: 16),
            Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• For addition and multiplication: inner → outer'),
                  Text('• For subtraction and division: outer → inner'),
                ],
              ),
            ),
            SizedBox(height: 10),
            (widget.operationName == 'multiplication' ||
                        widget.operationName == 'division') &&
                    widget.targetNumber != null
                ? Text(
                    '${widget.operationName.capitalize()} Number: ${widget.targetNumber}',
                    style: TextStyle(fontWeight: FontWeight.bold))
                : Text('Difficulty: ${widget.difficultyLevel.displayName}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: operation.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: operation.color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

// Add this extension method
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
