import 'package:flutter/material.dart';

class SquarePositionUtils {
  // Calculate position for an item on outer square (16 tiles)
  static Offset calculateSquarePosition(int index, double squareSize, double itemSize, {double cornerSizeMultiplier = 1.0}) {
    // Calculate the available space
    final availableSpace = squareSize - itemSize;
    
    // Adjust for larger corner tiles - reduce available space proportionally
    final cornerSize = itemSize * cornerSizeMultiplier;
    final insetAmount = cornerSize - itemSize;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 5) {
      // Top row: indices 0-4
      if (index == 0) {
        // Top-left corner
        x = 0;
        y = 0;
      } else if (index == 4) {
        // Top-right corner - account for larger size
        x = availableSpace - insetAmount;
        y = 0;
      } else {
        // Regular top edge tiles
        x = (index / 4) * availableSpace;
        y = 0;
      }
    } else if (index < 9) {
      // Right column: indices 4-8
      if (index == 4) {
        // Top-right corner (already handled)
        x = availableSpace - insetAmount;
        y = 0;
      } else if (index == 8) {
        // Bottom-right corner
        x = availableSpace - insetAmount;
        y = availableSpace - insetAmount;
      } else {
        // Regular right edge tiles
        x = availableSpace;
        y = ((index - 4) / 4) * availableSpace;
      }
    } else if (index < 13) {
      // Bottom row: indices 8-12
      if (index == 8) {
        // Bottom-right corner (already handled)
        x = availableSpace - insetAmount;
        y = availableSpace - insetAmount;
      } else if (index == 12) {
        // Bottom-left corner
        x = 0;
        y = availableSpace - insetAmount;
      } else {
        // Regular bottom edge tiles
        x = availableSpace - ((index - 8) / 4) * availableSpace;
        y = availableSpace;
      }
    } else {
      // Left column: indices 12-15
      if (index == 12) {
        // Bottom-left corner (already handled)
        x = 0;
        y = availableSpace - insetAmount;
      } else if (index == 0) {
        // Top-left corner (handled in first section)
        x = 0;
        y = 0;
      } else {
        // Regular left edge tiles
        x = 0;
        y = availableSpace - ((index - 12) / 4) * availableSpace;
      }
    }
    
    return Offset(x, y);
  }
  
  // Calculate position for an item on inner square (12 tiles)
  static Offset calculateInnerSquarePosition(int index, double squareSize, double itemSize, {double cornerSizeMultiplier = 1.0}) {
    // Calculate the available space
    final availableSpace = squareSize - itemSize;
    
    // Adjust for larger corner tiles
    final cornerSize = itemSize * cornerSizeMultiplier;
    final insetAmount = cornerSize - itemSize;
    
    // Position depends on which segment the index falls into
    double x, y;
    
    if (index < 4) {
      // Top row: indices 0-3
      if (index == 0) {
        // Top-left corner
        x = 0;
        y = 0;
      } else if (index == 3) {
        // Top-right corner
        x = availableSpace - insetAmount;
        y = 0;
      } else {
        // Regular top edge tiles
        x = (index / 3) * availableSpace;
        y = 0;
      }
    } else if (index < 7) {
      // Right column: indices 3-6
      if (index == 3) {
        // Top-right corner (already handled)
        x = availableSpace - insetAmount;
        y = 0;
      } else if (index == 6) {
        // Bottom-right corner
        x = availableSpace - insetAmount;
        y = availableSpace - insetAmount;
      } else {
        // Regular right edge tiles
        x = availableSpace;
        y = ((index - 3) / 3) * availableSpace;
      }
    } else if (index < 10) {
      // Bottom row: indices 6-9
      if (index == 6) {
        // Bottom-right corner (already handled)
        x = availableSpace - insetAmount;
        y = availableSpace - insetAmount;
      } else if (index == 9) {
        // Bottom-left corner
        x = 0;
        y = availableSpace - insetAmount;
      } else {
        // Regular bottom edge tiles
        x = availableSpace - ((index - 6) / 3) * availableSpace;
        y = availableSpace;
      }
    } else {
      // Left column: indices 9-11
      if (index == 9) {
        // Bottom-left corner (already handled)
        x = 0;
        y = availableSpace - insetAmount;
      } else {
        // Regular left edge tiles
        x = 0;
        y = availableSpace - ((index - 9) / 3) * availableSpace;
      }
    }
    
    return Offset(x, y);
  }
}