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
  static const primaryDark = Color(0xFF3700B3);
  static const primaryLight = Color(0xFFB388FF);
  
  static const secondary = Color(0xFF00E676); // Bright Green
  static const secondaryDark = Color(0xFF00A854);
  
  static const accent = Color(0xFFFFD600); // Yellow/Gold
  static const brown = Color(0xFF5D4037); 
  
  static const bgStandard = Colors.white;
  static const bgLocked = Color(0xFFF3F4F6); // Light Gray
  static const borderLocked = Color(0xFFE5E7EB);
  static const shadowLocked = Color(0xFF9CA3AF);
  
  static const bgReward = Color(0xFFFFF9C4); // Light yellow
  static const borderReward = accent;
}

// --- Models ---
class LevelWithProgress {
  final Level level;
  final int unlockedDifficulty;

  LevelWithProgress(this.level, this.unlockedDifficulty);
  
  // Logic: 
  // 0 = Locked
  // 1 = Unlocked (0 stars)
  // 2 = Passed Easy (1 star)
  // 3 = Passed Medium (2 stars)
  // 4 = Passed Hard (3 stars)
  int get stars => (unlockedDifficulty - 1).clamp(0, 3);
  
  // A level is "Completed" if passed at least Easy (1 star).
  bool get isCompleted => stars >= 1;
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

enum LevelCardState { completed, active, locked }

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
    
    // Themes matching screenshot
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
      shadowColor: unlocked ? color.withOpacity(0.1) : Colors.black12,
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

// --- Unit Section with Strict State Logic ---

class _UnitSection extends StatelessWidget {
  final Unit unit;
  final Function(LevelWithProgress) onLevelTap;

  const _UnitSection({required this.unit, required this.onLevelTap});

  @override
  Widget build(BuildContext context) {
    // Logic: Color levels based on their state relative to progress.
    // 1. Completed (Green)
    // 2. Active (Purple) - The first non-completed level
    // 3. Locked (Gray) - Everything after active
    
    // Find index of first non-completed level
    int activeIndex = -1;
    for (int i = 0; i < unit.levels.length; i++) {
      if (!unit.levels[i].isCompleted) {
        activeIndex = i;
        break;
      }
    }
    
    // If all are completed, no active? or last is considered done?
    // Let's assume if all completed, none are "Active" in the "Purple/Next" sense, 
    // or maybe the last one stays purple? The prompt implies linear progress.
    // If activeIndex == -1, meant all are completed.

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
              
              LevelCardState state;
              
              if (activeIndex == -1) {
                // All completed
                state = LevelCardState.completed;
              } else {
                if (index < activeIndex) {
                  state = LevelCardState.completed;
                } else if (index == activeIndex) {
                  // This is the one user should work on
                  state = LevelCardState.active;
                } else {
                  // After active -> Locked/Future
                  state = LevelCardState.locked;
                }
              }
              
              // Handle clickable: Locked levels are disabled.
              // Active and Completed are clickable.
              final isClickable = state != LevelCardState.locked;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LevelCard(
                  levelWP: levelWP, 
                  onTap: () {
                     if (isClickable) onLevelTap(levelWP);
                  },
                  state: state,
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
      shadowColor: const Color(0xFFE6C60D), 
      borderRadius: 32, 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: KuiColors.accent, 
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                      color: Color(0xFFE6C60D), // Solid yellow shadow
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
        borderRadius: BorderRadius.circular(32), 
        boxShadow: unit.isLocked ? [] : [
           BoxShadow(
            color: unit.color == KuiColors.primary ? KuiColors.primaryDark : KuiColors.secondaryDark,
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
  final VoidCallback? onTap;
  final LevelCardState state;

  const _LevelCard({
    required this.levelWP, 
    required this.onTap,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Styles mapping
    Color borderColor;
    Color bgColor;
    Color shadowColor;
    Color iconCircleColor;
    Color iconCircleShadow;
    IconData leadingIcon;
    Color leadingIconColor;
    
    switch (state) {
      case LevelCardState.completed:
        borderColor = KuiColors.secondary; // Green
        bgColor = KuiColors.bgStandard; // White
        shadowColor = KuiColors.secondaryDark; // Green Shadow
        iconCircleColor = KuiColors.secondary;
        iconCircleShadow = KuiColors.secondaryDark;
        leadingIcon = Icons.check_rounded;
        leadingIconColor = Colors.white;
        break;
      case LevelCardState.active:
        borderColor = KuiColors.primary; // Purple
        bgColor = KuiColors.bgStandard; // White
        shadowColor = KuiColors.primaryDark; // Purple Shadow
        iconCircleColor = KuiColors.primary;
        iconCircleShadow = KuiColors.primaryDark;
        leadingIcon = Icons.music_note_rounded;
        leadingIconColor = Colors.white;
        break;
      case LevelCardState.locked:
        borderColor = KuiColors.borderLocked; // Gray
        bgColor = KuiColors.bgLocked; // Grayish
        shadowColor = KuiColors.shadowLocked; // Dark Gray Shadow
        iconCircleColor = KuiColors.borderLocked; 
        iconCircleShadow = Colors.transparent;
        leadingIcon = Icons.lock_rounded;
        leadingIconColor = Colors.grey;
        break;
    }

    return _GameButton(
      onTap: onTap,
      color: bgColor,
      borderColor: borderColor,
      shadowColor: shadowColor,
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
                    boxShadow: state != LevelCardState.locked ? [
                       BoxShadow(
                          color: iconCircleShadow, 
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
                        levelWP.level.name, 
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: state == LevelCardState.locked ? Colors.grey[400] : const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (state == LevelCardState.completed)
                          Row(
                              children: List.generate(levelWP.stars, (index) => Icon(
                                 Icons.star_rounded,
                                 color: KuiColors.accent, // Yellow stars
                                 size: 20)
                              )
                          )
                      else if (state == LevelCardState.active)
                          Text(
                            '¡EN CURSO!',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: KuiColors.primary, 
                              letterSpacing: 0.5,
                            ),
                          )
                      else 
                          Container()
                    ],
                  ),
                ),
              ],
            ),
            
            // "PRÓXIMO" Badge (Only for Active)
            if (state == LevelCardState.active)
               Positioned(
                  top: -22, 
                  right: -8, 
                  child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                        color: KuiColors.primaryLight, 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2)
                     ),
                     child: Text(
                        'PRÓXIMO',
                        style: GoogleFonts.nunito(
                           fontSize: 11,
                           fontWeight: FontWeight.w900,
                           color: KuiColors.primary,
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

// --- Animation Widget (Refined) ---

class _GameButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double borderRadius;

  const _GameButton({
    this.onTap,
    required this.child,
    this.color = Colors.white,
    this.borderColor = Colors.grey,
    this.shadowColor = Colors.black12,
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
    final bool isPressed = _isPressed;
    final double shadowHeight = 4.0; 
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Stack(
         children: [
            // Shadow Layer: Positioned to create a solid block shadow
            if (!isPressed)
             Positioned(
               top: shadowHeight,
               left: 0,
               right: 0,
               bottom: 0,
               child: Container(
                 decoration: BoxDecoration(
                   color: widget.shadowColor,
                   borderRadius: BorderRadius.circular(widget.borderRadius),
                 ),
               ),
             ),
            
            // Invisible placeholder for layout size stability
            if (!isPressed)
               Container(
                  height: shadowHeight, 
                  width: double.infinity,
                  color: Colors.transparent,
               ),

            // Button Surface
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(0, isPressed ? shadowHeight : 0, 0),
              margin: EdgeInsets.only(bottom: isPressed ? 0 : shadowHeight),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: widget.borderColor, width: widget.borderWidth),
              ),
              child: widget.child,
            ),
         ]
      ),
    );
  }
}
