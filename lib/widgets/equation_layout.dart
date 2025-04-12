// lib/widgets/equation_layout.dart
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
    // Determine if we're using reverse equation format (outside to inside)
    final bool isReverseFormat = 
        operation.name == 'subtraction' || operation.name == 'division';
    
    return Stack(
      children: [
        // Operation symbols 
        // For addition and multiplication, between center and inner ring
        // For subtraction and division, between inner and outer ring
        ...(isReverseFormat ? _buildOperationSymbolsReverse() : _buildOperationSymbols()),

        // Equals signs 
        // For addition and multiplication, between inner and outer ring
        // For subtraction and division, between center and inner ring
        ...(isReverseFormat ? _buildEqualsSymbolsReverse() : _buildEqualsSymbols()),
      ],
    );
  }

  Widget _buildOperationSymbol(String symbol, Color color, double opacity) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(opacity),
            height: 0.9, // Adjust this value to center vertically
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // STANDARD DIRECTION: Inner -> Target -> Outer
  // For addition and multiplication
  List<Widget> _buildOperationSymbols() {
    final symbolSize = 30.0;
    
    // Calculate positions for operation symbols at the corners
    // between center and inner ring
    final List<Offset> symbolPositions = [
      // Top-left corner
      Offset(boardSize * 0.36, boardSize * 0.36),
      
      // Top-right corner
      Offset(boardSize * 0.64, boardSize * 0.36),
      
      // Bottom-right corner
      Offset(boardSize * 0.64, boardSize * 0.64),
      
      // Bottom-left corner
      Offset(boardSize * 0.36, boardSize * 0.64),
    ];
    
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      // Use a greyed-out color if locked
      final Color textColor = isLocked ? Colors.grey : operation.color;
      final double opacity = isLocked ? 0.7 : 1.0;
      
      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: GestureDetector(
          onTap: isLocked ? null : () => onEquationTap(index),
          child: Container(
            width: symbolSize,
            height: symbolSize,
            child: isLocked
              ? Icon(
                  Icons.lock,
                  size: 24,
                  color: Colors.grey.shade600,
                )
              : _buildOperationSymbol(
                  operation.symbol,
                  textColor,
                  opacity,
                ),
          ),
        ),
      );
    });
  }

  // REVERSE DIRECTION: Outer -> Inner -> Target
  // For subtraction and division, operation symbols between inner and outer rings
  List<Widget> _buildOperationSymbolsReverse() {
    final symbolSize = 30.0;
    
    // Calculate positions for operation symbols at the corners
    // between inner and outer rings
    final List<Offset> symbolPositions = [
      // Top-left corner
      Offset(boardSize * 0.17, boardSize * 0.17),
      
      // Top-right corner
      Offset(boardSize * 0.83, boardSize * 0.17),
      
      // Bottom-right corner
      Offset(boardSize * 0.83, boardSize * 0.83),
      
      // Bottom-left corner
      Offset(boardSize * 0.17, boardSize * 0.83),
    ];
    
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      // Use a greyed-out color if locked
      final Color textColor = isLocked ? Colors.grey : operation.color;
      final double opacity = isLocked ? 0.7 : 1.0;
      
      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: GestureDetector(
          onTap: isLocked ? null : () => onEquationTap(index),
          child: Container(
            width: symbolSize,
            height: symbolSize,
            child: isLocked
              ? Icon(
                  Icons.lock,
                  size: 24,
                  color: Colors.grey.shade600,
                )
              : _buildOperationSymbol(
                  operation.symbol,
                  textColor,
                  opacity,
                ),
          ),
        ),
      );
    });
  }

  // STANDARD DIRECTION: Inner -> Target -> Outer
  // For addition and multiplication, equals sign between inner and outer rings
  List<Widget> _buildEqualsSymbols() {
    final symbolSize = 30.0;
    
    // Calculate positions for equals symbols at the corners
    // between inner and outer rings 
    final List<Offset> symbolPositions = [
      // Top-left corner
      Offset(boardSize * 0.17, boardSize * 0.17),
      
      // Top-right corner
      Offset(boardSize * 0.83, boardSize * 0.17),
      
      // Bottom-right corner
      Offset(boardSize * 0.83, boardSize * 0.83),
      
      // Bottom-left corner
      Offset(boardSize * 0.17, boardSize * 0.83),
    ];
    
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: ClickableEquals(
          onTap: () => onEquationTap(index),
          isLocked: isLocked,
          size: symbolSize,
          color: operation.color, // Pass the operation color
        ),
      );
    });
  }
  
  // REVERSE DIRECTION: Outer -> Inner -> Target
  // For subtraction and division, equals sign between center and inner ring
  List<Widget> _buildEqualsSymbolsReverse() {
    final symbolSize = 30.0;
    
    // Calculate positions for equals symbols at the corners
    // between center and inner ring
    final List<Offset> symbolPositions = [
      // Top-left corner
      Offset(boardSize * 0.36, boardSize * 0.36),
      
      // Top-right corner
      Offset(boardSize * 0.64, boardSize * 0.36),
      
      // Bottom-right corner
      Offset(boardSize * 0.64, boardSize * 0.64),
      
      // Bottom-left corner
      Offset(boardSize * 0.36, boardSize * 0.64),
    ];
    
    return List.generate(4, (index) {
      // Check if this corner is locked
      final isLocked = lockedEquations.any((eq) => eq.cornerIndex == index);
      
      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: ClickableEquals(
          onTap: () => onEquationTap(index),
          isLocked: isLocked,
          size: symbolSize,
          color: operation.color, // Pass the operation color
        ),
      );
    });
  }
}