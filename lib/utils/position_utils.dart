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
    final isCorner = index == 0 || index == 4 || index == 8 || index == 12;
    final tileSize = isCorner ? itemSize * cornerSizeMultiplier : itemSize;
    final availableSpace = squareSize - tileSize - margin * 2;

    // This value shifts the tile outward slightly to visually center it
    final visualAdjust =
        isCorner ? (itemSize * (cornerSizeMultiplier - 1)) / 2 : 0.0;

    double x = 0, y = 0;

    if (index < 5) {
      if (index == 0) {
        x = margin - visualAdjust;
        y = margin - visualAdjust;
      } else if (index == 4) {
        x = margin + availableSpace + visualAdjust;
        y = margin - visualAdjust;
      } else {
        x = margin + (index / 4) * availableSpace;
        y = margin;
      }
    } else if (index < 9) {
      if (index == 8) {
        x = margin + availableSpace + visualAdjust;
        y = margin + availableSpace + visualAdjust;
      } else {
        x = margin + availableSpace;
        y = margin + ((index - 4) / 4) * availableSpace;
      }
    } else if (index < 13) {
      if (index == 12) {
        x = margin - visualAdjust;
        y = margin + availableSpace + visualAdjust;
      } else {
        x = margin + availableSpace - ((index - 8) / 4) * availableSpace;
        y = margin + availableSpace;
      }
    } else {
      x = margin;
      y = margin + availableSpace - ((index - 12) / 4) * availableSpace;
    }

    return Offset(x, y);
  }

  static Offset calculateInnerSquarePosition(
    int index,
    double squareSize,
    double itemSize, {
    double cornerSizeMultiplier = 1.0,
    double margin = 0.0,
  }) {
    final isCorner = index == 0 || index == 3 || index == 6 || index == 9;
    final tileSize = isCorner ? itemSize * cornerSizeMultiplier : itemSize;
    final availableSpace = squareSize - tileSize - margin * 2;

    // Adjust corner tile position outward to center it visually
    final visualAdjust =
        isCorner ? (itemSize * (cornerSizeMultiplier - 1)) / 2 : 0.0;

    double x = 0, y = 0;

    if (index < 4) {
      if (index == 0) {
        x = margin - visualAdjust;
        y = margin - visualAdjust;
      } else if (index == 3) {
        x = margin + availableSpace + visualAdjust;
        y = margin - visualAdjust;
      } else {
        x = margin + (index / 3) * availableSpace;
        y = margin;
      }
    } else if (index < 7) {
      if (index == 6) {
        x = margin + availableSpace + visualAdjust;
        y = margin + availableSpace + visualAdjust;
      } else {
        x = margin + availableSpace;
        y = margin + ((index - 3) / 3) * availableSpace;
      }
    } else if (index < 10) {
      if (index == 9) {
        x = margin - visualAdjust;
        y = margin + availableSpace + visualAdjust;
      } else {
        x = margin + availableSpace - ((index - 6) / 3) * availableSpace;
        y = margin + availableSpace;
      }
    } else {
      x = margin;
      y = margin + availableSpace - ((index - 9) / 3) * availableSpace;
    }

    return Offset(x, y);
  }
}
