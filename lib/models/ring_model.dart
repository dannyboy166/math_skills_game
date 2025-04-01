import 'package:flutter/material.dart';
import '../widgets/square_ring.dart';

class RingModel {
  // Original numbers list (used for initial setup)
  final List<int> numbers;
  
  // Color of the ring items
  final Color itemColor;
  
  // Size of the square ring
  final double squareSize;
  
  // Number of items in the ring
  final int itemCount;
  
  // Current rotation steps (for tracking model state)
  int rotationSteps;
  
  // Corner indices based on ring type
  late final List<int> cornerIndices;
  
  // Reference to currently locked corner positions
  final Set<int> _lockedPositions = {};
  
  // Map of locked positions to their fixed numbers
  final Map<int, int> _lockedNumbers = {};

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
    RingModel model = RingModel(
      numbers: numbers,
      itemColor: itemColor,
      squareSize: squareSize,
      rotationSteps: rotationSteps ?? this.rotationSteps,
      itemCount: itemCount,
    );
    
    // Copy locked positions and numbers to the new model
    model._lockedPositions.addAll(_lockedPositions);
    model._lockedNumbers.addAll(_lockedNumbers);
    
    return model;
  }
  
  // Mark a position as locked with its current number
  void lockPosition(int position, int number) {
    _lockedPositions.add(position);
    _lockedNumbers[position] = number;
  }
  
  // Check if a position is locked
  bool isPositionLocked(int position) {
    return _lockedPositions.contains(position);
  }
  
  // Get the locked number at a position (if locked)
  int? getLockedNumber(int position) {
    return _lockedNumbers[position];
  }
  
  // Get all locked positions
  Set<int> getLockedPositions() {
    return Set.from(_lockedPositions);
  }
  
  // Clear a locked position
  void clearLock(int position) {
    _lockedPositions.remove(position);
    _lockedNumbers.remove(position);
  }
  
  // Clear all locks
  void clearAllLocks() {
    _lockedPositions.clear();
    _lockedNumbers.clear();
  }
  
  // Convert RingModel to RingTiles (for integration with AnimatedSquareRing)
  List<RingTile> toRingTiles() {
    List<RingTile> tiles = [];
    
    for (int i = 0; i < numbers.length; i++) {
      tiles.add(RingTile(
        number: numbers[i],
        currentPosition: i,
        isCorner: cornerIndices.contains(i),
        isLocked: _lockedPositions.contains(i),
      ));
    }
    
    // Apply current rotation to tile positions
    if (rotationSteps != 0) {
      // Create a copy to avoid modifying during iteration
      List<RingTile> rotatedTiles = List.from(tiles);
      
      for (int i = 0; i < rotationSteps.abs(); i++) {
        _applyRotationStep(rotatedTiles, rotationSteps > 0 ? 1 : -1);
      }
      
      tiles = rotatedTiles;
    }
    
    return tiles;
  }
  
  // Apply a single rotation step to a list of tiles
  void _applyRotationStep(List<RingTile> tiles, int direction) {
    // First identify which positions are locked
    Set<int> lockedPositions = {};
    for (var tile in tiles) {
      if (tile.isLocked) {
        lockedPositions.add(tile.currentPosition);
      }
    }
    
    // For each tile, calculate its new position
    for (var tile in tiles) {
      // Skip tiles that are locked
      if (tile.isLocked) continue;
      
      // Calculate the next position
      int nextPosition;
      if (direction < 0) {
        // Clockwise rotation
        nextPosition = (tile.currentPosition + 1) % itemCount;
      } else {
        // Counterclockwise rotation
        nextPosition = (tile.currentPosition - 1 + itemCount) % itemCount;
      }
      
      // Skip over any locked positions
      while (lockedPositions.contains(nextPosition)) {
        if (direction < 0) {
          nextPosition = (nextPosition + 1) % itemCount;
        } else {
          nextPosition = (nextPosition - 1 + itemCount) % itemCount;
        }
      }
      
      // Update the tile's position
      tile.currentPosition = nextPosition;
      
      // Update corner status
      tile.isCorner = cornerIndices.contains(nextPosition);
    }
  }
  
  // Update the model based on RingTiles (from AnimatedSquareRing)
  void updateFromRingTiles(List<RingTile> tiles) {
    // Clear existing locks
    _lockedPositions.clear();
    _lockedNumbers.clear();
    
    // Update locks based on tiles
    for (var tile in tiles) {
      if (tile.isLocked) {
        _lockedPositions.add(tile.currentPosition);
        _lockedNumbers[tile.currentPosition] = tile.number;
      }
    }
  }
}