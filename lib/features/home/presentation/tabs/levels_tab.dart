import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

class LevelsTab extends StatefulWidget {
  const LevelsTab({super.key});

  @override
  State<LevelsTab> createState() => _LevelsTabState();
}

class _LevelsTabState extends State<LevelsTab> {
  late Future<List<Level>> _levelsFuture;

  @override
  void initState() {
    super.initState();
    // Simple DI mechanism for now - ideally use Provider
    final repository = LessonRepository(ApiClient());
    _levelsFuture = repository.getLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar removed to use main scaffold AppBar
      body: FutureBuilder<List<Level>>(
        future: _levelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron niveles.'));
          }

          final levels = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text('${level.id}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(level.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('Dificultad: ${level.difficulty}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showDifficultyDialog(context, level.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _showDifficultyDialog(BuildContext context, int levelId) async {
    // Fetch unlocked difficulty
    final progressRepo = ProgressRepository();
    final maxUnlocked = await progressRepo.getMaxUnlockedDifficulty(levelId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona la Dificultad',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDifficultyOption(context, levelId, 1, 'Fácil', '10 Preguntas, 30s', 1, maxUnlocked >= 1),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 2, 'Medio', '15 Preguntas, 20s', 2, maxUnlocked >= 2),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 3, 'Difícil', '20 Preguntas, 10s', 3, maxUnlocked >= 3),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(BuildContext context, int levelId, int difficulty, String label, String sublabel, int stars, bool unlocked) {
    return InkWell(
      onTap: unlocked ? () {
        context.pop(); // Close modal
        context.push('/lesson/$levelId', extra: difficulty);
      } : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: unlocked ? Colors.grey.shade300 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: unlocked ? null : Colors.grey.shade100,
        ),
        child: Row(
          children: [
             Row(
               children: List.generate(3, (index) => Icon(
                 Icons.star, 
                 color: unlocked ? (index < stars ? Colors.amber : Colors.grey.shade300) : Colors.grey,
                 size: 20,
               )),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: unlocked ? Colors.black : Colors.grey)),
                   Text(sublabel, style: TextStyle(color: unlocked ? Colors.grey.shade600 : Colors.grey, fontSize: 13)),
                 ],
               ),
             ),
             if (unlocked)
               Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400)
             else
               const Icon(Icons.lock, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
