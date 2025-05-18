// lib/widgets/simple_ring.dart - refactored with separate animation controller
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import '../models/locked_equation.dart';
import '../widgets/number_tile.dart';
import '../controllers/ring_animation_controller.dart';
import 'dart:math' as math;

class SimpleRing extends StatefulWidget {
  final RingModel ringModel;
  final double size;
  final double tileSize;
  final bool isInner;
  final ValueChanged<int> onRotateSteps;
  final List<LockedEquation> lockedEquations;
  final Function(int, int) onTileTap; // (cornerIndex, position)
  final double transitionRate; // Control how quickly transitions happen
  final double margin;

  const SimpleRing({
    Key? key,
    required this.ringModel,
    required this.size,
    required this.tileSize,
    required this.isInner,
    required this.onRotateSteps,
    required this.lockedEquations,
    required this.onTileTap,
    this.transitionRate = 1.0, // Default to 1.0 (normal speed)
    required this.margin,
  }) : super(key: key);

  @override
  State<SimpleRing> createState() => _SimpleRingState();
}

class _SimpleRingState extends State<SimpleRing>
    with SingleTickerProviderStateMixin {
  // Store initial touch position
  Offset? _startPosition;

  // Animation controller
  late RingAnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController =
        RingAnimationController(this, transitionRate: widget.transitionRate);

    // Set callback for when animation completes
    _animationController.setOnAnimationComplete(() {
      setState(() {});
    });

    // Initialize position mappings
    _updatePositionMappings();
  }

  void _updatePositionMappings() {
    _animationController.updatePositionMappings(
      ringModel: widget.ringModel,
      size: widget.size,
      tileSize: widget.tileSize,
      isInner: widget.isInner,
      margin: widget.margin, // 👈 Add this
    );
  }

  @override
  void didUpdateWidget(SimpleRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update transition rate if it changed
    if (widget.transitionRate != oldWidget.transitionRate) {
      _animationController.updateTransitionRate(widget.transitionRate);
    }

    // Check if the ring model has changed
    if (widget.ringModel != oldWidget.ringModel) {
      // Prepare and start animation
      if (!_animationController.isAnimating) {
        _animateRotation();
      }
    }
  }

  void _animateRotation() {
    // Prepare the animation
    _animationController.prepareAnimation(
      ringModel: widget.ringModel,
      size: widget.size,
      tileSize: widget.tileSize,
      isInner: widget.isInner,
      margin: widget.margin, // 👈 Add this
    );

    // Start the animation
    setState(() {
      _animationController.startAnimation();
    });
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
        if (_isPositionOnLockedCorner(details.localPosition) ||
            _animationController.isAnimating) {
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
        if (_startPosition == null || _animationController.isAnimating) return;

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
      // Is this a corner?
      final isCorner = widget.ringModel.cornerIndices.contains(positionIndex);

      // Get the size multiplier for this position
      final sizeMultiplier = isCorner ? 1.20 : 1.0;

      // Get the position of this tile
      final tilePosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier)
          : SquarePositionUtils.calculateSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier);

      // Calculate the actual size of this tile
      final actualTileSize = widget.tileSize * sizeMultiplier;

      // Check if the touch is within this tile
      final tileRect = Rect.fromLTWH(
          tilePosition.dx, tilePosition.dy, actualTileSize, actualTileSize);

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
    final dragThreshold = 40.0; // Increased from 3 to 15

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

  // Updated _buildTiles method using the animation controller
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

      // Create animation for this tile
      Widget tileWidget;

      if (_animationController.shouldAnimate() && !isLocked) {
        // Get animation info for this tile
        final animInfo =
            _animationController.getAnimatedTileInfo(i, isCorner, isLocked);

        // Animated position and size for unlocked tiles
        tileWidget = AnimatedBuilder(
          animation: animInfo.animationController,
          builder: (context, child) {
            // Get the current position based on animation progress
            final currentPosition = animInfo
                .calculateCurrentPosition(animInfo.animationController.value);

            // Get the current size
            final currentSize = animInfo
                .calculateCurrentSize(animInfo.animationController.value);

            // Get the current opacity
            final currentOpacity = animInfo
                .calculateCurrentOpacity(animInfo.animationController.value);

            return Positioned(
              left: currentPosition.dx,
              top: currentPosition.dy,
              child: GestureDetector(
                onTap: isCorner ? () => widget.onTileTap(cornerIndex, i) : null,
                child: NumberTile(
                  number: numberToDisplay,
                  color: widget.ringModel.color.withOpacity(currentOpacity),
                  isLocked: isLocked,
                  isCorner: isCorner,
                  size: widget.tileSize,
                  sizeMultiplier: currentSize,
                ),
              ),
            );
          },
        );
      } else {
        // Get static position and appearance for this tile
        final animInfo =
            _animationController.getAnimatedTileInfo(i, isCorner, isLocked);

        // Static position for locked tiles or when not animating
        tileWidget = Positioned(
          left: animInfo.endPosition.dx,
          top: animInfo.endPosition.dy,
          child: GestureDetector(
            onTap: isCorner ? () => widget.onTileTap(cornerIndex, i) : null,
            child: NumberTile(
              number: numberToDisplay,
              color: widget.ringModel.color.withOpacity(animInfo.endOpacity),
              isLocked: isLocked,
              isCorner: isCorner,
              size: widget.tileSize,
              sizeMultiplier: animInfo.endSize,
            ),
          ),
        );
      }

      tiles.add(tileWidget);
    }

    return tiles;
  }
}
