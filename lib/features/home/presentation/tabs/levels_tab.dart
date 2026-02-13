import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
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
  void _showDifficultyDialog(BuildContext context, int levelId) {
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
              _buildDifficultyOption(context, levelId, 1, 'Fácil', '30s, 3 Teclas', 1),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 2, 'Medio', '20s, 5 Teclas', 2),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 3, 'Difícil', '10s, Todas las Teclas', 3),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(BuildContext context, int levelId, int difficulty, String label, String sublabel, int stars) {
    return InkWell(
      onTap: () {
        context.pop(); // Close modal
        context.push('/lesson/$levelId', extra: difficulty);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
             Row(
               children: List.generate(3, (index) => Icon(
                 Icons.star, 
                 color: index < stars ? Colors.amber : Colors.grey.shade300,
                 size: 20,
               )),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text(sublabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                 ],
               ),
             ),
             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
