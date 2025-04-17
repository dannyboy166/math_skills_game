// lib/widgets/streak_flame_widget.dart
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 44,
        height: 44,
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

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flame icon
          Icon(
            Icons.local_fire_department,
            color: Colors.deepOrange,
            size: 24,
          ),

          // Streak count
          Positioned(
            bottom: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_currentStreak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
