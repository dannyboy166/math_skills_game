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
    print('ROTATION DEBUG: Starting rotation by $steps steps');
    print(
        'ROTATION DEBUG: Locked positions: ${_lockedPositions.keys.toList()}');

    if (steps == 0) return;

    final itemCount = numbers.length;
    steps = steps % itemCount;
    if (steps == 0) return;

    print('ROTATION DEBUG: Effective rotation steps: $steps');

    // Create a new numbers map for the result
    Map<int, int> newNumbers = {};

    // Copy all locked positions to preserve them
    for (int pos in _lockedPositions.keys) {
      newNumbers[pos] = _currentNumbers[pos]!;
    }

    // Create a list of unlocked positions and their current numbers
    List<MapEntry<int, int>> unlockedItems = [];
    for (int i = 0; i < itemCount; i++) {
      if (!_lockedPositions.containsKey(i)) {
        unlockedItems.add(MapEntry(i, _currentNumbers[i]!));
      }
    }

    // Sort the unlocked items by position for consistent processing
    unlockedItems.sort((a, b) => a.key.compareTo(b.key));

    // Step 1: Collect all unlocked numbers in their correct order
    List<int> unlockedNumbers = unlockedItems.map((e) => e.value).toList();

    // Step 2: Rotate the unlocked numbers
    if (steps > 0) {
      // Counterclockwise rotation (positive steps)
      final rotationCount = steps % unlockedNumbers.length;
      final rotatedNumbers = [
        ...unlockedNumbers.sublist(rotationCount),
        ...unlockedNumbers.sublist(0, rotationCount)
      ];
      unlockedNumbers = rotatedNumbers;
    } else {
      // Clockwise rotation (negative steps)
      final rotationCount = (-steps) % unlockedNumbers.length;
      final rotatedNumbers = [
        ...unlockedNumbers.sublist(unlockedNumbers.length - rotationCount),
        ...unlockedNumbers.sublist(0, unlockedNumbers.length - rotationCount)
      ];
      unlockedNumbers = rotatedNumbers;
    }

    // Step 3: Place the rotated unlocked numbers back into their positions
    List<int> unlockedPositions = unlockedItems.map((e) => e.key).toList();

    for (int i = 0; i < unlockedPositions.length; i++) {
      int position = unlockedPositions[i];
      int number = unlockedNumbers[i];
      newNumbers[position] = number;
      print('ROTATION DEBUG: Placed number $number at position $position');
    }

    // Replace the current numbers with the rotated numbers
    _currentNumbers.clear();
    _currentNumbers.addAll(newNumbers);

    // Print final state after rotation
    print('ROTATION DEBUG: Numbers after rotation:');
    for (int i = 0; i < itemCount; i++) {
      String lockStatus = _lockedPositions.containsKey(i) ? '(LOCKED)' : '';
      print('ROTATION DEBUG:   Position $i: ${_currentNumbers[i]} $lockStatus');
    }
  }

  // Get the number at a position
  int getNumberAtPosition(int position) {
    return _currentNumbers[position] ?? numbers[position];
  }

  // For debugging: print the current state
  void debugPrintState() {
    print('Current numbers:');
    for (int i = 0; i < numbers.length; i++) {
      String lockStatus = _lockedPositions.containsKey(i) ? '(LOCKED)' : '';
      print('Position $i: ${_currentNumbers[i]} $lockStatus');
    }
  }
}
