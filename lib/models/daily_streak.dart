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
    
    // FIXED: Consistent day of week calculation (Sunday = 0)
    int dayOfWeek = normalizedDate.weekday == 7 ? 0 : normalizedDate.weekday;
    
    return DailyStreak(
      date: normalizedDate,
      completed: completed,
      dayOfWeek: dayOfWeek,
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
    final date = (map['date'] as Timestamp).toDate();
    // Ensure consistent day of week calculation when reading from Firestore
    int dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
    
    return DailyStreak(
      date: date,
      completed: map['completed'] ?? false,
      dayOfWeek: dayOfWeek, // Use calculated value, not stored value for consistency
    );
  }

  // Helper to check if this streak is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
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
  
  // FIXED: Initialize an empty week starting from Sunday of current week
  factory WeeklyStreak.currentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DailyStreak>[];
    
    // Find the start of the week (Sunday) - FIXED calculation
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday; // Sunday = 0
    final startOfWeek = today.subtract(Duration(days: todayWeekday));
    
    // Create streak entries for each day of the week (Sunday to Saturday)
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
    if (dayOfWeek < 0 || dayOfWeek > 6) return null;
    
    for (final day in days) {
      if (day.dayOfWeek == dayOfWeek) {
        return day;
      }
    }
    
    // If not found, create a default one (shouldn't happen with proper initialization)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday;
    final targetDate = today.subtract(Duration(days: todayWeekday - dayOfWeek));
    
    return DailyStreak.fromDate(targetDate);
  }
  
  // Check if today's streak is completed
  bool get isTodayCompleted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayOfWeek = today.weekday == 7 ? 0 : today.weekday; // Sunday = 0
    
    final todayStreak = getDayStreak(todayDayOfWeek);
    return todayStreak?.completed ?? false;
  }
  
  // FIXED: Get the current streak length (consecutive days up to today)
  int get currentStreakLength {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayOfWeek = today.weekday == 7 ? 0 : today.weekday;
    
    // Check if today is completed first
    if (!isTodayCompleted) {
      return 0; // No streak if today isn't completed
    }
    
    int streak = 1; // Today is completed
    
    // Check previous days in reverse order
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
  
  // Helper method to get today's day of week index
  static int getTodayDayOfWeek() {
    final now = DateTime.now();
    return now.weekday == 7 ? 0 : now.weekday; // Sunday = 0
  }
}