import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

// --- Models for UI ---
enum LevelStatus { completed, active, locked }

class Unit {
  final int number;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLocked;
  final List<Level> levels;

  Unit({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLocked = false,
    required this.levels,
  });
}

// --- Main Tab ---

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
    final repository = LessonRepository(ApiClient());
    _levelsFuture = repository.getLevels();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from Design
    final bgColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF121212) 
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
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
          // Group levels into Units (e.g., 5 levels per unit)
          final units = _groupLevelsIntoUnits(levels);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
            child: Column(
              children: units.map((unit) => _UnitSection(
                unit: unit,
                onLevelTap: (level) => _showDifficultyDialog(context, level.id),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
  
  List<Unit> _groupLevelsIntoUnits(List<Level> levels) {
    final List<Unit> units = [];
    int chunkSize = 5;
    
    // Define Unit Themes
    final themes = [
      {'title': 'Introducción al Oído', 'color': const Color(0xFF6200EA)},
      {'title': 'Armonía y Acordes', 'color': const Color(0xFF00E676)}, // Greenish for variety
      {'title': 'Lectura Avanzada', 'color': const Color(0xFFFFD600)}, // Amber
    ];

    for (var i = 0; i < levels.length; i += chunkSize) {
      final chunk = levels.skip(i).take(chunkSize).toList();
      final unitIndex = i ~/ chunkSize;
      final theme = themes[unitIndex % themes.length];
      
      units.add(Unit(
        number: unitIndex + 1,
        title: theme['title'] as String,
        subtitle: 'Unidad ${unitIndex + 1}',
        color: theme['color'] as Color,
        levels: chunk,
        isLocked: false, // For now, assuming units are unlocked or logic is handled elsewhere
      ));
    }
    return units;
  }

  void _showDifficultyDialog(BuildContext context, int levelId) async {
    // Fetch unlocked difficulty
    final progressRepo = ProgressRepository();
    final maxUnlocked = await progressRepo.getMaxUnlockedDifficulty(levelId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Selecciona la Dificultad',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildDifficultyOption(context, levelId, 1, 'Fácil', '10 Preguntas, 30s', 1, maxUnlocked >= 1, Colors.green),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 2, 'Medio', '15 Preguntas, 20s', 2, maxUnlocked >= 2, Colors.orange),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 3, 'Difícil', '20 Preguntas, 10s', 3, maxUnlocked >= 3, Colors.red),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(BuildContext context, int levelId, int difficulty, String label, String sublabel, int stars, bool unlocked, Color color) {
    return InkWell(
      onTap: unlocked ? () {
        context.pop(); // Close modal
        context.push('/lesson/$levelId', extra: difficulty);
      } : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: unlocked ? color.withOpacity(0.3) : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: unlocked ? color.withOpacity(0.05) : Colors.grey.shade50,
        ),
        child: Row(
          children: [
             Container(
               width: 48,
               height: 48,
               decoration: BoxDecoration(
                 color: unlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
                 shape: BoxShape.circle,
               ),
               child: Icon(
                 unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                 color: unlocked ? color : Colors.grey.shade400,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18, color: unlocked ? Colors.black87 : Colors.grey)),
                   Text(sublabel, style: GoogleFonts.nunito(color: unlocked ? Colors.grey.shade600 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                 ],
               ),
             ),
             if (unlocked)
               Icon(Icons.arrow_forward_ios_rounded, size: 20, color: color)
          ],
        ),
      ),
    );
  }
}

// --- Component Widgets ---

class _UnitSection extends StatelessWidget {
  final Unit unit;
  final Function(Level) onLevelTap;

  const _UnitSection({required this.unit, required this.onLevelTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unit.isLocked ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Header
            _UnitHeader(unit: unit),
            
            // Levels List (if unlocked)
            if (!unit.isLocked) ...[
              const SizedBox(height: 16),
              ...unit.levels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LevelCard(level: level, onTap: () => onLevelTap(level)),
              )),
            ],
          ],
        ),
      ),
    );
  }
}


class _UnitHeader extends StatelessWidget {
  final Unit unit;

  const _UnitHeader({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: unit.isLocked ? Colors.grey[200] : unit.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: unit.isLocked ? [] : [
          BoxShadow(
            color: unit.color.withOpacity(0.4),
            offset: const Offset(0, 8),
            blurRadius: 12, 
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.subtitle.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: unit.isLocked ? Colors.grey[500] : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unit.title,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: unit.isLocked ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                ],
              ),
              Icon(
                unit.isLocked ? Icons.lock : Icons.menu_book,
                color: unit.isLocked ? Colors.grey[500] : Colors.white.withOpacity(0.9),
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Level level;
  final VoidCallback onTap;

  const _LevelCard({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Visual Mocking for now as we don't have level status in the model yet
    // Assuming mostly active for demo purposes, or we could fetch status async too
    // For now, let's make them all "Active" style to be safe, or just standard.
    
    // Using the 'Active' style from design as default for fetched levels
    final bool isActive = true; 

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6200EA), width: 2), // Primary Border
            boxShadow: const [
               BoxShadow(
                  color: Color(0xFF3700B3), // Primary Dark Shadow
                  offset: Offset(0, 6),
                  blurRadius: 0
               )
            ]
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Leading Icon Circle
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF6200EA),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.name,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.grey[900],
                    ),
                  ),
                   Text(
                     'DIFICULTAD: ${level.difficulty}', // Showing original difficulty info
                     style: GoogleFonts.nunito(
                       color: const Color(0xFF6200EA),
                       fontWeight: FontWeight.bold,
                       fontSize: 12,
                       letterSpacing: 0.5
                     ),
                   ),
                ],
              ),
            ),

            Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               decoration: BoxDecoration(
                  color: const Color(0xFFB388FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
               ),
               child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF6200EA)),
            )
          ],
        ),
      ),
    );
  }
}
