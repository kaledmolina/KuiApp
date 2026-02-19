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
        borderRadius: BorderRadius.circular(24), // rounded-2xl
        boxShadow: unit.isLocked ? [] : [
          const BoxShadow(
            color: Color(0xFF3700B3), // solid-primary
            offset: Offset(0, 6),
            blurRadius: 0, 
          )
        ],
        border: unit.isLocked ? Border.all(color: Colors.grey.shade300, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
           // Decoration
           if (!unit.isLocked)
            Positioned(
              bottom: -20,
              left: -10,
              child: Transform.rotate(
                angle: 0.2, // ~12 deg
                child: Text(
                  '♪',
                  style: TextStyle(
                    fontSize: 80,
                    color: Colors.white.withOpacity(0.1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

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
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)
                 ),
                 child: Icon(
                    Icons.menu_book,
                    color: unit.isLocked ? Colors.grey[500] : Colors.white,
                    size: 28,
                 )
              )
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
    // Determining status mock (Active vs Completed vs Locked)
    // For now assuming all Active for demo, but applying styles based on hypothetical state
    // Let's make Level 1 Completed, Level 2 Active, Level 3 Locked
    
    LevelStatus status = LevelStatus.active;
    if (level.name.contains('Nivel 1')) status = LevelStatus.completed;
    if (level.name.contains('Nivel 3')) status = LevelStatus.locked;
    
    final bool isCompleted = status == LevelStatus.completed;
    final bool isActive = status == LevelStatus.active;
    final bool isLocked = status == LevelStatus.locked;
    
    // HTML Styles Mapped
    // Active: border-primary (6200EA), shadow-solid-primary (3700B3)
    // Completed: border-secondary (00E676), shadow-solid-secondary (00A854)
    // Locked: bg-gray-100, border-gray-200, opacity-70
    
    final Color borderColor = isLocked ? const Color(0xFFE5E7EB) : (isActive ? const Color(0xFF6200EA) : const Color(0xFF00E676));
    final Color? shadowColor = isLocked ? null : (isActive ? const Color(0xFF3700B3) : const Color(0xFF00A854));
    final Color bgColor = isLocked ? const Color(0xFFF3F4F6) : Colors.white;
    final Color iconBg = isLocked ? const Color(0xFFE5E7EB) : (isActive ? const Color(0xFF6200EA) : const Color(0xFF00E676));
    final Color iconColor = isLocked ? Colors.grey : Colors.white;
    final IconData icon = isActive ? Icons.music_note : (isCompleted ? Icons.check : Icons.lock);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: shadowColor != null ? [
               BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 6), // solid-primary/secondary
                  blurRadius: 0
               )
            ] : [],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  // HTML has shadow-solid-secondary/primary on the CIRCLE too for completed/active
                  boxShadow: shadowColor != null ? [
                     BoxShadow(
                        color: shadowColor,
                        offset: const Offset(0, 2), // slightly smaller for icon
                        blurRadius: 0
                     )
                  ] : []
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name, // e.g. "Nivel 1: Teclas Blancas"
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, // font-extrabold
                        fontSize: 16,
                        color: isLocked ? Colors.grey[400] : Colors.grey[900],
                      ),
                    ),
                    if (isCompleted)
                       Row(
                          children: List.generate(3, (index) => const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 18))
                       ),
                    if (isActive)
                       Padding(
                         padding: const EdgeInsets.only(top: 2.0),
                         child: Text(
                           '¡EN CURSO!',
                           style: GoogleFonts.nunito(
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                             color: const Color(0xFF6200EA), // text-primary
                             letterSpacing: -0.5 // tracking-tight
                           ),
                         ),
                       )
                  ],
                ),
              ),
              
              // Tag for Active
              if (isActive)
                 Container(
                    transform: Matrix4.translationValues(8, -24, 0), // Absolute positioning hack
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                       color: const Color(0xFFB388FF), // Primary Light
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.white, width: 2)
                    ),
                    child: Text(
                       'PRÓXIMO',
                       style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3700B3) // Primary Dark
                       ),
                    ),
                 )
            ],
          ),
        ),
      ),
    );
  }
}
