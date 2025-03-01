import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';
import 'number_tile.dart';

class InnerRing extends StatelessWidget {
  final List<int> numbers;
  final Color itemColor;
  final double squareSize;
  final Function(int) onRotate;
  final List<bool> solvedCorners;
  final int rotationSteps;
  
  const InnerRing({
    Key? key,
    required this.numbers,
    required this.itemColor,
    required this.squareSize,
    required this.onRotate,
    required this.solvedCorners,
    required this.rotationSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set fixed tile size relative to the ring size
    final tileSize = squareSize * 0.13;
    final cornerSize = tileSize * 1.6; // Make corner tiles 40% larger
    
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Determine swipe direction and rotate accordingly
        if (details.primaryVelocity == null) return;
        
        if (details.primaryVelocity! > 0) {
          // Right swipe - rotate counter-clockwise
          onRotate(rotationSteps - 1);
        } else if (details.primaryVelocity! < 0) {
          // Left swipe - rotate clockwise
          onRotate(rotationSteps + 1);
        }
      },
      child: Container(
        width: squareSize,
        height: squareSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow tiles to overflow if needed
          fit: StackFit.expand,
          children: [
            // Position all tiles for inner ring (highlighting corners)
            // Corner tiles with larger size
            _buildCornerTile(0, numbers, cornerSize, 0, 0),   // Top-left
            _buildCornerTile(3, numbers, cornerSize, 3, 0),   // Top-right
            _buildCornerTile(6, numbers, cornerSize, 3, 3),   // Bottom-right
            _buildCornerTile(9, numbers, cornerSize, 0, 3),   // Bottom-left
            
            // Regular tiles
            _buildRegularTile(1, numbers, tileSize, 1, 0),    // Top row
            _buildRegularTile(2, numbers, tileSize, 2, 0),    // Top row
            
            _buildRegularTile(4, numbers, tileSize, 3, 1),    // Right column
            _buildRegularTile(5, numbers, tileSize, 3, 2),    // Right column
            
            _buildRegularTile(7, numbers, tileSize, 2, 3),    // Bottom row
            _buildRegularTile(8, numbers, tileSize, 1, 3),    // Bottom row
            
            _buildRegularTile(10, numbers, tileSize, 0, 2),   // Left column
            _buildRegularTile(11, numbers, tileSize, 0, 1),   // Left column
          ],
        ),
      ),
    ); 
  }
  
  Widget _buildCornerTile(int index, List<int> numbers, double tileSize, int gridX, int gridY) {
    // Calculate position based on a 4x4 grid (0-3 in both directions)
    final gridSize = squareSize;
    final cellSize = gridSize / 4;
    
    // Position the tile in the center of its grid cell
    // For corner tiles, adjust the position to account for larger size
    final offsetDiff = (tileSize - (squareSize * 0.13)) / 2;
    final x = gridX * cellSize + (cellSize - tileSize) / 2;
    final y = gridY * cellSize + (cellSize - tileSize) / 2;
    
    // Determine which corner this is (0-3)
    int cornerIndex = -1;
    if (index == 0) cornerIndex = 0;      // Top-left
    else if (index == 3) cornerIndex = 1; // Top-right
    else if (index == 6) cornerIndex = 2; // Bottom-right
    else if (index == 9) cornerIndex = 3; // Bottom-left
    
    final isSolved = cornerIndex >= 0 && solvedCorners[cornerIndex];
    
    return Positioned(
      left: x,
      top: y,
      width: tileSize,
      height: tileSize,
      child: NumberTile(
        number: numbers[index],
        color: itemColor,
        isDisabled: isSolved,
        onTap: () {},
        size: tileSize,
      ),
    );
  }
  
  Widget _buildRegularTile(int index, List<int> numbers, double tileSize, int gridX, int gridY) {
    // Calculate position based on a 4x4 grid (0-3 in both directions)
    final gridSize = squareSize;
    final cellSize = gridSize / 4;
    
    // Position the tile in the center of its grid cell
    final x = gridX * cellSize + (cellSize - tileSize) / 2;
    final y = gridY * cellSize + (cellSize - tileSize) / 2;
    
    return Positioned(
      left: x,
      top: y,
      width: tileSize,
      height: tileSize,
      child: NumberTile(
        number: numbers[index],
        color: itemColor,
        isDisabled: false,
        onTap: () {},
        size: tileSize,
      ),
    );
  }
}