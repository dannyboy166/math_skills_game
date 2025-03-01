import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';
import 'center_target.dart';
import 'square_ring.dart';
import 'inner_ring.dart';

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
  late List<int> innerNumbers; // Just use a simple list for inner numbers
  int innerRotationSteps = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize ring models
    generateGameNumbers();
  }
  
  void generateGameNumbers() {
    final random = Random();
    
    // For inner ring, use fixed numbers 1-12 in order
    innerNumbers = List.generate(12, (index) => index + 1);
    innerRotationSteps = 0;
    
    // Generate outer ring numbers
    final outerNumbers = List.generate(16, (index) {
      // Special handling for corner positions
      final isCorner = SquarePositionUtils.isCornerIndex(index);
      
      if (isCorner) {
        // Map corner indices to the corresponding positions in the inner ring
        // 0 → 0, 4 → 3, 8 → 6, 12 → 9
        int innerIndex;
        if (index == 0) innerIndex = 0;       // Top-left
        else if (index == 4) innerIndex = 3;  // Top-right
        else if (index == 8) innerIndex = 6;  // Bottom-right
        else innerIndex = 9;                  // Bottom-left (index == 12)
        
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
      innerRotationSteps = steps;
    });
  }
  
  // Get the rotated inner numbers
  List<int> getRotatedInnerNumbers() {
    if (innerRotationSteps == 0) return innerNumbers;
    
    // Normalize the rotation steps
    final normalizedSteps = innerRotationSteps % 12;
    if (normalizedSteps == 0) return innerNumbers;
    
    // Rotate the list
    return [...innerNumbers.sublist(normalizedSteps), ...innerNumbers.sublist(0, normalizedSteps)];
  }
  
  // Get the inner numbers at positions corresponding to corners
  List<int> getInnerCornerNumbers() {
    final rotated = getRotatedInnerNumbers();
    // In the inner ring, the "corner aligned" positions are 0, 3, 6, 9
    return [rotated[0], rotated[3], rotated[6], rotated[9]];
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen width and adjust the container size accordingly
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth * 0.95; // Use 95% of screen width
    
    // Add more space between rings to prevent overlap
    final outerRingSize = boardSize * 0.95;
    final innerRingSize = boardSize * 0.60; // Smaller inner ring to prevent overlapping
    
    // Create the model with larger outer ring to avoid overlap
    outerRingModel = RingModel(
      numbers: outerRingModel.numbers,
      itemColor: outerRingModel.itemColor,
      squareSize: outerRingSize,
      rotationSteps: outerRingModel.rotationSteps,
    );
    
    // Get rotated inner numbers
    final rotatedInnerNumbers = getRotatedInnerNumbers();
    
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
          // Outer ring - with larger corner tiles
          SquareRing(
            ringModel: outerRingModel,
            onRotate: rotateOuterRing,
            solvedCorners: solvedCorners,
          ),
          
          // Inner ring with 12 tiles (with larger corner tiles)
          Container(
            width: innerRingSize,
            height: innerRingSize,
            child: InnerRing(
              numbers: rotatedInnerNumbers,
              itemColor: Colors.lightGreen,
              squareSize: innerRingSize,
              onRotate: rotateInnerRing,
              solvedCorners: solvedCorners,
              rotationSteps: innerRotationSteps,
            ),
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
    final diagonalOffset = boardSize * 0.28;
    
    // Position operators at diagonals
    return [
      // Top-right
      Positioned(
        top: diagonalOffset,
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
    final cornerOffset = boardSize * 0.15;
    final detectorSize = 70.0;
    
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
              color: solvedCorners[0] ? Colors.green.withOpacity(0.3) : Colors.transparent,
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
              color: solvedCorners[1] ? Colors.green.withOpacity(0.3) : Colors.transparent,
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
              color: solvedCorners[2] ? Colors.green.withOpacity(0.3) : Colors.transparent,
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
              color: solvedCorners[3] ? Colors.green.withOpacity(0.3) : Colors.transparent,
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
    final innerCornerNumbers = getInnerCornerNumbers();
    
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
        isCorrect = innerNumber * widget.targetNumber == outerNumber || // inner * target = outer
                    outerNumber / widget.targetNumber == innerNumber;   // outer / target = inner
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
                final innerCornerNumbers = getInnerCornerNumbers();
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