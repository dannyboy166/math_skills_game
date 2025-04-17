import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:math_skills_game/services/user_service.dart';
import 'dart:async';

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.deepOrange,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Your Streak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current streak: $_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Longest streak: $_longestStreak ${_longestStreak == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Practice math every day to build your streak! Each day you complete at least one practice session, your streak grows. Miss a day and your streak resets to zero.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep your streak alive to earn special rewards!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepOrange.shade400,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: Colors.deepOrange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
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
      onTap: () => _showStreakInfo(context),
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