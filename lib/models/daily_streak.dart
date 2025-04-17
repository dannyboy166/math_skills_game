// lib/models/daily_streak.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStreak {
  final DateTime date;
  final bool completed;
  
  // For convenience, store the day of week (0 = Sunday, 1 = Monday, etc.)
  final int dayOfWeek;

  const DailyStreak({
    required this.date,
    required this.completed,
    required this.dayOfWeek,
  });

  // Create from a DateTime, setting completed status
  factory DailyStreak.fromDate(DateTime date, {bool completed = false}) {
    // Normalize the date to midnight to ensure consistent comparisons
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    return DailyStreak(
      date: normalizedDate,
      completed: completed,
      dayOfWeek: normalizedDate.weekday % 7, // Convert to 0-based to match our UI (0 = Sunday)
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'completed': completed,
      'dayOfWeek': dayOfWeek,
    };
  }

  // Create from Firestore document
  factory DailyStreak.fromMap(Map<String, dynamic> map) {
    return DailyStreak(
      date: (map['date'] as Timestamp).toDate(),
      completed: map['completed'] ?? false,
      dayOfWeek: map['dayOfWeek'] ?? 0,
    );
  }

  // Helper to check if this streak is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  // Copy with new values
  DailyStreak copyWith({
    DateTime? date,
    bool? completed,
    int? dayOfWeek,
  }) {
    return DailyStreak(
      date: date ?? this.date,
      completed: completed ?? this.completed,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    );
  }
}

// Helper class to manage weekly streaks
class WeeklyStreak {
  final List<DailyStreak> days;
  
  WeeklyStreak(this.days);
  
  // Initialize an empty week starting from today
  factory WeeklyStreak.currentWeek() {
    final now = DateTime.now();
    final days = <DailyStreak>[];
    
    // Find the start of the week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    // Create streak entries for each day of the week
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      days.add(DailyStreak.fromDate(date));
    }
    
    return WeeklyStreak(days);
  }
  
  // Mark a specific day as completed
  void markDayCompleted(DateTime date, {bool completed = true}) {
    final targetDate = DateTime(date.year, date.month, date.day);
    
    for (int i = 0; i < days.length; i++) {
      final streakDate = days[i].date;
      if (streakDate.year == targetDate.year && 
          streakDate.month == targetDate.month && 
          streakDate.day == targetDate.day) {
        days[i] = days[i].copyWith(completed: completed);
        break;
      }
    }
  }
  
  // Get the streak for a specific day of week (0 = Sunday, 1 = Monday, etc.)
  DailyStreak? getDayStreak(int dayOfWeek) {
    return days.firstWhere(
      (day) => day.dayOfWeek == dayOfWeek,
      orElse: () => DailyStreak.fromDate(
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - dayOfWeek)),
      ),
    );
  }
  
  // Check if today's streak is completed
  bool get isTodayCompleted {
    final now = DateTime.now();
    final todayDayOfWeek = now.weekday % 7; // 0-based day of week
    
    final today = getDayStreak(todayDayOfWeek);
    return today?.completed ?? false;
  }
  
  // Get the current streak length (consecutive days up to today)
  int get currentStreakLength {
    int streak = 0;
    
    // Go backwards from today's weekday
    final now = DateTime.now();
    final todayDayOfWeek = now.weekday % 7; // 0-based 
    
    // Check today first
    if (!isTodayCompleted) {
      return 0; // No streak today
    }
    
    streak = 1; // Today is completed
    
    // Check previous days
    for (int i = 1; i <= 6; i++) {
      final checkDay = (todayDayOfWeek - i + 7) % 7; // Ensure positive index
      final dayStreak = getDayStreak(checkDay);
      
      if (dayStreak?.completed == true) {
        streak++;
      } else {
        break; // Streak ends
      }
    }
    
    return streak;
  }
}