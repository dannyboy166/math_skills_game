import 'package:flutter/material.dart';

class SquarePositionUtils {
  // Calculate position for an item on outer square (16 tiles)
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize) {
    // Calculate the available space
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
  
  // Calculate position for an item on inner square (12 tiles)
  static Offset calculateInnerSquarePosition(int index, double squareSize, double itemSize) {
    // Calculate the available space
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
}
