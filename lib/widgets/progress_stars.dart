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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final bool isCompleted = index < completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: isCompleted
              ? _buildCompletedStar()
              : _buildEmptyStar(),
        );
      }),
    );
  }
  
  Widget _buildCompletedStar() {
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
        size: 40, 
        color: Color(0xFFFFD700), // Gold color
      ),
    );
  }
  
  Widget _buildEmptyStar() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: StarWidget(
        size: 40, 
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
      ..color = Colors.white.withOpacity(0.6)
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