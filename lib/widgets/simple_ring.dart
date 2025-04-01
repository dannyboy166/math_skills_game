import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';

class SimpleRing extends StatelessWidget {
  final RingModel ringModel;
  final double size;
  final double tileSize;
  final bool isInner;
  final ValueChanged<int> onRotateSteps;
  
  const SimpleRing({
    Key? key,
    required this.ringModel,
    required this.size,
    required this.tileSize,
    required this.isInner,
    required this.onRotateSteps,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        
        // Determine rotation direction based on drag
        final int steps = details.primaryVelocity! > 0 ? -1 : 1;
        onRotateSteps(ringModel.rotationSteps + steps);
      },
      child: Container(
        width: size,
        height: size,
        color: Colors.transparent,
        child: Stack(
          children: _buildTiles(),
        ),
      ),
    );
  }
  
  List<Widget> _buildTiles() {
    final itemCount = ringModel.numbers.length;
    List<Widget> tiles = [];
    
    for (int i = 0; i < itemCount; i++) {
      // Get position for this tile
      final offset = isInner 
          ? SquarePositionUtils.calculateInnerSquarePosition(i, size, tileSize)
          : SquarePositionUtils.calculateSquarePosition(i, size, tileSize);
      
      // Get the current number at this position
      final number = ringModel.getNumberAtPosition(i);
      
      // Is this a corner?
      final isCorner = ringModel.cornerIndices.contains(i);
      
      // Debug info for corner positions
      final String debugLabel = isCorner ? "[C${ringModel.cornerIndices.indexOf(i)}]" : "";
      
      tiles.add(
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: isCorner ? ringModel.color : ringModel.color.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              // Fix: Replace Column with a single Stack widget to avoid overflow
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main number
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: isCorner ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Debug label, positioned at the bottom
                  if (debugLabel.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      child: Text(
                        debugLabel,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return tiles;
  }
}