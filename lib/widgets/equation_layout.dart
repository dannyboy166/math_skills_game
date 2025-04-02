import 'package:flutter/material.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import 'clickable_equals.dart';

class EquationLayout extends StatelessWidget {
  final double boardSize;
  final double innerRingSize;
  final double outerRingSize;
  final OperationConfig operation;
  final List<LockedEquation> lockedEquations;
  final Function(int cornerIndex) onEquationTap;

  const EquationLayout({
    Key? key,
    required this.boardSize,
    required this.innerRingSize,
    required this.outerRingSize,
    required this.operation,
    required this.lockedEquations,
    required this.onEquationTap,
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
    // We need to place the operation symbols (×) exactly between the center and the inner ring
    final symbolSize = 30.0;
    final verticalAdjustment = -5.0; // Move all symbols up a bit
    
    // Calculate positions for the inner ring corner tiles
    final innerCornerPositions = [
      _calculateInnerTilePosition(0), // Top
      _calculateInnerTilePosition(3), // Right
      _calculateInnerTilePosition(6), // Bottom
      _calculateInnerTilePosition(9), // Left
    ];
    
    // Center position of the board
    final centerX = boardSize / 2;
    final centerY = boardSize / 2;
    
    // Create operation symbols at the midpoints between center and inner corners
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      // Calculate midpoint between center and inner corner
      final cornerPos = innerCornerPositions[index];
      final midX = (centerX + cornerPos.dx) / 2;
      final midY = (centerY + cornerPos.dy) / 2 + verticalAdjustment;
      
      // Use a greyed-out color if locked
      final Color textColor = isLocked ? Colors.grey : Colors.red;
      final double opacity = isLocked ? 0.7 : 1.0;
      
      return Positioned(
        left: midX - symbolSize / 2,
        top: midY - symbolSize / 2,
        child: GestureDetector(
          onTap: isLocked ? null : () => onEquationTap(index),
          child: Container(
            width: symbolSize,
            height: symbolSize,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Show operation symbol when not locked, lock icon when locked
                isLocked
                  ? Icon(
                      Icons.lock,
                      size: 24,
                      color: Colors.grey.shade600,
                    )
                  : Text(
                      operation.symbol,
                      style: TextStyle(
                        fontSize: 30,
                        color: textColor.withOpacity(opacity),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildEqualsSymbols() {
    final symbolSize = 30.0;
    final verticalAdjustment = -5.0; // Move all symbols up a bit
    
    // Inner ring corner positions indices: 0, 3, 6, 9
    // Outer ring corner positions indices: 0, 4, 8, 12
    
    // Get positions for inner and outer ring corner tiles
    final innerCornerPositions = [
      _calculateInnerTilePosition(0), // Top
      _calculateInnerTilePosition(3), // Right
      _calculateInnerTilePosition(6), // Bottom
      _calculateInnerTilePosition(9), // Left
    ];
    
    final outerCornerPositions = [
      _calculateOuterTilePosition(0), // Top
      _calculateOuterTilePosition(4), // Right
      _calculateOuterTilePosition(8), // Bottom
      _calculateOuterTilePosition(12), // Left
    ];
    
    // Create equals symbols between inner and outer corners
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      final innerPos = innerCornerPositions[index];
      final outerPos = outerCornerPositions[index];
      
      // Calculate exact midpoint between inner and outer tiles
      final midX = (innerPos.dx + outerPos.dx) / 2;
      final midY = (innerPos.dy + outerPos.dy) / 2 + verticalAdjustment;
      
      return Positioned(
        left: midX - symbolSize / 2,
        top: midY - symbolSize / 2,
        child: Container(
          width: symbolSize,
          height: symbolSize,
          alignment: Alignment.center,
          child: ClickableEquals(
            onTap: () => onEquationTap(index),
            isLocked: isLocked,
            size: symbolSize,
          ),
        ),
      );
    });
  }
  
  // Calculate position for inner ring tile at a given index
  Offset _calculateInnerTilePosition(int index) {
    final innerTileSize = innerRingSize * 0.16;
    final availableSpace = innerRingSize - innerTileSize;
    double x, y;
    
    if (index < 4) {
      // Top row: indices 0-3
      x = (index / 3) * availableSpace;
      y = 0;
    } else if (index < 7) {
      // Right column: indices 3-6
      x = availableSpace;
      y = ((index - 3) / 3) * availableSpace;
    } else if (index < 10) {
      // Bottom row: indices 6-9
      x = availableSpace - ((index - 6) / 3) * availableSpace;
      y = availableSpace;
    } else {
      // Left column: indices 9-11
      x = 0;
      y = availableSpace - ((index - 9) / 3) * availableSpace;
    }
    
    // Convert to absolute position on the board
    final offsetFromCenter = (boardSize - innerRingSize) / 2;
    return Offset(
      offsetFromCenter + x + innerTileSize / 2,
      offsetFromCenter + y + innerTileSize / 2
    );
  }
  
  // Calculate position for outer ring tile at a given index
  Offset _calculateOuterTilePosition(int index) {
    final outerTileSize = boardSize * 0.12;
    final availableSpace = boardSize - outerTileSize;
    double x, y;
    
    if (index < 5) {
      // Top row: indices 0-4
      x = (index / 4) * availableSpace;
      y = 0;
    } else if (index < 9) {
      // Right column: indices 4-8
      x = availableSpace;
      y = ((index - 4) / 4) * availableSpace;
    } else if (index < 13) {
      // Bottom row: indices 8-12
      x = availableSpace - ((index - 8) / 4) * availableSpace;
      y = availableSpace;
    } else {
      // Left column: indices 12-15
      x = 0;
      y = availableSpace - ((index - 12) / 4) * availableSpace;
    }
    
    // Return tile center position
    return Offset(
      x + outerTileSize / 2,
      y + outerTileSize / 2
    );
  }
}