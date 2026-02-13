import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/piano_keyboard.dart';
import '../../auth/models/user_model.dart';
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
      List<String> failedRecs = [];
      for (var note in lessonNotes) {
        try {
          await widget.repository.downloadAudio(note.filePath, '${note.fullName}.webm');
        } catch (e) {
          debugPrint("Failed to download ${note.fullName}: $e");
          failedRecs.add(note.fullName);
        }
      }
      
      if (mounted) {
        if (failedRecs.isNotEmpty) {
           setState(() {
             isLoading = false;
             // We use 'error' to trigger the error view, but we'll customize it 
             // or we can add a specific state for partial failure.
             // For now, let's use a specific error message format we can parse or just a separate list.
             error = "Falló la descarga de audio para: ${failedRecs.join(', ')}";
           });
           _showDownloadErrorDialog(failedRecs);
        } else {
          setState(() {
            isLoading = false;
            lives = user.lives;
          });

          if (lives <= 0) {
             _showNoLivesDialog();
          } else {
             _startNewRound();
          }
        }
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

  void _showDownloadErrorDialog(List<String> failedNotes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Archivos de Audio Faltantes"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("Los siguientes archivos de audio no se pudieron descargar:"),
               const SizedBox(height: 10),
               ...failedNotes.map((n) => Text("• $n", style: const TextStyle(color: Colors.red))),
               const SizedBox(height: 10),
               const Text("Por favor verifica tu conexión a internet e intenta nuevamente."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
               context.pop();
               context.go('/home');
            },
            child: const Text("Volver"),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              setState(() {
                isLoading = true;
                error = null;
              });
              _loadLesson(); // Retry
            },
            child: const Text("Reintentar Descarga"),
          )
        ],
      ),
    );
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
         feedback = '¡Correcto! Era ${targetNote!.fullName}';
       });
       // Auto advance after short delay
       Future.delayed(const Duration(milliseconds: 1500), () {
         if (mounted) _startNewRound();
       });
    } else {
       // Wrong Answer Logic
       setState(() {
         isCorrect = false;
         feedback = '¡Incorrecto!';
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
        title: const Text("Juego Terminado"),
        content: const Text("¡Te quedaste sin vidas! Espera a que se regeneren."),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/home');
            },
            child: const Text("Volver a Inicio"),
          )
        ],
      ),
    );
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Sin Vidas Restantes"),
        content: const Text("Tienes 0 vidas. ¡Ve al Modo Práctica para ganar más!"),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/home'); // Go to home (Practice tab is there)
            },
            child: const Text("Ir a Práctica"),
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
        title: const Text('Entrenamiento Auditivo'),
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
             
             // Piano Keyboard
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: PianoKeyboard(
                 availableNotes: lessonNotes.map((n) => n.fullName).toList(),
                 correctNote: isCorrect == true ? targetNote?.fullName : null, 
                 targetNote: isCorrect != null ? targetNote?.fullName : null, // Show target when round done
                 wrongNote: isCorrect == false ? selectedOption?.fullName : null,
                 onNoteTap: (note) {
                    if (isCorrect != null || lives <= 0) return;
                    
                    // Find the NoteAudio object for this string
                    try {
                      final selected = lessonNotes.firstWhere((n) => n.fullName == note);
                      selectedOption = selected;
                      _checkAnswer(selected);
                    } catch (e) {
                      // Note not in lesson (e.g. user pressed a key not in the config)
                      // We can ignore or count as wrong.
                      // Let's count as wrong but with specific feedback?
                      // Or just ignore if it's not part of the active notes? 
                      // If it's a piano, usually all keys work. 
                      // But we need the audio file to play it? (Optional, user didn't ask to play sound on touch, but good UX)
                      // If we don't have the audio file downloaded, we can't play it.
                      // lessonNotes only contains downloaded notes.
                      debugPrint("Note $note not in lesson config");
                    }
                 },
               ),
             ),
               
             const SizedBox(height: 30),
             
             // Feedback
             if (feedback.isNotEmpty)
               Container(
                 margin: const EdgeInsets.symmetric(horizontal: 20),
                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                 decoration: BoxDecoration(
                   color: isCorrect == true ? Colors.green.shade100 : Colors.red.shade100,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(
                     color: isCorrect == true ? Colors.green : Colors.red,
                     width: 2
                   )
                 ),
                 child: Text(
                   feedback, 
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 18, 
                     fontWeight: FontWeight.bold,
                     color: isCorrect == true ? Colors.green.shade800 : Colors.red.shade800
                   ),
                 ),
               ),
          ],
        ),
      )
    );
  }
  
  NoteAudio? selectedOption;
}
