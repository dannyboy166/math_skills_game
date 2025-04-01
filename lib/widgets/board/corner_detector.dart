import 'package:flutter/material.dart';
import '../celebrations/burst_animation.dart';
import '../celebrations/particle_burst.dart';

class CornerDetector extends StatelessWidget {
  final int cornerIndex;
  final double boardSize;
  final bool isSolved;
  final Color operationColor;
  final GlobalKey<State<BurstAnimation>> burstKey;
  final VoidCallback onTap;
  final Function(DragEndDetails, int, bool) onSwipe;

  const CornerDetector({
    Key? key,
    required this.cornerIndex,
    required this.boardSize,
    required this.isSolved,
    required this.operationColor,
    required this.burstKey,
    required this.onTap,
    required this.onSwipe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate corner position based on index
    // 0: top-left, 1: top-right, 2: bottom-right, 3: bottom-left
    final cornerOffset = boardSize * 0.15;
    final detectorSize = 70.0;

    return Positioned(
      top: (cornerIndex == 0 || cornerIndex == 1) ? cornerOffset : null,
      bottom: (cornerIndex == 2 || cornerIndex == 3) ? cornerOffset : null,
      left: (cornerIndex == 0 || cornerIndex == 3) ? cornerOffset : null,
      right: (cornerIndex == 1 || cornerIndex == 2) ? cornerOffset : null,
      child: GestureDetector(
        onTap: () {
          print("Corner $cornerIndex tapped!"); // Debug print
          onTap();
        },
        // Add swipe gesture handlers
        onHorizontalDragEnd: (details) => onSwipe(details, cornerIndex, true),
        onVerticalDragEnd: (details) => onSwipe(details, cornerIndex, false),
        child: BurstAnimation(
          key: burstKey,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Visualization to show corner hit area (helpful for debugging)
              Container(
                width: detectorSize,
                height: detectorSize,
                decoration: BoxDecoration(
                  color: isSolved
                      ? operationColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSolved 
                        ? operationColor.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isSolved
                      ? Icon(
                          Icons.check_circle_outline,
                          color: operationColor,
                          size: 30,
                        )
                      : null,
                ),
              ),
              
              // Particle burst effect (only visible when solved)
              if (isSolved)
                ParticleBurst(color: operationColor.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}