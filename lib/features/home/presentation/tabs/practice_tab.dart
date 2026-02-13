import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/api_client.dart';
import '../../../../core/widgets/piano_keyboard.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/lesson_config.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> with TickerProviderStateMixin {
  // Config
  static const int questionsPerRound = 10;
  static const int timePerQuestion = 10; // seconds

  // State
  bool isLoading = true;
  bool isPlaying = false; // Is quiz active?
  bool isProcessing = false; // Processing an answer?
  String? error;
  
  List<NoteAudio> allNotes = [];
  List<NoteAudio> quizQuestions = [];
  int currentIndex = 0;
  int score = 0;
  
  // Timer
  late AnimationController _timerController;
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  // Answer State
  bool? isLastCorrect;
  String? feedbackMessage;
  NoteAudio? currentQuestion;
  String? wrongNotePressed;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: timePerQuestion),
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimeout();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final repo = LessonRepository(ApiClient());
      // Fetch Octave 4 for simple practice
      allNotes = await repo.getNoteAudioList(4);
      
      // Pre-download audio
      List<String> failedRecs = [];
      for (var note in allNotes) {
        try {
          await repo.downloadAudio(note.filePath, '${note.fullName}.webm');
        } catch (e) {
          debugPrint("Failed to download ${note.fullName}: $e");
          failedRecs.add(note.fullName);
        }
      }

      if (mounted) {
        if (failedRecs.isNotEmpty) {
           setState(() {
             isLoading = false;
             error = "Failed to download audio for: ${failedRecs.join(', ')}";
           });
           _showDownloadErrorDialog(failedRecs);
        } else {
           setState(() {
            isLoading = false;
           });
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
        title: const Text("Audio Files Missing"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("The following audio files could not be downloaded:"),
               const SizedBox(height: 10),
               ...failedNotes.map((n) => Text("• $n", style: const TextStyle(color: Colors.red))),
               const SizedBox(height: 10),
               const Text("Please check your internet connection and try again."),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
               context.pop();
               context.go('/home');
            },
            child: const Text("Go Back"),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              setState(() {
                isLoading = true;
                error = null;
              });
              _loadData(); // Retry
            },
            child: const Text("Retry Download"),
          )
        ],
      ),
    );

  void _startQuiz() {
    if (allNotes.isEmpty) return;

    List<NoteAudio> shuffled = List.from(allNotes)..shuffle(_random);
    // Ensure we have enough notes, repeat if necessary
    if (shuffled.length < questionsPerRound) {
      while (shuffled.length < questionsPerRound) {
        shuffled.addAll(allNotes);
      }
      shuffled.shuffle(_random);
    }
    
    setState(() {
      quizQuestions = shuffled.take(questionsPerRound).toList();
      currentIndex = 0;
      score = 0;
      isPlaying = true;
      isProcessing = false;
      isLastCorrect = null;
      feedbackMessage = null;
    });

    _playQuestion();
  }

  Future<void> _playQuestion() async {
    if (currentIndex >= quizQuestions.length) return;

    final question = quizQuestions[currentIndex];
    
    setState(() {
      currentQuestion = question;
      isProcessing = false;
      isLastCorrect = null;
      feedbackMessage = null;
      wrongNotePressed = null;
    });

    _timerController.reset();
    _timerController.forward();

    try {
       final repo = LessonRepository(ApiClient());
       final path = await repo.downloadAudio(question.filePath, '${question.fullName}.webm');
       await _audioPlayer.stop();
       await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
       debugPrint("Error playing audio: $e");
    }
  }

  void _handleTimeout() {
    if (!mounted || !isPlaying || isProcessing) return;
    _submitAnswer(null); // Null means timeout
  }

  void _submitAnswer(String? pressedNote) {
    _timerController.stop();
    setState(() {
      isProcessing = true;
    });

    final correctNote = currentQuestion?.fullName;
    bool correct = pressedNote == correctNote;

    setState(() {
      isLastCorrect = correct;
      wrongNotePressed = correct ? null : pressedNote;
      if (correct) {
        score++;
        feedbackMessage = "Correct!";
      } else {
        feedbackMessage = "Wrong! It was $correctNote";
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (currentIndex < questionsPerRound - 1) {
        setState(() {
           currentIndex++;
        });
        _playQuestion();
      } else {
        _endQuiz();
      }
    });
  }

  Future<void> _endQuiz() async {
    setState(() {
      isPlaying = false;
    });

    // Determine rewards
    // Simple logic: If score > 5, count as practice complete?
    // Or always count it? Let's always count it for now to be generous, 
    // or maybe require at least 50%?
    // Practice is practice. Let's award it.

    bool success = score >= (questionsPerRound / 2); // 50% pass rate?
    
    Map<String, dynamic>? result;
    if (success) {
      try {
        final repo = LessonRepository(ApiClient());
        result = await repo.completePractice();
        
        // Refresh User Stats
        if (mounted) {
           context.read<AuthProvider>().checkAuth();
        }
      } catch (e) {
        debugPrint("Error completing practice: $e");
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(success ? "Practice Complete!" : "Practice Failed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Score: $score / $questionsPerRound"),
              const SizedBox(height: 10),
              if (result != null) ...[
                 Text(result['message'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 if (result['gained_life'] == true)
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite, color: Colors.red), Text(" +1")]),
                 Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star, color: Colors.amber), Text(" +${result['xp_gained']} XP")]),
              ] else if (!success)
                 const Text("You need at least 50% correct to earn rewards. Try again!"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(); // Close dialog
                setState(() {
                   // Reset to start screen
                   isPlaying = false;
                });
              },
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                _startQuiz(); // Retry
              },
              child: const Text("Play Again"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text("Error: $error")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Mode')),
      body: !isPlaying ? _buildStartScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Ear Training Practice',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
           const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Identify 10 random notes. Get >50% correct to farm lives and XP.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Practice'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    return Column(
      children: [
        // Top Bar: Timer & Score
        LinearProgressIndicator(
          value: _timerController.value,
          backgroundColor: Colors.grey[200],
          color: Colors.blue, 
          minHeight: 6,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Question ${currentIndex + 1} / $questionsPerRound", style: const TextStyle(fontSize: 16)),
              Text("Score: $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Listen Button
        GestureDetector(
           onTap: () => _playQuestion(), // Replay
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
         const Text("Tap to Replay Sound", style: TextStyle(color: Colors.grey)),
         
         const Spacer(),
         
         // Feedback
         if (feedbackMessage != null)
           Padding(
             padding: const EdgeInsets.all(8.0),
             child: Text(
               feedbackMessage!,
               style: TextStyle(
                 fontSize: 20, 
                 fontWeight: FontWeight.bold,
                 color: isLastCorrect == true ? Colors.green : Colors.red
               ),
             ),
           ),

         const SizedBox(height: 20),
         
         // Piano
         Padding(
           padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
           child: SizedBox(
             height: 200, // Explicit height for piano
             child: PianoKeyboard(
               availableNotes: allNotes.map((n) => n.fullName).toList(),
               correctNote: isLastCorrect == true ? currentQuestion?.fullName : null,
               targetNote: isLastCorrect != null ? currentQuestion?.fullName : null, // Show target if done
               wrongNote: wrongNotePressed,
               onNoteTap: (note) {
                 if (isProcessing) return;
                 _submitAnswer(note);
               },
             ),
           ),
         ),
      ],
    );
  }
}
