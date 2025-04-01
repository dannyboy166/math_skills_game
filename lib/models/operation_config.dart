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
  
  /// Factory method to get config for a specific operation
  static OperationConfig forOperation(String operationName) {
    switch (operationName) {
      case 'addition':
        return OperationConfig(
          name: 'addition',
          symbol: '+',
          color: Colors.green,
          checkEquation: (inner, outer, target) => inner + target == outer,
          getEquationString: (inner, target, outer) => '$inner + $target = $outer',
        );
      
      case 'subtraction':
        return OperationConfig(
          name: 'subtraction',
          symbol: '-',
          color: Colors.purple,
          // Two valid cases: inner - target = outer OR target - inner = outer
          checkEquation: (inner, outer, target) => 
            inner - target == outer || target - inner == outer,
          getEquationString: (inner, target, outer) => 
            inner - target == outer 
              ? '$inner - $target = $outer' 
              : '$target - $inner = $outer',
        );
      
      case 'division':
        return OperationConfig(
          name: 'division',
          symbol: '÷',
          color: Colors.orange,
          // Two valid cases: inner ÷ target = outer OR target ÷ inner = outer
          checkEquation: (inner, outer, target) => 
            (inner % target == 0 && inner ~/ target == outer) || 
            (target % inner == 0 && target ~/ inner == outer),
          getEquationString: (inner, target, outer) => 
            (inner % target == 0 && inner ~/ target == outer)
              ? '$inner ÷ $target = $outer' 
              : '$target ÷ $inner = $outer',
        );
      
      case 'multiplication':
      default:
        return OperationConfig(
          name: 'multiplication',
          symbol: '×',
          color: Colors.blue,
          checkEquation: (inner, outer, target) => inner * target == outer,
          getEquationString: (inner, target, outer) => '$inner × $target = $outer',
        );
    }
  }
}