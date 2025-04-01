import 'package:flutter/material.dart';

class RingModel {
  final List<int> numbers;
  final Color color;
  int rotationSteps;

  // Corner indices based on ring type
  final List<int> cornerIndices;

  RingModel({
    required this.numbers,
    required this.color,
    required this.cornerIndices,
    this.rotationSteps = 0,
  });

  // Create a copy with updated rotation
  RingModel copyWith({int? rotationSteps}) {
    return RingModel(
      numbers: numbers,
      color: color,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      cornerIndices: cornerIndices,
    );
  }

  // Get the number at position considering rotation
  int getNumberAtPosition(int position) {
    if (rotationSteps == 0) return numbers[position];

    final itemCount = numbers.length;
    final actualSteps = rotationSteps % itemCount;

    // Calculate the original position before rotation
    int originalPos;
    if (actualSteps > 0) {
      // Counterclockwise rotation
      originalPos = (position - actualSteps + itemCount) % itemCount;
    } else {
      // Clockwise rotation
      originalPos = (position + (-actualSteps) + itemCount) % itemCount;
    }

    return numbers[originalPos];
  }
}
