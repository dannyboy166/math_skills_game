// lib/widgets/equation_highlight_overlay.dart
import 'package:flutter/material.dart';
import '../models/ring_model.dart';
import '../utils/position_utils.dart';

class EquationHighlightOverlay extends StatelessWidget {
  final double size;
  final double tileSize;
  final double margin;
  final RingModel innerRingModel;
  final RingModel outerRingModel;
  final int targetNumber;
  final bool isVisible;

  const EquationHighlightOverlay({
    super.key,
    required this.size,
    required this.tileSize,
    required this.margin,
    required this.innerRingModel,
    required this.outerRingModel,
    required this.targetNumber,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size(size, size),
        painter: EquationHighlightPainter(
          innerRingModel: innerRingModel,
          outerRingModel: outerRingModel,
          size: size,
          tileSize: tileSize,
          margin: margin,
          targetNumber: targetNumber,
        ),
      ),
    );
  }
}

class EquationHighlightPainter extends CustomPainter {
  final RingModel innerRingModel;
  final RingModel outerRingModel;
  final double size;
  final double tileSize;
  final double margin;
  final int targetNumber;

  EquationHighlightPainter({
    required this.innerRingModel,
    required this.outerRingModel,
    required this.size,
    required this.tileSize,
    required this.margin,
    required this.targetNumber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create shadow overlay for non-equation areas (just the X shadow pattern)
    _drawShadowOverlay(canvas, size);
  }

  void _drawShadowOverlay(Canvas canvas, Size canvasSize) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final shadowPath = Path();

    // Create shadow for center circle
    final centerOffset = Offset(size / 2, size / 2);
    shadowPath.addOval(Rect.fromCenter(
      center: centerOffset,
      width: 110,
      height: 110,
    ));

    // Create shadow for corners and diagonal paths
    _addCornerShadows(shadowPath);
    _addDiagonalPathShadows(shadowPath);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _addCornerShadows(Path shadowPath) {
    // Inner ring corner shadows (keep as rectangles)
    for (int cornerIndex in innerRingModel.cornerIndices) {
      final cornerPos = SquarePositionUtils.calculateInnerSquarePosition(
        cornerIndex,
        size,
        tileSize,
        cornerSizeMultiplier: 1.2,
        margin: margin,
      );

      shadowPath.addRect(Rect.fromLTWH(
        cornerPos.dx - 5,
        cornerPos.dy - 5,
        tileSize * 1.2 + 10,
        tileSize * 1.2 + 10,
      ));
    }

    // Outer ring corner shadows - IMPROVED curved shadows
    for (int cornerIndex in outerRingModel.cornerIndices) {
      final cornerPos = SquarePositionUtils.calculateSquarePosition(
        cornerIndex,
        size,
        tileSize,
        cornerSizeMultiplier: 1.2,
        margin: margin,
      );

      // Calculate the actual tile center more precisely
      final tileCenter = Offset(
        cornerPos.dx + (tileSize * 1.2) / 2,
        cornerPos.dy + (tileSize * 1.2) / 2,
      );

      // Make the radius larger and more generous to better curve around the tile
      final baseRadius = (tileSize * 1.2) / 2;
      final expandedRadius =
          baseRadius + 8; // Increased padding for better curve

      // Create a more generous circular shadow
      shadowPath.addOval(Rect.fromCenter(
        center: tileCenter,
        width: expandedRadius * 2,
        height: expandedRadius * 2,
      ));

      // Optional: Add a secondary, smaller circular area for even smoother transition
      // This creates a "feathered" edge effect
      final featherRadius = expandedRadius + 8;
      shadowPath.addOval(Rect.fromCenter(
        center: tileCenter,
        width: featherRadius * 2,
        height: featherRadius * 2,
      ));
    }
  }

  void _addDiagonalPathShadows(Path shadowPath) {
    final centerOffset = Offset(size / 2, size / 2);
    final pathWidth = 50.0;

    // Create diagonal path shadows (big X pattern)
    final innerCorners = innerRingModel.cornerIndices;
    final outerCorners = outerRingModel.cornerIndices;

    for (int i = 0; i < innerCorners.length; i++) {
      final innerCornerIndex = innerCorners[i];
      final outerCornerIndex = outerCorners[i];

      // Get corner positions
      final innerCornerPos = SquarePositionUtils.calculateInnerSquarePosition(
        innerCornerIndex,
        size,
        tileSize,
        cornerSizeMultiplier: 1.2,
        margin: margin,
      );

      final outerCornerPos = SquarePositionUtils.calculateSquarePosition(
        outerCornerIndex,
        size,
        tileSize,
        cornerSizeMultiplier: 1.2,
        margin: margin,
      );

      // Calculate center points of tiles
      final innerCenter = Offset(
        innerCornerPos.dx + (tileSize * 1.2) / 2,
        innerCornerPos.dy + (tileSize * 1.2) / 2,
      );

      final outerCenter = Offset(
        outerCornerPos.dx + (tileSize * 1.2) / 2,
        outerCornerPos.dy + (tileSize * 1.2) / 2,
      );

      // Create path from inner corner through center to outer corner
      _addThickLinePath(shadowPath, innerCenter, centerOffset, pathWidth);
      _addThickLinePath(shadowPath, centerOffset, outerCenter, pathWidth);
    }
  }

  void _addThickLinePath(Path path, Offset start, Offset end, double width) {
    // Calculate perpendicular vector for line thickness
    final direction = end - start;
    final length = direction.distance;
    if (length == 0) return;

    final normalized = Offset(direction.dx / length, direction.dy / length);
    final perpendicular = Offset(-normalized.dy, normalized.dx) * (width / 2);

    // Create rectangle along the line
    final rect = Path()
      ..moveTo(start.dx + perpendicular.dx, start.dy + perpendicular.dy)
      ..lineTo(start.dx - perpendicular.dx, start.dy - perpendicular.dy)
      ..lineTo(end.dx - perpendicular.dx, end.dy - perpendicular.dy)
      ..lineTo(end.dx + perpendicular.dx, end.dy + perpendicular.dy)
      ..close();

    path.addPath(rect, Offset.zero);
  }

  @override
  bool shouldRepaint(EquationHighlightPainter oldDelegate) {
    return oldDelegate.innerRingModel != innerRingModel ||
        oldDelegate.outerRingModel != outerRingModel;
  }
}
