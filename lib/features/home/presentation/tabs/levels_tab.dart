import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../ear_training/data/progress_repository.dart';
import '../../../../core/api_client.dart';

// --- Colors from HTML ---
class KuiColors {
  static const primary = Color(0xFF6200EA);
  static const primaryLight = Color(0xFFB388FF);
  static const primaryDark = Color(0xFF3700B3);
  static const secondary = Color(0xFF00E676);
  static const secondaryDark = Color(0xFF00A854);
  static const accent = Color(0xFFFFD600);
  static const cardShadow = Color.fromRGBO(0, 0, 0, 0.1); // rgba(0,0,0,0.1)
  static const lockedLight = Color(0xFFE5E7EB);
  static const lockedDark = Color(0xFF374151);
  static const backgroundLight = Color(0xFFF3F4F6);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E1E);
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? KuiColors.backgroundDark : KuiColors.backgroundLight;

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
    int chunkSize = 5; // Assuming 5 levels per unit for now
    
    // Define Unit Themes based on design
    final themes = [
      {'title': 'Introducción al Oído', 'color': KuiColors.primary},
      {'title': 'Armonía y Acordes', 'color': KuiColors.secondary}, // Using secondary for variety
      {'title': 'Lectura Avanzada', 'color': KuiColors.primary}, 
    ];

    for (var i = 0; i < levels.length; i += chunkSize) {
      final chunk = levels.skip(i).take(chunkSize).toList();
      final unitIndex = i ~/ chunkSize;
      final theme = themes[unitIndex % themes.length];
      
      // logic for locking needs to be real, for now mock
      final isLocked = unitIndex > 0; 

      units.add(Unit(
        number: unitIndex + 1,
        title: theme['title'] as String,
        subtitle: 'Unidad ${unitIndex + 1}',
        color: theme['color'] as Color,
        levels: chunk,
        isLocked: isLocked,
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
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
             maxHeight: MediaQuery.of(context).size.height * 0.85
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
      shadowColor: KuiColors.cardShadow,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _UnitHeader(unit: unit),
            if (!unit.isLocked) ...[
              const SizedBox(height: 16),
              // Filter logic or just map active levels for now. 
              // Assuming all levels in a non-locked unit are visible, 
              // but we might want to distinguish between active/current/locked steps if needed.
              ...unit.levels.map((levelWP) {
                // Determine status based on progress (this logic might need refinement)
                // For now, let's assume we pass the levelWP directly and the card handles rendering.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _LevelCard(levelWP: levelWP, onTap: () => onLevelTap(levelWP)),
                );
              }),
              // Reward Chest
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: _RewardCard(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard();

  @override
  Widget build(BuildContext context) {
    return _GameButton(
      color: KuiColors.accent.withOpacity(0.1),
      borderColor: KuiColors.accent,
      shadowColor: KuiColors.cardShadow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: KuiColors.accent, 
                shape: BoxShape.circle,
                boxShadow: [
                   BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1), // shadow-solid
                      offset: Offset(0, 4),
                      blurRadius: 0
                   )
                ]
              ),
              child: const Center(
                child: Icon(Icons.inventory_2_outlined, color: Color(0xFF713F12), size: 24), // text-yellow-900
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Cofre de Recompensas',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: const Color(0xFF713F12), // text-yellow-900
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
    // shadow-solid-primary: 0 6px 0 0 #3700B3
    // background: primary (#6200EA) or gray if locked
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: unit.isLocked ? Colors.grey[200] : unit.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: unit.isLocked ? [] : [
          // If unit color is primary, use primary-dark shadow. 
          // If secondary, use secondary-dark. 
          // Simple mapping for now.
          BoxShadow(
            color: unit.color == KuiColors.primary ? KuiColors.primaryDark : KuiColors.secondaryDark, 
            offset: const Offset(0, 6),
            blurRadius: 0, 
          )
        ],
        border: unit.isLocked ? Border.all(color: Colors.grey.shade300, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
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
    final level = levelWP.level;
    final int stars = levelWP.stars;
    
    // Determine state
    // For now: 
    // - stars == 3 -> Completed (Green)
    // - stars < 3 (but unlocked) -> Active (Purple)
    // - locked -> Gray (TODO: Implement proper locking logic in model)
    // For this simple mock, we treat all fetched levels as at least Active if they are in the list.
    // Real logic would depend on previous level completion. 
    // Assuming 'active' implies current level to work on.
    
    final bool isCompleted = stars == 3;
    final bool isActive = !isCompleted; // Simplifying for this view
    final bool isLocked = false; 

    // Colors
    final Color borderColor = isLocked ? KuiColors.lockedLight : (isActive ? KuiColors.primary : KuiColors.secondary);
    final Color bgColor = isLocked ? KuiColors.backgroundLight : Colors.white; // dark:bg-locked-dark/50 (TODO dark mode)
    
    final Color iconBg = isLocked ? KuiColors.lockedLight : (isActive ? KuiColors.primary : KuiColors.secondary);
    final Color? iconShadow = isLocked ? null : (isActive ? KuiColors.primaryDark : KuiColors.secondaryDark);
    final IconData iconData = isCompleted ? Icons.check : Icons.music_note;

    return _GameButton(
      onTap: isLocked ? null : onTap,
      color: bgColor,
      borderColor: borderColor,
      shadowColor: KuiColors.cardShadow,
      child: Padding(
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
                    boxShadow: iconShadow != null ? [
                       BoxShadow(
                          color: iconShadow, 
                          offset: const Offset(0, 6), 
                          blurRadius: 0
                       )
                    ] : []
                  ),
                  child: Center(
                    child: Icon(iconData, color: isLocked ? Colors.grey[400] : Colors.white, size: 24),
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
                          color: isLocked ? Colors.grey[400] : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[900]),
                        ),
                      ),
                      if (stars > 0)
                          Row(
                              children: List.generate(3, (index) => Icon(
                                 index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                 color: KuiColors.accent,
                                 size: 18)
                              )
                          )
                      else if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              '¡En curso!',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: KuiColors.primary, 
                                letterSpacing: -0.5,
                              ),
                            ),
                          )
                    ],
                  ),
                ),
              ],
            ),
            
            // "PRÓXIMO" Tag
            if (isActive)
               Positioned(
                  top: -24, 
                  right: -8,
                  child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                        color: KuiColors.primaryLight, 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2)
                     ),
                     child: Text(
                        'PRÓXIMO',
                        style: GoogleFonts.nunito(
                           fontSize: 10,
                           fontWeight: FontWeight.w900,
                           color: KuiColors.primaryDark 
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
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(
          top: _isPressed ? 4.0 : 0.0,
          bottom: _isPressed ? 0.0 : 4.0, // Compensate to keep layout stable if needed, usually just Top is enough
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.borderColor, width: widget.borderWidth),
          boxShadow: _isPressed || widget.onTap == null
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}
