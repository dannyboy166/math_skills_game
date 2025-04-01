// lib/models/locked_equation.dart
import 'package:flutter/material.dart';

/// Model class to track information about locked equations
class LockedEquation {
  /// Identifies which corner is locked (0-3)
  final int cornerIndex;
  
  /// Numbers involved in the equation
  final int innerNumber;
  final int targetNumber;
  final int outerNumber;
  
  /// Positions in their respective rings
  final int innerPosition;
  final int outerPosition;
  
  /// Operation that this equation uses
  final String operation;
  
  /// Equation string for display
  final String equationString;
  
  const LockedEquation({
    required this.cornerIndex,
    required this.innerNumber,
    required this.targetNumber,
    required this.outerNumber,
    required this.innerPosition,
    required this.outerPosition,
    required this.operation,
    required this.equationString,
  });
}