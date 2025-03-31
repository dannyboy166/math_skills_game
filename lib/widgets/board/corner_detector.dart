import 'package:flutter/material.dart';
import '../celebrations/burst_animation.dart';
import '../celebrations/particle_burst.dart';

/// Widget that handles the corner touch detection and animations
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
    final cornerOffset = boardSize * 0.15;
    final detectorSize = 70.0;

    return Positioned(
      top: (cornerIndex == 0 || cornerIndex == 1) ? cornerOffset : null,
      bottom: (cornerIndex == 2 || cornerIndex == 3) ? cornerOffset : null,
      left: (cornerIndex == 0 || cornerIndex == 3) ? cornerOffset : null,
      right: (cornerIndex == 1 || cornerIndex == 2) ? cornerOffset : null,
      child: GestureDetector(
        onTap: onTap,
        // Add these gesture handlers to allow swiping on corners
        onHorizontalDragEnd: (details) => onSwipe(details, cornerIndex, true),
        onVerticalDragEnd: (details) => onSwipe(details, cornerIndex, false),
        child: BurstAnimation(
          key: burstKey,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particle burst (only visible when animation plays)
              if (isSolved)
                ParticleBurst(color: operationColor.withOpacity(0.7)),

              // The corner indicator
              Container(
                width: detectorSize,
                height: detectorSize,
                decoration: BoxDecoration(
                  color: isSolved
                      ? operationColor.withOpacity(0.3)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}