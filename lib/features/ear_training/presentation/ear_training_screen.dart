import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../data/lesson_repository.dart';
import '../models/lesson_config.dart';
import '../../auth/models/user_model.dart';

class EarTrainingScreen extends StatefulWidget {
  final LessonRepository repository;

  const EarTrainingScreen({super.key, required this.repository});

  @override
  State<EarTrainingScreen> createState() => _EarTrainingScreenState();
}

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  bool isLoading = true;
  String? error;
  List<NoteAudio> lessonNotes = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  
  // Quiz State
  NoteAudio? targetNote;
  List<NoteAudio> options = [];
  bool? isCorrect;
  String feedback = '';
  
  // Gamification State
  int lives = 5;

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
      // 0. Get User Stats (Lives)
      final userData = await widget.repository.getUser();
      final user = User.fromJson(userData);
      
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
          lives = user.lives;
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
       final path = await widget.repository.downloadAudio(targetNote!.filePath, '${targetNote!.fullName}.webm');
       await _audioPlayer.stop();
       await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
       debugPrint("Error playing sound: $e");
    }
  }

  Future<void> _checkAnswer(NoteAudio selected) async {
    if (isCorrect != null) return; // Prevent double taps during feedback

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
       // Wrong Answer Logic
       setState(() {
         isCorrect = false;
         feedback = 'Wrong!';
         lives--; 
       });
       
       // Deduct life on server (fire and forget or await?)
       // Better to await to ensure sync, but for UX speed fire and forget is okish if UI updates immediately
       // Let's fire and forget for UI responsiveness, but logic depends on local 'lives'
       widget.repository.deductLife().then((success) {
         if (!success) debugPrint("Failed to deduct life on server");
       });

       if (lives <= 0) {
         _showGameOverDialog();
       } else {
         Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
               setState(() {
                  isCorrect = null; // Reset for retry? Or next round?
                  // Usually Duolingo lets you retry or moves on. Let's move to next for flow flow.
                  // Actually, let's just reset state to allow retry if not game over? 
                  // No, Ear Training usually reveals answer. 
                  // Let's reveal answer via text and move on.
                  _startNewRound();
               });
            }
         });
       }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("You ran out of lives! Wait for them to regenerate."),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/home');
            },
            child: const Text("Back to Home"),
          )
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text('Ear Training'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text('$lives', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
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
                     const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
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
                           : (isCorrect == false && opt != targetNote 
                                ? (opt == selectedOption ? Colors.red : null) // Highlight wrong selection? 
                                : Colors.white),
                       foregroundColor: Colors.black,
                     ),
                     onPressed: (isCorrect != null || lives <= 0) ? null : () {
                        // Hack to track selected option for color?
                        // For simplicity passing opt to checkAnswer
                        selectedOption = opt;
                        _checkAnswer(opt);
                     },
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
  
  NoteAudio? selectedOption;
}
