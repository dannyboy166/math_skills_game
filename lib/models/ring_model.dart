// First, update the RingModel class
import 'package:flutter/material.dart';
import 'package:math_skills_game/models/solved_corner.dart';

class RingModel {
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  final int itemCount;
  int rotationSteps;

  // Remove this - we'll use the SolvedCorner objects instead
  // List<bool> solvedCorners;

  // Corner indices based on ring type
  late final List<int> cornerIndices;

  // NEW: Use SolvedCorner objects to track each corner's state and numbers
  final List<SolvedCorner> corners = List.generate(
      4,
      (index) => SolvedCorner(
          isLocked: false, innerNumber: 0, outerNumber: 0, equationString: ""));

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
    RingModel newModel = RingModel(
      numbers: numbers,
      itemColor: itemColor,
      squareSize: squareSize,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      itemCount: itemCount,
    );

    // Copy the corner states
    for (int i = 0; i < 4; i++) {
      newModel.corners[i] = corners[i];
    }

    return newModel;
  }

  // Get the unrotated number at a position (base reference)
  int getBaseNumber(int position) {
    return numbers[position];
  }

  // Get whether a corner is solved
  bool isCornerSolved(int cornerIndex) {
    return corners[cornerIndex].isLocked;
  }

  // Set a corner as solved and store its current numbers
  void setCornerSolved(
      int cornerIndex, int innerNumber, int outerNumber, String equation) {
    corners[cornerIndex] = SolvedCorner(
        isLocked: true,
        innerNumber: innerNumber,
        outerNumber: outerNumber,
        equationString: equation);
  }

  // Clear a corner's solved status
  void clearCornerSolved(int cornerIndex) {
    corners[cornerIndex] = SolvedCorner(
        isLocked: false, innerNumber: 0, outerNumber: 0, equationString: "");
  }

  // Get all solved corner indices
  List<int> get solvedCornerIndices =>
      List.generate(4, (i) => i).where((i) => corners[i].isLocked).toList();
}
