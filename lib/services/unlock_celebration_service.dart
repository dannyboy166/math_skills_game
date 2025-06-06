// lib/services/unlock_celebration_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:math_skills_game/services/haptic_service.dart';
import 'package:math_skills_game/services/sound_service.dart';

class UnlockCelebrationService {
  static final UnlockCelebrationService _instance = UnlockCelebrationService._internal();
  factory UnlockCelebrationService() => _instance;
  UnlockCelebrationService._internal();

  final HapticService _hapticService = HapticService();
  final SoundService _soundService = SoundService();

  // Show celebration for unlocking new tables
  Future<void> showUnlockCelebration(
    BuildContext context, 
    List<int> newlyUnlockedTables,
  ) async {
    if (newlyUnlockedTables.isEmpty) return;

    // Play celebration sound and haptic feedback
    _soundService.playCelebrationByStar(3); // Use 3-star sound for excitement
    _hapticService.heavyImpact(); // Strong vibration for celebration

    // Show the celebration dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _UnlockCelebrationDialog(
          unlockedTables: newlyUnlockedTables,
        );
      },
    );
  }
}

class _UnlockCelebrationDialog extends StatefulWidget {
  final List<int> unlockedTables;

  const _UnlockCelebrationDialog({
    required this.unlockedTables,
  });

  @override
  _UnlockCelebrationDialogState createState() => _UnlockCelebrationDialogState();
}

class _UnlockCelebrationDialogState extends State<_UnlockCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _sparkleController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation for the main content
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Sparkle animation for background effects
    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _bounceController.forward();
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                    Colors.green.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.5),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Sparkle effects
                  _buildSparkleEffects(),
                  
                  // Main content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Celebration icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.celebration,
                          size: 40,
                          color: Colors.orange,
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Celebration text
                      Text(
                        '🎉 AWESOME! 🎉',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text(
                        'You unlocked new tables!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Show unlocked tables
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'New Times Tables:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.unlockedTables.map((table) {
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade300, Colors.orange.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${table}× Table',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Continue button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.purple.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rocket_launch, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Let\'s Practice!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSparkleEffects() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Rotating sparkles
            ...List.generate(8, (index) {
              final angle = (index * 45.0) + (_sparkleAnimation.value * 360);
              final radius = 60.0;
              final x = radius * cos(angle * pi / 180);
              final y = radius * sin(angle * pi / 180);
              
              return Positioned(
                left: 150 + x,
                top: 100 + y,
                child: Transform.rotate(
                  angle: _sparkleAnimation.value * 2 * pi,
                  child: Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}