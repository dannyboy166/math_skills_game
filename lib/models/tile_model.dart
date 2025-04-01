import 'package:flutter/material.dart';

/// Represents a single tile in the ring with its associated number and properties
class TileModel {
  /// The number displayed on this tile
  final int number;
  
  /// The index position of this tile in the ring (0-15 for outer, 0-11 for inner)
  int positionIndex;
  
  /// Whether this tile is positioned at a corner
  bool isCorner;
  
  /// Whether this corner tile has been solved (only applicable for corner tiles)
  bool isSolved;
  
  /// The color of this tile
  final Color color;
  
  TileModel({
    required this.number,
    required this.positionIndex,
    required this.isCorner,
    this.isSolved = false,
    required this.color,
  });
  
  /// Create a copy of this tile with updated properties
  TileModel copyWith({
    int? number,
    int? positionIndex,
    bool? isCorner,
    bool? isSolved,
    Color? color,
  }) {
    return TileModel(
      number: number ?? this.number,
      positionIndex: positionIndex ?? this.positionIndex,
      isCorner: isCorner ?? this.isCorner,
      isSolved: isSolved ?? this.isSolved,
      color: color ?? this.color,
    );
  }
}