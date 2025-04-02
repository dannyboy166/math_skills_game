// lib/screens/game_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/ring_model.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../widgets/simple_ring.dart';
import '../widgets/equation_layout.dart';

class GameScreen extends StatefulWidget {
  final int targetNumber;
  final String operationName;

  const GameScreen({
    Key? key,
    required this.targetNumber,
    required this.operationName,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RingModel outerRingModel;
  late RingModel innerRingModel;
  late OperationConfig operation;

  // Track locked equations
  List<LockedEquation> lockedEquations = [];

  // Track if the game is complete
  bool isGameComplete = false;

  @override
  void initState() {
    super.initState();

    // Initialize the operation configuration
    operation = OperationConfig.forOperation(widget.operationName);

    // Generate game numbers
    _generateGameNumbers();
  }

  void _generateGameNumbers() {
    final random = Random();

    // For inner ring: Use fixed numbers 1-12
    final innerNumbers = List.generate(12, (index) => index + 1);

    // For outer ring: Generate numbers based on operation
    List<int> outerNumbers;

    // Different number generation based on operation
    switch (widget.operationName) {
      case 'addition':
        outerNumbers = _generateAdditionNumbers(innerNumbers, random);
        break;
      case 'subtraction':
        outerNumbers = _generateSubtractionNumbers(innerNumbers, random);
        break;
      case 'division':
        outerNumbers = _generateDivisionNumbers(innerNumbers, random);
        break;
      case 'multiplication':
      default:
        outerNumbers = _generateMultiplicationNumbers(innerNumbers, random);
        break;
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

  // Generate numbers for multiplication operation
  List<int> _generateMultiplicationNumbers(
      List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random non-product numbers
      return random.nextInt(100) + 1;
    });

    // Select 4 inner numbers to create valid products
    List<int> validInnerNumbers = [];
    List<int> validProducts = [];

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take 4 numbers from the shuffled list
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);
      validProducts.add(innerNum * widget.targetNumber);
    }

    // Place valid products at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[possiblePositions[i]] = validProducts[i];
    }

    return outerNumbers;
  }

  // Generate numbers for addition operation
  List<int> _generateAdditionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers
      return random.nextInt(24) + 1;
    });

    // Select 4 inner numbers to create valid sums
    List<int> validInnerNumbers = [];
    List<int> validSums = [];

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take 4 numbers from the shuffled list
    for (int i = 0; i < 4; i++) {
      final innerNum = shuffledInner[i];
      validInnerNumbers.add(innerNum);
      validSums.add(innerNum + widget.targetNumber);
    }

    // Place valid sums at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);

    for (int i = 0; i < 4; i++) {
      outerNumbers[possiblePositions[i]] = validSums[i];
    }

    return outerNumbers;
  }

// Generate numbers for subtraction operation
  List<int> _generateSubtractionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers
      return random.nextInt(50) + 1;
    });

    List<int> validInnerNumbers = [];
    List<int> validOuterNumbers = [];

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take up to 4 numbers that satisfy our criteria
    int count = 0;
    for (int i = 0; i < shuffledInner.length && count < 4; i++) {
      final innerNum = shuffledInner[i];

      // For each inner number, generate a valid outer number
      // such that outer - inner = target
      final outerNum = innerNum + widget.targetNumber;

      validInnerNumbers.add(innerNum);
      validOuterNumbers.add(outerNum);
      count++;
    }

    // Place valid outer numbers at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);

    for (int i = 0; i < count; i++) {
      outerNumbers[possiblePositions[i]] = validOuterNumbers[i];
    }

    return outerNumbers;
  }

// Generate numbers for division operation
  List<int> _generateDivisionNumbers(List<int> innerNumbers, Random random) {
    final outerNumbers = List.generate(16, (index) {
      // Generate random numbers for non-corner positions
      return random.nextInt(60) + 1;
    });

    List<int> validInnerNumbers = [];
    List<int> validOuterNumbers = [];

    // Shuffle inner numbers to pick 4 random ones
    final shuffledInner = List<int>.from(innerNumbers);
    shuffledInner.shuffle(random);

    // Take up to 4 numbers that satisfy our criteria
    int count = 0;
    for (int i = 0; i < shuffledInner.length && count < 4; i++) {
      final innerNum = shuffledInner[i];

      // Skip zero to avoid division by zero
      if (innerNum == 0) continue;

      // Generate a valid outer number such that outer ÷ inner = target
      final outerNum = innerNum * widget.targetNumber;

      validInnerNumbers.add(innerNum);
      validOuterNumbers.add(outerNum);
      count++;
    }

    // Place valid outer numbers at corner positions
    List<int> possiblePositions = [0, 4, 8, 12]; // Corner positions
    possiblePositions.shuffle(random);

    for (int i = 0; i < count; i++) {
      outerNumbers[possiblePositions[i]] = validOuterNumbers[i];
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

    return operation.checkEquation(
        innerNumber, outerNumber, widget.targetNumber);
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

// Helper to get locked positions for a specific ring

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
      targetNumber: widget.targetNumber,
      outerNumber: outerNumber,
      innerPosition: innerCornerPos,
      outerPosition: outerCornerPos,
      operation: widget.operationName,
      equationString: operation.getEquationString(
          innerNumber, widget.targetNumber, outerNumber),
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
            // Update this in your _showWinDialog method
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Reset the game with our new API
                setState(() {
                  lockedEquations = [];
                  isGameComplete = false;

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

      print(operation.getEquationString(
          innerNumber, widget.targetNumber, outerNumber));
    }
  }

  // Show help dialog
  void _showHelpDialog() {
    String equationFormat;

    switch (widget.operationName) {
      case 'addition':
        equationFormat = 'inner + ${widget.targetNumber} = outer';
        break;
      case 'subtraction':
        equationFormat = 'outer - inner = ${widget.targetNumber}';
        break;
      case 'division':
        equationFormat = 'outer ÷ inner = ${widget.targetNumber}';
        break;
      case 'multiplication':
      default:
        equationFormat = 'inner × ${widget.targetNumber} = outer';
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
            SizedBox(height: 16),
            Text('Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• For addition and multiplication: inner → outer'),
            Text('• For subtraction and division: outer → inner'),
            Text('This reflects how these operations relate to each other!'),
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
        title = 'Math Game - Inner + ${widget.targetNumber} = Outer';
        break;
      case 'subtraction':
        title = 'Math Game - Outer - Inner = ${widget.targetNumber}';
        break;
      case 'division':
        title = 'Math Game - Outer ÷ Inner = ${widget.targetNumber}';
        break;
      case 'multiplication':
      default:
        title = 'Math Game - Inner × ${widget.targetNumber} = Outer';
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
              'Rotate the rings to make equations',
              style: TextStyle(fontSize: 18),
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange,
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
                        '${widget.targetNumber}',
                        style: TextStyle(
                          fontSize: 24,
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
