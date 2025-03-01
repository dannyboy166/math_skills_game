import 'package:flutter/material.dart';

class RingModel {
  final int itemCount = 16; // Fixed at 16 tiles (4 per side)
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  int rotationSteps; // Number of step rotations (0 = initial position)
  
  // Corner indices (clockwise from top-left)
  final List<int> cornerIndices = [0, 3, 8, 11];
  
  RingModel({
    required this.numbers,
    required this.itemColor,
    required this.squareSize,
    this.rotationSteps = 0,
  });
  
  // Create a copy with updated rotation
  RingModel copyWith({int? rotationSteps}) {
    return RingModel(
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
  
  // Get the numbers at the corner positions based on current rotation
  List<int> getCornerNumbers() {
    final rotatedNumbers = getRotatedNumbers();
    return cornerIndices.map((index) => rotatedNumbers[index]).toList();
  }
}