import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class SquareRing extends StatelessWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  
  const SquareRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set fixed tile size relative to the ring size
    final tileSize = ringModel.squareSize * 0.13;
    final rotatedNumbers = ringModel.getRotatedNumbers();
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Determine swipe direction and rotate accordingly
        if (details.primaryVelocity == null) return;
        
        if (details.primaryVelocity! > 0) {
          // Right swipe - rotate counter-clockwise
          onRotate(ringModel.rotationSteps - 1);
        } else if (details.primaryVelocity! < 0) {
          // Left swipe - rotate clockwise
          onRotate(ringModel.rotationSteps + 1);
        }
      },
      child: Container(
        width: ringModel.squareSize,
        height: ringModel.squareSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: ringModel.itemColor.withOpacity(0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow tiles to overflow if needed
          children: [
            // Position all the number tiles
            for (int index = 0; index < 20; index++) // 5 tiles per side * 4 sides
              _buildPositionedTile(index, rotatedNumbers, tileSize),
          ],
        ),
      ),
    ); 
  }
  
  Widget _buildPositionedTile(int index, List<int> rotatedNumbers, double tileSize) {
    final position = SquarePositionUtils.calculateSquarePosition(
      index, 
      ringModel.squareSize, 
      tileSize
    );
    
    // Check if this is a corner position
    final isCorner = ringModel.cornerIndices.contains(index);
    final cornerIndex = isCorner ? ringModel.cornerIndices.indexOf(index) : -1;
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: NumberTile(
        number: rotatedNumbers[index],
        color: ringModel.itemColor,
        isDisabled: isCorner && cornerIndex >= 0 && solvedCorners[cornerIndex],
        onTap: () {},
        size: tileSize,
      ),
    );
  }
}