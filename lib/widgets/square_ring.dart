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
    // Scale tile size based on the ring size
    final tileSize = ringModel.squareSize * 0.125; // Adjusted tile size
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
          children: [
            // Position all the number tiles
            ...List.generate(20, (index) { // Changed from 16 to 20
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
                  isDisabled: isCorner && solvedCorners[cornerIndex],
                  onTap: () {},
                  size: tileSize, // Pass the dynamic tile size
                ),
              );
            }),
          ],
        ),
      ),
    ); 
  }
}