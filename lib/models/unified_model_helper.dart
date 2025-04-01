import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../models/tile_model.dart';
import '../widgets/square_ring.dart';

/// Helper class to integrate the existing system with our unified number-tile mechanism
class UnifiedModelHelper {
  /// Convert a list of RingTiles to TileModels
  static List<TileModel> convertRingTilesToTileModels(
      List<RingTile> ringTiles, Color color) {
    return ringTiles.map((ringTile) {
      return TileModel(
        number: ringTile.number,
        positionIndex: ringTile.currentPosition,
        isCorner: ringTile.isCorner,
        isSolved: ringTile.isLocked,
        color: color,
        originalIndex: ringTiles.indexOf(ringTile), // Store original index
      );
    }).toList();
  }

  /// Convert TileModels back to RingTiles
  static List<RingTile> convertTileModelsToRingTiles(
      List<TileModel> tileModels) {
    return tileModels.map((tileModel) {
      return RingTile(
        number: tileModel.number,
        currentPosition: tileModel.positionIndex,
        isCorner: tileModel.isCorner,
        isLocked: tileModel.isSolved,
      );
    }).toList();
  }

  /// Sync the RingModel with the current state of RingTiles
  static void syncRingModelWithTiles(RingModel model, List<RingTile> tiles) {
    // Clear existing locks in the model
    model.clearAllLocks();
    
    // Add locks for any locked tiles
    for (var tile in tiles) {
      if (tile.isLocked) {
        model.lockPosition(tile.currentPosition, tile.number);
      }
    }
  }
  
  /// Find the RingTile at a specific corner position
  static RingTile? findTileAtCorner(List<RingTile> tiles, List<int> cornerIndices, int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= cornerIndices.length) {
      return null;
    }
    
    final cornerPosition = cornerIndices[cornerIndex];
    
    for (var tile in tiles) {
      if (tile.currentPosition == cornerPosition) {
        return tile;
      }
    }
    
    return null;
  }
  
  /// Lock a corner in both the RingModel and the RingTiles
  static void lockCorner(RingModel model, List<RingTile> tiles, int cornerIndex) {
    if (cornerIndex < 0 || cornerIndex >= model.cornerIndices.length) {
      return;
    }
    
    final cornerPosition = model.cornerIndices[cornerIndex];
    
    // Find the tile at this corner position
    RingTile? tileAtCorner;
    for (var tile in tiles) {
      if (tile.currentPosition == cornerPosition) {
        tileAtCorner = tile;
        break;
      }
    }
    
    if (tileAtCorner != null) {
      // Lock in both the tile and the model
      tileAtCorner.isLocked = true;
      model.lockPosition(cornerPosition, tileAtCorner.number);
    }
  }
  
  /// Check if all the required modifications have been applied
  static bool checkForUnifiedSystem(RingModel model, List<RingTile>? tiles) {
    // Check if RingModel has the new locking methods
    bool hasLockingMethods = true;
    try {
      model.lockPosition(0, 0);
      model.clearLock(0);
    } catch (e) {
      hasLockingMethods = false;
    }
    
    // Check if tiles use the unified representation
    bool usesUnifiedTiles = tiles != null && tiles.isNotEmpty;
    
    return hasLockingMethods && usesUnifiedTiles;
  }
}