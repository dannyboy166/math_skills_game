import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class RotatingRing extends StatelessWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  
  const RotatingRing({
    Key? key,
    required this.ringModel,
    required this.onRotate,
    required this.solvedCorners,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tileSize = 45.0;
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
            ...List.generate(16, (index) {
              // Use our square position utils to calculate position
              final position = SquarePositionUtils.calculateSquarePosition(
                index, 
                ringModel.squareSize, 
                tileSize
              );
              
              // Check if this is a corner position
              final isCorner = ringModel.cornerIndices.contains(index);
              final cornerIndex = isCorner ? ringModel.cornerIndices.indexOf(index) : -1;
              
              return Positioned(
                left: position.dx + tileSize/2,
                top: position.dy + tileSize/2,
                child: NumberTile(
                  number: rotatedNumbers[index],
                  color: ringModel.itemColor,
                  isDisabled: isCorner && cornerIndex >= 0 && solvedCorners[cornerIndex],
                  onTap: () {},
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}