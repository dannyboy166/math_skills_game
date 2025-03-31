import 'package:flutter/material.dart';
import 'ring_model.dart';

/// Abstract class defining the interface for all game operations.
/// This allows each operation (+, -, ×, ÷) to have its own implementation
/// of number generation and equation checking logic.
abstract class GameOperation {
  /// The name of the operation (e.g., "addition", "multiplication")
  String get name;
  
  /// The display name for the operation (e.g., "Addition", "Multiplication")
  String get displayName;
  
  /// The symbol representing the operation (e.g., "+", "×")
  String get symbol;
  
  /// The emoji representing the operation (e.g., "➕", "✖️")
  String get emoji;
  
  /// The color associated with this operation
  Color get color;
  
  /// Generate numbers for both rings based on the target number
  /// 
  /// This method populates the inner and outer ring models with appropriate 
  /// numbers for the specific operation.
  void generateGameNumbers({
    required RingModel outerRingModel, 
    required RingModel innerRingModel, 
    required int targetNumber
  });
  
  /// Check if the equation at a specific corner is correct
  /// 
  /// For example, for multiplication: innerNumber × targetNumber == outerNumber
  bool checkEquation({
    required int innerNumber, 
    required int outerNumber, 
    required int targetNumber
  });
  
  /// Get the equation as a string (for display purposes)
  /// 
  /// For example: "3 × 5 = 15"
  String getEquationString({
    required int innerNumber, 
    required int targetNumber, 
    required int outerNumber
  });
}