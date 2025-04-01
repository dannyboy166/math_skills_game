// lib/models/ring_model.dart - Simple version with no changes after locking
import 'package:flutter/material.dart';

class RingModel {
  final List<int> numbers;
  final Color color;
  int rotationSteps;

  // Corner indices based on ring type
  final List<int> cornerIndices;

  // Track which positions are locked
  Set<int> lockedPositions = {};

  RingModel({
    required this.numbers,
    required this.color,
    required this.cornerIndices,
    this.rotationSteps = 0,
    this.lockedPositions = const {},
  });

  // Create a copy with updated rotation and/or locked positions
  RingModel copyWith({
    int? rotationSteps,
    Set<int>? lockedPositions,
  }) {
    return RingModel(
      numbers: numbers,
      color: color,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      cornerIndices: cornerIndices,
      lockedPositions: lockedPositions ?? this.lockedPositions,
    );
  }

  // Get the number at position considering rotation
  int getNumberAtPosition(int position) {
    // If this position is locked, return whatever is currently there
    if (lockedPositions.contains(position)) {
      // Calculate what number is currently at this position
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