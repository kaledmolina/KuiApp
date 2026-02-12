
class User {
  final int id;
  final String name;
  final String email;
  final int lives;
  final int streakCount;
  final int xpTotal;
  final int goldNotes;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.lives = 5,
    this.streakCount = 0,
    this.xpTotal = 0,
    this.goldNotes = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      lives: json['lives'] ?? 5,
      streakCount: json['streak_count'] ?? 0,
      xpTotal: json['xp_total'] ?? 0,
      goldNotes: json['gold_notes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'lives': lives,
      'streak_count': streakCount,
      'xp_total': xpTotal,
      'gold_notes': goldNotes,
    };
  }
}
