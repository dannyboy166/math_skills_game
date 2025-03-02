import 'dart:math';
import 'package:flutter/material.dart';

/// Calculates positions for items arranged in a square with 5 items per side
/// but corners are shared between sides for a total of 16 tiles
class SquarePositionUtils {
  /// Calculate position for an item on a square layout
  /// [index] - The item's index (0-15)
  /// [squareSize] - Size of the square
  /// [itemSize] - Size of the item (width/height)
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize) {
    // Each side has 5 positions (0-4), but corners are shared
    // So the indices are:
    // Top row: 0, 1, 2, 3, 4
    // Right column: 4, 5, 6, 7, 8
    // Bottom row (right to left): 8, 9, 10, 11, 12 
    // Left column (bottom to top): 12, 13, 14, 15, 0
    
    // The physical mapping of indices is:
    // [0]  [1]  [2]  [3]  [4]
    // [15]           [5]
    // [14]           [6]
    // [13]           [7]
    // [12] [11] [10] [9]  [8]
    
    // Calculate the available space (full path along each side)
    final availableSpace = squareSize - itemSize;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 5) {
      // Top row: indices 0-4
      x = (index / 4) * availableSpace;
      y = 0;
    } else if (index < 9) {
      // Right column: indices 4-8
      x = availableSpace;
      y = ((index - 4) / 4) * availableSpace;
    } else if (index < 13) {
      // Bottom row: indices 8-12
      x = availableSpace - ((index - 8) / 4) * availableSpace;
      y = availableSpace;
    } else {
      // Left column: indices 12-15
      x = 0;
      y = availableSpace - ((index - 12) / 4) * availableSpace;
    }
    
    return Offset(x, y);
  }
  
  /// Calculate position for an item on the inner square layout (12 items)
  /// [index] - The item's index (0-11)
  /// [squareSize] - Size of the square
  /// [itemSize] - Size of the item (width/height)
  static Offset calculateInnerSquarePosition(int index, double squareSize, double itemSize) {
    // For inner ring with 12 items, we have 3 items per side (excluding corners)
    // Inner ring indices:
    // Top row: 0, 1, 2, 3
    // Right column: 3, 4, 5, 6
    // Bottom row (right to left): 6, 7, 8, 9
    // Left column (bottom to top): 9, 10, 11, 0
    
    // The physical mapping of indices is:
    // [0]  [1]  [2]  [3]
    // [11]         [4]
    // [10]         [5]
    // [9]  [8]  [7]  [6]
    
    // Calculate the available space (full path along each side)
    final availableSpace = squareSize - itemSize;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 4) {
      // Top row: indices 0-3
      x = (index / 3) * availableSpace;
      y = 0;
    } else if (index < 7) {
      // Right column: indices 3-6
      x = availableSpace;
      y = ((index - 3) / 3) * availableSpace;
    } else if (index < 10) {
      // Bottom row: indices 6-9
      x = availableSpace - ((index - 6) / 3) * availableSpace;
      y = availableSpace;
    } else {
      // Left column: indices 9-11
      x = 0;
      y = availableSpace - ((index - 9) / 3) * availableSpace;
    }
    
    return Offset(x, y);
  }
  
  /// Gets all positions for items in a square
  static List<Offset> getSquarePositions(double squareSize, double itemSize) {
    List<Offset> positions = [];
    for (int i = 0; i < 16; i++) {
      positions.add(calculateSquarePosition(i, squareSize, itemSize));
    }
    return positions;
  }
  
  /// Gets the index of the items at corners
  static List<int> getCornerIndices() {
    // Corners are at indices 0, 4, 8, 12
    return [0, 4, 8, 12];
  }
  
  /// Determines if an index is a corner
  static bool isCornerIndex(int index) {
    // Corners are at indices 0, 4, 8, 12
    return [0, 4, 8, 12].contains(index);
  }

  /// Gets the index of the items at corners for inner ring
  static List<int> getInnerCornerIndices() {
    // Corners are at indices 0, 3, 6, 9 for the inner ring
    return [0, 3, 6, 9];
  }
  
  /// Determines if an index is a corner for inner ring
  static bool isInnerCornerIndex(int index) {
    // Corners are at indices 0, 3, 6, 9 for the inner ring
    return [0, 3, 6, 9].contains(index);
  }
}