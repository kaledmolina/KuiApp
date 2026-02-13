import 'package:flutter/material.dart';

class PianoKeyboard extends StatelessWidget {
  final List<String> availableNotes; // Notes to be interactive (or all in range)
  final Function(String) onNoteTap;
  final String? correctNote;
  final String? wrongNote;
  final String? targetNote; // Note to highlight as hint/answer

  const PianoKeyboard({
    super.key,
    required this.availableNotes,
    required this.onNoteTap,
    this.correctNote,
    this.wrongNote,
    this.targetNote,
  });

  @override
  Widget build(BuildContext context) {
    // Determine range based on availableNotes or default C4-B4
    // For simplicity, we hardcode C4-B4 range for now, but valid logic would parse notes
    // Let's assume one octave C4-B4 for Level 1 & 2
    // C4, C#4, D4, D#4, E4, F4, F#4, G4, G#4, A4, A#4, B4

    final whiteKeys = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4'];
    final blackKeys = ['C#4', 'D#4', null, 'F#4', 'G#4', 'A#4']; // null for spacing

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / whiteKeys.length;
        final blackKeyWidth = keyWidth * 0.6;
        final height = 200.0; // Fixed height for piano

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // White Keys
              Row(
                children: whiteKeys.map((note) {
                  return _buildWhiteKey(note, keyWidth, height);
                }).toList(),
              ),
              // Black Keys
              Positioned(
                top: 0,
                left: keyWidth - (blackKeyWidth / 2),
                child: Row(
                  children: blackKeys.map((note) {
                    if (note == null) {
                      return SizedBox(width: keyWidth); // Spacer between E-F and B-C
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBlackKey(note, blackKeyWidth, height * 0.6),
                        SizedBox(width: keyWidth - blackKeyWidth),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhiteKey(String note, double width, double height) {
    Color keyColor = Colors.white;
    if (note == correctNote) keyColor = Colors.green;
    else if (note == wrongNote) keyColor = Colors.red;
    else if (note == targetNote) keyColor = Colors.yellow.shade100; // Hint

    return GestureDetector(
      onTap: () => onNoteTap(note),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: keyColor,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          note, 
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBlackKey(String note, double width, double height) {
    Color keyColor = Colors.black;
    if (note == correctNote) keyColor = Colors.green;
    else if (note == wrongNote) keyColor = Colors.red;
    else if (note == targetNote) keyColor = Colors.yellow.shade700;

    return GestureDetector(
      onTap: () => onNoteTap(note),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: keyColor,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
        ),
      ),
    );
  }
}
