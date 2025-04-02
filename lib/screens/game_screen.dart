// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'package:math_skills_game/models/difficulty_level.dart';
import 'dart:math';
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../widgets/simple_ring.dart';
import '../widgets/equation_layout.dart';

class GameScreen extends StatefulWidget {
  final String operationName;
  final DifficultyLevel difficultyLevel;
  final int?
      targetNumber; // Optional - if not provided, will be randomly generated

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

  // Track if the game is complete
  bool isGameComplete = false;

  @override
  void initState() {
    super.initState();

    // Initialize the operation configuration
    operation = OperationConfig.forOperation(widget.operationName);

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

  void _generateGameNumbers() {
    final random = Random();

    List<int> innerNumbers;
    List<int> outerNumbers;

    // Special handling for multiplication and division
    if (widget.operationName == 'multiplication') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = _generateMultiplicationNumbers(random);
    } else if (widget.operationName == 'division') {
      innerNumbers = List.generate(12, (index) => index + 1); // 1-12
      outerNumbers = _generateDivisionNumbers(random);
    } else {
      // Original logic for other operations
      innerNumbers = widget.difficultyLevel.innerRingNumbers;

      switch (widget.operationName) {
        case 'addition':
          outerNumbers = _generateAdditionNumbers(innerNumbers, random);
          break;
        case 'subtraction':
          outerNumbers = _generateSubtractionNumbers(innerNumbers, random);
          break;
        default:
          outerNumbers = _generateAdditionNumbers(innerNumbers, random);
          break;
      }
    }

    // Initialize ring models
    innerRingModel = RingModel(
      numbers: innerNumbers,
      color: Colors.blue,
      cornerIndices: [0, 3, 6, 9], // Inner ring corners
    );

    outerRingModel = RingModel(
      numbers: outerNumbers,
      color: Colors.teal,
      cornerIndices: [0, 4, 8, 12], // Outer ring corners
    );
  }

  // Generate numbers for addition operation
  List<int> _generateAdditionNumbers(List<int> innerNumbers, Random random) {
    final maxOuterNumber = widget.difficultyLevel.maxOuterNumber;

    // Initialize outer numbers list with placeholders
    final outerNumbers = List.filled(16, 0);

    // 1. First, ensure we have exactly 4 valid equations
    List<int> validInnerNumbers = [];
    List<int> validOuterNumbers = [];
    Set<int> usedOuterNumbers = {};

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take 4 numbers from the shuffled list for our valid equations
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);

      // For addition: inner + target = outer
      final outerNum = innerNum + targetNumber;

      // Make sure we don't exceed max range and don't have duplicates
      if (outerNum <= maxOuterNumber && !usedOuterNumbers.contains(outerNum)) {
        validOuterNumbers.add(outerNum);
        usedOuterNumbers.add(outerNum);
      } else {
        // If we can't use this number, try another until we find a valid one
        int attempts = 0;
        bool found = false;
        while (attempts < 20 && !found) {
          final newInnerNum = innerNumbers[random.nextInt(innerNumbers.length)];
          final newOuterNum = newInnerNum + targetNumber;

          if (newOuterNum <= maxOuterNumber &&
              !usedOuterNumbers.contains(newOuterNum)) {
            validInnerNumbers[i] = newInnerNum;
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            found = true;
          }
          attempts++;
        }

        // If we still couldn't find a valid number, create one by decrementing
        if (!found) {
          int newOuterNum = maxOuterNumber;
          while (usedOuterNumbers.contains(newOuterNum) &&
              newOuterNum > targetNumber) {
            newOuterNum--;
          }

          if (!usedOuterNumbers.contains(newOuterNum)) {
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            // Recalculate corresponding inner number
            validInnerNumbers[i] = newOuterNum - targetNumber;
          } else {
            // Extreme fallback - just use a number and accept the duplicate
            final fallbackOuter = innerNum + targetNumber;
            validOuterNumbers.add(fallbackOuter);
            usedOuterNumbers.add(fallbackOuter);
          }
        }
      }
    }

    // 2. Place valid outer numbers at corners
    List<int> cornerPositions = [0, 4, 8, 12]; // Corner positions
    cornerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[cornerPositions[i]] = validOuterNumbers[i];
    }

    // 3. Fill remaining positions with random numbers within range
    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(maxOuterNumber) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  // Generate numbers for subtraction operation
  List<int> _generateSubtractionNumbers(List<int> innerNumbers, Random random) {
    final maxOuterNumber = widget.difficultyLevel.maxOuterNumber;

    // Initialize outer numbers list with placeholders
    final outerNumbers = List.filled(16, 0);

    // For subtraction: outer - inner = target
    // This means: outer = inner + target
    // So we can reuse the addition logic but be clearer about what we're doing

    // 1. First, ensure we have exactly 4 valid equations
    List<int> validInnerNumbers = [];
    List<int> validOuterNumbers = [];
    Set<int> usedOuterNumbers = {};

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take 4 numbers from the shuffled list for our valid equations
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);

      // For subtraction: outer = inner + target
      final outerNum = innerNum + targetNumber;

      // Make sure we don't exceed max range and don't have duplicates
      if (outerNum <= maxOuterNumber && !usedOuterNumbers.contains(outerNum)) {
        validOuterNumbers.add(outerNum);
        usedOuterNumbers.add(outerNum);
      } else {
        // If we can't use this number, try another until we find a valid one
        int attempts = 0;
        bool found = false;
        while (attempts < 20 && !found) {
          final newInnerNum = innerNumbers[random.nextInt(innerNumbers.length)];
          final newOuterNum = newInnerNum + targetNumber;

          if (newOuterNum <= maxOuterNumber &&
              !usedOuterNumbers.contains(newOuterNum)) {
            validInnerNumbers[i] = newInnerNum;
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            found = true;
          }
          attempts++;
        }

        // If we still couldn't find a valid number, create one by decrementing
        if (!found) {
          int newOuterNum = maxOuterNumber;
          while (usedOuterNumbers.contains(newOuterNum) &&
              newOuterNum > targetNumber) {
            newOuterNum--;
          }

          if (!usedOuterNumbers.contains(newOuterNum)) {
            validOuterNumbers.add(newOuterNum);
            usedOuterNumbers.add(newOuterNum);
            // Recalculate corresponding inner number
            validInnerNumbers[i] = newOuterNum - targetNumber;
          } else {
            // Extreme fallback - just use a number and accept the duplicate
            final fallbackOuter = innerNum + targetNumber;
            validOuterNumbers.add(fallbackOuter);
            usedOuterNumbers.add(fallbackOuter);
          }
        }
      }
    }

    // 2. Place valid outer numbers at corners
    List<int> cornerPositions = [0, 4, 8, 12]; // Corner positions
    cornerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[cornerPositions[i]] = validOuterNumbers[i];
    }

    // 3. Fill remaining positions with random numbers within range
    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(maxOuterNumber) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

// Updated method to generate numbers for multiplication
  List<int> _generateMultiplicationNumbers(Random random) {
    final maxOuterNumber = targetNumber * 12; // Maximum product possible

    // Initialize outer numbers list
    final outerNumbers = List.filled(16, 0);

    // 1. Choose 4 random numbers from 1-12 (not visible to player, just for calculation)
    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    // 2. Calculate the 4 products with the center number
    List<int> productNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    // 3. Randomly place the 4 product numbers anywhere in the outer ring
    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = productNumbers[i];
    }

    // 4. Fill remaining positions with numbers that:
    //    - Are not duplicates of our chosen products
    //    - Are not duplicates of any previously generated number
    //    - Are within range 1 to maxOuterNumber
    Set<int> usedOuterNumbers = Set.from(productNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(maxOuterNumber) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
  }

  List<int> _generateDivisionNumbers(Random random) {
    final maxOuterNumber = targetNumber * 12; // Maximum possible dividend

    // Initialize outer numbers list
    final outerNumbers = List.filled(16, 0);

    // 1. Choose 4 random numbers from 1-12 as divisors
    Set<int> selectedInnerNumbers = {};
    while (selectedInnerNumbers.length < 4) {
      selectedInnerNumbers.add(random.nextInt(12) + 1);
    }

    // 2. Calculate the 4 dividends (outer = inner × target)
    // This ensures outer ÷ inner = target
    List<int> dividendNumbers =
        selectedInnerNumbers.map((n) => n * targetNumber).toList();

    // 3. Randomly place the 4 dividend numbers anywhere in the outer ring
    List<int> outerPositions = List.generate(16, (index) => index);
    outerPositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[outerPositions[i]] = dividendNumbers[i];
    }

    // 4. Fill remaining positions with numbers that:
    //    - Are not duplicates of our chosen dividends
    //    - Are not duplicates of any previously generated number
    //    - Are within range 1 to maxOuterNumber
    Set<int> usedOuterNumbers = Set.from(dividendNumbers);

    for (int i = 0; i < 16; i++) {
      if (outerNumbers[i] == 0) {
        // Generate a random number that's not already used
        int randomNum;
        do {
          randomNum = random.nextInt(maxOuterNumber) + 1;
        } while (usedOuterNumbers.contains(randomNum));

        outerNumbers[i] = randomNum;
        usedOuterNumbers.add(randomNum);
      }
    }

    return outerNumbers;
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
          content: Text(
              'This equation is not correct. Rotate the rings to make it match.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle tapping on a ring tile
  void _handleTileTap(int cornerIndex, int position) {
    // Same behavior as tapping on an equation element
    _handleEquationTap(cornerIndex);
  }

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

      // Check if all four corners are locked (win condition)
      if (lockedEquations.length == 4) {
        isGameComplete = true;
        _showWinDialog();
      }
    });

    // Provide visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Equation locked! ${lockedEquations.length}/4 completed.'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Show win dialog when all equations are locked
  void _showWinDialog() {
    Future.delayed(Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You have successfully completed all equations!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to home screen
              },
              child: Text('Return to Menu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Reset the game with our new API
                setState(() {
                  lockedEquations = [];
                  isGameComplete = false;

                  // Generate a new target number
                  final random = Random();
                  targetNumber =
                      widget.difficultyLevel.getRandomCenterNumber(random);

                  // Recreate the ring models from scratch
                  _generateGameNumbers();
                });
              },
              child: Text('Play Again'),
            ),
          ],
        ),
      );
    });
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
        title: Text('How to Play'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '1. Rotate the rings to form correct equations at the four corners.'),
            Text('2. Each corner should satisfy: $equationFormat'),
            Text(
                '3. When a corner has a correct equation, tap any part of it to lock it.'),
            Text(
                '4. Locked equations stay in place while you continue rotating to solve the remaining corners.'),
            Text('5. Complete all four corners to win!'),
            if (additionalInfo.isNotEmpty) ...[
              SizedBox(height: 10),
              Text(additionalInfo),
            ],
            SizedBox(height: 16),
            Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• For addition and multiplication: inner → outer'),
            Text('• For subtraction and division: outer → inner'),
            Text('This reflects how these operations relate to each other!'),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.9;
    final innerRingSize = boardSize * 0.6;

    final outerTileSize = boardSize * 0.12;
    final innerTileSize = innerRingSize * 0.16;

    // Determine the appropriate title based on operation
    String title;
    switch (widget.operationName) {
      case 'addition':
        title = 'Addition - Target: $targetNumber';
        break;
      case 'subtraction':
        title = 'Subtraction - Target: $targetNumber';
        break;
      case 'division':
        title = 'Division - Target: $targetNumber';
        break;
      case 'multiplication':
      default:
        title = 'Multiplication - Target: $targetNumber';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: operation.color,
        actions: [
          // Help button
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.difficultyLevel.displayName} Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: operation.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Rotate the rings to make equations',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Progress: '),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: lockedEquations.length / 4,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(operation.color),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('${lockedEquations.length}/4'),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Game board
            Container(
              width: boardSize,
              height: boardSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  SimpleRing(
                    ringModel: outerRingModel,
                    size: boardSize,
                    tileSize: outerTileSize,
                    isInner: false,
                    onRotateSteps: _updateOuterRing,
                    lockedEquations: lockedEquations,
                    onTileTap: _handleTileTap,
                  ),

                  // Inner ring
                  SimpleRing(
                    ringModel: innerRingModel,
                    size: innerRingSize,
                    tileSize: innerTileSize,
                    isInner: true,
                    onRotateSteps: _updateInnerRing,
                    lockedEquations: lockedEquations,
                    onTileTap: _handleTileTap,
                  ),

                  // Center target number
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: operation.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$targetNumber',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Equation symbols (properly positioned)
                  EquationLayout(
                    boardSize: boardSize,
                    innerRingSize: innerRingSize,
                    outerRingSize: boardSize,
                    operation: operation,
                    lockedEquations: lockedEquations,
                    onEquationTap: _handleEquationTap,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Locked equations display
            if (lockedEquations.isNotEmpty)
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locked Equations:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    ...lockedEquations
                        .map((eq) => Row(
                              children: [
                                Icon(Icons.lock,
                                    size: 16, color: operation.color),
                                SizedBox(width: 5),
                                Text(eq.equationString),
                              ],
                            ))
                        .toList(),
                  ],
                ),
              ),

            Spacer(),

            // Hint button
            if (!isGameComplete)
              TextButton.icon(
                onPressed: () {
                  // Find an unlocked corner that could be locked with the current position
                  bool foundHint = false;
                  for (int i = 0; i < 4; i++) {
                    if (!lockedEquations.any((eq) => eq.cornerIndex == i) &&
                        _checkEquation(i)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'There\'s a correct equation at corner ${i + 1}. Tap to lock it!'),
                          duration: Duration(seconds: 3),
                          backgroundColor: operation.color,
                        ),
                      );
                      foundHint = true;
                      break;
                    }
                  }

                  if (!foundHint) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Keep rotating the rings until the equations match!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.lightbulb_outline),
                label: Text('Hint'),
              ),

            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Add this extension method somewhere in your file or in a utilities file
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
