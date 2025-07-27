// lib/widgets/progress_stars.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget to display star progress at the top of the game screen
class ProgressStars extends StatelessWidget {
  final int total;
  final int completed;
  
  const ProgressStars({
    Key? key,
    required this.total,
    required this.completed,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Display 6 stars per row with 2 rows
    final int starsPerRow = 6;
    final double spacing = 6;
    final double starSize = 32;
    
    // Split stars into rows
    List<Widget> rows = [];
    for (int row = 0; row < 2; row++) {
      List<Widget> rowStars = [];
      for (int col = 0; col < starsPerRow; col++) {
        final int index = row * starsPerRow + col;
        final bool isCompleted = index < completed;
        
        rowStars.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            child: isCompleted
                ? _buildCompletedStar(starSize)
                : _buildEmptyStar(starSize),
          ),
        );
      }
      
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rowStars,
        ),
      );
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows.map((row) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: row,
      )).toList(),
    );
  }
  
  Widget _buildCompletedStar(double size) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: StarWidget(
        size: size, 
        color: Color(0xFFFFD700), // Gold color
      ),
    );
  }
  
  Widget _buildEmptyStar(double size) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: StarWidget(
        size: size, 
        color: Colors.white,
      ),
    );
  }
}

/// Star widget for drawing a star shape
class StarWidget extends StatelessWidget {
  final double size;
  final Color color;
  
  const StarWidget({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: StarPainter(color: color),
      ),
    );
  }
}

/// Custom painter for drawing a star
class StarPainter extends CustomPainter {
  final Color color;
  
  StarPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.4;
    
    final double startAngle = -math.pi / 2; // Start at top
    
    final Path path = Path();
    
    for (int i = 0; i < 5; i++) {
      final double outerAngle = startAngle + i * 2 * math.pi / 5;
      final double innerAngle = outerAngle + math.pi / 5;
      
      final double outerX = centerX + outerRadius * math.cos(outerAngle);
      final double outerY = centerY + outerRadius * math.sin(outerAngle);
      
      final double innerX = centerX + innerRadius * math.cos(innerAngle);
      final double innerY = centerY + innerRadius * math.sin(innerAngle);
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      
      path.lineTo(innerX, innerY);
    }
    
    path.close();
    canvas.drawPath(path, paint);
    
    // Add highlight/shine effect
    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    final Path shinePath = Path();
    shinePath.moveTo(centerX, centerY);
    shinePath.lineTo(centerX - outerRadius * 0.2, centerY - outerRadius * 0.6);
    shinePath.lineTo(centerX + outerRadius * 0.2, centerY - outerRadius * 0.4);
    shinePath.close();
    
    canvas.drawPath(shinePath, shinePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}