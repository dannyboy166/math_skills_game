// lib/widgets/animated_square_ring.dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    _currentNumbers = List<int>.from(widget.ringModel.getRotatedNumbers());
    _targetNumbers = List<int>.from(_currentNumbers);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Slightly slowed down
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

  // This is the key method that starts rotation with proper number preparation
  void _startRotationAnimation(bool clockwise) {
    if (_animationController.isAnimating) return;

    // Determine rotation direction - REVERSED from before
    // Now when clockwise is true, _rotationDirection is -1 (clockwise movement)
    // When clockwise is false, _rotationDirection is 1 (counter-clockwise movement)
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

  @override
  Widget build(BuildContext context) {
    // Set tile sizes
    final tileSize = widget.ringModel.squareSize * 0.13;
    final cornerSize = tileSize * (widget.isInner ? 1.6 : 1.5);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! > 0) {
          // Right swipe - rotate clockwise (CHANGED)
          _startRotationAnimation(true);
        } else if (details.primaryVelocity! < 0) {
          // Left swipe - rotate counter-clockwise (CHANGED)
          _startRotationAnimation(false);
        }
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
      // IMPORTANT CHANGE: We're reversing the direction for visual animation compared to number rotation
      final nextIndex = (_rotationDirection < 0) // Note the reversed comparison
          ? (i + 1) % totalItems // For clockwise visual movement
          : (i - 1 + totalItems) %
              totalItems; // For counter-clockwise visual movement

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

  // Build the outer ring tiles with animation (similar approach to inner ring)
  List<Widget> _buildOuterRingTiles(
      double tileSize, double cornerSize, double animationValue) {
    final totalItems = widget.ringModel.itemCount;
    final List<Widget> tiles = [];

    for (int i = 0; i < totalItems; i++) {
      // Get current position for this index
      final currentPosition = SquarePositionUtils.calculateSquarePosition(
          i, widget.ringModel.squareSize, tileSize);

      // Calculate the next position index based on rotation direction
      // IMPORTANT CHANGE: We're reversing the direction for visual animation compared to number rotation
      final nextIndex = (_rotationDirection < 0) // Note the reversed comparison
          ? (i + 1) % totalItems // For clockwise visual movement
          : (i - 1 + totalItems) %
              totalItems; // For counter-clockwise visual movement

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
