import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';
import 'center_target.dart';
// Import our new widgets instead of using SquareRing for both
import 'square_ring.dart'; // For outer ring
import 'inner_ring.dart'; // For inner ring

class GameBoard extends StatefulWidget {
  final int targetNumber;
  final String operation;

  const GameBoard({
    Key? key,
    required this.targetNumber,
    required this.operation,
  }) : super(key: key);

  @override
  GameBoardState createState() => GameBoardState();
}

class GameBoardState extends State<GameBoard> {
  // Track solved corners
  List<bool> solvedCorners = [false, false, false, false];

  // Models for our rings
  late RingModel outerRingModel;
  late RingModel innerRingModel;

  @override
  void initState() {
    super.initState();
    // Initialize ring models
    generateGameNumbers();
  }

  void generateGameNumbers() {
    final random = Random();

    // Generate 16 numbers for each ring (5 per side, with corners shared)

    // Generate inner ring numbers
    final innerNumbers = List.generate(16, (index) {
      // Basic numbers 1-12
      return random.nextInt(12) + 1;
    });

    // Generate outer ring numbers
    final outerNumbers = List.generate(16, (index) {
      // Special handling for corner positions
      final isCorner = SquarePositionUtils.isCornerIndex(index);

      if (isCorner) {
        // For corners, create numbers that form valid equations with the target
        // and the corresponding inner corner
        final innerValue =
            innerNumbers[index]; // Same index for inner/outer corners

        switch (widget.operation) {
          case 'addition':
            return innerValue + widget.targetNumber;
          case 'subtraction':
            return (random.nextBool())
                ? innerValue + widget.targetNumber // inner - target = outer
                : innerValue - widget.targetNumber; // inner + target = outer
          case 'multiplication':
            return innerValue * widget.targetNumber;
          case 'division':
            return innerValue * widget.targetNumber; // inner = outer ÷ target
          default:
            return random.nextInt(30) + 1;
        }
      } else {
        // Non-corner positions can have more random values
        return random.nextInt(30) + 1;
      }
    });

    // Create ring models with appropriate square sizes
    innerRingModel = RingModel(
      numbers: innerNumbers,
      itemColor: Colors.lightGreen,
      squareSize: 240,
    );

    outerRingModel = RingModel(
      numbers: outerNumbers,
      itemColor: Colors.teal,
      squareSize: 360,
    );
  }

  // Handles rotation of the outer ring
  void rotateOuterRing(int steps) {
    setState(() {
      outerRingModel = outerRingModel.copyWith(rotationSteps: steps);
    });
  }

  // Handles rotation of the inner ring
  void rotateInnerRing(int steps) {
    setState(() {
      innerRingModel = innerRingModel.copyWith(rotationSteps: steps);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width and adjust the container size accordingly
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.95; // Use 95% of screen width

    // Add more space between rings to prevent overlap
    final outerRingSize = boardSize * 0.95;
    final innerRingSize =
        boardSize * 0.60; // Smaller inner ring to prevent overlapping

    // Create the models with larger outer ring and smaller inner ring to avoid overlap
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

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring - uses SquareRing that renders corners
          SquareRing(
            ringModel: outerRingModel,
            onRotate: rotateOuterRing,
            solvedCorners: solvedCorners,
          ),

          // Inner ring - uses InnerRing that doesn't render corners
          InnerRing(
            ringModel: innerRingModel,
            onRotate: rotateInnerRing,
            solvedCorners: solvedCorners,
          ),

          // Center number (fixed)
          CenterTarget(targetNumber: widget.targetNumber),

          // Operators at diagonals
          ...buildOperatorOverlays(boardSize),

          // Detect taps on corners for checking equations
          ...buildCornerDetectors(boardSize),
        ],
      ),
    );
  }

  List<Widget> buildOperatorOverlays(double boardSize) {
    // Get operator symbol
    String operatorSymbol;
    switch (widget.operation) {
      case 'addition':
        operatorSymbol = '+';
        break;
      case 'subtraction':
        operatorSymbol = '-';
        break;
      case 'multiplication':
        operatorSymbol = '×';
        break;
      case 'division':
        operatorSymbol = '÷';
        break;
      default:
        operatorSymbol = '?';
    }

    // Calculate diagonal positions based on board size
    final diagonalOffset = boardSize * 0.28; // Adjusted for 5 tiles per side

    // Position operators at diagonals
    return [
      // Top-right
      Positioned(
        top: diagonalOffset,
        right: diagonalOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 28, // Increased from 24
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: diagonalOffset,
        right: diagonalOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 28,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: diagonalOffset,
        left: diagonalOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 28,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Top-left
      Positioned(
        top: diagonalOffset,
        left: diagonalOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 28,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  List<Widget> buildCornerDetectors(double boardSize) {
    // Calculate corner positions based on board size
    final cornerOffset = boardSize * 0.15; // Adjusted for larger board
    final detectorSize = 70.0; // Increased from 60

    // Position corner detectors
    return [
      // Top-left
      Positioned(
        top: cornerOffset,
        left: cornerOffset,
        child: GestureDetector(
          onTap: () => checkCornerEquation(0),
          child: Container(
            width: detectorSize,
            height: detectorSize,
            decoration: BoxDecoration(
              color: solvedCorners[0]
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: cornerOffset,
        right: cornerOffset,
        child: GestureDetector(
          onTap: () => checkCornerEquation(1),
          child: Container(
            width: detectorSize,
            height: detectorSize,
            decoration: BoxDecoration(
              color: solvedCorners[1]
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: cornerOffset,
        right: cornerOffset,
        child: GestureDetector(
          onTap: () => checkCornerEquation(2),
          child: Container(
            width: detectorSize,
            height: detectorSize,
            decoration: BoxDecoration(
              color: solvedCorners[2]
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: cornerOffset,
        left: cornerOffset,
        child: GestureDetector(
          onTap: () => checkCornerEquation(3),
          child: Container(
            width: detectorSize,
            height: detectorSize,
            decoration: BoxDecoration(
              color: solvedCorners[3]
                  ? Colors.green.withOpacity(0.3)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ];
  }

  void checkCornerEquation(int cornerIndex) {
    // Get the numbers at the corners
    final outerCornerNumbers = outerRingModel.getCornerNumbers();
    final innerCornerNumbers = innerRingModel.getCornerNumbers();

    // Get the current corner numbers based on rotation
    final outerNumber = outerCornerNumbers[cornerIndex];
    final innerNumber = innerCornerNumbers[cornerIndex];

    // Check if the equation is correct
    bool isCorrect = false;

    switch (widget.operation) {
      case 'addition':
        isCorrect = innerNumber + widget.targetNumber == outerNumber;
        break;
      case 'subtraction':
        isCorrect = innerNumber - widget.targetNumber == outerNumber ||
            widget.targetNumber - innerNumber == outerNumber;
        break;
      case 'multiplication':
        isCorrect = innerNumber * widget.targetNumber == outerNumber;
        break;
      case 'division':
        isCorrect = innerNumber * widget.targetNumber ==
                outerNumber || // inner * target = outer
            outerNumber / widget.targetNumber ==
                innerNumber; // outer / target = inner
        break;
    }

    setState(() {
      solvedCorners[cornerIndex] = isCorrect;

      // Check if all corners are solved
      if (solvedCorners.every((solved) => solved)) {
        showLevelCompleteDialog();
      }
    });
  }

  void showLevelCompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Level Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You solved all the equations. Great job!'),
              SizedBox(height: 20),
              // Show the equations that were solved
              ...List.generate(4, (index) {
                final outerCornerNumbers = outerRingModel.getCornerNumbers();
                final innerCornerNumbers = innerRingModel.getCornerNumbers();
                String operatorSymbol;
                switch (widget.operation) {
                  case 'addition':
                    operatorSymbol = '+';
                    break;
                  case 'subtraction':
                    operatorSymbol = '-';
                    break;
                  case 'multiplication':
                    operatorSymbol = '×';
                    break;
                  case 'division':
                    operatorSymbol = '÷';
                    break;
                  default:
                    operatorSymbol = '?';
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${innerCornerNumbers[index]} $operatorSymbol ${widget.targetNumber} = ${outerCornerNumbers[index]}',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset game or go to next level
                setState(() {
                  solvedCorners = [false, false, false, false];
                  generateGameNumbers();
                });
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }
}
