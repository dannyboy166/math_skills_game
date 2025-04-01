import 'package:flutter/material.dart';

class RingModel {
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  final int itemCount;
  int rotationSteps;

  // Corner indices based on ring type
  late final List<int> cornerIndices;

  RingModel({
    required this.numbers,
    required this.itemColor,
    required this.squareSize,
    this.rotationSteps = 0,
    int? itemCount,
  }) : this.itemCount = itemCount ?? numbers.length {
    // Set corner indices based on item count
    if (this.itemCount == 12) {
      // Inner ring with 12 items
      cornerIndices = [0, 3, 6, 9];
    } else {
      // Default/outer ring with 16 items
      cornerIndices = [0, 4, 8, 12];
    }
  }

  // Create a copy with updated rotation
  RingModel copyWith({int? rotationSteps}) {
    return RingModel(
      numbers: numbers,
      itemColor: itemColor,
      squareSize: squareSize,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      itemCount: itemCount,
    );
  }

  // Get the unrotated number at a position (base reference)
  int getBaseNumber(int position) {
    return numbers[position];
  }
}