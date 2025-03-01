import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class InnerRing extends StatelessWidget {
  final RingModel ringModel;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  
  const InnerRing({
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow tiles to overflow if needed
          fit: StackFit.expand,
          children: [
            // Position only the non-corner tiles for inner ring
            for (int index = 0; index < 20; index++)
              if (!_isCornerIndex(index))
                _buildPositionedTile(index, rotatedNumbers, tileSize),
          ],
        ),
      ),
    ); 
  }
  
  bool _isCornerIndex(int index) {
    // Corners are at indices 0, 4, 10, 14
    return [0, 4, 10, 14].contains(index);
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
      child: Center(
        child: NumberTile(
          number: rotatedNumbers[index],
          color: ringModel.itemColor,
          isDisabled: false,
          onTap: () {},
          size: tileSize,
        ),
      ),
    );
  }
}