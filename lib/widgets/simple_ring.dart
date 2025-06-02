// lib/widgets/simple_ring.dart - Unified with swipe/drag toggle
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
  final Function(int, int) onTileTap;
  final double transitionRate;
  final double margin;
  final bool isDragMode; // NEW: Controls whether to use drag or swipe

  const SimpleRing({
    Key? key,
    required this.ringModel,
    required this.size,
    required this.tileSize,
    required this.isInner,
    required this.onRotateSteps,
    required this.lockedEquations,
    required this.onTileTap,
    this.transitionRate = 1.0,
    required this.margin,
    this.isDragMode = false, // NEW: Default to swipe mode
  }) : super(key: key);

  @override
  State<SimpleRing> createState() => _SimpleRingState();
}

class _SimpleRingState extends State<SimpleRing>
    with SingleTickerProviderStateMixin {
  // Common state variables
  Offset? _startPosition;
  bool _startedOnCorner = false;
  DateTime? _startTime;

  // Drag-specific variables
  double _dragDistance = 0.0;

  // Swipe-specific variables
  List<int> _pendingRotations = [];
  bool _isProcessingQueue = false;
  static const int _maxQueueSize = 2;

  // Animation controller
  late RingAnimationController _animationController;

  // Configuration constants
  static const double _swipeThreshold = 30.0;
  static const int _maxSwipeTimeMs = 400;
  static const double _velocityThreshold = 100.0;
  static const double _dragThreshold = 40.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
    _updatePositionMappings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.animationController.value = 0.01;
      Future.delayed(Duration(milliseconds: 10), () {
        _animationController.animationController.value = 0;
      });
    });
  }

  void _initializeAnimationController() {
    _animationController =
        RingAnimationController(this, transitionRate: widget.transitionRate);
    _animationController.setOnAnimationComplete(() {
      setState(() {});
      if (widget.isDragMode) {
        // For drag mode, no queue processing needed
      } else {
        // For swipe mode, process next queued rotation
        _processNextQueuedRotation();
      }
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

    if (widget.transitionRate != oldWidget.transitionRate) {
      _animationController.updateTransitionRate(widget.transitionRate);
    }

    // Clear queue when switching modes
    if (widget.isDragMode != oldWidget.isDragMode) {
      _pendingRotations.clear();
      _isProcessingQueue = false;
    }

    if (widget.ringModel != oldWidget.ringModel) {
      if (!_animationController.isAnimating) {
        _animateRotation();
      }
    }
  }

  void _animateRotation() {
    _animationController.prepareAnimation(
      ringModel: widget.ringModel,
      size: widget.size,
      tileSize: widget.tileSize,
      isInner: widget.isInner,
      margin: widget.margin,
    );

    Future.delayed(Duration(milliseconds: 5), () {
      setState(() {
        _animationController.startAnimation();
      });
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
      onPanStart: _handlePanStart,
      onPanUpdate: widget.isDragMode ? _handleDragUpdate : null,
      onPanEnd: _handlePanEnd,
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

  void _handlePanStart(DragStartDetails details) {
    print(
        "DEBUG: Pan started at ${details.localPosition} (${widget.isDragMode ? 'DRAG' : 'SWIPE'} mode)");

    if (widget.isDragMode && _animationController.isAnimating) {
      print("DEBUG: Not starting pan - animation is active in drag mode");
      return;
    }

    bool isOnCorner = _isPositionOnAnyCorner(details.localPosition);
    bool isOnLockedCorner = _isPositionOnLockedCorner(details.localPosition);

    if (isOnLockedCorner) {
      print("DEBUG: Not starting pan - position is on locked corner");
      return;
    }

    setState(() {
      _startPosition = details.localPosition;
      _startedOnCorner = isOnCorner;
      _startTime = DateTime.now();
      if (widget.isDragMode) {
        _dragDistance = 0.0;
      }
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // DRAG MODE ONLY
    if (_startPosition == null || _animationController.isAnimating) return;

    final dragDelta = details.localPosition - _startPosition!;
    _dragDistance += dragDelta.distance;

    if (_dragDistance > 20.0) {
      int rotationStep =
          _determineRotationDirection(_startPosition!, dragDelta, widget.size);

      if (rotationStep != 0) {
        widget.onRotateSteps(rotationStep);
        setState(() {
          _startPosition =
              details.localPosition; // Reset for continuous dragging
        });
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPosition == null || _startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inMilliseconds;

    if (widget.isDragMode) {
      _handleDragEnd(details, duration);
    } else {
      _handleSwipeEnd(details, duration);
    }

    // Reset state
    setState(() {
      _startPosition = null;
      _startedOnCorner = false;
      _startTime = null;
      if (widget.isDragMode) {
        _dragDistance = 0.0;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details, int duration) {
    // Handle corner taps in drag mode
    if (_startedOnCorner && _dragDistance < 10.0 && duration < 300) {
      print("DEBUG: Treating short drag as corner tap");
      _handleCornerTap(_startPosition!);
    }
  }

  void _handleSwipeEnd(DragEndDetails details, int duration) {
    final swipeVector = details.localPosition - _startPosition!;
    final swipeDistance = swipeVector.distance;

    print(
        "DEBUG: Pan ended - duration: ${duration}ms, distance: $swipeDistance");

    // Handle corner taps in swipe mode
    if (_startedOnCorner && duration < 200 && swipeDistance < 20.0) {
      print("DEBUG: Treating quick short interaction as corner tap");
      _handleCornerTap(_startPosition!);
      return;
    }

    // Handle swipes
    if (swipeDistance >= _swipeThreshold && duration <= _maxSwipeTimeMs) {
      final velocity = duration > 0 ? (swipeDistance / duration) * 1000 : 0.0;

      if (velocity >= _velocityThreshold) {
        print(
            "DEBUG: Valid swipe detected - distance: $swipeDistance, velocity: $velocity");

        final rotationStep =
            _getRotationDirectionFromSwipe(_startPosition!, swipeVector);

        if (rotationStep != 0) {
          print("DEBUG: Adding rotation step to queue: $rotationStep");
          _queueRotation(rotationStep);
        }
      }
    }
  }

  // SWIPE MODE: Queue management
  void _queueRotation(int rotationStep) {
    if (_pendingRotations.length >= _maxQueueSize) {
      print("DEBUG: Queue is full, ignoring new rotation");
      return;
    }

    _pendingRotations.add(rotationStep);
    print("DEBUG: Queue now has ${_pendingRotations.length} pending rotations");

    if (!_isProcessingQueue) {
      _processNextQueuedRotation();
    }
  }

  void _processNextQueuedRotation() {
    if (_pendingRotations.isEmpty ||
        _isProcessingQueue ||
        _animationController.isAnimating) {
      return;
    }

    _isProcessingQueue = true;
    final nextRotation = _pendingRotations.removeAt(0);

    print("DEBUG: Processing rotation step: $nextRotation");
    widget.onRotateSteps(nextRotation);
    _isProcessingQueue = false;
  }

  // SWIPE MODE: Direction calculation
  int _getRotationDirectionFromSwipe(Offset startPos, Offset swipeVector) {
    final region = _determineRegion(startPos, widget.size);
    return _getRotationDirection(region, swipeVector);
  }

// Add these missing corner cases to your _getRotationDirection method in simple_ring.dart
// Updated _getRotationDirection for intuitive swipe behavior
  int _getRotationDirection(String region, Offset swipeVector) {
    final dx = swipeVector.dx;
    final dy = swipeVector.dy;
    final isHorizontalDominant = dx.abs() > dy.abs();

    switch (region) {
      case 'top':
        return isHorizontalDominant ? (dx > 0 ? -1 : 1) : 0;
      case 'right':
        return !isHorizontalDominant ? (dy > 0 ? -1 : 1) : 0;
      case 'bottom':
        return isHorizontalDominant ? (dx > 0 ? 1 : -1) : 0;
      case 'left':
        return !isHorizontalDominant ? (dy > 0 ? 1 : -1) : 0;

      // 🔄 UPDATED: Intuitive corner logic
      case 'topLeft':
        if (dx > 0 && dx.abs() > dy.abs()) return -1; // Right = CLOCKWISE ✅
        if (dy < 0 && dy.abs() > dx.abs()) return -1; // Up = CLOCKWISE ✅
        if (dx < 0 && dx.abs() > dy.abs()) return 1; // Left = ANTI-CLOCKWISE ✅
        if (dy > 0 && dy.abs() > dx.abs()) return 1; // Down = ANTI-CLOCKWISE ✅
        return 0;

      case 'topRight':
        if (dx > 0 && dx.abs() > dy.abs()) return -1; // Right = CLOCKWISE ✅
        if (dy > 0 && dy.abs() > dx.abs()) return -1; // Down = CLOCKWISE ✅
        if (dx < 0 && dx.abs() > dy.abs()) return 1; // Left = ANTI-CLOCKWISE ✅
        if (dy < 0 && dy.abs() > dx.abs()) return 1; // Up = ANTI-CLOCKWISE ✅
        return 0;

      case 'bottomRight':
        if (dx < 0 && dx.abs() > dy.abs()) return -1; // Left = CLOCKWISE ✅
        if (dy < 0 && dy.abs() > dx.abs()) return 1; // Up = CLOCKWISE ✅
        if (dx > 0 && dx.abs() > dy.abs()) return 1; // Right = ANTI-CLOCKWISE ✅
        if (dy > 0 && dy.abs() > dx.abs()) return -1; // Down = CLOCKWISE ✅
        return 0;

      case 'bottomLeft':
        if (dx < 0 && dx.abs() > dy.abs()) return -1; // Left = CLOCKWISE ✅
        if (dy > 0 && dy.abs() > dx.abs()) return 1; // Down = ANTICLOCKWISE ✅
        if (dx > 0 && dx.abs() > dy.abs()) return 1; // Right = ANTI-CLOCKWISE ✅
        if (dy < 0 && dy.abs() > dx.abs()) return -1; // Up = CLOCKWISE ✅
        return 0;

      default:
        final angle = math.atan2(dy, dx);
        final normalizedAngle = (angle + 2 * math.pi) % (2 * math.pi);
        return normalizedAngle > math.pi ? 1 : -1;
    }
  }
// Add these missing corner cases to your _determineRotationDirection method in simple_ring.dart

  int _determineRotationDirection(
      Offset startPos, Offset dragDelta, double size) {
    final region = _determineRegion(startPos, size);

    switch (region) {
      case 'top':
        return dragDelta.dx < -_dragThreshold
            ? 1
            : (dragDelta.dx > _dragThreshold ? -1 : 0);
      case 'right':
        return dragDelta.dy < -_dragThreshold
            ? 1
            : (dragDelta.dy > _dragThreshold ? -1 : 0);
      case 'bottom':
        return dragDelta.dx > _dragThreshold
            ? 1
            : (dragDelta.dx < -_dragThreshold ? -1 : 0);
      case 'left':
        return dragDelta.dy > _dragThreshold
            ? 1
            : (dragDelta.dy < -_dragThreshold ? -1 : 0);

      // 🔥 ADD THESE MISSING CORNER CASES FOR DRAG MODE:
      case 'topLeft':
        if (dragDelta.dx > _dragThreshold) {
          return -1; // Moving right → counterclockwise
        } else if (dragDelta.dx < -_dragThreshold) {
          return 1; // Moving left → clockwise
        } else if (dragDelta.dy < -_dragThreshold) {
          return -1; // Moving up → clockwise (reversed)
        } else if (dragDelta.dy > _dragThreshold) {
          return 1; // Moving down → counterclockwise (reversed)
        }
        return 0;

      case 'topRight':
        if (dragDelta.dx < -_dragThreshold) {
          return 1; // Moving left → counterclockwise
        } else if (dragDelta.dx > _dragThreshold) {
          return -1; // Moving right → clockwise
        } else if (dragDelta.dy > _dragThreshold) {
          return -1; // Moving down → counterclockwise
        } else if (dragDelta.dy < -_dragThreshold) {
          return 1; // Moving up → clockwise
        }
        return 0;

      case 'bottomRight':
        if (dragDelta.dx < -_dragThreshold) {
          return -1; // Moving left → counterclockwise
        } else if (dragDelta.dx > _dragThreshold) {
          return 1; // Moving right → clockwise
        } else if (dragDelta.dy < -_dragThreshold) {
          return 1; // Moving up → counterclockwise (reversed)
        } else if (dragDelta.dy > _dragThreshold) {
          return -1; // Moving down → clockwise (reversed)
        }
        return 0;

      case 'bottomLeft':
        if (dragDelta.dx > _dragThreshold) {
          return 1; // Moving right → counterclockwise
        } else if (dragDelta.dx < -_dragThreshold) {
          return -1; // Moving left → clockwise
        } else if (dragDelta.dy > _dragThreshold) {
          return 1; // Moving down → clockwise
        } else if (dragDelta.dy < -_dragThreshold) {
          return -1; // Moving up → counterclockwise
        }
        return 0;

      default:
        final center = Offset(size / 2, size / 2);
        final dragAngle = math.atan2(dragDelta.dy, dragDelta.dx);
        final touchAngle =
            math.atan2(startPos.dy - center.dy, startPos.dx - center.dx);
        final angleDiff = (dragAngle - touchAngle) % (2 * math.pi);

        if (dragDelta.distance > _dragThreshold) {
          return (angleDiff > 0 && angleDiff < math.pi) ? 1 : -1;
        }
        return 0;
    }
  }

  void _handleCornerTap(Offset tapPosition) {
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
      print(
          "DEBUG: Corner tap detected - cornerIndex: $cornerIndex, position: $position");
      widget.onTileTap(cornerIndex, position);
    }
  }

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
        print(
            "DEBUG: Position ${touchPosition} is on corner at index $cornerPositionIndex");
        return true;
      }
    }
    return false;
  }

  bool _isPositionOnLockedCorner(Offset touchPosition) {
    final lockedPositions = _getLockedPositionsForRing();

    for (int positionIndex in lockedPositions) {
      final isCorner = widget.ringModel.cornerIndices.contains(positionIndex);
      final sizeMultiplier = isCorner ? 1.20 : 1.0;

      final tilePosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier, margin: widget.margin)
          : SquarePositionUtils.calculateSquarePosition(
              positionIndex, widget.size, widget.tileSize,
              cornerSizeMultiplier: sizeMultiplier, margin: widget.margin);

      final actualTileSize = widget.tileSize * sizeMultiplier;
      final tileRect = Rect.fromLTWH(
          tilePosition.dx, tilePosition.dy, actualTileSize, actualTileSize);

      if (tileRect.contains(touchPosition)) {
        return true;
      }
    }
    return false;
  }

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
    final edgeThreshold = size * 0.2;

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

    return 'center';
  }

  List<Widget> _buildTiles() {
    final itemCount = widget.ringModel.numbers.length;
    List<Widget> tiles = [];
    final lockedPositions = _getLockedPositionsForRing();

    for (int i = 0; i < itemCount; i++) {
      final cornerIndex = widget.ringModel.cornerIndices.indexOf(i);
      final isCorner = cornerIndex != -1;
      final isLocked = lockedPositions.contains(i);
      int numberToDisplay = widget.ringModel.getNumberAtPosition(i);

      Widget tileWidget;

      if (_animationController.shouldAnimate() && !isLocked) {
        final animInfo =
            _animationController.getAnimatedTileInfo(i, isCorner, isLocked);

        tileWidget = AnimatedBuilder(
          animation: animInfo.animationController,
          builder: (context, child) {
            final currentPosition = animInfo
                .calculateCurrentPosition(animInfo.animationController.value);
            final currentSize = animInfo
                .calculateCurrentSize(animInfo.animationController.value);
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
                        print(
                            "DEBUG: Corner tile tapped in animation, cornerIndex: $cornerIndex, position: $i");
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
        final animInfo =
            _animationController.getAnimatedTileInfo(i, isCorner, isLocked);

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
                    print(
                        "DEBUG: Corner tile tapped static, cornerIndex: $cornerIndex, position: $i");
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
