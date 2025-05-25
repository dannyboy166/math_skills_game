// lib/widgets/time_penalty_animation.dart
import 'package:flutter/material.dart';

class TimePenaltyAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final int penaltySeconds;
  final Offset startPosition;
  final String animationId; // Add unique ID to track animations

  const TimePenaltyAnimation({
    Key? key,
    required this.onComplete,
    this.penaltySeconds = 3,
    required this.startPosition,
    required this.animationId, // Make this required
  }) : super(key: key);

  @override
  State<TimePenaltyAnimation> createState() => _TimePenaltyAnimationState();
}

class _TimePenaltyAnimationState extends State<TimePenaltyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale up then slightly down
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Fade in, hold, then fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Slide up slightly
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
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
        // Calculate safe position to avoid clipping with top bars
        final screenHeight = MediaQuery.of(context).size.height;
        final safeAreaTop = MediaQuery.of(context).padding.top;
        final appBarHeight = kToolbarHeight;
        final minTopPosition = safeAreaTop + appBarHeight + 80; // Extra padding for safety
        
        // Adjust Y position if it would be clipped
        double adjustedY = widget.startPosition.dy - 80;
        if (adjustedY < minTopPosition) {
          adjustedY = minTopPosition;
        }
        
        // Also ensure we don't go off the bottom
        if (adjustedY > screenHeight - 150) {
          adjustedY = screenHeight - 150;
        }

        return Positioned(
          left: widget.startPosition.dx - 60,
          top: adjustedY,
          child: Transform.translate(
            offset: _slideAnimation.value * 60,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '+${widget.penaltySeconds}s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}