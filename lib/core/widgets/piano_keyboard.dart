import 'package:flutter/material.dart';

class PianoKeyboard extends StatefulWidget {
  final List<String> availableNotes;
  final Function(String) onNoteTap;
  final String? correctNote;
  final String? wrongNote;
  final String? targetNote;

  const PianoKeyboard({
    super.key,
    required this.availableNotes,
    required this.onNoteTap,
    this.correctNote,
    this.wrongNote,
    this.targetNote,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  // Track pressed key for animation
  String? _pressedKey;

  void _handleTapDown(String note) {
    setState(() {
      _pressedKey = note;
    });
  }

  void _handleTapUp(String note) {
    setState(() {
      _pressedKey = null;
    });
    widget.onNoteTap(note);
  }

  void _handleTapCancel() {
    setState(() {
      _pressedKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Current Range C4-B4
    final whiteKeys = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4'];
    final blackKeys = ['C#4', 'D#4', null, 'F#4', 'G#4', 'A#4'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / whiteKeys.length;
        final blackKeyWidth = keyWidth * 0.6;
        final height = 200.0;

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
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
                      return SizedBox(width: keyWidth);
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
    bool isPressed = _pressedKey == note;
    bool isCorrect = note == widget.correctNote;
    bool isWrong = note == widget.wrongNote;
    bool isTarget = note == widget.targetNote;

    // Base Color
    Color baseColor = Colors.white;
    if (isCorrect) baseColor = Colors.green.shade100;
    if (isWrong) baseColor = Colors.red.shade100;
    if (isTarget) baseColor = Colors.yellow.shade100;

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(note),
      onTapUp: (_) => _handleTapUp(note),
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: height,
        margin: EdgeInsets.only(
          top: isPressed ? 10 : 0, 
          bottom: isPressed ? 0 : 4, // "Up" state has margin for shadow
        ),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          border: Border.all(color: Colors.grey.shade400, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               baseColor,
               isPressed ? baseColor : baseColor.withOpacity(0.9), // Subtle gradient
               Colors.grey.shade300,
            ],
            stops: const [0.0, 0.8, 1.0],
          ),
          boxShadow: isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 3,
            ),
          ],
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          note,
          style: TextStyle(
            color: Colors.grey.shade700, 
            fontSize: 12, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  Widget _buildBlackKey(String note, double width, double height) {
    bool isPressed = _pressedKey == note;
    bool isCorrect = note == widget.correctNote;
    bool isWrong = note == widget.wrongNote;
    bool isTarget = note == widget.targetNote;

    Color baseColor = const Color(0xFF222222);
    if (isCorrect) baseColor = Colors.green.shade900;
    if (isWrong) baseColor = Colors.red.shade900;
    if (isTarget) baseColor = Colors.amber.shade900;

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(note),
      onTapUp: (_) => _handleTapUp(note),
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: width,
        height: isPressed ? height - 2 : height, // Visual press effect
        transform: Matrix4.translationValues(0, isPressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              baseColor,
              Colors.black,
            ],
          ),
          boxShadow: isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(2, 4),
              blurRadius: 4,
            ),
          ],
          border: Border.all(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}
