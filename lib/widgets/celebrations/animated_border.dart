import 'package:flutter/material.dart';

class AnimatedBorder extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const AnimatedBorder({
    Key? key,
    required this.child,
    this.isActive = false,
  }) : super(key: key);

  @override
  State<AnimatedBorder> createState() => _AnimatedBorderState();
}

class _AnimatedBorderState extends State<AnimatedBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedBorder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
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
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: Colors.green
                          .withOpacity(0.3 + _glowAnimation.value * 0.5),
                      blurRadius: 8 + _glowAnimation.value * 15,
                      spreadRadius: 2 + _glowAnimation.value * 8,
                    ),
                    BoxShadow(
                      color: Colors.yellow
                          .withOpacity(0.2 + _glowAnimation.value * 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
