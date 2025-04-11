// lib/widgets/simple_ring.dart - updated with animations
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

class _SimpleRingState extends State<SimpleRing>
    with SingleTickerProviderStateMixin {
  // Store initial touch position
  Offset? _startPosition;

  // Animation controller for rotation
  late AnimationController _animationController;

  // Track whether we're currently animating
  bool _isAnimating = false;

  // Track tile positions for animation
  Map<int, Offset> _currentPositions = {};
  Map<int, Offset> _targetPositions = {};
  Map<int, int> _positionToNumber = {};
  Map<int, int> _previousPositionToNumber = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
        _animationController.reset();
      }
    });

    // Initialize position mappings
    _updatePositionMappings();
  }

  void _updatePositionMappings() {
    _positionToNumber.clear();
    _currentPositions.clear();
    _targetPositions.clear();

    final itemCount = widget.ringModel.numbers.length;

    for (int i = 0; i < itemCount; i++) {
      final number = widget.ringModel.getNumberAtPosition(i);
      _positionToNumber[i] = number;

      // Calculate the position for this tile
      final position = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              i, widget.size, widget.tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              i, widget.size, widget.tileSize);

      _targetPositions[i] = position;
      _currentPositions[i] = position;
    }
  }

  @override
  void didUpdateWidget(SimpleRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the ring model has changed
    if (widget.ringModel != oldWidget.ringModel) {
      // Store current positions and numbers before updating
      _previousPositionToNumber = Map.from(_positionToNumber);

      // Update position mappings for new model
      _updatePositionMappings();

      // Animate if not already animating
      if (!_isAnimating) {
        _animateRotation();
      }
    }
  }

  void _animateRotation() {
    // Don't animate if there's no previous data
    if (_previousPositionToNumber.isEmpty) return;

    setState(() {
      _isAnimating = true;

      // For each position in the new model, find where its number was in the old model
      final itemCount = widget.ringModel.numbers.length;
      for (int i = 0; i < itemCount; i++) {
        final currentNumber = _positionToNumber[i];

        // Find this number's previous position
        int? previousPosition;
        for (final entry in _previousPositionToNumber.entries) {
          if (entry.value == currentNumber) {
            previousPosition = entry.key;
            break;
          }
        }

        if (previousPosition != null) {
          // Calculate the old physical position of this number
          final oldPosition = widget.isInner
              ? SquarePositionUtils.calculateInnerSquarePosition(
                  previousPosition, widget.size, widget.tileSize)
              : SquarePositionUtils.calculateSquarePosition(
                  previousPosition, widget.size, widget.tileSize);

          // Set as current position for animation
          _currentPositions[i] = oldPosition;
        }
      }
    });

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        // Don't start a pan if we tapped on a locked corner
        if (_isPositionOnLockedCorner(details.localPosition) || _isAnimating) {
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
        if (_startPosition == null || _isAnimating) return;

        // Get the drag delta
        final dragDelta = details.localPosition - _startPosition!;

        // Determine which direction to rotate based on the start position and drag direction
        int rotationStep = _determineRotationDirection(
            _startPosition!, dragDelta, widget.size);

        if (rotationStep != 0) {
          // Apply the rotation using copyWithRotation
          widget.onRotateSteps(rotationStep);

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

  // Check if the touch position is on a locked corner
  bool _isPositionOnLockedCorner(Offset touchPosition) {
    // Get locked positions for this ring
    final lockedPositions = _getLockedPositionsForRing();

    for (int positionIndex in lockedPositions) {
      // Get the position of this tile
      final tilePosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              positionIndex, widget.size, widget.tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              positionIndex, widget.size, widget.tileSize);

      // Check if the touch is within this tile
      final tileRect = Rect.fromLTWH(
          tilePosition.dx, tilePosition.dy, widget.tileSize, widget.tileSize);

      if (tileRect.contains(touchPosition)) {
        return true;
      }
    }

    return false;
  }

  // Get all locked positions for this ring
  List<int> _getLockedPositionsForRing() {
    List<int> lockedPositions = [];

    for (final equation in widget.lockedEquations) {
      final cornerIndex = equation.cornerIndex;

      // Get the position in this ring that corresponds to this corner
      final lockedPosition = widget.ringModel.cornerIndices[cornerIndex];

      // Check if this is a corner position in this ring
      lockedPositions.add(lockedPosition);
    }

    return lockedPositions;
  }

  int _determineRotationDirection(
      Offset startPos, Offset dragDelta, double size) {
    // Calculate center of the square
    final center = Offset(size / 2, size / 2);

    // Determine which region the initial touch happened in
    final region = _determineRegion(startPos, size);

    // Threshold for drag sensitivity - increased for less sensitivity
    final dragThreshold = 65.0; // Increased from 3 to 15

    // Determine rotation direction based on region and drag direction
    switch (region) {
      case 'top':
        // For top edge: left drag -> clockwise, right drag -> counterclockwise
        return dragDelta.dx < -dragThreshold
            ? 1
            : (dragDelta.dx > dragThreshold ? -1 : 0);

      case 'right':
        // For right edge: up drag -> clockwise, down drag -> counterclockwise
        return dragDelta.dy < -dragThreshold
            ? 1
            : (dragDelta.dy > dragThreshold ? -1 : 0);

      case 'bottom':
        // For bottom edge: right drag -> clockwise, left drag -> counterclockwise
        return dragDelta.dx > dragThreshold
            ? 1
            : (dragDelta.dx < -dragThreshold ? -1 : 0);

      case 'left':
        // For left edge: down drag -> clockwise, up drag -> counterclockwise
        return dragDelta.dy > dragThreshold
            ? 1
            : (dragDelta.dy < -dragThreshold ? -1 : 0);

      case 'topLeft':
        // For top-left corner
        if (dragDelta.dx > dragThreshold) {
          // Moving right -> counterclockwise
          return -1;
        } else if (dragDelta.dx < -dragThreshold) {
          // Moving left -> clockwise
          return 1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> clockwise (reversed)
          return -1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> counterclockwise (reversed)
          return 1;
        }
        return 0;

      case 'topRight':
        // For top-right corner
        if (dragDelta.dx < -dragThreshold) {
          // Moving left -> counterclockwise
          return 1;
        } else if (dragDelta.dx > dragThreshold) {
          // Moving right -> clockwise
          return -1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> counterclockwise
          return -1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> clockwise
          return 1;
        }
        return 0;

      case 'bottomRight':
        // For bottom-right corner
        if (dragDelta.dx < -dragThreshold) {
          // Moving left -> counterclockwise
          return -1;
        } else if (dragDelta.dx > dragThreshold) {
          // Moving right -> clockwise
          return 1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> counterclockwise (reversed)
          return 1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> clockwise (reversed)
          return -1;
        }
        return 0;

      case 'bottomLeft':
        // For bottom-left corner
        if (dragDelta.dx > dragThreshold) {
          // Moving right -> counterclockwise
          return 1;
        } else if (dragDelta.dx < -dragThreshold) {
          // Moving left -> clockwise
          return -1;
        } else if (dragDelta.dy > dragThreshold) {
          // Moving down -> clockwise
          return 1;
        } else if (dragDelta.dy < -dragThreshold) {
          // Moving up -> counterclockwise
          return -1;
        }
        return 0;
      default:
        // Central area - determine based on drag angle relative to center
        final dragAngle = math.atan2(dragDelta.dy, dragDelta.dx);

        // Calculate angle from center to touch position
        final touchAngle =
            math.atan2(startPos.dy - center.dy, startPos.dx - center.dx);

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
    } else if (position.dx > size - edgeThreshold &&
        position.dy < edgeThreshold) {
      return 'topRight';
    } else if (position.dx > size - edgeThreshold &&
        position.dy > size - edgeThreshold) {
      return 'bottomRight';
    } else if (position.dx < edgeThreshold &&
        position.dy > size - edgeThreshold) {
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

  // Updated _buildTiles method to include animations
  List<Widget> _buildTiles() {
    final itemCount = widget.ringModel.numbers.length;
    List<Widget> tiles = [];

    // Get locked positions for this ring
    final lockedPositions = _getLockedPositionsForRing();

    for (int i = 0; i < itemCount; i++) {
      // Is this a corner?
      final cornerIndex = widget.ringModel.cornerIndices.indexOf(i);
      final isCorner = cornerIndex != -1;

      // Is this corner locked?
      final isLocked = lockedPositions.contains(i);

      // Get the number to display
      int numberToDisplay = widget.ringModel.getNumberAtPosition(i);

      // Calculate current position for animation
      Offset startPosition = _currentPositions[i] ?? _targetPositions[i]!;
      Offset endPosition = _targetPositions[i]!;

      // Create animation for this tile
      Widget tileWidget;

      if (_isAnimating && !isLocked) {
        // Animated position for unlocked tiles
        tileWidget = AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Calculate current position based on animation progress
            final currentX = startPosition.dx +
                (_animationController.value *
                    (endPosition.dx - startPosition.dx));
            final currentY = startPosition.dy +
                (_animationController.value *
                    (endPosition.dy - startPosition.dy));

            return Positioned(
              left: currentX,
              top: currentY,
              child: GestureDetector(
                onTap: isCorner ? () => widget.onTileTap(cornerIndex, i) : null,
                child: NumberTile(
                  number: numberToDisplay,
                  color: isCorner
                      ? widget.ringModel.color
                      : widget.ringModel.color.withOpacity(0.7),
                  isLocked: isLocked,
                  size: widget.tileSize,
                ),
              ),
            );
          },
        );
      } else {
        // Static position for locked tiles or when not animating
        tileWidget = Positioned(
          left: endPosition.dx,
          top: endPosition.dy,
          child: GestureDetector(
            onTap: isCorner ? () => widget.onTileTap(cornerIndex, i) : null,
            child: NumberTile(
              number: numberToDisplay,
              color: isCorner
                  ? widget.ringModel.color
                  : widget.ringModel.color.withOpacity(0.7),
              isLocked: isLocked,
              size: widget.tileSize,
            ),
          ),
        );
      }

      tiles.add(tileWidget);
    }

    return tiles;
  }
}
