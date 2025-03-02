// Create a new file: lib/widgets/celebrations/candy_crush_explosion.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class CandyCrushExplosion extends StatefulWidget {
  final Color color;
  final VoidCallback? onComplete;

  const CandyCrushExplosion({
    Key? key,
    required this.color,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CandyCrushExplosion> createState() => _CandyCrushExplosionState();
}

class _CandyCrushExplosionState extends State<CandyCrushExplosion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ExplosionParticle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Generate random particles
    _particles = List.generate(
      25, // More particles for a richer effect
      (index) => ExplosionParticle(
        angle: _random.nextDouble() * 2 * math.pi,
        speed: 0.5 + _random.nextDouble() * 1.0,
        size: 5.0 + _random.nextDouble() * 8.0,
        color: _getRandomColor(),
        rotationSpeed: _random.nextDouble() * 10,
        shape: _random.nextInt(3), // 0: circle, 1: star, 2: diamond
      ),
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    // Play the animation immediately
    _controller.forward();
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _ExplosionPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  final List<ExplosionParticle> particles;
  final double progress;

  _ExplosionPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw a bright flash at the beginning
    if (progress < 0.2) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity((0.2 - progress) / 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        center,
        size.width * 0.4 * progress / 0.2,
        flashPaint,
      );
    }

    for (final particle in particles) {
      // Start slightly after the flash begins
      final particleProgress = math.max(0.0, progress - 0.1);
      final normalizedProgress = particleProgress / 0.9; // Scale to 0.0-1.0

      if (normalizedProgress <= 0.0) continue;

      // Particle movement - outward and then a slight "gravity" pull
      final distance = particle.speed *
          size.width *
          0.5 *
          (normalizedProgress * (2.0 - normalizedProgress) // Easing curve
          );

      // Add a slight "gravity" effect in the y direction
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy +
          math.sin(particle.angle) * distance +
          25.0 * normalizedProgress * normalizedProgress; // Gravity

      // Size animation - grow and then shrink
      final sizeProgress = 1.0 - (normalizedProgress - 0.5).abs() * 2.0;
      final currentSize = particle.size * sizeProgress;

      // Opacity - fade out toward the end
      final opacity = math.max(0.0, 1.0 - normalizedProgress * 1.5);

      // Particle rotation
      final rotation =
          particle.rotationSpeed * normalizedProgress * 2 * math.pi;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw different shapes
      switch (particle.shape) {
        case 0: // Circle
          canvas.drawCircle(Offset.zero, currentSize, paint);
          break;
        case 1: // Star
          _drawStar(canvas, currentSize, paint);
          break;
        case 2: // Diamond
          _drawDiamond(canvas, currentSize, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (var i = 0; i < 5; i++) {
      final outerAngle = i * 2 * math.pi / 5 - math.pi / 2;
      final outerX = math.cos(outerAngle) * outerRadius;
      final outerY = math.sin(outerAngle) * outerRadius;

      final innerAngle = outerAngle + math.pi / 5;
      final innerX = math.cos(innerAngle) * innerRadius;
      final innerY = math.sin(innerAngle) * innerRadius;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }

      path.lineTo(innerX, innerY);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size, 0);
    path.lineTo(0, size);
    path.lineTo(-size, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ExplosionPainter oldDelegate) => true;
}

class ExplosionParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final int shape;

  ExplosionParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.shape,
  });
}
