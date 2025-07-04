// lib/widgets/star_animation.dart
import 'package:flutter/material.dart';
import 'package:number_ninja/widgets/progress_stars.dart';

class StarAnimation extends StatefulWidget {
  final Function onComplete;
  final Offset startPosition;
  final Offset endPosition;

  const StarAnimation({
    Key? key,
    required this.onComplete,
    required this.startPosition,
    required this.endPosition,
  }) : super(key: key);

  @override
  StarAnimationState createState() => StarAnimationState();
}

class StarAnimationState extends State<StarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Scale animation: start small, grow big, then shrink
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Opacity animation: fade in, stay visible, then fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Position animation: curve from start to end position
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation
    _controller.forward();

    // Call onComplete when animation is done
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
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
        return Positioned(
          left: _positionAnimation.value.dx - 40,
          top: _positionAnimation.value.dy - 40,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const StarWidget(
                size: 80,
                color: Color(0xFFFFD700), // Gold color
              ),
            ),
          ),
        );
      },
    );
  }
}
