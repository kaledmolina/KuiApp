import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api_client.dart';
import '../../ear_training/data/lesson_repository.dart';

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  bool isPracticing = false;

  Future<void> _doPractice() async {
    setState(() => isPracticing = true);
    
    // Simulate practice delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      final repo = LessonRepository(ApiClient());
      final result = await repo.completePractice();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Practice Complete!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => isPracticing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Mode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Farm XP & Lives',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Practice previously unlocked levels to gain XP and restore lives.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            isPracticing 
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _doPractice,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Practice (Simulate)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
