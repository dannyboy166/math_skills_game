// lib/widgets/equation_layout.dart
import 'package:flutter/material.dart';
import '../models/operation_config.dart';
import '../models/locked_equation.dart';
import '../models/game_mode.dart';
import 'clickable_equals.dart';

class EquationLayout extends StatelessWidget {
  final double boardSize;
  final double innerRingSize;
  final double outerRingSize;
  final OperationConfig operation;
  final List<LockedEquation> lockedEquations;
  final Function(int cornerIndex) onEquationTap;
  final GameMode gameMode;
  final bool isGameComplete;

  const EquationLayout({
    Key? key,
    required this.boardSize,
    required this.innerRingSize,
    required this.outerRingSize,
    required this.operation,
    required this.lockedEquations,
    required this.onEquationTap,
    required this.gameMode,
    required this.isGameComplete,
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
        ...(isReverseFormat
            ? _buildOperationSymbolsReverse()
            : _buildOperationSymbols()),

        // Equals signs
        // For addition and multiplication, between inner and outer ring
        // For subtraction and division, between center and inner ring
        ...(isReverseFormat
            ? _buildEqualsSymbolsReverse()
            : _buildEqualsSymbols()),
      ],
    );
  }
// lib/widgets/equation_layout.dart
// Method for creating perfectly centered operation symbols

  Widget _buildCustomOperationSymbol(Color color, double opacity) {
    // Default line height (will be adjusted per symbol)
    double lineHeight = 1.0;
    // Default vertical offset (will be adjusted per symbol)
    double verticalOffset = 0.0;
    // Symbol to display
    String symbol = '+';

    // Fine-tune alignment for each operation symbol
    switch (operation.name) {
      case 'addition':
        symbol = '+';
        lineHeight = 1.0;
        verticalOffset = -1.0; // Move up slightly
        break;
      case 'subtraction':
        symbol = '−';
        lineHeight = 0.8;
        verticalOffset = -1.0;
        break;
      case 'multiplication':
        symbol = '×';
        lineHeight = 0.9;
        verticalOffset = -1.5; // Multiplication symbol needs more adjustment
        break;
      case 'division':
        symbol = '÷';
        lineHeight = 0.9;
        verticalOffset = -1.0;
        break;
      default:
        symbol = '+';
        lineHeight = 1.0;
        verticalOffset = -1.0;
    }

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 0.5,
          )
        ],
      ),
      child: Transform.translate(
        offset: Offset(
            0, verticalOffset), // Apply vertical offset for precise centering
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(opacity),
            height: lineHeight,
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
      // Only lock when game is complete in times table ring mode
      final isLocked = isGameComplete;

      // Use a greyed-out color if locked
      final Color textColor = isLocked ? Colors.grey : operation.color;
      final double opacity = isLocked ? 0.7 : 1.0;

      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: GestureDetector(
          onTap: isLocked ? null : () => onEquationTap(index),
          child: isLocked
              ? Container(
                  width: symbolSize,
                  height: symbolSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                )
              : _buildCustomOperationSymbol(
                  textColor,
                  opacity,
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
      // Only lock when game is complete in times table ring mode
      final isLocked = isGameComplete;

      // Use a greyed-out color if locked
      final Color textColor = isLocked ? Colors.grey : operation.color;
      final double opacity = isLocked ? 0.7 : 1.0;

      return Positioned(
        left: symbolPositions[index].dx - symbolSize / 2,
        top: symbolPositions[index].dy - symbolSize / 2,
        child: GestureDetector(
          onTap: isLocked ? null : () => onEquationTap(index),
          child: isLocked
              ? Container(
                  width: symbolSize,
                  height: symbolSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                )
              : _buildCustomOperationSymbol(
                  textColor,
                  opacity,
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
      // Only lock when game is complete in times table ring mode
      final isLocked = isGameComplete;

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
      // Only lock when game is complete in times table ring mode
      final isLocked = isGameComplete;

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
