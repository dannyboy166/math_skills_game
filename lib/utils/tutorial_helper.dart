import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static const String _tutorialShownKey = 'math_game_tutorial_shown';
  
  static Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_tutorialShownKey) ?? false);
  }
  
  static Future<void> markTutorialAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, true);
  }
  
  // Optional: Add this method to reset the tutorial for testing
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, false);
  }
}