import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

// --- Theme Constants ---
const Color kPrimary = Color(0xFF7C3AED); // Vibrant Purple
const Color kPrimaryDark = Color(0xFF5B21B6);
const Color kPrimaryLight = Color(0xFF8B5CF6);
const Color kSecondary = Color(0xFFFBBF24); // Gold
const Color kAccentGreen = Color(0xFF58CC02);
const Color kBackgroundLight = Color(0xFFF3F4F6);
const Color kBackgroundDark = Color(0xFF111827);

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
        ? kBackgroundDark 
        : kBackgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<List<Level>>(
        future: _levelsFuture,
        builder: (context, snapshot) {
           // Loading / Error handled gracefully with simple center widgets if needed, 
           // but for slick UI we might want skeletons. For now keeping simple.
           if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimary));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron niveles.'));
          }

          final levels = snapshot.data!;
          final units = _groupLevelsIntoUnits(levels);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _EliteHeader(),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 24, 0, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final unit = units[index];
                      return _UnitSection(
                        unit: unit,
                        onLevelTap: (level) => _showDifficultyDialog(context, level.id),
                      );
                    },
                    childCount: units.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  List<Unit> _groupLevelsIntoUnits(List<Level> levels) {
    final List<Unit> units = [];
    int chunkSize = 5;
    
    // Define Unit Themes using new Palette
    final themes = [
      {'title': 'Introducción al Oído', 'color': kPrimary},
      {'title': 'Armonía y Acordes', 'color': kAccentGreen}, 
      {'title': 'Lectura Avanzada', 'color': kSecondary}, 
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              _buildDifficultyOption(context, levelId, 1, 'Fácil', '10 Preguntas, 30s', 1, maxUnlocked >= 1, kAccentGreen),
              const SizedBox(height: 12),
              _buildDifficultyOption(context, levelId, 2, 'Medio', '15 Preguntas, 20s', 2, maxUnlocked >= 2, kSecondary),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: unlocked ? color.withOpacity(0.3) : Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(20),
          color: unlocked ? color.withOpacity(0.05) : Colors.grey.shade50,
        ),
        child: Row(
          children: [
             Container(
               width: 50,
               height: 50,
               decoration: BoxDecoration(
                 color: unlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
                 shape: BoxShape.circle,
               ),
               child: Icon(
                 unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                 color: unlocked ? color : Colors.grey.shade400,
                 size: 24,
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

class _EliteHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryDark,
            offset: Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kui',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  _StatBadge(icon: Icons.local_fire_department, value: '3', color: kSecondary),
                  const SizedBox(width: 8),
                  _StatBadge(icon: Icons.bolt, value: '450', color: Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () {},
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          // League Info
          Text(
            'Liga Diamante',
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(offset: const Offset(0, 2), blurRadius: 4, color: Colors.black.withOpacity(0.2))
              ]
            ),
          ),
          Text(
            'Top 5 avanzan a la siguiente liga',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          // Trophy Placeholder
          Container(
             width: 120,
             height: 120,
             decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                   colors: [Color(0xFFFDE68A), Colors.transparent], 
                   center: Alignment.center,
                   radius: 0.5,
                )
             ),
             child: const Icon(LineIcons.trophy, size: 80, color: kSecondary),
          )
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSection extends StatelessWidget {
  final Unit unit;
  final Function(Level) onLevelTap;

  const _UnitSection({required this.unit, required this.onLevelTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unit.isLocked ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            // Header
            _UnitHeader(unit: unit),
            
            // Levels List (if unlocked)
            if (!unit.isLocked) ...[
              const SizedBox(height: 16),
              ...unit.levels.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LevelCard(level: level, unitColor: unit.color, onTap: () => onLevelTap(level)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: unit.isLocked ? Colors.grey[200] : unit.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: unit.isLocked ? [] : [
          BoxShadow(
            color: unit.color,
            offset: const Offset(0, 6),
            blurRadius: 0, 
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
                     'UNIDAD ${unit.number}',
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
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: unit.isLocked ? Colors.grey[600] : Colors.white,
                    ),
                  ),
                ],
              ),
              if (!unit.isLocked)
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)
                   ),
                   child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
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
  final Color unitColor;

  const _LevelCard({required this.level, required this.onTap, required this.unitColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: unitColor, width: 2), // Themed Border
            boxShadow: [
               BoxShadow(
                  color: unitColor, 
                  offset: const Offset(0, 5),
                  blurRadius: 0
               )
            ]
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Leading Icon Circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unitColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.music_note_rounded, color: Colors.white, size: 28),
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
                      fontSize: 18,
                      color: Colors.grey[900],
                    ),
                  ),
                   const SizedBox(height: 4),
                   Row(
                     children: [
                       Icon(Icons.star_rounded, size: 16, color: kSecondary),
                       Icon(Icons.star_rounded, size: 16, color: kSecondary),
                       Icon(Icons.star_rounded, size: 16, color: kSecondary),
                     ],
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
