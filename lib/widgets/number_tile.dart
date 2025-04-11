// lib/widgets/number_tile.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class NumberTile extends StatefulWidget {
  final int number;
  final Color color;
  final bool isLocked;
  final bool isCorner; // New parameter to indicate if it's a corner position
  final VoidCallback? onTap;
  final double size;
  final double sizeMultiplier; // New parameter for size adjustment

  const NumberTile({
    Key? key,
    required this.number,
    required this.color,
    this.isLocked = false,
    this.isCorner = false, // Default value
    this.onTap,
    this.size = 45,
    this.sizeMultiplier = 1.0, // Default value (no size change)
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
    
    // Calculate the adjusted size, applying the multiplier
    final adjustedSize = widget.size * widget.sizeMultiplier;
    
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
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: adjustedSize,
                height: adjustedSize,
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
                          blurRadius: adjustedSize * 0.1,
                          spreadRadius: adjustedSize * 0.02,
                          offset: Offset(adjustedSize * 0.04, adjustedSize * 0.04),
                        ),
                        // Inner highlight
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: adjustedSize * 0.1,
                          spreadRadius: adjustedSize * 0.01,
                          offset: Offset(-adjustedSize * 0.02, -adjustedSize * 0.02),
                        ),
                      ],
                ),
                child: _isPressed
                  ? _buildPressedContent(adjustedSize)
                  : _buildNormalContent(adjustedSize),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNormalContent(double size) {
    // Adjust the text color based on locked state
    final textColor = widget.isLocked ? Colors.white.withOpacity(0.7) : Colors.white;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner circle for depth
        Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(widget.isLocked ? 0.1 : 0.15),
              width: size * 0.03,
            ),
          ),
        ),
        
        // Text with subtle shadow
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Text(
                '${widget.number}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.45,
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
            top: size * 0.15,
            left: size * 0.15,
            child: Container(
              width: size * 0.2,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPressedContent(double size) {
    final textColor = widget.isLocked ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.9);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner circle for depth
        Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: size * 0.02,
            ),
          ),
        ),
        
        // Text with less pronounced shadow
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Text(
                '${widget.number}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * 0.45,
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