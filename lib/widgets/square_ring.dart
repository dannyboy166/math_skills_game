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
  int _previousRotationSteps = 0;
  int _targetRotationSteps = 0;

  @override
  void initState() {
    super.initState();
    _previousRotationSteps = widget.ringModel.rotationSteps;
    _targetRotationSteps = widget.ringModel.rotationSteps;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
        // Animation completed, update the model
        widget.onRotate(_targetRotationSteps);
        _previousRotationSteps = _targetRotationSteps;
        _animationController.reset();
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedSquareRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if rotation steps changed externally
    if (widget.ringModel.rotationSteps != _targetRotationSteps &&
        !_animationController.isAnimating) {
      _previousRotationSteps = _targetRotationSteps;
      _targetRotationSteps = widget.ringModel.rotationSteps;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startRotationAnimation(bool clockwise) {
    if (_animationController.isAnimating) return;

    setState(() {
      _previousRotationSteps = _targetRotationSteps;
      _targetRotationSteps =
          clockwise ? _targetRotationSteps + 1 : _targetRotationSteps - 1;
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Set fixed tile size relative to the ring size
    final tileSize = widget.ringModel.squareSize * 0.13;
    final cornerSize =
        tileSize * (widget.isInner ? 1.6 : 1.5); // Adjust based on ring

    final rotatedNumbers = widget.ringModel.getRotatedNumbers();

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Determine swipe direction and start animation
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! > 0) {
          // Right swipe - rotate counter-clockwise
          _startRotationAnimation(false);
        } else if (details.primaryVelocity! < 0) {
          // Left swipe - rotate clockwise
          _startRotationAnimation(true);
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
                  ? _buildInnerRingTiles(rotatedNumbers, tileSize, cornerSize,
                      _rotationAnimation.value)
                  : _buildOuterRingTiles(rotatedNumbers, tileSize, cornerSize,
                      _rotationAnimation.value),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildInnerRingTiles(List<int> rotatedNumbers, double tileSize,
      double cornerSize, double animationValue) {
    final totalItems = 12; // Total items in inner ring
    final List<Widget> tiles = [];

    // Inner corners (larger tiles)
    final cornerIndices = [0, 3, 6, 9];
    for (final index in cornerIndices) {
      final cornerIndex = cornerIndices.indexOf(index);
      final isSolved = widget.solvedCorners[cornerIndex];

      // Calculate position with animation
      final position = _calculateAnimatedInnerPosition(
          index,
          widget.ringModel.squareSize,
          tileSize,
          _previousRotationSteps,
          _targetRotationSteps,
          animationValue,
          totalItems);

      // Adjust for larger size
      final offsetDiff = (cornerSize - tileSize) / 2;
      final adjustedX = position.dx - offsetDiff;
      final adjustedY = position.dy - offsetDiff;

      tiles.add(
        Positioned(
          left: adjustedX,
          top: adjustedY,
          width: cornerSize,
          height: cornerSize,
          child: NumberTile(
            number: _getAnimatedNumber(
                index, rotatedNumbers, totalItems, animationValue),
            color: widget.ringModel.itemColor,
            isDisabled: isSolved,
            size: cornerSize,
            onTap: () {},
          ),
        ),
      );
    }

    // Regular tiles
    for (int index = 0; index < totalItems; index++) {
      if (cornerIndices.contains(index)) continue; // Skip corners

      // Calculate position with animation
      final position = _calculateAnimatedInnerPosition(
          index,
          widget.ringModel.squareSize,
          tileSize,
          _previousRotationSteps,
          _targetRotationSteps,
          animationValue,
          totalItems);

      tiles.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          width: tileSize,
          height: tileSize,
          child: NumberTile(
            number: _getAnimatedNumber(
                index, rotatedNumbers, totalItems, animationValue),
            color: widget.ringModel.itemColor,
            size: tileSize,
            onTap: () {},
          ),
        ),
      );
    }

    return tiles;
  }

  int _getAnimatedNumber(int index, List<int> rotatedNumbers, int totalItems,
      double animationValue) {
    final effectiveRotation = _previousRotationSteps +
        (animationValue > 0.5 ? 1 : 0) *
            (_targetRotationSteps - _previousRotationSteps);

    // Ensure the index is properly wrapped
    final adjustedIndex = (index - effectiveRotation) % totalItems;
    // Use the positive modulo to handle negative indices
    final normalizedIndex =
        adjustedIndex < 0 ? adjustedIndex + totalItems : adjustedIndex;

    // Ensure we don't access out of bounds
    if (normalizedIndex >= 0 && normalizedIndex < totalItems) {
      return rotatedNumbers[normalizedIndex];
    } else {
      // Fallback in case we somehow still get an invalid index
      return rotatedNumbers[0];
    }
  }

  // Calculate animated position for inner ring tiles
  Offset _calculateAnimatedInnerPosition(
    int index,
    double squareSize,
    double tileSize,
    int previousSteps,
    int targetSteps,
    double animationValue,
    int totalItems,
  ) {
    // Ensure index is within range
    final safeIndex = index % totalItems;

    // Calculate the current position
    final currentPosition = SquarePositionUtils.calculateInnerSquarePosition(
        safeIndex, squareSize, tileSize);

    // Calculate target position based on rotation
    int nextIndex;

    if (targetSteps > previousSteps) {
      // Clockwise movement
      nextIndex = (safeIndex - 1 + totalItems) % totalItems;
    } else {
      // Counter-clockwise movement
      nextIndex = (safeIndex + 1) % totalItems;
    }

    final nextPosition = SquarePositionUtils.calculateInnerSquarePosition(
        nextIndex, squareSize, tileSize);

    // Interpolate between current and next position
    return Offset(
      currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue,
      currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue,
    );
  }

  // Build outer ring tiles
  List<Widget> _buildOuterRingTiles(List<int> rotatedNumbers, double tileSize,
      double cornerSize, double animationValue) {
    final totalItems = 16;
    final List<Widget> tiles = [];

    // Helper function to get current number for index with animation
    int getAnimatedNumber(int index) {
      final effectiveRotation = _previousRotationSteps +
          (animationValue > 0.5 ? 1 : 0) *
              (_targetRotationSteps - _previousRotationSteps);

      final adjustedIndex = (index - effectiveRotation) % totalItems;
      return rotatedNumbers[
          adjustedIndex >= 0 ? adjustedIndex : adjustedIndex + totalItems];
    }

    // Corners (larger tiles)
    final cornerIndices = [0, 4, 8, 12];
    for (final index in cornerIndices) {
      final cornerIndex = cornerIndices.indexOf(index);
      final isSolved = widget.solvedCorners[cornerIndex];

      // Calculate position with animation
      final position = _calculateAnimatedPosition(
          index,
          widget.ringModel.squareSize,
          tileSize,
          _previousRotationSteps,
          _targetRotationSteps,
          animationValue);

      // Adjust for larger size
      final offsetDiff = (cornerSize - tileSize) / 2;
      final adjustedX = position.dx - offsetDiff;
      final adjustedY = position.dy - offsetDiff;

      tiles.add(
        Positioned(
          left: adjustedX,
          top: adjustedY,
          width: cornerSize,
          height: cornerSize,
          child: NumberTile(
            number: getAnimatedNumber(index),
            color: widget.ringModel.itemColor,
            isDisabled: isSolved,
            size: cornerSize,
            onTap: () {},
          ),
        ),
      );
    }

    // Regular tiles
    for (int index = 0; index < totalItems; index++) {
      if (cornerIndices.contains(index)) continue; // Skip corners

      // Calculate position with animation
      final position = _calculateAnimatedPosition(
          index,
          widget.ringModel.squareSize,
          tileSize,
          _previousRotationSteps,
          _targetRotationSteps,
          animationValue);

      tiles.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          width: tileSize,
          height: tileSize,
          child: NumberTile(
            number: getAnimatedNumber(index),
            color: widget.ringModel.itemColor,
            size: tileSize,
            onTap: () {},
          ),
        ),
      );
    }

    return tiles;
  }

  // Calculate animated position for outer ring tiles
  Offset _calculateAnimatedPosition(
    int index,
    double squareSize,
    double tileSize,
    int previousSteps,
    int targetSteps,
    double animationValue,
  ) {
    // Get current position
    final currentPosition = SquarePositionUtils.calculateSquarePosition(
        index, squareSize, tileSize);

    // Calculate target position based on rotation
    int nextIndex;
    final totalItems = 16;

    if (targetSteps > previousSteps) {
      // Clockwise movement
      nextIndex = (index - 1 + totalItems) % totalItems;
    } else {
      // Counter-clockwise movement
      nextIndex = (index + 1) % totalItems;
    }

    final nextPosition = SquarePositionUtils.calculateSquarePosition(
        nextIndex, squareSize, tileSize);

    // Interpolate between current and next position
    return Offset(
      currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue,
      currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue,
    );
  }
}
