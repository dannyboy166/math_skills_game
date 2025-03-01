import 'dart:math';
import 'package:flutter/material.dart';

/// Calculates positions for items arranged in a square
class SquarePositionUtils {
  /// Calculate position for an item on a square layout
  /// [index] - The item's index (0-19)
  /// [squareSize] - Size of the square
  /// [itemSize] - Size of the item (width/height)
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize) {
    final tilesPerSide = 5; // 5 tiles per side
    
    // Determine which side the tile is on
    int side = index ~/ tilesPerSide; // 0=top, 1=right, 2=bottom, 3=left
    int positionOnSide = index % tilesPerSide;
    
    // Calculate the available space on each side
    final availableSpace = squareSize - itemSize;
    
    // Fixed positions for each element on a side (normalized from 0.0 to 1.0)
    // These values create the non-uniform spacing you requested
    // First and last positions are corners, others follow your spacing pattern
    List<double> positions = [0.0, 0.25, 0.5, 0.75, 1.0];
    
    double x, y;
    final inset = itemSize / 2;
    
    switch (side) {
      case 0: // Top side
        x = inset + positions[positionOnSide] * availableSpace;
        y = inset;
        break;
      case 1: // Right side
        x = squareSize - inset;
        y = inset + positions[positionOnSide] * availableSpace;
        break;
      case 2: // Bottom side
        x = squareSize - inset - positions[positionOnSide] * availableSpace;
        y = squareSize - inset;
        break;
      case 3: // Left side
        x = inset;
        y = squareSize - inset - positions[positionOnSide] * availableSpace;
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
    for (int i = 0; i < 20; i++) { // 20 positions (5 tiles per side * 4 sides)
      positions.add(calculateSquarePosition(i, squareSize, itemSize));
    }
    return positions;
  }
  
  /// Gets the index of the item at a corner
  static List<int> getCornerIndices() {
    // Corners are at indices 0, 4, 10, 14
    return [0, 4, 10, 14];
  }
}