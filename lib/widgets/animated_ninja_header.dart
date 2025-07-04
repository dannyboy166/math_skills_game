// lib/widgets/animated_ninja_header.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedNinjaHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? trailingWidget;

  const AnimatedNinjaHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    this.trailingWidget,
  }) : super(key: key);

  @override
  State<AnimatedNinjaHeader> createState() => _AnimatedNinjaHeaderState();
}

class _AnimatedNinjaHeaderState extends State<AnimatedNinjaHeader>
    with TickerProviderStateMixin {
  late AnimationController _ninjaController;
  late AnimationController _bounceController;
  late Timer _animationTimer;
  int _currentFrame = 0;
  bool _isAttacking = false;

  @override
  void initState() {
    super.initState();

    // Controller for ninja sprite animation
    _ninjaController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    // Controller for bounce effect
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Set to show just the first ninja (static)
    _currentFrame = 0;

    // Start the animation cycle - COMMENTED OUT FOR NOW
    // _startNinjaAnimation();
  }

  void _startNinjaAnimation() {
    // DISABLED - keeping code for later if you want animation back
    /*
    _animationTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % 6; // Cycle through 6 frames
          
          // Trigger attack animation occasionally
          if (_currentFrame == 0 && Random().nextBool()) {
            _triggerAttack();
          }
        });
      }
    });
    */
  }

  void _triggerAttack() {
    setState(() {
      _isAttacking = true;
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isAttacking = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _ninjaController.dispose();
    _bounceController.dispose();
    _animationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade500,
            Colors.blue.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Ninja with fighting sprites
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _isAttacking ? sin(_bounceController.value * pi * 4) * 3 : 0,
                  _isAttacking ? -_bounceController.value * 8 : 0,
                ),
                child: Transform.scale(
                  scale: _isAttacking
                      ? 1.0 + (_bounceController.value * 0.1)
                      : 1.0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.yellow.shade300,
                          Colors.orange.shade400
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isAttacking
                              ? Colors.orange.withOpacity(0.8)
                              : Colors.yellow.withOpacity(0.5),
                          blurRadius: _isAttacking ? 15 : 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildNinjaSprite(),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 16),

          // App title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    // Animated fighting emojis
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Text(
                          _isAttacking ? '⚔️' : '🥷',
                          style: TextStyle(
                            fontSize: _isAttacking ? 22 : 20,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Trailing widget (like streak widget)
          if (widget.trailingWidget != null)
            Stack(
              children: [
                widget.trailingWidget!,
                // Add battle effects when attacking
                if (_isAttacking)
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange
                                  .withOpacity(_bounceController.value),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNinjaSprite() {
    // Calculate sprite position based on current frame
    int row = _currentFrame ~/ 2; // 2 sprites per row
    int col = _currentFrame % 2; // Column (0 or 1)

    // Debug output
    print('🥷 NINJA DEBUG: Frame $_currentFrame, Row $row, Col $col');

    // Scale factor - adjust this to zoom in/out
    double scaleFactor = 0.35; // Smaller value = more zoomed out

    return Container(
      width: 50,
      height: 50,
      child: ClipOval(
        child: Transform.scale(
          scale: scaleFactor,
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment(
              // For a 2x3 grid:
              // Column 0 should be at x = -0.5, Column 1 at x = 0.5
              -0.5 + col * 1.0,
              // Row 0 at y = -0.667, Row 1 at y = 0, Row 2 at y = 0.667
              -0.667 + row * 0.667,
            ),
            child: Image.asset(
              'assets/images/ninja_sprites.png',
              width: 256, // Full sprite sheet width
              height: 384, // Full sprite sheet height
              fit: BoxFit.none, // Don't scale the image
              errorBuilder: (context, error, stackTrace) {
                print('❌ NINJA SPRITE ERROR: $error');
                return Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 28,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced header widget that uses the animated ninja
class EnhancedNinjaHeader extends StatelessWidget {
  final String Function() getHeaderSubtitle;
  final Widget streakWidget;

  const EnhancedNinjaHeader({
    Key? key,
    required this.getHeaderSubtitle,
    required this.streakWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedNinjaHeader(
      title: 'Number Ninja',
      subtitle: getHeaderSubtitle(),
      trailingWidget: streakWidget,
    );
  }
}
