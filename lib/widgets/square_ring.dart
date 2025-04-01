import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

// Class to represent a tile with its fixed number and current position
class RingTile {
  final int number;
  int currentPosition;
  bool isCorner;
  bool isLocked;
  
  RingTile({
    required this.number,
    required this.currentPosition,
    this.isCorner = false,
    this.isLocked = false,
  });
  
  // Clone this tile
  RingTile clone() {
    return RingTile(
      number: number,
      currentPosition: currentPosition,
      isCorner: isCorner,
      isLocked: isLocked,
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

// Callback type for tile initialization
typedef OnTilesInitialized = void Function(List<RingTile> tiles);

class AnimatedSquareRing extends StatefulWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  final bool isInner;
  final double tileSizeFactor;
  final double cornerSizeFactor;
  final OnTilesInitialized? onTilesInitialized;

  const AnimatedSquareRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
    this.isInner = false,
    this.tileSizeFactor = 0.13,
    this.cornerSizeFactor = 1.6,
    this.onTilesInitialized,
  }) : super(key: key);

  @override
  AnimatedSquareRingState createState() => AnimatedSquareRingState();
}

class AnimatedSquareRingState extends State<AnimatedSquareRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  int _rotationDirection = 0;
  
  // List of tiles with their fixed numbers and current positions
  late List<RingTile> _tiles;
  
  // To track where the drag starts
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    
    // Initialize tiles with fixed numbers
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
        // When animation completes, update the actual tile positions
        setState(() {
          _rotateTiles(_rotationDirection);
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
    
    // If rotation steps changed externally, update our tiles
    if (widget.ringModel.rotationSteps != oldWidget.ringModel.rotationSteps) {
      _syncTilesToModel();
    }
    
    // If solvedCorners changed, update our locked state
    if (widget.solvedCorners != oldWidget.solvedCorners) {
      _updateLockedTiles();
    }
  }
  
  // Initialize tiles with their fixed numbers
  void _initializeTiles() {
    final cornerIndices = _getCornerIndices();
    final itemCount = widget.ringModel.numbers.length;
    
    _tiles = List.generate(itemCount, (index) {
      // Each tile has a fixed number and position
      return RingTile(
        number: widget.ringModel.numbers[index],
        currentPosition: index,
        isCorner: cornerIndices.contains(index),
        isLocked: false,
      );
    });
    
    // Apply any existing rotation from the model
    _syncTilesToModel();
    
    // Update locked status
    _updateLockedTiles();
    
    // Notify parent about our tiles (for controller to reference)
    if (widget.onTilesInitialized != null) {
      widget.onTilesInitialized!(_tiles);
    }
  }
  
  // Get the current tiles
  List<RingTile> getTiles() {
    return List.from(_tiles);
  }
  
  // Sync tile positions with the model's rotation state
  void _syncTilesToModel() {
    final rotationSteps = widget.ringModel.rotationSteps;
    if (rotationSteps == 0) return;
    
    // Reset tiles to their initial positions
    for (int i = 0; i < _tiles.length; i++) {
      _tiles[i].currentPosition = i;
    }
    
    // Apply each rotation step
    for (int i = 0; i < rotationSteps.abs(); i++) {
      _rotateTiles(rotationSteps > 0 ? 1 : -1, updateModel: false);
    }
  }
  
  // Update which tiles are locked based on solvedCorners
  void _updateLockedTiles() {
    final cornerIndices = _getCornerIndices();
    
    // First, reset all locked states
    for (var tile in _tiles) {
      tile.isLocked = false;
    }
    
    // Then, set locked state for tiles at solved corner positions
    for (int i = 0; i < cornerIndices.length && i < widget.solvedCorners.length; i++) {
      if (widget.solvedCorners[i]) {
        // Find the tile currently at this corner position
        for (var tile in _tiles) {
          if (tile.currentPosition == cornerIndices[i]) {
            tile.isLocked = true;
            break;
          }
        }
      }
    }
    
    // Notify parent about updated tiles
    if (widget.onTilesInitialized != null) {
      widget.onTilesInitialized!(_tiles);
    }
  }
  
  // Rotate tiles to new positions
  void _rotateTiles(int direction, {bool updateModel = true}) {
    final itemCount = _tiles.length;
    final cornerIndices = _getCornerIndices();
    
    // First identify which positions are locked
    Set<int> lockedPositions = {};
    for (var tile in _tiles) {
      if (tile.isLocked) {
        lockedPositions.add(tile.currentPosition);
      }
    }
    
    // Create a copy of the tiles to work with
    List<RingTile> tilesCopy = _tiles.map((tile) => tile.clone()).toList();
    
    // For each tile, calculate its new position
    for (var tile in tilesCopy) {
      // Skip tiles that are locked
      if (tile.isLocked) continue;
      
      // Calculate the next position
      int nextPosition;
      if (direction < 0) {
        // Clockwise rotation
        nextPosition = (tile.currentPosition + 1) % itemCount;
      } else {
        // Counterclockwise rotation
        nextPosition = (tile.currentPosition - 1 + itemCount) % itemCount;
      }
      
      // Skip over any locked positions
      while (lockedPositions.contains(nextPosition)) {
        if (direction < 0) {
          nextPosition = (nextPosition + 1) % itemCount;
        } else {
          nextPosition = (nextPosition - 1 + itemCount) % itemCount;
        }
      }
      
      // Update the tile's position
      tile.currentPosition = nextPosition;
      
      // Update corner status
      tile.isCorner = cornerIndices.contains(nextPosition);
    }
    
    // Update the tiles
    setState(() {
      _tiles = tilesCopy;
    });
    
    // Notify parent about updated tiles
    if (widget.onTilesInitialized != null && updateModel) {
      widget.onTilesInitialized!(_tiles);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get corner indices based on ring type
  List<int> _getCornerIndices() {
    return widget.isInner 
        ? [0, 3, 6, 9]  // Inner ring corners
        : [0, 4, 8, 12]; // Outer ring corners
  }

  // Public method for starting rotation animation
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
    // Set tile sizes using the factors provided
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
            isClockwise = dragEndPosition.dx > 0;
            break;
          case _DragSide.right:
            isClockwise = dragEndPosition.dy > 0;
            break;
          case _DragSide.bottom:
            isClockwise = dragEndPosition.dx < 0;
            break;
          case _DragSide.left:
            isClockwise = dragEndPosition.dy < 0;
            break;
        }

        startRotationAnimation(isClockwise);
        _dragStartPosition = null;
      },
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
              children: _buildTiles(tileSize, cornerSize, _rotationAnimation.value),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTiles(double tileSize, double cornerSize, double animationValue) {
    final List<Widget> tileWidgets = [];
    final itemCount = _tiles.length;
    final cornerIndices = _getCornerIndices();
    
    // Helper function to get position coordinates
    Offset getPositionCoordinates(int position) {
      return widget.isInner
          ? SquarePositionUtils.calculateInnerSquarePosition(
              position, widget.ringModel.squareSize, tileSize)
          : SquarePositionUtils.calculateSquarePosition(
              position, widget.ringModel.squareSize, tileSize);
    }
    
    // For each tile, build its widget
    for (var tile in _tiles) {
      // Current position and whether it's a corner
      final currentPosition = tile.currentPosition;
      final isCorner = cornerIndices.contains(currentPosition);
      final cornerIndex = isCorner ? cornerIndices.indexOf(currentPosition) : -1;
      final isLocked = tile.isLocked;
      
      // Determine tile size based on whether it's at a corner
      final effectiveTileSize = isCorner ? cornerSize : tileSize;
      
      // Get current position coordinates
      final currentCoords = getPositionCoordinates(currentPosition);
      
      // For locked tiles or when no animation is happening, just show at current position
      if (isLocked || animationValue == 0) {
        tileWidgets.add(
          Positioned(
            left: currentCoords.dx - (effectiveTileSize - tileSize) / 2,
            top: currentCoords.dy - (effectiveTileSize - tileSize) / 2,
            width: effectiveTileSize,
            height: effectiveTileSize,
            child: AbsorbPointer(
              absorbing: isLocked,
              child: NumberTile(
                number: tile.number,
                color: widget.ringModel.itemColor,
                isDisabled: isLocked,
                size: effectiveTileSize,
              ),
            ),
          ),
        );
        continue;
      }
      
      // For animated tiles, calculate the next position
      int nextPosition;
      if (_rotationDirection < 0) {
        // Clockwise rotation
        nextPosition = (currentPosition + 1) % itemCount;
      } else {
        // Counterclockwise rotation
        nextPosition = (currentPosition - 1 + itemCount) % itemCount;
      }
      
      // Skip locked positions
      Set<int> lockedPositions = {};
      for (var t in _tiles) {
        if (t.isLocked) {
          lockedPositions.add(t.currentPosition);
        }
      }
      
      while (lockedPositions.contains(nextPosition)) {
        if (_rotationDirection < 0) {
          nextPosition = (nextPosition + 1) % itemCount;
        } else {
          nextPosition = (nextPosition - 1 + itemCount) % itemCount;
        }
      }
      
      // Determine if next position is a corner
      final nextIsCorner = cornerIndices.contains(nextPosition);
      
      // Get next position coordinates
      final nextCoords = getPositionCoordinates(nextPosition);
      
      // Calculate size animation
      double startSize, endSize;
      if (!isCorner && nextIsCorner) {
        // Growing from regular to corner size
        startSize = tileSize;
        endSize = cornerSize;
      } else if (isCorner && !nextIsCorner) {
        // Shrinking from corner to regular size
        startSize = cornerSize;
        endSize = tileSize;
      } else {
        // Maintaining same size
        startSize = endSize = isCorner ? cornerSize : tileSize;
      }
      
      // Current animated size
      final currentSize = startSize * (1 - animationValue) + endSize * animationValue;
      
      // Interpolate position
      final x = currentCoords.dx * (1 - animationValue) + nextCoords.dx * animationValue;
      final y = currentCoords.dy * (1 - animationValue) + nextCoords.dy * animationValue;
      
      // Position adjustments for size changes
      final offsetX = (currentSize - tileSize) / 2;
      
      tileWidgets.add(
        Positioned(
          left: x - offsetX,
          top: y - offsetX,
          width: currentSize,
          height: currentSize,
          child: NumberTile(
            number: tile.number,
            color: widget.ringModel.itemColor,
            isDisabled: false,
            size: currentSize,
          ),
        ),
      );
    }
    
    return tileWidgets;
  }
}