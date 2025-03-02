import 'dart:math';
import 'package:flutter/material.dart';
import 'package:math_skills_game/widgets/square_ring.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'center_target.dart';

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

  final GlobalKey<State<AnimatedSquareRing>> innerRingKey =
      GlobalKey<State<AnimatedSquareRing>>();

  @override
  void initState() {
    super.initState();
    // Initialize ring models
    generateGameNumbers();
  }

  void generateGameNumbers() {
    final random = Random();

    // For inner ring, use fixed numbers 1-12 in order
    final innerNumbers = List.generate(12, (index) => index + 1);

    // Create inner ring model (similar to outer)
    innerRingModel = RingModel(
      numbers: innerNumbers,
      itemColor: Colors.lightGreen,
      squareSize: 240, // Will be adjusted in build
      rotationSteps: 0,
    );

    // Generate outer ring numbers
    final outerNumbers = List.generate(16, (index) {
      // Special handling for corner positions
      final isCorner = SquarePositionUtils.isCornerIndex(index);

      if (isCorner) {
        // Map corner indices to the corresponding positions in the inner ring
        // 0 → 0, 4 → 3, 8 → 6, 12 → 9
        int innerIndex;
        if (index == 0)
          innerIndex = 0; // Top-left
        else if (index == 4)
          innerIndex = 3; // Top-right
        else if (index == 8)
          innerIndex = 6; // Bottom-right
        else
          innerIndex = 9; // Bottom-left (index == 12)

        final innerValue = innerNumbers[innerIndex];

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

    // Create the outer ring model
    outerRingModel = RingModel(
      numbers: outerNumbers,
      itemColor: Colors.teal,
      squareSize: 360, // Will be adjusted in build
      rotationSteps: 0,
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
        boardSize * 0.58; // Smaller inner ring to prevent overlapping

    // Create the models with updated sizes
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
        child: Stack(alignment: Alignment.center, children: [
          // Outer ring - with animated rotation
          AnimatedSquareRing(
            ringModel: outerRingModel,
            onRotate: rotateOuterRing,
            solvedCorners: solvedCorners,
            isInner: false,
            tileSizeFactor: 0.12, // Customize outer ring regular tile size
            cornerSizeFactor:
                1.6, // Customize outer ring corner size multiplier
          ),

          // Inner ring with animated rotation
          Container(
            width: innerRingSize,
            height: innerRingSize,
            child: AnimatedSquareRing(
              key: innerRingKey,
              ringModel: innerRingModel,
              onRotate: rotateInnerRing,
              solvedCorners: solvedCorners,
              isInner: true,
              tileSizeFactor: 0.16, // Customize inner ring regular tile size
              cornerSizeFactor:
                  1.4, // Customize inner ring corner size multiplier
            ),
          ),

          // Center number (fixed)
          CenterTarget(targetNumber: widget.targetNumber),

// Operators at diagonals
          ...buildOperatorOverlays(boardSize, innerRingSize),

// Equals signs between corner tiles
          ...buildEqualsOverlays(boardSize, innerRingSize, outerRingSize),

// Detect taps on corners for checking equations
          ...buildCornerDetectors(boardSize),
        ]));
  }

  List<Widget> buildOperatorOverlays(double boardSize, double innerRingSize) {
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
    // Position between inner ring and center
    final centerSize = 60.0; // Width of the center target
    final operatorOffset = (innerRingSize / 2 + centerSize / 2) /
        2; // Halfway between center and inner ring

    // Position operators at diagonals
    return [
      // Top-right
      Positioned(
        top: boardSize / 2.1 - operatorOffset,
        right: boardSize / 2 - operatorOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 40, // Doubled from 28
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: boardSize / 2.1 - operatorOffset,
        right: boardSize / 2 - operatorOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 40,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: boardSize / 2.1 - operatorOffset,
        left: boardSize / 2 - operatorOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 40,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Top-left
      Positioned(
        top: boardSize / 2.1 - operatorOffset,
        left: boardSize / 2 - operatorOffset,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 40,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  List<Widget> buildEqualsOverlays(
      double boardSize, double innerRingSize, double outerRingSize) {
    // Calculate positions for equals signs between inner and outer corner tiles
    final innerCornerOffset =
        innerRingSize / 2 * 1.3; // 90% to the edge of inner ring
    final outerCornerOffset =
        outerRingSize / 2 * 0.8; // 70% to the edge of outer ring

    // Halfway between inner and outer rings
    final equalsOffset = (innerCornerOffset + outerCornerOffset) / 2;

    return [
      // Top-left equals (rotated clockwise 45 degrees)
      Positioned(
        top: boardSize / 2 - (equalsOffset + 5),
        left: boardSize / 2 - (equalsOffset - 10),
        child: Transform.rotate(
          angle: 45 * (pi / 180), // Convert 45 degrees to radians (clockwise)
          child: Text(
            "=",
            style: TextStyle(
              fontSize: 36,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Top-right equals (rotated counter-clockwise 45 degrees)
      Positioned(
        top: boardSize / 2 - (equalsOffset + 5),
        right: boardSize / 2 - (equalsOffset - 10),
        child: Transform.rotate(
          angle: -45 *
              (pi / 180), // Convert -45 degrees to radians (counter-clockwise)
          child: Text(
            "=",
            style: TextStyle(
              fontSize: 36,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Bottom-right equals (rotated clockwise 45 degrees)
      Positioned(
        bottom: boardSize / 2 - (equalsOffset + 5),
        right: boardSize / 2 - (equalsOffset - 10),
        child: Transform.rotate(
          angle: 45 * (pi / 180), // Convert 45 degrees to radians (clockwise)
          child: Text(
            "=",
            style: TextStyle(
              fontSize: 36,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      // Bottom-left equals (rotated counter-clockwise 45 degrees)
      Positioned(
        bottom: boardSize / 2 - (equalsOffset + 5),
        left: boardSize / 2 - (equalsOffset - 10),
        child: Transform.rotate(
          angle: -45 *
              (pi / 180), // Convert -45 degrees to radians (counter-clockwise)
          child: Text(
            "=",
            style: TextStyle(
              fontSize: 36,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> buildCornerDetectors(double boardSize) {
    final cornerOffset = boardSize * 0.15;
    final detectorSize = 70.0;

    return [
      // Top-left
      Positioned(
        top: cornerOffset,
        left: cornerOffset,
        child: GestureDetector(
          onTap: () => checkCornerEquation(0),
          // Add these gesture handlers to allow swiping on corners
          onHorizontalDragEnd: (details) =>
              _handleCornerSwipe(details, 0, true),
          onVerticalDragEnd: (details) => _handleCornerSwipe(details, 0, false),
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
          // Add these gesture handlers to allow swiping on corners
          onHorizontalDragEnd: (details) =>
              _handleCornerSwipe(details, 1, true),
          onVerticalDragEnd: (details) => _handleCornerSwipe(details, 1, false),
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
          // Add these gesture handlers to allow swiping on corners
          onHorizontalDragEnd: (details) =>
              _handleCornerSwipe(details, 2, true),
          onVerticalDragEnd: (details) => _handleCornerSwipe(details, 2, false),
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
          // Add these gesture handlers to allow swiping on corners
          onHorizontalDragEnd: (details) =>
              _handleCornerSwipe(details, 3, true),
          onVerticalDragEnd: (details) => _handleCornerSwipe(details, 3, false),
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

// This file contains the updated _handleCornerSwipe method and related code
// to be placed in your game_board.dart file

// Method to handle swipes on corner tiles and triggers inner ring animation
  void _handleCornerSwipe(
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
          rotateClockwise =
              details.primaryVelocity! > 0; // Right = clockwise (FIXED)
          break;
        case 2: // Bottom-right
          rotateClockwise = details.primaryVelocity! < 0; // Left = clockwise
          break;
        case 3: // Bottom-left
          rotateClockwise =
              details.primaryVelocity! < 0; // Left = clockwise (FIXED)
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

  void checkCornerEquation(int cornerIndex) {
    // Get the numbers at the corners
    final outerCornerNumbers = outerRingModel.getCornerNumbers();

    // For inner ring, map cornerIndex to the corresponding positions
    final innerCornerIndices = [
      0,
      3,
      6,
      9
    ]; // Positions in inner ring that align with corners
    final rotatedInnerNumbers = innerRingModel.getRotatedNumbers();
    final innerCornerNumbers = innerCornerIndices.map((index) {
      // Make sure to wrap around properly for the 12-item inner ring
      return rotatedInnerNumbers[index % 12];
    }).toList();

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

                // Get inner corner numbers
                final innerCornerIndices = [0, 3, 6, 9];
                final rotatedInnerNumbers = innerRingModel.getRotatedNumbers();
                final innerCornerNumbers = innerCornerIndices
                    .map((i) => rotatedInnerNumbers[i % 12])
                    .toList();

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
