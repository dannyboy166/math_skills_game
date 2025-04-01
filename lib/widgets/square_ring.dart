import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class AnimatedSquareRing extends StatefulWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  final bool isInner; // To differentiate between inner and outer rings
  final double tileSizeFactor; // Add parameter for tile size factor
  final double cornerSizeFactor; // Add parameter for corner size multiplier

  const AnimatedSquareRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
    this.isInner = false,
    this.tileSizeFactor = 0.13, // Default tile size factor
    this.cornerSizeFactor = 1.6, // Default corner multiplier
  }) : super(key: key);

  @override
  State<AnimatedSquareRing> createState() => _AnimatedSquareRingState();
}

class _AnimatedSquareRingState extends State<AnimatedSquareRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  int _rotationDirection = 0;

  // New approach: Each tile is a separate object with its own number
  // This makes it clearer that numbers stay with their tiles
  late List<TileData> _tiles = [];

  // To track where the drag starts
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();

    // Initialize tiles with their fixed numbers
    _initializeTiles();

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
        // When animation completes, update the tile positions
        setState(() {
          _rotateTiles(_rotationDirection);
        });

        // Notify parent of the rotation
        widget.onRotate(widget.ringModel.rotationSteps + _rotationDirection);
        _animationController.reset();
      }
    });
  }

  // Initialize the tiles with their positions and numbers
  void _initializeTiles() {
    final numbers = widget.ringModel.getRotatedNumbers();
    final totalItems = widget.ringModel.itemCount;

    _tiles = List.generate(totalItems, (index) {
      return TileData(
        index: index,
        number: numbers[index],
        isCorner: _isCornerIndex(index),
      );
    });
  }

  // Check if an index is a corner position
  bool _isCornerIndex(int index) {
    return widget.isInner
        ? SquarePositionUtils.isInnerCornerIndex(index)
        : SquarePositionUtils.isCornerIndex(index);
  }

  // Rotate tiles in memory (not visually yet)
  void _rotateTiles(int direction) {
    // direction: -1 for clockwise, 1 for counterclockwise

    // Create a copy of current tiles
    final List<TileData> newTiles = List.from(_tiles);

    // For clockwise rotation, move the last tile to first position
    if (direction < 0) {
      final lastTile = newTiles.removeLast();
      newTiles.insert(0, lastTile.copyWith(index: 0));

      // Update indices for all other tiles
      for (int i = 1; i < newTiles.length; i++) {
        newTiles[i] = newTiles[i].copyWith(index: i);
      }
    }
    // For counterclockwise rotation, move the first tile to last position
    else if (direction > 0) {
      final firstTile = newTiles.removeAt(0);
      newTiles.add(firstTile.copyWith(index: newTiles.length));

      // Update indices for all tiles
      for (int i = 0; i < newTiles.length; i++) {
        newTiles[i] = newTiles[i].copyWith(index: i);
      }
    }

    // Update tile corner status
    for (int i = 0; i < newTiles.length; i++) {
      newTiles[i] = newTiles[i].copyWith(isCorner: _isCornerIndex(i));
    }

    _tiles = newTiles;
  }

  @override
  void didUpdateWidget(AnimatedSquareRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update tiles if the model changed externally
    if (widget.ringModel.rotationSteps != oldWidget.ringModel.rotationSteps) {
      _initializeTiles();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // This method is now public so it can be called from outside
  void startRotationAnimation(bool clockwise) {
    if (_animationController.isAnimating) return;

    // Determine rotation direction
    _rotationDirection = clockwise ? -1 : 1;

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
    // Set tile sizes using the custom factors provided by parameters
    final tileSize = widget.ringModel.squareSize * widget.tileSizeFactor;
    final cornerSize = tileSize * widget.cornerSizeFactor;

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

        startRotationAnimation(isClockwise);
        _dragStartPosition = null;
      },
      // Ensure corners are included in gesture detection
      behavior: HitTestBehavior.translucent,
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
              children:
                  _buildTiles(tileSize, cornerSize, _rotationAnimation.value),
            );
          },
        ),
      ),
    );
  }

  // Build all the tiles with proper animation
  List<Widget> _buildTiles(
      double tileSize, double cornerSize, double animationValue) {
    final List<Widget> tileWidgets = [];
    final totalItems = widget.ringModel.itemCount;
    final cornerIndices = widget.isInner
        ? [0, 3, 6, 9] // Inner ring corner indices
        : [0, 4, 8, 12]; // Outer ring corner indices

    for (var tile in _tiles) {
      // Determine if this tile is at a corner position
      final isCorner = cornerIndices.contains(tile.index);
      final cornerIndex = isCorner ? cornerIndices.indexOf(tile.index) : -1;
      final isSolved = cornerIndex >= 0 && widget.solvedCorners[cornerIndex];

      // Get current position
      final currentPosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              tile.index, widget.ringModel.squareSize, tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              tile.index, widget.ringModel.squareSize, tileSize);

      // For solved corners, don't animate
      if (isSolved) {
        final effectiveTileSize = cornerSize;
        final offsetDiff = (cornerSize - tileSize) / 2;

        tileWidgets.add(
          Positioned(
            left: currentPosition.dx - offsetDiff,
            top: currentPosition.dy - offsetDiff,
            width: effectiveTileSize,
            height: effectiveTileSize,
            child: AbsorbPointer(
              child: NumberTile(
                number: tile.number,
                color: widget.ringModel.itemColor,
                isDisabled: true,
                size: effectiveTileSize,
                onTap: () {},
              ),
            ),
          ),
        );
        continue;
      }

      // For non-solved corners and regular tiles, animate their movement

      // Calculate next position index
      int nextIndex = (_rotationDirection < 0)
          ? (tile.index + 1) % totalItems
          : (tile.index - 1 + totalItems) % totalItems;

      // Skip solved corners when calculating next position
      if (cornerIndices.contains(nextIndex)) {
        final nextCornerIdx = cornerIndices.indexOf(nextIndex);
        if (widget.solvedCorners[nextCornerIdx]) {
          // Skip to the position after the solved corner
          nextIndex = (_rotationDirection < 0)
              ? (nextIndex + 1) % totalItems
              : (nextIndex - 1 + totalItems) % totalItems;
        }
      }

      // Calculate the next position
      final nextPosition = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              nextIndex, widget.ringModel.squareSize, tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              nextIndex, widget.ringModel.squareSize, tileSize);

      // Determine if moving to/from a corner
      final nextIsCorner = cornerIndices.contains(nextIndex);
      final isMovingToCorner = !isCorner && nextIsCorner;
      final isMovingFromCorner = isCorner && !nextIsCorner;

      // Calculate size animation
      double startSize, endSize;

      if (isMovingToCorner) {
        // Growing from regular to corner size
        startSize = tileSize;
        endSize = cornerSize;
      } else if (isMovingFromCorner) {
        // Shrinking from corner to regular size
        startSize = cornerSize;
        endSize = tileSize;
      } else {
        // Maintaining same size
        startSize = endSize = isCorner ? cornerSize : tileSize;
      }

      // Interpolate current size
      final currentSize =
          startSize * (1 - animationValue) + endSize * animationValue;

      // Adjust for position offset for changing sizes
      final startOffset = (startSize - tileSize) / 2;
      final endOffset = (endSize - tileSize) / 2;
      final offsetX =
          startOffset * (1 - animationValue) + endOffset * animationValue;
      final offsetY = offsetX; // Same for square tiles

      // Interpolate between current and next position
      final interpolatedX = currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue;
      final interpolatedY = currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue;

      tileWidgets.add(
        Positioned(
          left: interpolatedX - offsetX,
          top: interpolatedY - offsetY,
          width: currentSize,
          height: currentSize,
          child: AbsorbPointer(
            child: NumberTile(
              number: tile.number,
              color: widget.ringModel.itemColor,
              isDisabled: false,
              size: currentSize,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    return tileWidgets;
  }
}

class TileData {
  final int index; // Position index
  final int number; // The number on the tile
  final bool isCorner; // Whether this tile is at a corner position

  TileData({
    required this.index,
    required this.number,
    required this.isCorner,
  });

  TileData copyWith({int? index, int? number, bool? isCorner}) {
    return TileData(
      index: index ?? this.index,
      number: number ?? this.number,
      isCorner: isCorner ?? this.isCorner,
    );
  }
}

// Enum to represent which side of the ring a drag started on
enum _DragSide {
  top,
  right,
  bottom,
  left,
}
