// lib/widgets/number_tile.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class NumberTile extends StatefulWidget {
  final int number;
  final Color color;
  final bool isLocked;
  final VoidCallback? onTap;
  final double size;

  const NumberTile({
    Key? key,
    required this.number,
    required this.color,
    this.isLocked = false,
    this.onTap,
    this.size = 45,
  }) : super(key: key);

  @override
  State<NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<NumberTile> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    if (!widget.isLocked && widget.onTap != null) {
      setState(() {
        _isPressed = true;
      });
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLocked && widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLocked && widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the base color - if locked, use a gray version
    Color baseColor;
    if (widget.isLocked) {
      // Convert to grayscale with reduced opacity
      final grayValue = _getGrayscaleValue(widget.color);
      baseColor = Color.fromRGBO(grayValue, grayValue, grayValue, 0.7);
    } else {
      baseColor = widget.color;
    }
    
    // Create gradient colors for 3D effect
    final Color lightColor = _getLighterColor(baseColor);
    final Color darkColor = _getDarkerColor(baseColor);
    
    return Semantics(
      button: true,
      enabled: !widget.isLocked,
      child: AnimatedBuilder(
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      lightColor,
                      baseColor,
                      darkColor,
                    ],
                    stops: const [0.1, 0.5, 0.9],
                  ),
                  boxShadow: widget.isLocked
                    ? []
                    : [
                        // Outer shadow
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: widget.size * 0.1,
                          spreadRadius: widget.size * 0.02,
                          offset: Offset(widget.size * 0.04, widget.size * 0.04),
                        ),
                        // Inner highlight
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: widget.size * 0.1,
                          spreadRadius: widget.size * 0.01,
                          offset: Offset(-widget.size * 0.02, -widget.size * 0.02),
                        ),
                      ],
                ),
                child: _isPressed
                  ? _buildPressedContent()
                  : _buildNormalContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNormalContent() {
    // Adjust the text color based on locked state
    final textColor = widget.isLocked ? Colors.white.withOpacity(0.7) : Colors.white;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner circle for depth
        Container(
          width: widget.size * 0.85,
          height: widget.size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(widget.isLocked ? 0.1 : 0.15),
              width: widget.size * 0.03,
            ),
          ),
        ),
        
        // Text with subtle shadow
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.12),
              child: Text(
                '${widget.number}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.size * 0.45,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Shine effect (subtle arc at top-left) - only if not locked
        if (!widget.isLocked)
          Positioned(
            top: widget.size * 0.15,
            left: widget.size * 0.15,
            child: Container(
              width: widget.size * 0.2,
              height: widget.size * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(widget.size * 0.1),
              ),
            ),
          ),
          
        // Removed lock icon from number tiles
      ],
    );
  }

  Widget _buildPressedContent() {
    final textColor = widget.isLocked ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.9);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner circle for depth
        Container(
          width: widget.size * 0.85,
          height: widget.size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: widget.size * 0.02,
            ),
          ),
        ),
        
        // Text with less pronounced shadow
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.12),
              child: Text(
                '${widget.number}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.size * 0.45,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 1,
                      offset: Offset(0.5, 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Removed lock icon from number tiles
      ],
    );
  }

  // Helper method to calculate grayscale equivalent
  int _getGrayscaleValue(Color color) {
    return ((0.299 * color.red) + (0.587 * color.green) + (0.114 * color.blue)).round();
  }

  Color _getLighterColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.min(1.0, hsl.lightness + 0.15)).toColor();
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.max(0.0, hsl.lightness - 0.15)).toColor();
  }
}