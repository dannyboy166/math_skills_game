// lib/models/ring_model.dart
import 'package:flutter/material.dart';

class RingModel {
  // Original numbers array (never changes)
  final List<int> numbers;
  final Color color;

  // Corner indices based on ring type
  final List<int> cornerIndices;

  // Current state data
  final Map<int, int> _currentNumbers = {};
  final Map<int, bool> _lockedPositions = {};
  final Map<int, bool> _greyedNumbers = {};

  RingModel({
    required this.numbers,
    required this.color,
    required this.cornerIndices,
    int rotationSteps = 0,
    Set<int> lockedPositions = const {},
  }) {
    // Initialize current numbers from original numbers
    for (int i = 0; i < numbers.length; i++) {
      _currentNumbers[i] = numbers[i];
    }

    // Apply initial rotation if needed
    if (rotationSteps != 0) {
      _applyRotation(rotationSteps);
    }

    // Set initial locked positions
    for (int pos in lockedPositions) {
      _lockedPositions[pos] = true;
    }
  }

  // Get all currently locked positions
  Set<int> get lockedPositions => _lockedPositions.keys.toSet();

  // For compatibility with old code
  int get rotationSteps => 0; // We don't use this anymore

  // Compatibility with old API
  RingModel copyWith({int? rotationSteps, Set<int>? lockedPositions}) {
    // Create a new instance
    RingModel newModel = RingModel(
      numbers: numbers,
      color: color,
      cornerIndices: cornerIndices,
    );

    // Copy the current state
    newModel._currentNumbers.addAll(_currentNumbers);
    newModel._lockedPositions.addAll(_lockedPositions);
    newModel._greyedNumbers.addAll(_greyedNumbers);

    // Apply rotation if needed
    if (rotationSteps != null && rotationSteps != 0) {
      newModel._applyRotation(rotationSteps);
    }

    // Add any new locked positions
    if (lockedPositions != null) {
      for (int pos in lockedPositions) {
        if (!newModel._lockedPositions.containsKey(pos)) {
          newModel._lockedPositions[pos] = true;
        }
      }
    }

    return newModel;
  }

  // Create a copy with a new rotation
  RingModel copyWithRotation(int rotationSteps) {
    // Create a new instance
    RingModel newModel = RingModel(
      numbers: numbers,
      color: color,
      cornerIndices: cornerIndices,
    );

    // Copy the current state
    newModel._currentNumbers.addAll(_currentNumbers);
    newModel._lockedPositions.addAll(_lockedPositions);

    // Apply the rotation (which respects locked positions)
    newModel._applyRotation(rotationSteps);

    return newModel;
  }

  // Create a copy with locked positions
  RingModel copyWithLockedPosition(int position, int number) {
    // Create a new instance
    RingModel newModel = RingModel(
      numbers: numbers,
      color: color,
      cornerIndices: cornerIndices,
    );

    // Copy the current state
    newModel._currentNumbers.addAll(_currentNumbers);
    newModel._lockedPositions.addAll(_lockedPositions);

    // Lock the position with the specified number
    newModel._lockedPositions[position] = true;
    newModel._currentNumbers[position] = number;

    return newModel;
  }

  void _applyRotation(int steps) {
    if (steps == 0) return;

    // Force steps to be in range -1 to 1 (simplify to just direction)
    steps = steps > 0 ? 1 : -1;

    // Get all unlocked positions
    List<int> unlockedPositions = [];
    for (int i = 0; i < numbers.length; i++) {
      if (!_lockedPositions.containsKey(i)) {
        unlockedPositions.add(i);
      }
    }

    if (unlockedPositions.isEmpty) return;

    // Create copy of current state
    Map<int, int> newNumbers = Map.of(_currentNumbers);

    if (steps > 0) {
      // Counterclockwise: first value becomes last
      int firstPos = unlockedPositions.first;
      int firstVal = _currentNumbers[firstPos]!;

      // Shift all other values left
      for (int i = 0; i < unlockedPositions.length - 1; i++) {
        newNumbers[unlockedPositions[i]] =
            _currentNumbers[unlockedPositions[i + 1]]!;
      }

      // Last position gets the first value
      newNumbers[unlockedPositions.last] = firstVal;
    } else {
      // Clockwise: last value becomes first
      int lastPos = unlockedPositions.last;
      int lastVal = _currentNumbers[lastPos]!;

      // Shift all other values right
      for (int i = unlockedPositions.length - 1; i > 0; i--) {
        newNumbers[unlockedPositions[i]] =
            _currentNumbers[unlockedPositions[i - 1]]!;
      }

      // First position gets the last value
      newNumbers[unlockedPositions.first] = lastVal;
    }

    // Replace current numbers with new arrangement
    _currentNumbers.clear();
    _currentNumbers.addAll(newNumbers);

    // Debug output
    for (int i = 0; i < numbers.length; i++) {}
  }

  int getNumberAtPosition(int position) {
    // Always return from _currentNumbers, which contains our current state
    // Fall back to original numbers array only if not found in _currentNumbers
    return _currentNumbers[position] ?? numbers[position];
  }

  // Check if a number is greyed out
  bool isNumberGreyedOut(int number) {
    return _greyedNumbers[number] == true;
  }
  
  // Grey out a specific number
  RingModel copyWithGreyedNumber(int number) {
    RingModel newModel = RingModel(
      numbers: numbers,
      color: color,
      cornerIndices: cornerIndices,
    );
    
    newModel._currentNumbers.addAll(_currentNumbers);
    newModel._lockedPositions.addAll(_lockedPositions);
    newModel._greyedNumbers.addAll(_greyedNumbers);
    newModel._greyedNumbers[number] = true;
    
    return newModel;
  }
}
