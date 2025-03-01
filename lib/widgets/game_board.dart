import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';
import 'square_ring.dart';

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
    
    // Generate inner ring numbers (16 items - 4 per side)
    final innerNumbers = List.generate(16, (index) {
      // Basic numbers 1-12
      return random.nextInt(12) + 1;
    });
    
    // Generate outer ring numbers (16 items - 4 per side)
    final outerNumbers = List.generate(16, (index) {
      // Generate numbers based on operation
      switch (widget.operation) {
        case 'addition':
          return random.nextInt(30) + 1;
        case 'subtraction':
          return random.nextInt(30) + 1;
        case 'multiplication':
          return random.nextInt(12) * widget.targetNumber; // Multiples of target
        case 'division':
          // For division, ensure we get whole number results
          final possibleMultiples = List.generate(10, (i) => widget.targetNumber * (i + 1));
          return possibleMultiples[random.nextInt(possibleMultiples.length)];
        default:
          return random.nextInt(30) + 1;
      }
    });
    
    // Create ring models
    innerRingModel = RingModel(
      numbers: innerNumbers,
      itemColor: Colors.lightGreen,
      squareSize: 200,
    );
    
    outerRingModel = RingModel(
      numbers: outerNumbers,
      itemColor: Colors.teal,
      squareSize: 300,
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
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          SquareRing(
            ringModel: outerRingModel,
            onRotate: rotateOuterRing,
            solvedCorners: solvedCorners,
          ),
          
          // Inner ring
          SquareRing(
            ringModel: innerRingModel,
            onRotate: rotateInnerRing,
            solvedCorners: solvedCorners,
          ),
          
          // Center number (fixed)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
              border: Border.all(color: Colors.teal, width: 4),
            ),
            child: Center(
              child: Text(
                '${widget.targetNumber}',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
          
          // Operators at diagonals
          ...buildOperatorOverlays(),
          
          // Detect taps on corners for checking equations
          ...buildCornerDetectors(),
        ],
      ),
    );
  }
  
  List<Widget> buildOperatorOverlays() {
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
    
    // Position operators at diagonals
    return [
      // Top-right
      Positioned(
        top: 90,
        right: 90,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 24,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 90,
        right: 90,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 24,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 90,
        left: 90,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 24,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Top-left
      Positioned(
        top: 90,
        left: 90,
        child: Text(
          operatorSymbol,
          style: TextStyle(
            fontSize: 24,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }
  
  List<Widget> buildCornerDetectors() {
    // Position corner detectors
    return [
      // Top-left
      Positioned(
        top: 30,
        left: 30,
        child: GestureDetector(
          onTap: () => checkCornerEquation(0),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: solvedCorners[0] ? Colors.green.withOpacity(0.3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 30,
        right: 30,
        child: GestureDetector(
          onTap: () => checkCornerEquation(1),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: solvedCorners[1] ? Colors.green.withOpacity(0.3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 30,
        right: 30,
        child: GestureDetector(
          onTap: () => checkCornerEquation(2),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: solvedCorners[2] ? Colors.green.withOpacity(0.3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 30,
        left: 30,
        child: GestureDetector(
          onTap: () => checkCornerEquation(3),
          child: Container(
            width: 60,
            height: 60,
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
    final innerCornerNumbers = innerRingModel.getCornerNumbers();
    
    // Check if the equation is correct
    bool isCorrect = false;
    
    switch (widget.operation) {
      case 'addition':
        isCorrect = innerCornerNumbers[cornerIndex] + widget.targetNumber == outerCornerNumbers[cornerIndex];
        break;
      case 'subtraction':
        isCorrect = innerCornerNumbers[cornerIndex] - widget.targetNumber == outerCornerNumbers[cornerIndex] ||
                    widget.targetNumber - innerCornerNumbers[cornerIndex] == outerCornerNumbers[cornerIndex];
        break;
      case 'multiplication':
        isCorrect = innerCornerNumbers[cornerIndex] * widget.targetNumber == outerCornerNumbers[cornerIndex];
        break;
      case 'division':
        isCorrect = innerCornerNumbers[cornerIndex] / widget.targetNumber == outerCornerNumbers[cornerIndex] ||
                    widget.targetNumber / innerCornerNumbers[cornerIndex] == outerCornerNumbers[cornerIndex];
        break;
    }
    
    setState(() {
      solvedCorners[cornerIndex] = isCorrect;
      
      // If correct, show celebration effect (to be implemented)
      if (isCorrect) {
        // TODO: Add celebration effect
      }
      
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
          content: Text('You solved all the equations. Great job!'),
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