// File: lib/widgets/equation_layout.dart
import 'package:flutter/material.dart';
import '../models/operation_config.dart';

class EquationLayout extends StatelessWidget {
  final double boardSize;
  final double innerRingSize;
  final double outerRingSize;
  final OperationConfig operation;

  const EquationLayout({
    Key? key,
    required this.boardSize,
    required this.innerRingSize,
    required this.outerRingSize,
    required this.operation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Operation symbols (between center and inner ring)
        ..._buildOperationSymbols(),

        // Equals signs (between inner and outer ring)
        ..._buildEqualsSymbols(),
      ],
    );
  }

  List<Widget> _buildOperationSymbols() {
    // Calculate positions based on inner ring corners
    final innerRadius = innerRingSize / 2;

    // Define offsets for each corner (proportional to board size for consistency)
    final offsets = [
      // Top-left (from center)
      Offset(-innerRadius * 0.5, -innerRadius * 0.5),
      // Top-right
      Offset(innerRadius * 0.5, -innerRadius * 0.5),
      // Bottom-right
      Offset(innerRadius * 0.5, innerRadius * 0.5),
      // Bottom-left
      Offset(-innerRadius * 0.5, innerRadius * 0.5),
    ];

    // Create operation symbols
    return offsets.map((offset) {
      return Positioned(
        // Position relative to center
        left: boardSize / 2 + offset.dx - 15,
        top: boardSize / 2 + offset.dy - 15,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Text(
            operation.symbol,
            style: TextStyle(
              fontSize: 30,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEqualsSymbols() {
    // Calculate positions based on both rings
    final innerRadius = innerRingSize / 2;
    final outerRadius = outerRingSize / 2;

    // Position exactly halfway between inner and outer corners
    final positions = [
      // Top-left corner
      _getCornerPosition(0, innerRadius, outerRadius),
      // Top-right corner
      _getCornerPosition(1, innerRadius, outerRadius),
      // Bottom-right corner
      _getCornerPosition(2, innerRadius, outerRadius),
      // Bottom-left corner
      _getCornerPosition(3, innerRadius, outerRadius),
    ];

    // Create equal signs
    return positions.map((position) {
      return Positioned(
        left: position.dx - 15, // Center the = sign
        top: position.dy - 15,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Text(
            "=",
            style: TextStyle(
              fontSize: 30,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  // Calculate exact position for a corner's equals sign
  Offset _getCornerPosition(
      int cornerIndex, double innerRadius, double outerRadius) {
    // Center of the board
    final centerX = boardSize / 2;
    final centerY = boardSize / 2;

    // Calculate positions of inner and outer corners
    Offset innerCorner;
    Offset outerCorner;

    // Calculate inner ring corner position
    if (cornerIndex == 0) {
      // Top-left
      innerCorner = Offset(centerX - innerRadius, centerY - innerRadius);
      outerCorner = Offset(centerX - outerRadius, centerY - outerRadius);
    } else if (cornerIndex == 1) {
      // Top-right
      innerCorner = Offset(centerX + innerRadius, centerY - innerRadius);
      outerCorner = Offset(centerX + outerRadius, centerY - outerRadius);
    } else if (cornerIndex == 2) {
      // Bottom-right
      innerCorner = Offset(centerX + innerRadius, centerY + innerRadius);
      outerCorner = Offset(centerX + outerRadius, centerY + outerRadius);
    } else {
      // Bottom-left
      innerCorner = Offset(centerX - innerRadius, centerY + innerRadius);
      outerCorner = Offset(centerX - outerRadius, centerY + outerRadius);
    }

    // Midpoint between inner and outer corners
    return Offset(
      (innerCorner.dx + outerCorner.dx) / 2,
      (innerCorner.dy + outerCorner.dy) / 2,
    );
  }
}
