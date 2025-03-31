import 'package:flutter/material.dart';

class RingModel {
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  final int itemCount; // Flexible item count
  int rotationSteps; // Number of step rotations (0 = initial position)
  List<bool> solvedCorners; // Track which corners are solved

  // Corner indices based on ring type
  late final List<int> cornerIndices;

  RingModel({
    required this.numbers,
    required this.itemColor,
    required this.squareSize,
    this.rotationSteps = 0,
    int? itemCount,
    List<bool>? solvedCorners,
  }) : 
    this.itemCount = itemCount ?? numbers.length,
    this.solvedCorners = solvedCorners ?? [false, false, false, false] {
    // Set corner indices based on item count
    if (this.itemCount == 12) {
      // Inner ring with 12 items
      cornerIndices = [0, 3, 6, 9];
    } else {
      // Default/outer ring with 16 items
      cornerIndices = [0, 4, 8, 12];
    }
  }

  // Create a copy with updated rotation and solved corners
  RingModel copyWith({int? rotationSteps, List<bool>? solvedCorners}) {
    return RingModel(
      numbers: numbers,
      itemColor: itemColor,
      squareSize: squareSize,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      itemCount: itemCount,
      solvedCorners: solvedCorners ?? this.solvedCorners,
    );
  }

  // Get the rotated list of numbers based on current rotation steps, 
  // preserving any numbers at solved corner positions
  List<int> getRotatedNumbers() {
    if (rotationSteps == 0) return List<int>.from(numbers);

    // Create a copy of the original numbers
    final List<int> rotated = List<int>.from(numbers);
    final actualSteps = rotationSteps % itemCount;
    
    // If no steps to rotate, return the original
    if (actualSteps == 0) return rotated;
    
    // Save the corner values if they're solved
    final Map<int, int> solvedCornerValues = {};
    for (int i = 0; i < cornerIndices.length; i++) {
      if (solvedCorners[i]) {
        solvedCornerValues[cornerIndices[i]] = rotated[cornerIndices[i]];
      }
    }
    
    // Apply rotation
    if (actualSteps > 0) {
      // Positive rotation (clockwise in your app)
      final List<int> removed = List<int>.from(rotated.sublist(0, actualSteps));
      rotated.removeRange(0, actualSteps);
      rotated.addAll(removed);
    } else if (actualSteps < 0) {
      // Negative rotation (counter-clockwise in your app)
      final stepsToMove = -actualSteps;
      final List<int> removed = List<int>.from(rotated.sublist(itemCount - stepsToMove));
      rotated.removeRange(itemCount - stepsToMove, itemCount);
      rotated.insertAll(0, removed);
    }
    
    // Restore the corner values for solved corners
    solvedCornerValues.forEach((index, value) {
      rotated[index] = value;
    });
    
    return rotated;
  }

  // Get the numbers at the corner positions based on current rotation
  List<int> getCornerNumbers() {
    final rotatedNumbers = getRotatedNumbers();
    return cornerIndices.map((index) => rotatedNumbers[index]).toList();
  }
}