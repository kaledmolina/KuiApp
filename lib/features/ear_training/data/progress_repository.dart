import 'package:shared_preferences/shared_preferences.dart';

class ProgressRepository {
  static const String _keyPrefix = 'level_progress_';

  Future<void> saveLevelComplete(int levelId, int difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$levelId';
    
    // Get current max unlocked difficulty
    final currentMax = prefs.getInt(key) ?? 1;
    
    // If we completed the current max difficulty, unlock the next one (up to 3)
    if (difficulty >= currentMax && currentMax < 3) {
      await prefs.setInt(key, currentMax + 1);
    }
  }

  Future<int> getMaxUnlockedDifficulty(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$levelId';
    return prefs.getInt(key) ?? 1; // Default to 1 (Easy unlocked)
  }
}
