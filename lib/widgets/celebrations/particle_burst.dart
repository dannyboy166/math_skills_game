import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBurst extends StatefulWidget {
  final Color color;
  final double size;
  
  const ParticleBurst({
    Key? key,
    required this.color,
    this.size = 100.0,
  }) : super(key: key);

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Generate random particles
    _generateParticles();
    
    // Play animation once
    _controller.forward();
  }
  
  void _generateParticles() {
    final random = math.Random();
    const particleCount = 20;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 2.0 + random.nextDouble() * 3.0;
      final size = 2.0 + random.nextDouble() * 5.0;
      final ttl = 0.5 + random.nextDouble() * 0.5; // Time to live (0.5-1.0)
      
      _particles.add(Particle(
        angle: angle,
        speed: speed,
        size: size,
        ttl: ttl,
        color: widget.color,
      ));
    }
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
          size: Size(widget.size, widget.size),
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  final double ttl; // Time to live (0.0-1.0)
  final Color color;
  
  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.ttl,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  
  ParticlePainter({
    required this.particles,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final particle in particles) {
      // Calculate particle lifetime
      final particleProgress = math.min(progress / particle.ttl, 1.0);
      if (particleProgress >= 1.0) continue;
      
      // Calculate position based on angle, speed and progress
      final distance = particle.speed * size.width / 2 * particleProgress;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy + math.sin(particle.angle) * distance;
      
      // Calculate opacity based on lifetime
      final opacity = 1.0 - particleProgress;
      
      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - particleProgress),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}