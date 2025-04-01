// lib/widgets/simple_ring.dart
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import '../models/locked_equation.dart';
import '../widgets/number_tile.dart';
import 'dart:math' as math;

class SimpleRing extends StatefulWidget {
  final RingModel ringModel;
  final double size;
  final double tileSize;
  final bool isInner;
  final ValueChanged<int> onRotateSteps;
  final List<LockedEquation> lockedEquations;
  final Function(int, int) onTileTap; // (cornerIndex, position)
  
  const SimpleRing({
    Key? key,
    required this.ringModel,
    required this.size,
    required this.tileSize,
    required this.isInner,
    required this.onRotateSteps,
    required this.lockedEquations,
    required this.onTileTap,
  }) : super(key: key);
  
  @override
  State<SimpleRing> createState() => _SimpleRingState();
}

class _SimpleRingState extends State<SimpleRing> {
  // Store initial touch position
  Offset? _startPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // Don't start a pan if we tapped on a locked corner
        if (_isPositionOnLockedCorner(details.localPosition)) {
          return;
        }
        
        setState(() {
          _startPosition = details.localPosition;
        });
      },
      onPanEnd: (details) {
        if (_startPosition == null) return;
        
        // Reset the start position
        setState(() {
          _startPosition = null;
        });
      },
      onPanUpdate: (details) {
        if (_startPosition == null) return;
        
        // Get the drag delta
        final dragDelta = details.localPosition - _startPosition!;
        
        // Determine which direction to rotate based on the start position and drag direction
        int rotationStep = _determineRotationDirection(
          _startPosition!, 
          dragDelta, 
          widget.size
        );
        
        if (rotationStep != 0) {
          // Calculate the new rotation steps
          final newRotationSteps = widget.ringModel.rotationSteps + rotationStep;
          
          // Check if rotation would impact a locked position
          if (!_wouldRotationAffectLockedCorner(newRotationSteps)) {
            widget.onRotateSteps(newRotationSteps);
          }
          
          // Reset the start position to the current position
          setState(() {
            _startPosition = details.localPosition;
          });
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        color: Colors.transparent,
        child: Stack(
          children: _buildTiles(),
        ),
      ),
    );
  }
  
  // Check if rotation would affect a locked corner
  bool _wouldRotationAffectLockedCorner(int newRotationSteps) {
    // If no equations are locked, we're free to rotate
    if (widget.lockedEquations.isEmpty) return false;
    
    // Check for each locked equation if the affected corners would move
    for (final equation in widget.lockedEquations) {
      // We only care about corners that involve this ring
      final int lockedPosition = widget.isInner 
          ? equation.innerPosition 
          : equation.outerPosition;
      
      // Get corner index for this position
      final cornerIndex = _getCornerIndexForPosition(lockedPosition);
      if (cornerIndex == -1) continue; // Not a corner position in this ring
      
      // If this rotation would move a locked tile, reject the rotation
      final int currentRotatedIndex = _getRotatedIndex(lockedPosition, widget.ringModel.rotationSteps);
      final int newRotatedIndex = _getRotatedIndex(lockedPosition, newRotationSteps);
      
      if (currentRotatedIndex != newRotatedIndex) {
        return true;
      }
    }
    
    return false;
  }
  
  // Get corner index (0-3) for a position if it's a corner, or -1 if not
  int _getCornerIndexForPosition(int position) {
    final cornerIndices = widget.ringModel.cornerIndices;
    for (int i = 0; i < cornerIndices.length; i++) {
      if (cornerIndices[i] == position) {
        return i;
      }
    }
    return -1; // Not a corner
  }
  
  // Helper to calculate rotated index
  int _getRotatedIndex(int position, int rotationSteps) {
    final itemCount = widget.ringModel.numbers.length;
    final actualSteps = rotationSteps % itemCount;
    
    if (actualSteps == 0) return position;
    
    if (actualSteps > 0) {
      // Counterclockwise rotation
      return (position + actualSteps) % itemCount;
    } else {
      // Clockwise rotation
      return (position - (-actualSteps) + itemCount) % itemCount;
    }
  }
  
  // Check if the touch position is on a locked corner
  bool _isPositionOnLockedCorner(Offset position) {
    for (int i = 0; i < widget.ringModel.cornerIndices.length; i++) {
      // Check if this corner is locked
      final cornerIndex = i;
      final hasLockedEquation = widget.lockedEquations.any((eq) => eq.cornerIndex == cornerIndex);
      
      if (hasLockedEquation) {
        // Get the position of this corner tile
        final cornerPosition = widget.ringModel.cornerIndices[i];
        final tilePosition = widget.isInner
            ? SquarePositionUtils.calculateInnerSquarePosition(cornerPosition, widget.size, widget.tileSize)
            : SquarePositionUtils.calculateSquarePosition(cornerPosition, widget.size, widget.tileSize);
        
        // Check if the touch is within this tile
        final tileRect = Rect.fromLTWH(
          tilePosition.dx, 
          tilePosition.dy, 
          widget.tileSize, 
          widget.tileSize
        );
        
        if (tileRect.contains(position)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  int _determineRotationDirection(Offset startPos, Offset dragDelta, double size) {
    // Calculate center of the square
    final center = Offset(size / 2, size / 2);
    
    // Determine which region the initial touch happened in
    final region = _determineRegion(startPos, size);
    
    // Threshold for drag sensitivity - increased for less sensitivity
    final dragThreshold = 15.0; // Increased from 3 to 15
    
    // Determine rotation direction based on region and drag direction
    switch (region) {
      case 'top':
        // For top edge: left drag -> counterclockwise, right drag -> clockwise
        return dragDelta.dx < -dragThreshold ? -1 : (dragDelta.dx > dragThreshold ? 1 : 0);
      
      case 'right':
        // For right edge: up drag -> counterclockwise, down drag -> clockwise
        return dragDelta.dy < -dragThreshold ? -1 : (dragDelta.dy > dragThreshold ? 1 : 0);
      
      case 'bottom':
        // For bottom edge: right drag -> counterclockwise, left drag -> clockwise
        return dragDelta.dx > dragThreshold ? -1 : (dragDelta.dx < -dragThreshold ? 1 : 0);
      
      case 'left':
        // For left edge: down drag -> counterclockwise, up drag -> clockwise
        return dragDelta.dy > dragThreshold ? -1 : (dragDelta.dy < -dragThreshold ? 1 : 0);
      
      case 'topLeft':
        // For top-left corner
        if (dragDelta.dx > dragThreshold) {
          // Moving right -> clockwise
          return 1;
        } else if (dragDelta.dx < -dragThreshold) {
          // Moving left -> counterclockwise
          return -1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> counterclockwise (reversed)
          return 1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> clockwise (reversed)
          return -1;
        }
        return 0;
      
      case 'topRight':
        // For top-right corner
        if (dragDelta.dx < -dragThreshold) {
          // Moving left -> clockwise
          return -1;
        } else if (dragDelta.dx > dragThreshold) {
          // Moving right -> counterclockwise
          return 1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> clockwise
          return 1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> counterclockwise
          return -1;
        }
        return 0;
      
      case 'bottomRight':
        // For bottom-right corner
        if (dragDelta.dx < -dragThreshold) {
          // Moving left -> clockwise
          return 1;
        } else if (dragDelta.dx > dragThreshold) {
          // Moving right -> counterclockwise
          return -1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> clockwise (reversed)
          return -1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> counterclockwise (reversed)
          return 1;
        }
        return 0;
      
      case 'bottomLeft':
        // For bottom-left corner
        if (dragDelta.dx > dragThreshold) {
          // Moving right -> clockwise
          return -1;
        } else if (dragDelta.dx < -dragThreshold) {
          // Moving left -> counterclockwise
          return 1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> counterclockwise
          return -1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> clockwise
          return 1;
        }
        return 0;
      
      default:
        // Central area - determine based on drag angle relative to center
        final dragAngle = math.atan2(
          dragDelta.dy, 
          dragDelta.dx
        );
        
        // Calculate angle from center to touch position
        final touchAngle = math.atan2(
          startPos.dy - center.dy, 
          startPos.dx - center.dx
        );
        
        // Determine if the drag is clockwise or counterclockwise relative to the center
        final angleDiff = (dragAngle - touchAngle) % (2 * math.pi);
        
        // Increased threshold to prevent accidental rotations and make rotation less sensitive
        if (dragDelta.distance > dragThreshold) {
          return (angleDiff > 0 && angleDiff < math.pi) ? 1 : -1;
        }
        return 0;
    }
  }
  
  String _determineRegion(Offset position, double size) {
    final edgeThreshold = size * 0.2; // 20% of the size for the edge detection
    
    // Check corners first
    if (position.dx < edgeThreshold && position.dy < edgeThreshold) {
      return 'topLeft';
    } else if (position.dx > size - edgeThreshold && position.dy < edgeThreshold) {
      return 'topRight';
    } else if (position.dx > size - edgeThreshold && position.dy > size - edgeThreshold) {
      return 'bottomRight';
    } else if (position.dx < edgeThreshold && position.dy > size - edgeThreshold) {
      return 'bottomLeft';
    }
    
    // Then check edges
    if (position.dy < edgeThreshold) {
      return 'top';
    } else if (position.dx > size - edgeThreshold) {
      return 'right';
    } else if (position.dy > size - edgeThreshold) {
      return 'bottom';
    } else if (position.dx < edgeThreshold) {
      return 'left';
    }
    
    // Default to center if not on an edge or corner
    return 'center';
  }
  
  List<Widget> _buildTiles() {
    final itemCount = widget.ringModel.numbers.length;
    List<Widget> tiles = [];
    
    for (int i = 0; i < itemCount; i++) {
      // Get position for this tile
      final offset = widget.isInner 
          ? SquarePositionUtils.calculateInnerSquarePosition(i, widget.size, widget.tileSize)
          : SquarePositionUtils.calculateSquarePosition(i, widget.size, widget.tileSize);
      
      // Get the current number at this position
      final number = widget.ringModel.getNumberAtPosition(i);
      
      // Is this a corner?
      final cornerIndex = _getCornerIndexForPosition(i);
      final isCorner = cornerIndex != -1;
      
      // Is this corner locked?
      final isLocked = isCorner && widget.lockedEquations.any((eq) => eq.cornerIndex == cornerIndex);
      
      // For console debugging
      if (isCorner) {
        print('${widget.isInner ? "Inner" : "Outer"} Ring - Corner $cornerIndex: Position $i, Number $number, Locked: $isLocked');
      }
      
      tiles.add(
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: GestureDetector(
            onTap: isCorner ? () => widget.onTileTap(cornerIndex, i) : null,
            child: NumberTile(
              number: number,
              color: isCorner ? widget.ringModel.color : widget.ringModel.color.withOpacity(0.7),
              isLocked: isLocked,
              size: widget.tileSize,
            ),
          ),
        ),
      );
    }
    
    return tiles;
  }
}