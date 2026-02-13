class Level {
  final int id;
  final String name;
  final int difficulty;

  Level({
    required this.id,
    required this.name,
    required this.difficulty,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      name: json['name'],
      difficulty: json['difficulty'],
    );
  }
}
