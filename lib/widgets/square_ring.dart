import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class AnimatedSquareRing extends StatefulWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  final bool isInner; // To differentiate between inner and outer rings

  const AnimatedSquareRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
    this.isInner = false,
  }) : super(key: key);

  @override
  State<AnimatedSquareRing> createState() => _AnimatedSquareRingState();
}

class _AnimatedSquareRingState extends State<AnimatedSquareRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late List<int> _currentNumbers;
  late List<int> _targetNumbers;
  int _rotationDirection = 0;

  // To track where the drag starts
  Offset? _dragStartPosition;
  
  @override
  void initState() {
    super.initState();

    _currentNumbers = List<int>.from(widget.ringModel.getRotatedNumbers());
    _targetNumbers = List<int>.from(_currentNumbers);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Only update numbers AFTER animation is fully complete
        setState(() {
          _currentNumbers = List<int>.from(_targetNumbers);
        });

        // Notify parent of the rotation
        widget.onRotate(widget.ringModel.rotationSteps + _rotationDirection);
        _animationController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedSquareRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update numbers if the model changed externally
    if (widget.ringModel.rotationSteps != oldWidget.ringModel.rotationSteps) {
      _currentNumbers = List<int>.from(widget.ringModel.getRotatedNumbers());
      _targetNumbers = List<int>.from(_currentNumbers);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Start rotation animation with proper number preparation
  void _startRotationAnimation(bool clockwise) {
    if (_animationController.isAnimating) return;

    _rotationDirection = clockwise ? -1 : 1;

    // Prepare the target numbers by rotating the current numbers
    final totalItems = widget.ringModel.itemCount;
    _targetNumbers = List<int>.from(_currentNumbers);

    if (clockwise) {
      // Clockwise rotation - shift numbers right
      final last = _targetNumbers.last;
      _targetNumbers.removeLast();
      _targetNumbers.insert(0, last);
    } else {
      // Counter-clockwise rotation - shift numbers left
      final first = _targetNumbers.first;
      _targetNumbers.removeAt(0);
      _targetNumbers.add(first);
    }

    // Start the animation
    _animationController.forward();
  }

  // Detect which side of the ring the drag started on 
  _DragSide _getDragSide(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    
    // Determine which side of the ring the drag is on
    if (dx.abs() > dy.abs()) {
      // Horizontal sides
      return dx > 0 ? _DragSide.right : _DragSide.left;
    } else {
      // Vertical sides
      return dy > 0 ? _DragSide.bottom : _DragSide.top;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set tile sizes
    final tileSize = widget.ringModel.squareSize * 0.13;
    final cornerSize = tileSize * (widget.isInner ? 1.6 : 1.5);

    return GestureDetector(
      // Track the start position of the drag
      onPanStart: (details) {
        _dragStartPosition = details.localPosition;
      },
      // Handle both vertical and horizontal drags
      onPanEnd: (details) {
        if (_dragStartPosition == null) return;
        
        final size = widget.ringModel.squareSize;
        final dragEndPosition = details.velocity.pixelsPerSecond;
        
        if (dragEndPosition.distance < 50) return; // Ignore very small drags
        
        final dragSide = _getDragSide(_dragStartPosition!, Size(size, size));
        
        // Determine rotation based on gesture direction and the side it started on
        bool isClockwise;
        
        switch (dragSide) {
          case _DragSide.top:
            // Top side: right→clockwise, left→counter-clockwise
            isClockwise = dragEndPosition.dx > 0;
            break;
          case _DragSide.right:
            // Right side: down→clockwise, up→counter-clockwise
            isClockwise = dragEndPosition.dy > 0;
            break;
          case _DragSide.bottom:
            // Bottom side: left→clockwise, right→counter-clockwise
            isClockwise = dragEndPosition.dx < 0;
            break;
          case _DragSide.left:
            // Left side: up→clockwise, down→counter-clockwise
            isClockwise = dragEndPosition.dy < 0;
            break;
        }
        
        _startRotationAnimation(isClockwise);
        _dragStartPosition = null;
      },
      child: Container(
        width: widget.ringModel.squareSize,
        height: widget.ringModel.squareSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: widget.isInner
                  ? _buildInnerRingTiles(
                      tileSize, cornerSize, _rotationAnimation.value)
                  : _buildOuterRingTiles(
                      tileSize, cornerSize, _rotationAnimation.value),
            );
          },
        ),
      ),
    );
  }

  // Build the inner ring tiles with animation
  List<Widget> _buildInnerRingTiles(
      double tileSize, double cornerSize, double animationValue) {
    final totalItems = widget.ringModel.itemCount;
    final List<Widget> tiles = [];

    for (int i = 0; i < totalItems; i++) {
      // Get current position for this index
      final currentPosition = SquarePositionUtils.calculateInnerSquarePosition(
          i, widget.ringModel.squareSize, tileSize);

      // Calculate the next position index based on rotation direction
      final nextIndex = (_rotationDirection < 0)
          ? (i + 1) % totalItems // For clockwise visual movement
          : (i - 1 + totalItems) % totalItems; // For counter-clockwise visual movement

      final nextPosition = SquarePositionUtils.calculateInnerSquarePosition(
          nextIndex, widget.ringModel.squareSize, tileSize);

      // Interpolate between current and next position
      final interpolatedX = currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue;
      final interpolatedY = currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue;

      // Check if this is a corner
      final isCorner = SquarePositionUtils.isInnerCornerIndex(i);
      final cornerIndex = isCorner ? [0, 3, 6, 9].indexOf(i) : -1;
      final isSolved = cornerIndex >= 0 && widget.solvedCorners[cornerIndex];

      // Get the number for this tile (current number during animation)
      final displayNumber = _currentNumbers[i];

      // Adjust for corner size if needed
      final effectiveTileSize = isCorner ? cornerSize : tileSize;
      final offsetDiff = isCorner ? (cornerSize - tileSize) / 2 : 0.0;

      tiles.add(
        Positioned(
          left: interpolatedX - (isCorner ? offsetDiff : 0),
          top: interpolatedY - (isCorner ? offsetDiff : 0),
          width: effectiveTileSize,
          height: effectiveTileSize,
          child: NumberTile(
            number: displayNumber,
            color: widget.ringModel.itemColor,
            isDisabled: isSolved,
            size: effectiveTileSize,
            onTap: () {},
          ),
        ),
      );
    }

    return tiles;
  }

  // Build the outer ring tiles with animation
  List<Widget> _buildOuterRingTiles(
      double tileSize, double cornerSize, double animationValue) {
    final totalItems = widget.ringModel.itemCount;
    final List<Widget> tiles = [];

    for (int i = 0; i < totalItems; i++) {
      // Get current position for this index
      final currentPosition = SquarePositionUtils.calculateSquarePosition(
          i, widget.ringModel.squareSize, tileSize);

      // Calculate the next position index based on rotation direction
      final nextIndex = (_rotationDirection < 0)
          ? (i + 1) % totalItems // For clockwise visual movement
          : (i - 1 + totalItems) % totalItems; // For counter-clockwise visual movement

      final nextPosition = SquarePositionUtils.calculateSquarePosition(
          nextIndex, widget.ringModel.squareSize, tileSize);

      // Interpolate between current and next position
      final interpolatedX = currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue;
      final interpolatedY = currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue;

      // Check if this is a corner
      final isCorner = SquarePositionUtils.isCornerIndex(i);
      final cornerIndex = isCorner ? [0, 4, 8, 12].indexOf(i) : -1;
      final isSolved = cornerIndex >= 0 && widget.solvedCorners[cornerIndex];

      // Get the number for this tile
      final displayNumber = _currentNumbers[i];

      // Adjust for corner size if needed
      final effectiveTileSize = isCorner ? cornerSize : tileSize;
      final offsetDiff = isCorner ? (cornerSize - tileSize) / 2 : 0.0;

      tiles.add(
        Positioned(
          left: interpolatedX - (isCorner ? offsetDiff : 0),
          top: interpolatedY - (isCorner ? offsetDiff : 0),
          width: effectiveTileSize,
          height: effectiveTileSize,
          child: NumberTile(
            number: displayNumber,
            color: widget.ringModel.itemColor,
            isDisabled: isSolved,
            size: effectiveTileSize,
            onTap: () {},
          ),
        ),
      );
    }

    return tiles;
  }
}

// Enum to represent which side of the ring a drag started on
enum _DragSide {
  top,
  right,
  bottom,
  left,
}