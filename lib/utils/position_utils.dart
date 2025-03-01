import 'dart:math';
import 'package:flutter/material.dart';

/// Calculates positions for items arranged in a square
class SquarePositionUtils {
  /// Calculate position for an item on a square layout
  /// [index] - The item's index (0-15)
  /// [squareSize] - Size of the square
  /// [itemSize] - Size of the item (width/height)
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize) {
    final tilesPerSide = 4; // 4 tiles per side
    
    // Determine which side the tile is on
    int side = index ~/ tilesPerSide; // 0=top, 1=right, 2=bottom, 3=left
    int positionOnSide = index % tilesPerSide;
    
    double x, y;
    final padding = itemSize / 2;
    final availableSpace = squareSize - itemSize;
    final step = availableSpace / (tilesPerSide - 1);
    
    switch (side) {
      case 0: // Top side
        x = padding + positionOnSide * step;
        y = padding;
        break;
      case 1: // Right side
        x = squareSize - padding;
        y = padding + positionOnSide * step;
        break;
      case 2: // Bottom side
        x = squareSize - padding - positionOnSide * step;
        y = squareSize - padding;
        break;
      case 3: // Left side
        x = padding;
        y = squareSize - padding - positionOnSide * step;
        break;
      default:
        x = 0;
        y = 0;
    }
    
    return Offset(x - itemSize/2, y - itemSize/2);
  }
  
  /// Gets all positions for items in a square
  static List<Offset> getSquarePositions(double squareSize, double itemSize) {
    List<Offset> positions = [];
    for (int i = 0; i < 16; i++) {
      positions.add(calculateSquarePosition(i, squareSize, itemSize));
    }
    return positions;
  }
  
  /// Gets the index of the item at a corner
  static List<int> getCornerIndices() {
    // Corners are at indices 0, 3, 8, 11
    return [0, 3, 8, 11];
  }
}