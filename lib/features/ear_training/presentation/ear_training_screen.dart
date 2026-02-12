import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../data/lesson_repository.dart';
import '../models/lesson_config.dart';

class EarTrainingScreen extends StatefulWidget {
  final LessonRepository repository;

  const EarTrainingScreen({super.key, required this.repository});

  @override
  State<EarTrainingScreen> createState() => _EarTrainingScreenState();
}

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  bool isLoading = true;
  String? error;
  List<NoteAudio> lessonNotes = []; // Notes filtered by lesson config
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  
  // Quiz State
  NoteAudio? targetNote;
  List<NoteAudio> options = [];
  bool? isCorrect;
  String feedback = '';

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    try {
      // 1. Get Config for Lesson 1
      final config = await widget.repository.getLessonConfig(1);
      
      // 2. Get Audio Metadata for Octave 4
      final allNotes = await widget.repository.getNoteAudioList(4);
      
      // 3. Filter notes based on config
      lessonNotes = allNotes.where((n) => config.notes.contains(n.fullName)).toList();

      if (lessonNotes.isEmpty) {
        throw Exception("No notes found for this lesson.");
      }

      // 4. Pre-download Audio Files
      for (var note in lessonNotes) {
        await widget.repository.downloadAudio(note.filePath, '${note.fullName}.webm');
      }
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _startNewRound();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  void _startNewRound() {
    if (lessonNotes.isEmpty) return;

    setState(() {
      isCorrect = null;
      feedback = '';
      
      // Pick random target
      targetNote = lessonNotes[_random.nextInt(lessonNotes.length)];
      
      // Pick distractors (ensure unique options)
      final otherNotes = List<NoteAudio>.from(lessonNotes)..remove(targetNote);
      otherNotes.shuffle(_random);
      
      options = [targetNote!, ...otherNotes.take(2)];
      options.shuffle(_random);
    });
    
    _playTargetSound();
  }

  Future<void> _playTargetSound() async {
    if (targetNote == null) return;
    try {
       // Get local path (should be cached already)
       final path = await widget.repository.downloadAudio(targetNote!.filePath, '${targetNote!.fullName}.webm');
       await _audioPlayer.stop();
       await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
       debugPrint("Error playing sound: $e");
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error playing sound: $e')));
    }
  }

  void _checkAnswer(NoteAudio selected) {
    if (selected == targetNote) {
       setState(() {
         isCorrect = true;
         feedback = 'Correct! It was ${targetNote!.fullName}';
       });
       // Auto advance after short delay
       Future.delayed(const Duration(milliseconds: 1500), () {
         if (mounted) _startNewRound();
       });
    } else {
       setState(() {
         isCorrect = false;
         feedback = 'Wrong! Try again.';
       });
       // Replay sound for hint?
       // _playTargetSound(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ear Training: Lesson 1')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Sound Button
             GestureDetector(
               onTap: _playTargetSound,
               child: Container(
                 width: 120,
                 height: 120,
                 decoration: BoxDecoration(
                   color: Colors.blue.shade100,
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                   ]
                 ),
                 child: const Icon(Icons.volume_up_rounded, size: 64, color: Colors.blue),
               ),
             ),
             const SizedBox(height: 20),
             const Text('Listen and identify the note', style: TextStyle(fontSize: 18)),
             const SizedBox(height: 40),
             
             // Options
             if (options.isNotEmpty)
               Wrap(
                 spacing: 20,
                 runSpacing: 20,
                 alignment: WrapAlignment.center,
                 children: options.map((opt) => SizedBox(
                   width: 100,
                   height: 60,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: isCorrect == true && opt == targetNote 
                           ? Colors.green 
                           : (isCorrect == false && opt != targetNote ? null : Colors.white),
                       foregroundColor: Colors.black,
                     ),
                     onPressed: isCorrect == true ? null : () => _checkAnswer(opt),
                     child: Text(opt.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   ),
                 )).toList(),
               ),
               
             const SizedBox(height: 30),
             
             // Feedback
             Text(feedback, style: TextStyle(
               color: isCorrect == true ? Colors.green : Colors.red,
               fontSize: 20,
               fontWeight: FontWeight.bold
             )),
          ],
        ),
      )
    );
  }
}
