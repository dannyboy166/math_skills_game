import 'package:flutter/material.dart';

class SquarePositionUtils {
  // Calculate position for an item on outer square (16 tiles)
  static Offset calculateSquarePosition(
    int index,
    double squareSize,
    double itemSize, {
    double cornerSizeMultiplier = 1.0,
    double margin = 0.0,
  }) {
    final availableSpace = squareSize - itemSize - margin * 2;
    final cornerSize = itemSize * cornerSizeMultiplier;
    final insetAmount = cornerSize - itemSize;

    double x, y;

    if (index < 5) {
      if (index == 0) {
        x = margin;
        y = margin;
      } else if (index == 4) {
        x = margin + availableSpace - insetAmount;
        y = margin;
      } else {
        x = margin + (index / 4) * availableSpace;
        y = margin;
      }
    } else if (index < 9) {
      if (index == 4) {
        x = margin + availableSpace - insetAmount;
        y = margin;
      } else if (index == 8) {
        x = margin + availableSpace - insetAmount;
        y = margin + availableSpace - insetAmount;
      } else {
        x = margin + availableSpace;
        y = margin + ((index - 4) / 4) * availableSpace;
      }
    } else if (index < 13) {
      if (index == 8) {
        x = margin + availableSpace - insetAmount;
        y = margin + availableSpace - insetAmount;
      } else if (index == 12) {
        x = margin;
        y = margin + availableSpace - insetAmount;
      } else {
        x = margin + availableSpace - ((index - 8) / 4) * availableSpace;
        y = margin + availableSpace;
      }
    } else {
      if (index == 12) {
        x = margin;
        y = margin + availableSpace - insetAmount;
      } else if (index == 0) {
        x = margin;
        y = margin;
      } else {
        x = margin;
        y = margin + availableSpace - ((index - 12) / 4) * availableSpace;
      }
    }

    return Offset(x, y);
  }

  // Calculate position for an item on inner square (12 tiles)
  static Offset calculateInnerSquarePosition(
    int index,
    double squareSize,
    double itemSize, {
    double cornerSizeMultiplier = 1.0,
    double margin = 0.0,
  }) {
    final availableSpace = squareSize - itemSize - margin * 2;
    final cornerSize = itemSize * cornerSizeMultiplier;
    final insetAmount = cornerSize - itemSize;

    double x, y;

    if (index < 4) {
      if (index == 0) {
        x = margin;
        y = margin;
      } else if (index == 3) {
        x = margin + availableSpace - insetAmount;
        y = margin;
      } else {
        x = margin + (index / 3) * availableSpace;
        y = margin;
      }
    } else if (index < 7) {
      if (index == 3) {
        x = margin + availableSpace - insetAmount;
        y = margin;
      } else if (index == 6) {
        x = margin + availableSpace - insetAmount;
        y = margin + availableSpace - insetAmount;
      } else {
        x = margin + availableSpace;
        y = margin + ((index - 3) / 3) * availableSpace;
      }
    } else if (index < 10) {
      if (index == 6) {
        x = margin + availableSpace - insetAmount;
        y = margin + availableSpace - insetAmount;
      } else if (index == 9) {
        x = margin;
        y = margin + availableSpace - insetAmount;
      } else {
        x = margin + availableSpace - ((index - 6) / 3) * availableSpace;
        y = margin + availableSpace;
      }
    } else {
      if (index == 9) {
        x = margin;
        y = margin + availableSpace - insetAmount;
      } else {
        x = margin;
        y = margin + availableSpace - ((index - 9) / 3) * availableSpace;
      }
    }

    return Offset(x, y);
  }
}
