class Level {
  final int id;
  final String name;
  final int difficulty;
  final int maxUnlockedDifficulty; // 1 = Easy (default), 2 = Medium, 3 = Hard, 4 = Mastered

  Level({
    required this.id,
    required this.name,
    required this.difficulty,
    this.maxUnlockedDifficulty = 1,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    int maxUnlocked = 1;
    if (json['user_progress'] != null && json['user_progress'].isNotEmpty) {
      // Get the first progress record (since we filter by user in backend, there should be at most one)
      final progress = json['user_progress'][0];
      final stars = progress['stars'] ?? 0;
      // If a level is passed (at least 1 star), next difficulty is unlocked. stars + 1.
      // So 0 stars -> diff 1 (Easy) is unlocked
      // 1 star -> diff 2 (Medium) is unlocked
      // 2 stars -> diff 3 (Hard) is unlocked
      // 3 stars -> diff 4 (All completed/mastered)
      maxUnlocked = stars + 1;
    }

    return Level(
      id: json['id'],
      name: json['name'],
      difficulty: json['difficulty'],
      maxUnlockedDifficulty: maxUnlocked,
    );
  }
}
