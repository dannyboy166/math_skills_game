import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import '../widgets/board/game_board_controller.dart';
import 'number_tile.dart';

class AnimatedSquareRing extends StatefulWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  final bool isInner;
  final double tileSizeFactor;
  final double cornerSizeFactor;
  final GameBoardController controller; // Added controller reference

  const AnimatedSquareRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
    required this.controller, // Make controller required
    this.isInner = false,
    this.tileSizeFactor = 0.13,
    this.cornerSizeFactor = 1.6,
  }) : super(key: key);

  @override
  State<AnimatedSquareRing> createState() => _AnimatedSquareRingState();
}

class _AnimatedSquareRingState extends State<AnimatedSquareRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  int _rotationDirection = 0;

  // Tile-based model, each RingTile has a fixed number that moves with it
  late List<RingTile> _tiles = [];
  
  // To track where the drag starts
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();

    // Initialize tiles
    _initializeTiles();

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

  // Get the corner indices based on the ring type
  List<int> get _cornerIndices => widget.controller.getCornerIndices(widget.isInner);

  // Initialize all tiles
  void _initializeTiles() {
    // Get the unrotated base numbers
    final baseNumbers = widget.ringModel.numbers;
    final totalItems = widget.ringModel.itemCount;
    
    // Initialize with one tile per position
    _tiles = List.generate(totalItems, (index) {
      return RingTile(
        id: index,  // Unique ID for each tile
        number: baseNumbers[index],  // Fixed number for this tile
        currentPosition: index,  // Start at matching position
        isCorner: _cornerIndices.contains(index),  // Is this a corner position?
      );
    });
    
    // Apply any existing rotation from the model
    if (widget.ringModel.rotationSteps != 0) {
      // Apply each rotation step one by one to match the model's state
      for (int i = 0; i < widget.ringModel.rotationSteps.abs(); i++) {
        _rotateTiles(widget.ringModel.rotationSteps > 0 ? 1 : -1, updateParent: false);
      }
    }
  }

  // Rotate tiles to new positions
  void _rotateTiles(int direction, {bool updateParent = true}) {
    // direction: -1 for clockwise, 1 for counterclockwise
    final totalItems = widget.ringModel.itemCount;
    
    // Create a new tiles list for the updated positions
    List<RingTile> newTiles = List.from(_tiles);
    
    // First identify which positions are locked (correspond to solved corners)
    Set<int> lockedPositions = {};
    for (int i = 0; i < widget.solvedCorners.length; i++) {
      if (widget.solvedCorners[i]) {
        lockedPositions.add(_cornerIndices[i]);
      }
    }
    
    // For each tile, calculate its new position
    for (var tile in newTiles) {
      // Skip tiles that are in locked positions
      if (lockedPositions.contains(tile.currentPosition)) {
        // This tile is locked at its current position - don't move it
        continue;
      }
      
      // Calculate the next position
      int nextPosition;
      if (direction < 0) {
        // Clockwise: position increases
        nextPosition = (tile.currentPosition + 1) % totalItems;
      } else {
        // Counterclockwise: position decreases
        nextPosition = (tile.currentPosition - 1 + totalItems) % totalItems;
      }
      
      // Skip over locked positions
      while (lockedPositions.contains(nextPosition)) {
        if (direction < 0) {
          nextPosition = (nextPosition + 1) % totalItems;
        } else {
          nextPosition = (nextPosition - 1 + totalItems) % totalItems;
        }
      }
      
      // Update the tile's position
      tile.currentPosition = nextPosition;
      
      // Update corner status based on new position
      tile.isCorner = _cornerIndices.contains(nextPosition);
    }
    
    _tiles = newTiles;
  }

  @override
  void didUpdateWidget(AnimatedSquareRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if solved corners state has changed
    bool cornersChanged = false;
    for (int i = 0; i < widget.solvedCorners.length && i < oldWidget.solvedCorners.length; i++) {
      if (widget.solvedCorners[i] != oldWidget.solvedCorners[i]) {
        cornersChanged = true;
        break;
      }
    }
    
    // If the model's rotation has changed externally or corners changed, reinitialize tiles
    if (widget.ringModel.rotationSteps != oldWidget.ringModel.rotationSteps || cornersChanged) {
      _initializeTiles();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Public method for starting rotation
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
    final cornerIndices = _cornerIndices;
    
    // First identify which positions are locked (correspond to solved corners)
    Set<int> lockedPositions = {};
    for (int i = 0; i < widget.solvedCorners.length; i++) {
      if (widget.solvedCorners[i]) {
        lockedPositions.add(cornerIndices[i]);
      }
    }
    
    // First determine which tiles are moving to which positions
    for (var tile in _tiles) {
      // Get current position index
      final currentPosition = tile.currentPosition;
      
      // Check if this position is locked (corresponds to a solved corner)
      final isPositionLocked = lockedPositions.contains(currentPosition);
      
      // Determine if this is a corner position and if it's solved
      final isCornerPosition = cornerIndices.contains(currentPosition);
      final cornerIndex = isCornerPosition ? cornerIndices.indexOf(currentPosition) : -1;
      final isPositionSolved = cornerIndex >= 0 && 
                              cornerIndex < widget.solvedCorners.length && 
                              widget.solvedCorners[cornerIndex];
      
      // Get the current position's coordinates
      final currentPosCoords = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              currentPosition, widget.ringModel.squareSize, tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              currentPosition, widget.ringModel.squareSize, tileSize);
      
      // For locked positions or during no animation, just show the tile at its position
      if (isPositionLocked || animationValue == 0) {
        final effectiveTileSize = isCornerPosition ? cornerSize : tileSize;
        final offsetDiff = (effectiveTileSize - tileSize) / 2;

        tileWidgets.add(
          Positioned(
            left: currentPosCoords.dx - offsetDiff,
            top: currentPosCoords.dy - offsetDiff,
            width: effectiveTileSize,
            height: effectiveTileSize,
            child: AbsorbPointer(
              absorbing: isPositionSolved, // Only absorb if the position is solved
              child: NumberTile(
                number: tile.number,  // The tile's number never changes
                color: widget.ringModel.itemColor,
                isDisabled: isPositionSolved,
                size: effectiveTileSize,
                onTap: () {},
              ),
            ),
          ),
        );
        continue;
      }
      
      // For tiles that are moving (animating), calculate their next position
      int nextPosition;
      if (_rotationDirection < 0) {
        // Clockwise: position increases
        nextPosition = (currentPosition + 1) % totalItems;
        
        // Skip over locked positions
        while (lockedPositions.contains(nextPosition)) {
          nextPosition = (nextPosition + 1) % totalItems;
        }
      } else {
        // Counterclockwise: position decreases
        nextPosition = (currentPosition - 1 + totalItems) % totalItems;
        
        // Skip over locked positions
        while (lockedPositions.contains(nextPosition)) {
          nextPosition = (nextPosition - 1 + totalItems) % totalItems;
        }
      }
      
      // Calculate next position coordinates
      final nextPosCoords = widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              nextPosition, widget.ringModel.squareSize, tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              nextPosition, widget.ringModel.squareSize, tileSize);
      
      // Determine current/next position corner status for size changes
      final currentIsCorner = cornerIndices.contains(currentPosition);
      final nextIsCorner = cornerIndices.contains(nextPosition);
      
      // Calculate size animation
      double startSize, endSize;

      if (!currentIsCorner && nextIsCorner) {
        // Growing from regular to corner size
        startSize = tileSize;
        endSize = cornerSize;
      } else if (currentIsCorner && !nextIsCorner) {
        // Shrinking from corner to regular size
        startSize = cornerSize;
        endSize = tileSize;
      } else {
        // Maintaining same size
        startSize = endSize = currentIsCorner ? cornerSize : tileSize;
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
      final interpolatedX = currentPosCoords.dx * (1 - animationValue) +
          nextPosCoords.dx * animationValue;
      final interpolatedY = currentPosCoords.dy * (1 - animationValue) +
          nextPosCoords.dy * animationValue;

      tileWidgets.add(
        Positioned(
          left: interpolatedX - offsetX,
          top: interpolatedY - offsetY,
          width: currentSize,
          height: currentSize,
          child: AbsorbPointer(
            child: NumberTile(
              number: tile.number,  // Always use the tile's fixed number
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

// Represents an actual tile that moves between positions
class RingTile {
  final int id;          // Unique identifier for this tile
  final int number;      // The number displayed on this tile (never changes)
  int currentPosition;   // Current position index of this tile (changes with rotation)
  bool isCorner;         // Whether this tile is currently at a corner position
  
  RingTile({
    required this.id,
    required this.number,
    required this.currentPosition,
    required this.isCorner,
  });
}

// Enum to represent which side of the ring a drag started on
enum _DragSide {
  top,
  right,
  bottom,
  left,
}