class LessonConfig {
  final List<String> notes;
  final String type;

  LessonConfig({required this.notes, required this.type});

  factory LessonConfig.fromJson(dynamic json) {
    if (json is List) {
      return LessonConfig(
        notes: List<String>.from(json),
        type: 'ear_training', // Default for now since seeder only has notes
      );
    }
    return LessonConfig(
      notes: List<String>.from(json['notes'] ?? []),
      type: json['type'] ?? 'unknown',
    );
  }
}

class NoteAudio {
  final String noteName;
  final String octave;
  final String fullName;
  final String filePath;

  NoteAudio({
    required this.noteName,
    required this.octave,
    required this.fullName,
    required this.filePath,
  });

  factory NoteAudio.fromJson(Map<String, dynamic> json) {
    return NoteAudio(
      noteName: json['note_name'],
      octave: json['octave'],
      fullName: json['full_name'],
      filePath: json['file_path'],
    );
  }
}
