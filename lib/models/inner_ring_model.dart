import 'package:flutter/material.dart';

class InnerRingModel {
  final int itemCount = 12; // Total of 12 tiles (no corners)
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  int rotationSteps; // Number of step rotations (0 = initial position)
  
  InnerRingModel({
    required this.numbers,
    required this.itemColor,
    required this.squareSize,
    this.rotationSteps = 0,
  });
  
  // Create a copy with updated rotation
  InnerRingModel copyWith({int? rotationSteps}) {
    return InnerRingModel(
      numbers: numbers,
      itemColor: itemColor,
      squareSize: squareSize,
      rotationSteps: rotationSteps ?? this.rotationSteps,
    );
  }
  
  // Get the rotated list of numbers based on current rotation steps
  List<int> getRotatedNumbers() {
    if (rotationSteps == 0) return numbers;
    
    // Create a new list rotated by the number of steps
    final normalizedSteps = rotationSteps % itemCount;
    return [...numbers.sublist(normalizedSteps), ...numbers.sublist(0, normalizedSteps)];
  }
  
  // Get the numbers that align with the outer corners
  // These are at fixed positions in the 4x4 grid
  List<int> getCornerAlignedNumbers() {
    final rotatedNumbers = getRotatedNumbers();
    // In a 4x4 grid, these would be the numbers closest to each corner
    // Top-left = 0, Top-right = 3, Bottom-right = 6, Bottom-left = 9
    return [rotatedNumbers[0], rotatedNumbers[3], rotatedNumbers[6], rotatedNumbers[9]];
  }
}