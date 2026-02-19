import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

// --- Models for UI ---
// --- Models for UI ---
class LevelWithProgress {
  final Level level;
  final int unlockedDifficulty;

  LevelWithProgress(this.level, this.unlockedDifficulty);
  
  // 1 Unlocked -> 0 stars (Haven't passed easy)
  // 2 Unlocked -> 1 star (Passed easy)
  // 3 Unlocked -> 2 stars (Passed medium)
  // 4 Unlocked -> 3 stars (Passed hard)
  int get stars => (unlockedDifficulty - 1).clamp(0, 3);
}

enum LevelStatus { completed, active, locked }

class Unit {
  final int number;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLocked;
  final List<LevelWithProgress> levels;

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
  late Future<List<LevelWithProgress>> _levelsFuture;

  @override
  void initState() {
    super.initState();
    _levelsFuture = _fetchLevelsWithProgress();
  }
  
  Future<List<LevelWithProgress>> _fetchLevelsWithProgress() async {
    final repository = LessonRepository(ApiClient());
    final progressRepo = ProgressRepository();
    
    try {
      final levels = await repository.getLevels();
      final futures = levels.map((level) async {
        final unlocked = await progressRepo.getMaxUnlockedDifficulty(level.id);
        return LevelWithProgress(level, unlocked);
      });
      return Future.wait(futures);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors from Design
    final bgColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF121212) 
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<List<LevelWithProgress>>(
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
          final units = _groupLevelsIntoUnits(levels);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
            child: Column(
              children: units.map((unit) => _UnitSection(
                unit: unit,
                onLevelTap: (levelWP) => _showDifficultyDialog(context, levelWP.level.id),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
  
  List<Unit> _groupLevelsIntoUnits(List<LevelWithProgress> levels) {
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
        isLocked: false,
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
      isScrollControlled: true, // Allow modal to be taller and responsive
      backgroundColor: Colors.transparent, // Use child container for styling
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
             maxHeight: MediaQuery.of(context).size.height * 0.85 // Max 85% height
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
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
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                // Responsive Columns if wide, Stack if narrow? For now standard list is fine for mobile.
                Column(
                   children: [
                      _buildDifficultyOption(context, levelId, 1, 'Fácil', '10 Preguntas, 30s', 1, maxUnlocked >= 1, Colors.green),
                      const SizedBox(height: 12),
                      _buildDifficultyOption(context, levelId, 2, 'Medio', '15 Preguntas, 20s', 2, maxUnlocked >= 2, Colors.orange),
                      const SizedBox(height: 12),
                      _buildDifficultyOption(context, levelId, 3, 'Difícil', '20 Preguntas, 10s', 3, maxUnlocked >= 3, Colors.red),
                   ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyOption(BuildContext context, int levelId, int difficulty, String label, String sublabel, int stars, bool unlocked, Color color) {
    return InkWell(
      onTap: unlocked ? () {
        context.pop(); // Close modal
        context.push('/lesson/$levelId', extra: difficulty).then((_) {
           setState(() {
              _levelsFuture = _fetchLevelsWithProgress();
           });
        });
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
  final Function(LevelWithProgress) onLevelTap;

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
              ...unit.levels.map((levelWP) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LevelCard(levelWP: levelWP, onTap: () => onLevelTap(levelWP)),
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
  final LevelWithProgress levelWP;
  final VoidCallback onTap;

  const _LevelCard({required this.levelWP, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Logic:
    // Completed (3 stars) -> Green Styling (HTML Level 1)
    // Active (< 3 stars) -> Purple Styling (HTML Level 2)
    // Locked -> Gray Styling (HTML Level 3) - For now assuming all fetched are unlocked in unit context
    
    final level = levelWP.level;
    final int stars = levelWP.stars;
    
    final bool isCompleted = stars == 3;
    final bool isActive = !isCompleted; 
    final bool isLocked = false; 
    
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
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
                          level.name, 
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isLocked ? Colors.grey[400] : Colors.grey[900],
                          ),
                        ),
                        if (stars > 0)
                           // Show Stars if any progress
                           Row(
                              children: List.generate(3, (index) => Icon(
                                 index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                 color: const Color(0xFFFFD600), // accent
                                 size: 18)
                              )
                           )
                        else
                           // Show "¡En curso!" text like HTML Level 2 if new/active
                           Padding(
                             padding: const EdgeInsets.only(top: 2.0),
                             child: Text(
                               '¡En curso!',
                               style: GoogleFonts.nunito(
                                 fontSize: 12,
                                 fontWeight: FontWeight.bold,
                                 color: const Color(0xFF6200EA), 
                                 letterSpacing: -0.5,
                                 textBaseline: TextBaseline.alphabetic
                               ),
                             ),
                           )
                      ],
                    ),
                  ),
                ],
              ),
              
              // "PRÓXIMO" Tag (Absolute Position like HTML)
              if (isActive)
                 Positioned(
                    top: -24, // -top-2 in HTML relative to button padding? No, here relative to Stack
                    right: -8,
                    child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                          color: const Color(0xFFB388FF), // primary-light
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2)
                       ),
                       child: Text(
                          'PRÓXIMO',
                          style: GoogleFonts.nunito(
                             fontSize: 10,
                             fontWeight: FontWeight.w900,
                             color: const Color(0xFF3700B3) // primary-dark
                          ),
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
