import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';

class ProgressRepository {
  static const String _keyPrefix = 'level_progress_';

  Future<void> saveLevelComplete(int levelId, int difficulty, int score) async {
    // 1. Save to local cache
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$levelId';
    
    // Get current max unlocked difficulty
    final currentMax = prefs.getInt(key) ?? 1;
    
    // If we completed the current max difficulty, unlock the next one (up to 4 for mastery)
    if (difficulty >= currentMax && currentMax < 4) {
      await prefs.setInt(key, currentMax + 1);
    }

    // 2. Save to backend API
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/api/lesson/complete', data: {
        'level_id': levelId,
        'stars': difficulty,
        'score': score, 
      });
    } catch (e) {
      print('Error saving progress to backend: $e');
    }
  }

  Future<int> getMaxUnlockedDifficulty(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$levelId';
    return prefs.getInt(key) ?? 1; // Default to 1 (Easy unlocked)
  }
}
