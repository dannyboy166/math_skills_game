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
    // Calculate the midpoint between center and inner ring
    final centerRadius = 30.0; // Center target radius
    final innerRadius = innerRingSize / 2;
    final operatorDistance = (innerRadius + centerRadius) / 2;
    
    // Operation symbol positions (diagonal to corners)
    final positions = [
      // Top-right
      Offset(operatorDistance, -operatorDistance),
      // Bottom-right
      Offset(operatorDistance, operatorDistance),
      // Bottom-left
      Offset(-operatorDistance, operatorDistance),
      // Top-left
      Offset(-operatorDistance, -operatorDistance),
    ];
    
    return positions.map((offset) {
      return Positioned(
        left: boardSize / 2 + offset.dx - 15,
        top: boardSize / 2 + offset.dy - 15,
        child: Text(
          operation.symbol,
          style: TextStyle(
            fontSize: 30,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildEqualsSymbols() {
    // Calculate the midpoint between inner and outer rings
    final innerRadius = innerRingSize / 2;
    final outerRadius = outerRingSize / 2;
    final equalsDistance = (innerRadius + outerRadius) / 2;
    
    // Equals sign positions (diagonal to corners)
    final positions = [
      // Top-right
      Offset(equalsDistance, -equalsDistance),
      // Bottom-right
      Offset(equalsDistance, equalsDistance),
      // Bottom-left
      Offset(-equalsDistance, equalsDistance),
      // Top-left
      Offset(-equalsDistance, -equalsDistance),
    ];
    
    return positions.map((offset) {
      return Positioned(
        left: boardSize / 2 + offset.dx - 15,
        top: boardSize / 2 + offset.dy - 15,
        child: Text(
          "=",
          style: TextStyle(
            fontSize: 30,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }
}