// lib/widgets/simple_ring.dart - Updated with swipe queuing system
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
  // Store initial touch position for swipe detection
  Offset? _startPosition;
  
  // Swipe detection variables
  bool _startedOnCorner = false;
  DateTime? _swipeStartTime;
  
  // Animation controller
  late RingAnimationController _animationController;
  
  // Swipe queue system
  List<int> _pendingRotations = [];
  bool _isProcessingQueue = false;
  
  // Swipe configuration
  static const double _swipeThreshold = 30.0; // Minimum distance for a swipe
  static const int _maxSwipeTimeMs = 400; // Maximum time for a swipe gesture
  static const double _velocityThreshold = 100.0; // Minimum velocity for swipe detection

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController =
        RingAnimationController(this, transitionRate: widget.transitionRate);

    // Set callback for when animation completes
    _animationController.setOnAnimationComplete(() {
      setState(() {});
      // Process next queued rotation when current animation completes
      _processNextQueuedRotation();
    });

    // Initialize position mappings
    _updatePositionMappings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.animationController.value = 0.01;
      Future.delayed(Duration(milliseconds: 10), () {
        _animationController.animationController.value = 0;
      });
    });
  }

  void _updatePositionMappings() {
    _animationController.updatePositionMappings(
      ringModel: widget.ringModel,
      size: widget.size,
      tileSize: widget.tileSize,
      isInner: widget.isInner,
      margin: widget.margin,
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
      margin: widget.margin,
    );

    // Add a tiny delay before the first animation
    Future.delayed(Duration(milliseconds: 5), () {
      setState(() {
        _animationController.startAnimation();
      });
    });
  }

  /// Add a rotation to the queue and process it
  void _queueRotation(int rotationStep) {
    print("DEBUG: Queueing rotation step: $rotationStep");
    
    _pendingRotations.add(rotationStep);
    print("DEBUG: Queue now has ${_pendingRotations.length} pending rotations");
    
    // Start processing the queue if we're not already doing so
    if (!_isProcessingQueue) {
      _processNextQueuedRotation();
    }
  }

  /// Process the next rotation in the queue
  void _processNextQueuedRotation() {
    if (_pendingRotations.isEmpty || _isProcessingQueue) {
      return;
    }

    // Don't process if animation is still running
    if (_animationController.isAnimating) {
      print("DEBUG: Animation still running, waiting to process next rotation");
      return;
    }

    _isProcessingQueue = true;
    final nextRotation = _pendingRotations.removeAt(0);
    
    print("DEBUG: Processing rotation step: $nextRotation, ${_pendingRotations.length} remaining in queue");
    
    // Apply the rotation
    widget.onRotateSteps(nextRotation);
    
    // The animation completion callback will call this method again for the next item
    _isProcessingQueue = false;
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
        print("DEBUG: Pan started at ${details.localPosition}");

        // Check if starting on a corner or locked position
        bool isOnCorner = _isPositionOnAnyCorner(details.localPosition);
        bool isOnLockedCorner = _isPositionOnLockedCorner(details.localPosition);

        // Don't allow interaction on locked corners
        if (isOnLockedCorner) {
          print("DEBUG: Not starting pan - position is on locked corner");
          return;
        }

        // Store the start position and timing
        setState(() {
          _startPosition = details.localPosition;
          _startedOnCorner = isOnCorner;
          _swipeStartTime = DateTime.now();
        });
      },
      onPanEnd: (details) {
        if (_startPosition == null || _swipeStartTime == null) return;

        final endTime = DateTime.now();
        final swipeDuration = endTime.difference(_swipeStartTime!).inMilliseconds;
        final swipeVector = details.localPosition - _startPosition!;
        final swipeDistance = swipeVector.distance;
        
        print("DEBUG: Pan ended - duration: ${swipeDuration}ms, distance: $swipeDistance");

        // If it was a very quick interaction on a corner with minimal movement, treat as tap
        if (_startedOnCorner && swipeDuration < 200 && swipeDistance < 20.0) {
          print("DEBUG: Treating quick short interaction as corner tap");
          _handleCornerTap(_startPosition!);
        } 
        // Check if this qualifies as a swipe
        else if (swipeDistance >= _swipeThreshold && swipeDuration <= _maxSwipeTimeMs) {
          final velocity = swipeDuration > 0 ? (swipeDistance / swipeDuration) * 1000 : 0.0;
          
          if (velocity >= _velocityThreshold) {
            print("DEBUG: Valid swipe detected - distance: $swipeDistance, velocity: $velocity");
            
            // Determine swipe direction (always 1 step)
            final rotationStep = _getRotationDirectionFromSwipe(_startPosition!, swipeVector);
            
            if (rotationStep != 0) {
              print("DEBUG: Adding rotation step to queue: $rotationStep");
              _queueRotation(rotationStep);
            }
          }
        }

        // Reset state
        setState(() {
          _startPosition = null;
          _startedOnCorner = false;
          _swipeStartTime = null;
        });
      },
      onPanUpdate: (details) {
        // We don't need to do anything during pan update for swipe gestures
        // All the logic happens in onPanEnd
      },
      behavior: HitTestBehavior.deferToChild,
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

  /// Get rotation direction from swipe (always returns -1, 0, or 1)
  int _getRotationDirectionFromSwipe(Offset startPos, Offset swipeVector) {
    final size = widget.size;
    
    // Determine which region the swipe started in
    final region = _determineRegion(startPos, size);
    
    // Get the single rotation direction based on swipe
    return _getRotationDirection(region, swipeVector);
  }

  /// Get rotation direction based on region and swipe vector (always returns -1, 0, or 1)
  int _getRotationDirection(String region, Offset swipeVector) {
    final dx = swipeVector.dx;
    final dy = swipeVector.dy;
    
    // Use the stronger component of the swipe
    final isHorizontalDominant = dx.abs() > dy.abs();
    
    switch (region) {
      case 'top':
        return isHorizontalDominant 
          ? (dx > 0 ? -1 : 1)  // Right = clockwise, Left = counterclockwise
          : 0;
          
      case 'right':
        return !isHorizontalDominant 
          ? (dy > 0 ? -1 : 1)  // Down = clockwise, Up = counterclockwise  
          : 0;
          
      case 'bottom':
        return isHorizontalDominant 
          ? (dx > 0 ? 1 : -1)  // Right = counterclockwise, Left = clockwise
          : 0;
          
      case 'left':
        return !isHorizontalDominant 
          ? (dy > 0 ? 1 : -1)  // Down = counterclockwise, Up = clockwise
          : 0;
          
      case 'topLeft':
        if (dx > 0 && dx.abs() > dy.abs()) return -1; // Right
        if (dy > 0 && dy.abs() > dx.abs()) return 1;  // Down
        return 0;
        
      case 'topRight':
        if (dx < 0 && dx.abs() > dy.abs()) return 1;  // Left
        if (dy > 0 && dy.abs() > dx.abs()) return -1; // Down
        return 0;
        
      case 'bottomRight':
        if (dx < 0 && dx.abs() > dy.abs()) return -1; // Left
        if (dy < 0 && dy.abs() > dx.abs()) return 1;  // Up
        return 0;
        
      case 'bottomLeft':
        if (dx > 0 && dx.abs() > dy.abs()) return 1;  // Right
        if (dy < 0 && dy.abs() > dx.abs()) return -1; // Up
        return 0;
        
      default:
        // Center area - use circular motion logic
        final angle = math.atan2(dy, dx);
        final normalizedAngle = (angle + 2 * math.pi) % (2 * math.pi);
        
        // Determine if motion is generally clockwise or counterclockwise
        return normalizedAngle > math.pi ? 1 : -1;
    }
  }

  /// Handle corner tap
  void _handleCornerTap(Offset tapPosition) {
    // Find which corner was tapped
    int? cornerIndex;
    int? position;

    for (int i = 0; i < widget.ringModel.cornerIndices.length; i++) {
      final pos = widget.ringModel.cornerIndices[i];
      final cornerPos = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              pos, widget.size, widget.tileSize,
              cornerSizeMultiplier: 1.20, margin: widget.margin)
          : SquarePositionUtils.calculateSquarePosition(
              pos, widget.size, widget.tileSize,
              cornerSizeMultiplier: 1.20, margin: widget.margin);

      final tileRect = Rect.fromLTWH(cornerPos.dx, cornerPos.dy,
          widget.tileSize * 1.20, widget.tileSize * 1.20);

      if (tileRect.contains(tapPosition)) {
        cornerIndex = i;
        position = pos;
        break;
      }
    }

    if (cornerIndex != null && position != null) {
      print("DEBUG: Corner tap detected - cornerIndex: $cornerIndex, position: $position");
      widget.onTileTap(cornerIndex, position);
    }
  }

  // Check if a position is on any corner
  bool _isPositionOnAnyCorner(Offset touchPosition) {
    for (int cornerPositionIndex in widget.ringModel.cornerIndices) {
      final sizeMultiplier = 1.20;

      final tilePosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              cornerPositionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier, margin: widget.margin)
          : SquarePositionUtils.calculateSquarePosition(
              cornerPositionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier, margin: widget.margin);

      final actualTileSize = widget.tileSize * sizeMultiplier;
      final tileRect = Rect.fromLTWH(
          tilePosition.dx, tilePosition.dy, actualTileSize, actualTileSize);

      if (tileRect.contains(touchPosition)) {
        print("DEBUG: Position ${touchPosition} is on corner at index $cornerPositionIndex");
        return true;
      }
    }
    return false;
  }

  // Check if the touch position is on a locked corner
  bool _isPositionOnLockedCorner(Offset touchPosition) {
    final lockedPositions = _getLockedPositionsForRing();

    for (int positionIndex in lockedPositions) {
      final isCorner = widget.ringModel.cornerIndices.contains(positionIndex);
      final sizeMultiplier = isCorner ? 1.20 : 1.0;

      final tilePosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier)
          : SquarePositionUtils.calculateSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier);

      final actualTileSize = widget.tileSize * sizeMultiplier;
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
      final lockedPosition = widget.ringModel.cornerIndices[cornerIndex];
      lockedPositions.add(lockedPosition);
    }
    return lockedPositions;
  }

  String _determineRegion(Offset position, double size) {
    final edgeThreshold = size * 0.2; // 20% of the size for edge detection

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

    return 'center';
  }

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
              child: NumberTile(
                number: numberToDisplay,
                color: widget.ringModel.color.withOpacity(currentOpacity),
                isLocked: isLocked,
                isCorner: isCorner,
                onTap: isCorner
                    ? () {
                        print("DEBUG: Corner tile tapped in animation, cornerIndex: $cornerIndex, position: $i");
                        widget.onTileTap(cornerIndex, i);
                      }
                    : null,
                size: widget.tileSize,
                sizeMultiplier: currentSize,
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
          child: NumberTile(
            number: numberToDisplay,
            color: widget.ringModel.color.withOpacity(animInfo.endOpacity),
            isLocked: isLocked,
            isCorner: isCorner,
            onTap: isCorner
                ? () {
                    print("DEBUG: Corner tile tapped static, cornerIndex: $cornerIndex, position: $i");
                    widget.onTileTap(cornerIndex, i);
                  }
                : null,
            size: widget.tileSize,
            sizeMultiplier: animInfo.endSize,
          ),
        );
      }

      tiles.add(tileWidget);
    }

    return tiles;
  }
}