import 'package:flutter/material.dart';

class SquarePositionUtils {
  // Calculate position for an item on outer square (16 tiles)
  // Added cornerSizeMultiplier parameter to handle larger corner tiles
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize, {double cornerSizeMultiplier = 1.0}) {
    // Calculate the available space
    final availableSpace = squareSize - itemSize;
    
    // Determine if this is a corner position (0, 4, 8, 12)
    final isCorner = (index == 0 || index == 4 || index == 8 || index == 12);
    
    // Calculate padding to inset the ring from the square boundary
    // This will be larger for corner positions to accommodate their larger size
    double insetPadding = isCorner ? itemSize * (cornerSizeMultiplier - 1.0) : 0.0;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 5) {
      // Top row: indices 0-4
      x = (index / 4) * (availableSpace - insetPadding * 2) + insetPadding;
      y = insetPadding;
    } else if (index < 9) {
      // Right column: indices 4-8
      x = availableSpace - insetPadding;
      y = ((index - 4) / 4) * (availableSpace - insetPadding * 2) + insetPadding;
    } else if (index < 13) {
      // Bottom row: indices 8-12
      x = availableSpace - ((index - 8) / 4) * (availableSpace - insetPadding * 2) - insetPadding;
      y = availableSpace - insetPadding;
    } else {
      // Left column: indices 12-15
      x = insetPadding;
      y = availableSpace - ((index - 12) / 4) * (availableSpace - insetPadding * 2) - insetPadding;
    }
    
    return Offset(x, y);
  }
  
  // Calculate position for an item on inner square (12 tiles)
  // Added cornerSizeMultiplier parameter to handle larger corner tiles
  static Offset calculateInnerSquarePosition(int index, double squareSize, double itemSize, {double cornerSizeMultiplier = 1.0}) {
    // Calculate the available space
    final availableSpace = squareSize - itemSize;
    
    // Determine if this is a corner position (0, 3, 6, 9)
    final isCorner = (index == 0 || index == 3 || index == 6 || index == 9);
    
    // Calculate padding to inset the ring from the square boundary
    // This will be larger for corner positions to accommodate their larger size
    double insetPadding = isCorner ? itemSize * (cornerSizeMultiplier - 1.0) : 0.0;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 4) {
      // Top row: indices 0-3
      x = (index / 3) * (availableSpace - insetPadding * 2) + insetPadding;
      y = insetPadding;
    } else if (index < 7) {
      // Right column: indices 3-6
      x = availableSpace - insetPadding;
      y = ((index - 3) / 3) * (availableSpace - insetPadding * 2) + insetPadding;
    } else if (index < 10) {
      // Bottom row: indices 6-9
      x = availableSpace - ((index - 6) / 3) * (availableSpace - insetPadding * 2) - insetPadding;
      y = availableSpace - insetPadding;
    } else {
      // Left column: indices 9-11
      x = insetPadding;
      y = availableSpace - ((index - 9) / 3) * (availableSpace - insetPadding * 2) - insetPadding;
    }
    
    return Offset(x, y);
  }
}