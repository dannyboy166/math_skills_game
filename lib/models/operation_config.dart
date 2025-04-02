import 'package:flutter/material.dart';

/// Defines how equations work for a specific operation
class OperationConfig {
  /// Operation name (e.g., "addition", "multiplication")
  final String name;

  /// Display symbol (e.g., "+", "×")
  final String symbol;

  /// Color associated with this operation
  final Color color;

  /// Function to check if an equation is valid
  /// Parameters: innerNumber, outerNumber, targetNumber
  final bool Function(int, int, int) checkEquation;

  /// Function to get the equation as a string for display
  /// Parameters: innerNumber, outerNumber, targetNumber
  final String Function(int, int, int) getEquationString;

  const OperationConfig({
    required this.name,
    required this.symbol,
    required this.color,
    required this.checkEquation,
    required this.getEquationString,
  });

  static OperationConfig forOperation(String operationName) {
    switch (operationName) {
      case 'addition':
        return OperationConfig(
          name: 'addition',
          symbol: '+',
          color: Colors.green,
          checkEquation: (inner, outer, target) => inner + target == outer,
          getEquationString: (inner, target, outer) =>
              '$inner + $target = $outer',
        );

      case 'subtraction':
        return OperationConfig(
          name: 'subtraction',
          symbol: '-',
          color: Colors.purple,
          // For subtraction: outer - inner = target
          checkEquation: (inner, outer, target) => outer - inner == target,
          getEquationString: (inner, target, outer) =>
              '$outer - $inner = $target',
        );

      case 'division':
        return OperationConfig(
          name: 'division',
          symbol: '÷',
          color: Colors.orange,
          // For division: outer ÷ inner = target
          checkEquation: (inner, outer, target) =>
              inner != 0 && outer % inner == 0 && outer ~/ inner == target,
          getEquationString: (inner, target, outer) =>
              '$outer ÷ $inner = $target',
        );

      case 'multiplication':
      default:
        return OperationConfig(
          name: 'multiplication',
          symbol: '×',
          color: Colors.blue,
          checkEquation: (inner, outer, target) => inner * target == outer,
          getEquationString: (inner, target, outer) =>
              '$inner × $target = $outer',
        );
    }
  }
}
