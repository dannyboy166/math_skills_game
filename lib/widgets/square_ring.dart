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
    final cornerSize = tileSize * 1.5; // 50% larger for corners
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow tiles to overflow if needed
          fit: StackFit.expand,
          children: [
            // Position the non-corner tiles
            for (int index = 0; index < 16; index++)
              if (!SquarePositionUtils.isCornerIndex(index))
                _buildPositionedTile(index, rotatedNumbers, tileSize),
                
            // Handle corners separately with larger size - only for outer ring
            if (ringModel.itemColor == Colors.teal)
              ..._buildCornerTiles(rotatedNumbers, tileSize, cornerSize),
          ],
        ),
      ),
    ); 
  }
  
  List<Widget> _buildCornerTiles(List<int> rotatedNumbers, double tileSize, double cornerSize) {
    // Corners are at indices 0, 4, 8, 12
    final cornerIndices = [0, 4, 8, 12];
    
    return cornerIndices.map((index) {
      // Calculate the corner position
      final position = SquarePositionUtils.calculateSquarePosition(
        index, 
        ringModel.squareSize, 
        tileSize
      );
      
      // Apply adjustment to center the larger tile where the regular tile would be
      final offsetDiff = (cornerSize - tileSize) / 2;
      final adjustedX = position.dx - offsetDiff;
      final adjustedY = position.dy - offsetDiff;
      
      final cornerIndex = cornerIndices.indexOf(index);
      final isSolved = cornerIndex >= 0 && solvedCorners[cornerIndex];
      
      return Positioned(
        left: adjustedX,
        top: adjustedY,
        width: cornerSize,
        height: cornerSize,
        child: NumberTile(
          number: rotatedNumbers[index],
          color: ringModel.itemColor,
          isDisabled: isSolved,
          onTap: () {},
          size: cornerSize,
        ),
      );
    }).toList();
  }
  
  Widget _buildPositionedTile(int index, List<int> rotatedNumbers, double tileSize) {
    final position = SquarePositionUtils.calculateSquarePosition(
      index, 
      ringModel.squareSize, 
      tileSize
    );
    
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: tileSize,
      height: tileSize,
      child: NumberTile(
        number: rotatedNumbers[index],
        color: ringModel.itemColor,
        isDisabled: false,
        onTap: () {},
        size: tileSize,
      ),
    );
  }
}