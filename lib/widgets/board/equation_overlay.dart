import 'package:flutter/material.dart';
import 'dart:math' show pi;

/// Widget that displays the equation symbols (operators and equals signs) on the game board
class EquationOverlay extends StatelessWidget {
  final double boardSize;
  final double innerRingSize;
  final double outerRingSize;
  final String operationSymbol;

  const EquationOverlay({
    Key? key,
    required this.boardSize,
    required this.innerRingSize,
    required this.outerRingSize,
    required this.operationSymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...buildOperatorOverlays(),
        ...buildEqualsOverlays(),
      ],
    );
  }

  List<Widget> buildOperatorOverlays() {
    // Calculate diagonal positions based on board size
    // Position between inner ring and center
    final centerSize = 60.0; // Width of the center target
    final operatorOffset = (innerRingSize / 2 + centerSize / 2) / 2; // Halfway between center and inner ring

    // Position operators at diagonals
    return [
      // Top-right
      Positioned(
        top: boardSize / 2.1 - operatorOffset,
        right: boardSize / 2 - operatorOffset,
        child: Text(
          operationSymbol,
          style: TextStyle(
            fontSize: 40,
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
          operationSymbol,
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
          operationSymbol,
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
          operationSymbol,
          style: TextStyle(
            fontSize: 40,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ];
  }

  List<Widget> buildEqualsOverlays() {
    // Calculate positions for equals signs between inner and outer corner tiles
    final innerCornerOffset = innerRingSize / 2 * 1.3; // 90% to the edge of inner ring
    final outerCornerOffset = outerRingSize / 2 * 0.8; // 70% to the edge of outer ring

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
          angle: -45 * (pi / 180), // Convert -45 degrees to radians (counter-clockwise)
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
          angle: -45 * (pi / 180), // Convert -45 degrees to radians (counter-clockwise)
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
}