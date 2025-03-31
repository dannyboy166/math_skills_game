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

  // This method is now public so it can be called from outside
  void startRotationAnimation(bool clockwise) {
    if (_animationController.isAnimating) return;

    // Determine rotation direction
    _rotationDirection = clockwise ? -1 : 1;

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

  // Calculate the next position with solved corner skipping
  Offset _calculateNextPositionWithCornerSkipping(int currentIndex, bool isInner, double tileSize) {
    final totalItems = widget.ringModel.itemCount;
    final cornerIndices = isInner 
        ? [0, 3, 6, 9]  // Inner ring corners
        : [0, 4, 8, 12]; // Outer ring corners
    
    // Start with the simple next index calculation
    int nextIndex = (_rotationDirection < 0)
        ? (currentIndex + 1) % totalItems
        : (currentIndex - 1 + totalItems) % totalItems;
    
    // Check if the next index is a solved corner, and if so, skip it
    final nextCornerIndex = cornerIndices.indexOf(nextIndex);
    if (nextCornerIndex != -1 && widget.solvedCorners[nextCornerIndex]) {
      // Skip the corner by going one more step in the same direction
      nextIndex = (_rotationDirection < 0)
          ? (nextIndex + 1) % totalItems
          : (nextIndex - 1 + totalItems) % totalItems;
    }
    
    // Calculate the position for this adjusted next index
    final nextPosition = isInner
        ? SquarePositionUtils.calculateInnerSquarePosition(
            nextIndex, widget.ringModel.squareSize, tileSize)
        : SquarePositionUtils.calculateSquarePosition(
            nextIndex, widget.ringModel.squareSize, tileSize);
            
    return nextPosition;
  }

  // Build the inner ring tiles with animation
  List<Widget> _buildInnerRingTiles(
      double tileSize, double cornerSize, double animationValue) {
    final totalItems = widget.ringModel.itemCount;
    final List<Widget> tiles = [];
    final cornerIndices = [0, 3, 6, 9]; // Inner ring corner indices

    for (int i = 0; i < totalItems; i++) {
      // Check if this is a corner
      final isCorner = cornerIndices.contains(i);
      final cornerIndex = isCorner ? cornerIndices.indexOf(i) : -1;
      final isSolved = cornerIndex >= 0 && widget.solvedCorners[cornerIndex];
      
      // Get current position for this index
      final currentPosition = SquarePositionUtils.calculateInnerSquarePosition(
          i, widget.ringModel.squareSize, tileSize);

      // For solved corners, don't animate position
      if (isSolved) {
        // Get the number for this tile
        final displayNumber = _currentNumbers[i];
        
        // Adjust for corner size
        final effectiveTileSize = cornerSize;
        final offsetDiff = (cornerSize - tileSize) / 2;

        tiles.add(
          Positioned(
            left: currentPosition.dx - offsetDiff,
            top: currentPosition.dy - offsetDiff,
            width: effectiveTileSize,
            height: effectiveTileSize,
            child: AbsorbPointer(
              child: NumberTile(
                number: displayNumber,
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

      // For non-solved corners and regular tiles, handle animation

      // Calculate the next position index for animation
      // Get the next position, skipping solved corners if needed
      final nextPosition = _calculateNextPositionWithCornerSkipping(i, true, tileSize);

      // Interpolate between current and next position
      final interpolatedX = currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue;
      final interpolatedY = currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue;

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
          child: AbsorbPointer(
            child: NumberTile(
              number: displayNumber,
              color: widget.ringModel.itemColor,
              isDisabled: isSolved,
              size: effectiveTileSize,
              onTap: () {},
            ),
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
    final cornerIndices = [0, 4, 8, 12]; // Outer ring corner indices

    for (int i = 0; i < totalItems; i++) {
      // Check if this is a corner
      final isCorner = cornerIndices.contains(i);
      final cornerIndex = isCorner ? cornerIndices.indexOf(i) : -1;
      final isSolved = cornerIndex >= 0 && widget.solvedCorners[cornerIndex];
      
      // Get current position for this index
      final currentPosition = SquarePositionUtils.calculateSquarePosition(
          i, widget.ringModel.squareSize, tileSize);

      // For solved corners, don't animate position
      if (isSolved) {
        // Get the number for this tile
        final displayNumber = _currentNumbers[i];
        
        // Adjust for corner size
        final effectiveTileSize = cornerSize;
        final offsetDiff = (cornerSize - tileSize) / 2;

        tiles.add(
          Positioned(
            left: currentPosition.dx - offsetDiff,
            top: currentPosition.dy - offsetDiff,
            width: effectiveTileSize,
            height: effectiveTileSize,
            child: AbsorbPointer(
              child: NumberTile(
                number: displayNumber,
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

      // For non-solved corners and regular tiles, handle animation

      // Get the next position, skipping solved corners if needed
      final nextPosition = _calculateNextPositionWithCornerSkipping(i, false, tileSize);

      // Interpolate between current and next position
      final interpolatedX = currentPosition.dx * (1 - animationValue) +
          nextPosition.dx * animationValue;
      final interpolatedY = currentPosition.dy * (1 - animationValue) +
          nextPosition.dy * animationValue;

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
          child: AbsorbPointer(
            child: NumberTile(
              number: displayNumber,
              color: widget.ringModel.itemColor,
              isDisabled: isSolved,
              size: effectiveTileSize,
              onTap: () {},
            ),
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