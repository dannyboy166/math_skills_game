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
  })  : this.itemCount = itemCount ?? numbers.length,
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

  // FIXED: Get the rotated list of numbers based on current rotation steps
  // This new version properly rotates numbers WHILE preserving solved corners
  List<int> getRotatedNumbers() {
    if (rotationSteps == 0) return List<int>.from(numbers);

    final actualSteps = rotationSteps % itemCount;
    if (actualSteps == 0) return List<int>.from(numbers);

    // Create a map to track which number belongs at which position
    Map<int, int> positionToNumber = {};

    // Fill the map with initial position -> number mappings
    for (int i = 0; i < itemCount; i++) {
      positionToNumber[i] = numbers[i];
    }

    // Calculate new positions after rotation
    Map<int, int> newPositionToNumber = {};
    for (int oldPos = 0; oldPos < itemCount; oldPos++) {
      // Skip solved corners - they stay fixed
      if (cornerIndices.contains(oldPos)) {
        int cornerIndex = cornerIndices.indexOf(oldPos);
        if (solvedCorners[cornerIndex]) {
          // Keep solved corners fixed at their original positions
          newPositionToNumber[oldPos] = positionToNumber[oldPos]!;
          continue;
        }
      }

      // Calculate new position after rotation
      int newPos;
      if (actualSteps > 0) {
        // Clockwise rotation
        newPos = (oldPos - actualSteps) % itemCount;
        if (newPos < 0) newPos += itemCount;
      } else {
        // Counter-clockwise rotation
        newPos = (oldPos - actualSteps) % itemCount;
      }

      // Skip positions that are occupied by solved corners
      bool positionOccupied = false;
      for (int i = 0; i < cornerIndices.length; i++) {
        if (newPos == cornerIndices[i] && solvedCorners[i]) {
          positionOccupied = true;
          break;
        }
      }

      // If position is occupied by a solved corner, find the next available position
      if (positionOccupied) {
        // Find next non-corner position (clockwise)
        do {
          if (actualSteps > 0) {
            // Keep moving in the same direction (clockwise)
            newPos = (newPos - 1) % itemCount;
            if (newPos < 0) newPos += itemCount;
          } else {
            // Keep moving in the same direction (counter-clockwise)
            newPos = (newPos + 1) % itemCount;
          }

          positionOccupied = false;
          for (int i = 0; i < cornerIndices.length; i++) {
            if (newPos == cornerIndices[i] && solvedCorners[i]) {
              positionOccupied = true;
              break;
            }
          }
        } while (positionOccupied && newPositionToNumber.containsKey(newPos));
      }

      // Ensure we don't overwrite existing positions
      if (!newPositionToNumber.containsKey(newPos)) {
        newPositionToNumber[newPos] = positionToNumber[oldPos]!;
      }
    }

    // Create the final rotated list
    List<int> rotated = List.filled(itemCount, 0);
    for (int i = 0; i < itemCount; i++) {
      rotated[i] = newPositionToNumber[i] ?? numbers[i];
    }

    return rotated;
  }

  // Get the numbers at the corner positions based on current rotation
  List<int> getCornerNumbers() {
    final rotatedNumbers = getRotatedNumbers();
    return cornerIndices.map((index) => rotatedNumbers[index]).toList();
  }
}
