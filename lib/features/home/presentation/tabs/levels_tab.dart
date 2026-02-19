import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

// --- Colors from Mockup ---
class KuiColors {
  static const primary = Color(0xFF6200EA); // Deep Purple
  static const primaryLight = Color(0xFFB388FF);
  static const secondary = Color(0xFF00E676); // Bright Green
  static const accent = Color(0xFFFFD600); // Yellow/Gold
  static const brown = Color(0xFF5D4037); // Brown for chest text
  
  static const bgCompleted = Colors.white;
  static const borderCompleted = secondary;
  
  static const bgActive = Colors.white;
  static const borderActive = primary;
  
  static const bgLocked = Color(0xFFF5F5F5); // Light Gray
  static const borderLocked = Color(0xFFE0E0E0);
  static const iconLocked = Color(0xFFBDBDBD);
  
  static const bgReward = Color(0xFFFFFDE7); // Very light yellow
  static const borderReward = accent;
  static const iconRewardBg = accent;

  static const cardShadow = Color.fromRGBO(0, 0, 0, 0.05); 
}

// --- Models for UI ---
class LevelWithProgress {
  final Level level;
  final int unlockedDifficulty;

  LevelWithProgress(this.level, this.unlockedDifficulty);
  
  // Logic: 
  // Difficulty 1 passed -> unlockedDifficulty = 2 -> 1 star
  // Difficulty 2 passed -> unlockedDifficulty = 3 -> 2 stars
  // Difficulty 3 passed -> unlockedDifficulty = 4 -> 3 stars
  // If unlockedDifficulty is 1 (just started), stars = 0
  int get stars => (unlockedDifficulty - 1).clamp(0, 3);
  
  bool get isCompleted => stars >= 3;
}

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
    // Use a mock/local repo if needed, but here assuming we use the real one.
    // Ensure we trigger a refresh when returning from a lesson.
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
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
    
    final themes = [
      {'title': 'Introducción al Oído', 'color': KuiColors.primary},
      {'title': 'Armonía y Acordes', 'color': KuiColors.secondary}, 
      {'title': 'Lectura Avanzada', 'color': KuiColors.primary}, 
    ];

    for (var i = 0; i < levels.length; i += chunkSize) {
      final chunk = levels.skip(i).take(chunkSize).toList();
      final unitIndex = i ~/ chunkSize;
      final theme = themes[unitIndex % themes.length];
      
      final isLocked = unitIndex > 0; 

      units.add(Unit(
        number: unitIndex + 1,
        title: theme['title'] as String,
        subtitle: 'UNIDAD ${unitIndex + 1}',
        color: theme['color'] as Color,
        levels: chunk,
        isLocked: isLocked,
      ));
    }
    return units;
  }

  void _showDifficultyDialog(BuildContext context, int levelId) async {
    final progressRepo = ProgressRepository();
    final maxUnlocked = await progressRepo.getMaxUnlockedDifficulty(levelId);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
             maxHeight: MediaQuery.of(context).size.height * 0.85
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                Column(
                   children: [
                      _buildDifficultyOption(context, levelId, 1, 'Fácil', '10 Preguntas, 30s', 1, maxUnlocked >= 1, KuiColors.secondary),
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
    return _GameButton(
      onTap: unlocked ? () {
        context.pop(); 
        context.push('/lesson/$levelId', extra: difficulty).then((_) {
           setState(() {
              _levelsFuture = _fetchLevelsWithProgress();
           });
        });
      } : null,
      color: unlocked ? Colors.white : Colors.grey.shade50,
      borderColor: unlocked ? color.withOpacity(0.3) : Colors.grey.shade200,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _UnitHeader(unit: unit),
          if (!unit.isLocked) ...[
            const SizedBox(height: 16),
            ...unit.levels.asMap().entries.map((entry) {
              final index = entry.key;
              final levelWP = entry.value;
              // Simple logic to mock "Active" state for demo if not completed.
              // In real app, check if previous level is completed. 
              // Here we just say: if not completed, it's active.
              // If we want strictly one active at a time, we'd iterate.
              // For now, let's treat any non-completed level as potentially active or just display stats.
              
              // To match screenshot: 
              // Level 1 is Completed (Green)
              // Level 2 is Active (Purple, "En Curso")
              // Level 3 is Locked (Gray)
              
              // We'll trust the repo's 'unlockedDifficulty' to tell us state.
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LevelCard(
                  levelWP: levelWP, 
                  onTap: () => onLevelTap(levelWP),
                  isNext: index == 1, // Mocking "Next" on the second item for visual matching if dynamic logic isn't fully ready
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: _RewardCard(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard();

  @override
  Widget build(BuildContext context) {
    return _GameButton(
      color: KuiColors.bgReward,
      borderColor: KuiColors.borderReward,
      borderRadius: 32, // Pill shape
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: KuiColors.iconRewardBg, 
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                      color: Colors.black12, 
                      offset: Offset(0, 4),
                      blurRadius: 0
                   )
                ]
              ),
              child: const Center(
                child: Icon(Icons.inventory_2_outlined, color: KuiColors.brown, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Cofre de Recompensas',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: KuiColors.brown,
                ),
              ),
            ),
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
        color: unit.isLocked ? Colors.grey[400] : unit.color,
        borderRadius: BorderRadius.circular(32), // Pill shape
        boxShadow: unit.isLocked ? [] : [
           BoxShadow(
            color: unit.color == KuiColors.primary ? const Color(0xFF4500B5) : const Color(0xFF00B248),
            offset: const Offset(0, 6),
            blurRadius: 0, 
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit.title,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
             width: 50,
             height: 50,
             decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
             ),
             child: const Center(
               child: Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 28,
               ),
             )
          )
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelWithProgress levelWP;
  final VoidCallback onTap;
  final bool isNext;

  const _LevelCard({
    required this.levelWP, 
    required this.onTap,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = levelWP.level;
    final int stars = levelWP.stars;
    
    // Logic for State
    // Completed: stars >= 3 (Or just > 0 if we want strict completion, but let's stick to 3 stars = 'done' style)
    // Actually, design implies:
    // Green Card = Completed (Checkmark)
    // Purple Card = In Progress / Active (Music Note)
    // Gray Card = Locked (Lock)
    
    // We can infer state from stars:
    // If stars == 3 -> Completed
    // If stars < 3 but unlockedDifficulty > 0 -> Active
    // Else -> Locked (Assuming model handles this or we pass isLocked)
    
    final bool isCompleted = stars == 3;
    final bool isLocked = levelWP.unlockedDifficulty == 0; // Or some other flag
    final bool isActive = !isCompleted && !isLocked; 
    
    // Override logic to match specific visual request if needed, but logic should hold.
    
    Color borderColor;
    Color bgColor;
    Color iconCircleColor;
    IconData leadingIcon;
    Color leadingIconColor;
    
    if (isCompleted) {
      borderColor = KuiColors.secondary; // Green
      bgColor = KuiColors.bgCompleted;
      iconCircleColor = KuiColors.secondary;
      leadingIcon = Icons.check_rounded;
      leadingIconColor = Colors.white;
    } else if (isActive) {
      borderColor = KuiColors.primary; // Purple
      bgColor = KuiColors.bgActive;
      iconCircleColor = KuiColors.primary;
      leadingIcon = Icons.music_note_rounded;
      leadingIconColor = Colors.white;
    } else {
      borderColor = KuiColors.borderLocked;
      bgColor = KuiColors.bgLocked;
      iconCircleColor = KuiColors.borderLocked; 
      leadingIcon = Icons.lock_rounded;
      leadingIconColor = Colors.grey;
    }
    
    // Mocking for visual match of specific rows in screenshot
    // If this is called within a map, valid logic applies. 

    return _GameButton(
      onTap: isLocked ? null : onTap,
      color: bgColor,
      borderColor: borderColor,
      borderRadius: 32, // Pill shape
      borderWidth: 2.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconCircleColor,
                    shape: BoxShape.circle,
                    boxShadow: !isLocked ? [
                       BoxShadow(
                          color: (isCompleted ? KuiColors.secondary : KuiColors.primary).withOpacity(0.4), 
                          offset: const Offset(0, 4), 
                          blurRadius: 0
                       )
                    ] : []
                  ),
                  child: Center(
                    child: Icon(leadingIcon, color: leadingIconColor, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        level.name, 
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: isLocked ? Colors.grey[400] : const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isCompleted)
                          Row(
                              children: List.generate(3, (index) => Icon(
                                 Icons.star_rounded,
                                 color: KuiColors.accent,
                                 size: 20)
                              )
                          )
                      else if (isActive)
                          Text(
                            '¡EN CURSO!',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: KuiColors.primary, 
                              letterSpacing: 0.5,
                            ),
                          )
                      else // Locked text placeholder or empty
                          Container()
                    ],
                  ),
                ),
              ],
            ),
            
            // "PRÓXIMO" Badge (Only for Active)
            if (isActive)
               Positioned(
                  top: -30, 
                  right: -20, // Adjust to hang off edge slightly
                  child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                     decoration: BoxDecoration(
                        color: const Color(0xFFB388FF), 
                        borderRadius: BorderRadius.only(
                           topRight: Radius.circular(32),
                           bottomLeft: Radius.circular(16)
                        ),
                     ),
                     child: Text(
                        'PRÓXIMO',
                        style: GoogleFonts.nunito(
                           fontSize: 10,
                           fontWeight: FontWeight.w900,
                           color: Colors.white,
                           letterSpacing: 0.5
                        ),
                     ),
                  ),
               )
          ],
        ),
      ),
    );
  }
}

// --- Animation Widget ---

class _GameButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  const _GameButton({
    this.onTap,
    required this.child,
    this.color = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // shadow-solid effect 
    final bool isPressed = _isPressed;
    final double offset = isPressed ? 0 : 5; 
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Stack(
         children: [
            // Shadow Layer
            if (!isPressed)
             Positioned(
               top: 5,
               left: 0,
               right: 0,
               bottom: 0,
               child: Container(
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.05), // As per request/screenshot, simple shadow
                   // or maybe slightly colored depending on card? 
                   // The screenshot shows minimal shadow below. 
                   borderRadius: BorderRadius.circular(widget.borderRadius),
                 ),
               ),
             ),
             
            // Main Button Layer
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(0, isPressed ? 5 : 0, 0),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: widget.borderColor, width: widget.borderWidth),
                // To get exact look, maybe we don't need shadow here if we use Positioned stack above or just standard box shadow
              ),
              child: widget.child,
            ),
         ]
      ),
    );
  }
}
