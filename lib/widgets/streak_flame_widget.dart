import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:number_ninja/services/user_service.dart';
import 'package:number_ninja/services/haptic_service.dart';

class StreakFlameWidget extends StatefulWidget {
  const StreakFlameWidget({Key? key}) : super(key: key);

  @override
  State<StreakFlameWidget> createState() => _StreakFlameWidgetState();
}

class _StreakFlameWidgetState extends State<StreakFlameWidget> {
  int _currentStreak = 0;
  int _longestStreak = 0;
  bool _isLoading = true;
  StreamSubscription? _streakSubscription;
  final UserService _userService = UserService();
  final HapticService _hapticService = HapticService();

  @override
  void initState() {
    super.initState();
    _subscribeToStreakData();
  }

  @override
  void dispose() {
    _streakSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToStreakData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _streakSubscription =
          _userService.streakStatsStream(userId).listen((streakData) {
        if (mounted) {
          setState(() {
            _currentStreak = streakData['currentStreak'] ?? 0;
            _longestStreak = streakData['longestStreak'] ?? 0;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        print('Error in streak stream: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showStreakInfo(BuildContext context) {
    _hapticService.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade300,
                  Colors.deepOrange.shade400,
                  Colors.red.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated fire emoji or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 16),

                // Main streak title
                Text(
                  _currentStreak == 0
                      ? "Start Your Streak!"
                      : _currentStreak == 1
                          ? "🔥 1 Day Streak!"
                          : "🔥 $_currentStreak Day Streak!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Streak visualization with circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    math.min(_currentStreak, 7), // Show max 7 flames
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade300,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_currentStreak > 7) ...[
                  SizedBox(height: 8),
                  Text(
                    "And ${_currentStreak - 7} more! 🎉",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow.shade200,
                    ),
                  ),
                ],

                SizedBox(height: 20),

                // Personal best section
                if (_longestStreak > _currentStreak) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.yellow.shade200,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Personal Best: $_longestStreak days",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Motivational message
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getMotivationalMessage(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _getStreakTip(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Action button
                ElevatedButton(
                  onPressed: () {
                    _hapticService.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _currentStreak == 0 ? "Let's Start!" : "Keep Going! 🚀",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMotivationalMessage() {
    if (_currentStreak == 0) {
      return "Practice today to start your streak! 🌟";
    } else if (_currentStreak == 1) {
      return "Great start! Come back tomorrow! 🎯";
    } else if (_currentStreak < 7) {
      return "You're on fire! Keep it up! 🔥";
    } else if (_currentStreak < 30) {
      return "Amazing streak! You're a math champion! 🏆";
    } else {
      return "Incredible! You're a math legend! 👑";
    }
  }

  String _getStreakTip() {
    if (_currentStreak == 0) {
      return "Complete one game to start your streak";
    } else if (_currentStreak < 3) {
      return "Practice daily to keep your streak alive";
    } else if (_currentStreak < 7) {
      return "You're building a great habit!";
    } else {
      return "Daily practice makes you stronger!";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      );
    }

    // Create an interactive streak indicator
    return GestureDetector(
      onTap: () {
        _hapticService.lightImpact();
        _showStreakInfo(context);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle with gradient background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade300,
                  Colors.deepOrange.shade400,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // Flame icon
          Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 28,
          ),

          // Streak count in a small bubble on top right corner
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.deepOrange.shade400,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_currentStreak',
                  style: TextStyle(
                    color: Colors.deepOrange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
