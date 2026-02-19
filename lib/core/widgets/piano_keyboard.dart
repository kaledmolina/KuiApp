import 'package:flutter/material.dart';

class PianoKeyboard extends StatefulWidget {
  final List<String> availableNotes;
  final Function(String) onNoteTap;
  final String? correctNote;
  final String? wrongNote;
  final String? targetNote;
  final List<String>? visibleKeys;

  const PianoKeyboard({
    super.key,
    required this.availableNotes,
    required this.onNoteTap,
    this.correctNote,
    this.wrongNote,
    this.targetNote,
    this.visibleKeys,
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
    int minOctave = 4;
    int maxOctave = 4;
    for (String note in widget.availableNotes) {
      if (note.length >= 2) {
        int? oct = int.tryParse(note.substring(note.length - 1));
        if (oct != null) {
          if (oct < minOctave) minOctave = oct;
          if (oct > maxOctave) maxOctave = oct;
        }
      }
    }

    final whiteKeys = <String>[];
    final blackKeys = <String?>[];

    for (int i = minOctave; i <= maxOctave; i++) {
      whiteKeys.addAll(['C$i', 'D$i', 'E$i', 'F$i', 'G$i', 'A$i', 'B$i']);
      blackKeys.addAll(['C#$i', 'D#$i', null, 'F#$i', 'G#$i', 'A#$i', null]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Let the keys shrink to fit exactly on the screen constraints
        double keyWidth = constraints.maxWidth / whiteKeys.length;
        
        // If there are too many octaves (>2), we could still use scroll, but the user requested 
        // to fit them (specifically 2 octaves) without scrolling.
        final totalWidth = constraints.maxWidth;
        final blackKeyWidth = keyWidth * 0.6;
        final height = 200.0;

        Widget piano = SizedBox(
          width: totalWidth,
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

        return piano;
      },
    );
  }

  Widget _buildWhiteKey(String note, double width, double height) {
    bool isPressed = _pressedKey == note;
    bool isVisible = widget.visibleKeys == null || widget.visibleKeys!.contains(note);
    
    if (!isVisible) {
      return SizedBox(width: width, height: height);
    }

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
    bool isVisible = widget.visibleKeys == null || widget.visibleKeys!.contains(note);
    
    if (!isVisible) {
       // Maintain spacing but don't draw interactions
       // Actually for black keys, if it's not visible, we might just want to return an empty sized box 
       // but strictly speaking the 'row' layout expects a specific width?
       // The parent 'Stack' -> 'Row' structure for black keys uses specific spacing.
       // _buildBlackKey is called inside a Row with a SizedBox spacer. 
       // If we return a SizedBox(width: width), it maintains the layout.
       return SizedBox(width: width, height: height);
    }

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
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          note,
          style: const TextStyle(
            color: Colors.white70, 
            fontSize: 10, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
