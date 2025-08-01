// lib/widgets/number_tile.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class NumberTile extends StatefulWidget {
  final int number;
  final Color color;
  final bool isLocked;
  final bool isCorner;
  final bool isGreyedOut;
  final VoidCallback? onTap;
  final double size;
  final double sizeMultiplier;

  const NumberTile({
    Key? key,
    required this.number,
    required this.color,
    this.isLocked = false,
    this.isCorner = false,
    this.isGreyedOut = false,
    this.onTap,
    this.size = 45,
    this.sizeMultiplier = 1.0,
  }) : super(key: key);

  @override
  State<NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<NumberTile>
    with SingleTickerProviderStateMixin {
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
    if (widget.onTap != null) {
      print(
          "DEBUG: TapDown on NumberTile ${widget.number}, isCorner: ${widget.isCorner}");
      setState(() {
        _isPressed = true;
      });
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      print(
          "DEBUG: TapUp on NumberTile ${widget.number}, isCorner: ${widget.isCorner}");
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      print("DEBUG: TapCancel on NumberTile ${widget.number}");
      setState(() {
        _isPressed = false;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the base color - if locked or greyed out, use a gray version
    Color baseColor;
    if (widget.isLocked || widget.isGreyedOut) {
      // Convert to grayscale with reduced opacity
      final grayValue = _getGrayscaleValue(widget.color);
      baseColor = Color.fromRGBO(
          grayValue, grayValue, grayValue, widget.isGreyedOut ? 0.5 : 0.7);
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
      enabled: widget.onTap != null,
      label: "Number ${widget.number} ${widget.isCorner ? 'corner' : ''} tile",
      child: IgnorePointer(
        // Only ignore pointer if locked (greyed out should still be interactive)
        ignoring: widget.isLocked,
        child: GestureDetector(
          onTap: () {
            print(
                "DEBUG: TAPPED on NumberTile ${widget.number}, isCorner: ${widget.isCorner}, isLocked: ${widget.isLocked}");
            if (widget.onTap != null) {
              widget.onTap!();
            }
          },
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior
              .opaque, // Important: Makes the entire area clickable
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPressed ? _scaleAnimation.value : 1.0,
                child: Container(
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
                    boxShadow: (widget.isLocked || widget.isGreyedOut)
                        ? []
                        : [
                            // Outer shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: adjustedSize * 0.1,
                              spreadRadius: adjustedSize * 0.02,
                              offset: Offset(
                                  adjustedSize * 0.04, adjustedSize * 0.04),
                            ),
                            // Inner highlight
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: adjustedSize * 0.1,
                              spreadRadius: adjustedSize * 0.01,
                              offset: Offset(
                                  -adjustedSize * 0.02, -adjustedSize * 0.02),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: _isPressed
                        ? _buildPressedContent(adjustedSize)
                        : _buildNormalContent(adjustedSize),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContent(double size) {
    // Adjust the text color based on locked or greyed out state
    final textColor = (widget.isLocked || widget.isGreyedOut)
        ? Colors.white.withValues(alpha: widget.isGreyedOut ? 0.6 : 0.7)
        : Colors.white;

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
              color: Colors.white.withValues(
                  alpha: (widget.isLocked || widget.isGreyedOut) ? 0.1 : 0.15),
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
                  fontSize: size * 0.55,
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

        // Shine effect (subtle arc at top-left) - only if not locked or greyed out
        if (!widget.isLocked && !widget.isGreyedOut)
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            child: Container(
              width: size * 0.2,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),

        // Add a subtle indicator for corner pieces to make them more visually distinct
        if (widget.isCorner && !widget.isLocked && !widget.isGreyedOut)
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: size * 0.02,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPressedContent(double size) {
    final textColor = (widget.isLocked || widget.isGreyedOut)
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.9);

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
              color: Colors.white.withValues(alpha: 0.1),
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

        // Add a subtle indicator for corner pieces to make them more visually distinct
        if (widget.isCorner)
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: size * 0.015,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to calculate grayscale equivalent
  int _getGrayscaleValue(Color color) {
    return ((0.299 * color.red) + (0.587 * color.green) + (0.114 * color.blue))
        .round();
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
