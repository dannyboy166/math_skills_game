import 'package:flutter/material.dart';

class ClickableEquals extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLocked;
  final double size;
  final Color? color;

  const ClickableEquals({
    Key? key,
    required this.onTap,
    this.isLocked = false,
    this.size = 30.0,
    this.color,
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
    // Use a specified color or default to red
    final textColor = widget.isLocked ? Colors.grey : (widget.color ?? Colors.red);

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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Show equals sign when not locked, lock icon when locked
                  widget.isLocked
                    ? Icon(
                        Icons.lock,
                        size: widget.size * 0.8,
                        color: Colors.grey.shade600,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: widget.size * 0.6,
                            height: widget.size * 0.115, // Reduced from 0.15 to 0.1
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(textOpacity),
                              borderRadius: BorderRadius.circular(1), // Smaller radius for sharper edges
                            ),
                          ),
                          SizedBox(height: widget.size * 0.15), // Kept the same spacing
                          Container(
                            width: widget.size * 0.6,
                            height: widget.size * 0.115, // Reduced from 0.15 to 0.1
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(textOpacity),
                              borderRadius: BorderRadius.circular(1), // Smaller radius for sharper edges
                            ),
                          ),
                        ],
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