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
  Set<String> selectedNotes = {}; // For Custom Learning Mode
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
      
      // Default to picking all notes initially
      selectedNotes = allNotes.map((n) => n.fullName).toSet();

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
             error = "Falló la descarga de audio para: ${failedRecs.join(', ')}";
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
        title: const Text("Archivos de Audio Faltantes"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("Los siguientes archivos no se pudieron descargar:"),
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
              _loadData(); // Retry
            },
            child: const Text("Reintentar"),
          )
        ],
      ),
    );
  }

  void _startQuiz() {
    if (allNotes.isEmpty || selectedNotes.isEmpty) return;

    // Filter notes down to ONLY what the user selected to learn
    List<NoteAudio> activeNotes = allNotes.where((n) => selectedNotes.contains(n.fullName)).toList();

    List<NoteAudio> shuffled = List.from(activeNotes)..shuffle(_random);
    // Ensure we have enough notes, repeat if necessary
    if (shuffled.length < questionsPerRound) {
      while (shuffled.length < questionsPerRound) {
        shuffled.addAll(activeNotes);
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
        feedbackMessage = "¡Correcto!";
      } else {
        feedbackMessage = "¡Incorrecto! Era $correctNote";
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

    // Award rewards based on 50% pass rate
    bool success = score >= (questionsPerRound / 2); 
    
    Map<String, dynamic>? result;
    if (success) {
      try {
        final repo = LessonRepository(ApiClient());
        result = await repo.completePractice();
        
        // Refresh User Stats (Lives, Streak, DB stuff)
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
          title: Text(success ? "¡Entrenamiento Completado!" : "Entrenamiento Fallido"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Puntaje: $score / $questionsPerRound"),
              const SizedBox(height: 10),
              if (result != null) ...[
                 Text(result['message'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 if (result['gained_life'] == true)
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite, color: Colors.red), Text(" +1")]),
                 Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star, color: Colors.amber), Text(" +${result['xp_gained']} XP")]),
                 const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_fire_department_rounded, color: Colors.orange), Text(" Racha Mantenida/Aumentada")]),
              ] else if (!success) ...[
                 const Text("Necesitas al menos el 50% de aciertos para ganar vidas, racha y experiencia. ¡No te rindas!"),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(); // Close dialog
                setState(() {
                   // Reset to start/config screen
                   isPlaying = false;
                });
              },
              child: const Text("Volver a Configuración"),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                _startQuiz(); // Retry with same notes
              },
              child: const Text("Repetir Ejercicio"),
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
      body: !isPlaying ? _buildStartScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildStartScreen() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tune_rounded, size: 60, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Entrenamiento Libre',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecciona las notas específicas que quieres aislar y aprender a escuchar.\n\nElige al menos 2 notas para retar a tu oído.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              // Note selection grid
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: allNotes.map((note) {
                  final isSelected = selectedNotes.contains(note.fullName);
                  return FilterChip(
                    label: Text(note.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedNotes.add(note.fullName);
                        } else {
                          selectedNotes.remove(note.fullName);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Quick Select Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   OutlinedButton(
                     onPressed: () {
                       setState(() => selectedNotes = allNotes.map((n)=>n.fullName).toSet());
                     }, 
                     style: OutlinedButton.styleFrom(
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                     ),
                     child: const Text('Todas')
                   ),
                   const SizedBox(width: 8),
                   OutlinedButton(
                     onPressed: () {
                       setState(() {
                          // Filter to only C D E F G A B (no #'s or b's)
                          selectedNotes = allNotes.where((n) => !n.fullName.contains('#') && !n.fullName.contains('b'))
                                                  .map((n) => n.fullName).toSet();
                       });
                     }, 
                     style: OutlinedButton.styleFrom(
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                     ),
                     child: const Text('Naturales')
                   ),
                   const SizedBox(width: 8),
                   TextButton(
                     onPressed: () {
                       setState(() => selectedNotes.clear());
                     }, 
                     child: const Text('Limpiar', style: TextStyle(color: Colors.red))
                   ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedNotes.isEmpty ? null : _startQuiz,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    selectedNotes.isEmpty ? 'Selecciona notas...' : 'Entrenar Oído', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 80), // Prevent nav bar hiding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    // Determine which notes to draw on the piano perfectly, in order.
    // The piano keyboard uses the order of `availableNotes` to render.
    // We must pass the ordered list of `allNotes` filtered by `selectedNotes`, not a generic Set.
    List<String> orderedActiveNotes = allNotes
        .where((n) => selectedNotes.contains(n.fullName))
        .map((n) => n.fullName)
        .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
            children: [
          // Top Bar: Lesson Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Entrenamiento ${currentIndex + 1} / $questionsPerRound", 
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600]
                      )
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "$score", 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: Colors.amber.shade900
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Custom Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12, // Thicker
                    child: LinearProgressIndicator(
                      value: (currentIndex + 1) / questionsPerRound,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green.shade400, // Duolingo Green
                      minHeight: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Listen Button with Circular Timer
          Stack(
            alignment: Alignment.center,
            children: [
              // Timer Ring
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: 1.0 - _timerController.value, // Countdown visual
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: _timerController.value > 0.7 ? Colors.red : Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              // Button
              GestureDetector(
                 onTap: () => _playQuestion(), // Replay
                 child: Container(
                   width: 120,
                   height: 120,
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.primaryContainer,
                     shape: BoxShape.circle,
                     boxShadow: [
                       const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                     ]
                   ),
                   child: Icon(Icons.volume_up_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                 ),
               ),
            ],
          ),
           const SizedBox(height: 20),
           const Text("Toca para repetir sonido", style: TextStyle(color: Colors.grey)),
           
           const Spacer(),
           
           // Feedback
           if (feedbackMessage != null)
             Container(
               margin: const EdgeInsets.symmetric(horizontal: 20),
               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
               decoration: BoxDecoration(
                 color: isLastCorrect == true ? Colors.green.shade100 : Colors.red.shade100,
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(
                   color: isLastCorrect == true ? Colors.green : Colors.red,
                   width: 2
                 )
               ),
               child: Text(
                 feedbackMessage!,
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 18, 
                   fontWeight: FontWeight.bold,
                   color: isLastCorrect == true ? Colors.green.shade800 : Colors.red.shade800
                 ),
               ),
             ),
  
           const SizedBox(height: 20),
           
           // Piano tailored to specific isolated notes
           Padding(
             padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
             child: SizedBox(
               height: 200, // Explicit height for piano
               child: PianoKeyboard(
                 availableNotes: orderedActiveNotes,
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
           const SizedBox(height: 60), // Space for nav
        ],
      ),
          ),
        ],
      ),
    );
  }
}
