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
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLocked) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLocked) {
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Show equals sign when not locked, lock icon when locked
                  widget.isLocked
                    ? Icon(
                        Icons.lock,
                        size: 24,
                        color: Colors.grey.shade600,
                      )
                    : Text(
                        "=",
                        style: TextStyle(
                          fontSize: 30,
                          color: textColor.withOpacity(textOpacity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}