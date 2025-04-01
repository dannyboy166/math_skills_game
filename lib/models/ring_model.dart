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

// Completely fixed _applyRotation method with special handling for anticlockwise rotation
  void _applyRotation(int steps) {
    print('ROTATION DEBUG: Starting rotation by $steps steps');
    print(
        'ROTATION DEBUG: Locked positions: ${_lockedPositions.keys.toList()}');

    if (steps == 0) return;

    final itemCount = numbers.length;
    steps = steps % itemCount;
    if (steps == 0) return;

    print('ROTATION DEBUG: Effective rotation steps: $steps');

    // Create a fresh new numbers map
    Map<int, int> newNumbers = {};

    // DIFFERENT APPROACHES FOR CLOCKWISE VS COUNTERCLOCKWISE
    if (steps > 0) {
      // COUNTERCLOCKWISE ROTATION (positive steps)

      // First, assign all locked positions
      for (int pos in _lockedPositions.keys) {
        newNumbers[pos] = _currentNumbers[pos]!;
      }

      // Process unlocked positions in a specific order to avoid collisions
      List<int> unlockedPositions = [];
      for (int i = 0; i < itemCount; i++) {
        if (!_lockedPositions.containsKey(i)) {
          unlockedPositions.add(i);
        }
      }
// Change the sorting order for counterclockwise rotation
// Process positions in REVERSE order of their starting positions
// This ensures we handle positions that need to move past locked ones first
      unlockedPositions.sort((a, b) => b.compareTo(a));
      print(
          'ROTATION DEBUG: Processing unlocked positions in order: $unlockedPositions');

      // Now process in this strategic order
      for (int pos in unlockedPositions) {
        int currentNumber = _currentNumbers[pos]!;

        // Calculate target position
        int newPos = (pos + steps) % itemCount;

        // Find the next available position (not locked or already assigned)
        while (_lockedPositions.containsKey(newPos) ||
            newNumbers.containsKey(newPos)) {
          newPos = (newPos + 1) % itemCount;
        }

        newNumbers[newPos] = currentNumber;
        print(
            'ROTATION DEBUG: Moved number $currentNumber from $pos to $newPos');
      }
    } else {
      // CLOCKWISE ROTATION (negative steps)

      // First, assign all locked positions
      for (int pos in _lockedPositions.keys) {
        newNumbers[pos] = _currentNumbers[pos]!;
      }

      // Process unlocked positions in a specific order to avoid collisions
      List<int> unlockedPositions = [];
      for (int i = 0; i < itemCount; i++) {
        if (!_lockedPositions.containsKey(i)) {
          unlockedPositions.add(i);
        }
      }

      // Sort by the proposed new position in REVERSE order for clockwise
      // This ensures we process the furthest positions first
      unlockedPositions.sort((a, b) {
        int newPosA = (a + steps + itemCount) % itemCount;
        int newPosB = (b + steps + itemCount) % itemCount;
        return newPosB.compareTo(newPosA); // Note the reversed comparison
      });

      print(
          'ROTATION DEBUG: Processing unlocked positions in order: $unlockedPositions');

      // Now process in this strategic order
      for (int pos in unlockedPositions) {
        int currentNumber = _currentNumbers[pos]!;

        // Calculate target position
        int newPos = (pos + steps + itemCount) % itemCount;

        // Find the next available position (not locked or already assigned)
        while (_lockedPositions.containsKey(newPos) ||
            newNumbers.containsKey(newPos)) {
          newPos = (newPos - 1 + itemCount) % itemCount;
        }

        newNumbers[newPos] = currentNumber;
        print(
            'ROTATION DEBUG: Moved number $currentNumber from $pos to $newPos');
      }
    }

    // Fill in any missing positions with their original numbers (should not happen)
    for (int i = 0; i < itemCount; i++) {
      if (!newNumbers.containsKey(i)) {
        print(
            'ROTATION DEBUG: Position $i was not assigned! Using original number ${numbers[i]}');
        newNumbers[i] = numbers[i];
      }
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
