// lib/widgets/clickable_equals.dart
import 'package:flutter/material.dart';

class ClickableEquals extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLocked;
  final double size;

  const ClickableEquals({
    Key? key,
    required this.onTap,
    this.isLocked = false,
    this.size = 30.0,
  }) : super(key: key);

  @override
  State<ClickableEquals> createState() => _ClickableEqualsState();
}

class _ClickableEqualsState extends State<ClickableEquals> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLocked) {
      setState(() {
        _isPressed = true;
      });
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLocked) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLocked) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjust opacity based on locked state
    final textOpacity = widget.isLocked ? 0.7 : 1.0;
    // Use a softer shade of red when locked
    final textColor = widget.isLocked ? Colors.grey : Colors.red;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.isLocked ? null : widget.onTap,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: widget.isLocked ? BoxDecoration(
                color: Colors.black12,
                shape: BoxShape.circle,
              ) : null,
              child: Text(
                "=",
                style: TextStyle(
                  fontSize: 30,
                  color: textColor.withOpacity(textOpacity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}