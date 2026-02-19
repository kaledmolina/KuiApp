import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../ear_training/models/level_model.dart';
import '../../../../core/api_client.dart';

// --- Models for UI ---
enum LevelStatus { completed, active, locked }

class Unit {
  final int number;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLocked;
  final List<LevelUI> levels;

  Unit({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLocked = false,
    required this.levels,
  });
}

class LevelUI {
  final String title;
  final String? subtitle;
  final LevelStatus status;
  final int stars;
  final int? levelId; // Link to actual level ID if available

  LevelUI({
    required this.title,
    this.subtitle,
    this.status = LevelStatus.locked,
    this.stars = 0,
    this.levelId,
  });
}

// --- Main Tab ---

class LevelsTab extends StatefulWidget {
  const LevelsTab({super.key});

  @override
  State<LevelsTab> createState() => _LevelsTabState();
}

class _LevelsTabState extends State<LevelsTab> {
  // Mock Data mimicking the design
  final List<Unit> _units = [
    Unit(
      number: 1,
      title: 'Introducción al Oído',
      subtitle: 'Unidad 1',
      color: const Color(0xFF6200EA), // Primary
      levels: [
        LevelUI(
          title: 'Nivel 1: Teclas Blancas',
          status: LevelStatus.completed,
          stars: 3,
          levelId: 1,
        ),
        LevelUI(
          title: 'Nivel 2: Intervalos Básicos',
          subtitle: '¡En curso!',
          status: LevelStatus.active,
          levelId: 2,
        ),
        LevelUI(
          title: 'Nivel 3: El Pentagrama',
          status: LevelStatus.locked,
          levelId: 3,
        ),
      ],
    ),
    Unit(
      number: 2,
      title: 'Armonía y Acordes',
      subtitle: 'Unidad 2',
      color: Colors.grey,
      isLocked: true,
      levels: [],
    ),
    Unit(
      number: 3,
      title: 'Lectura Avanzada',
      subtitle: 'Unidad 3',
      color: Colors.grey,
      isLocked: true,
      levels: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Colors from Design
    final bgColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF121212) 
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final unit = _units[index];
                  return _UnitSection(unit: unit);
                },
                childCount: _units.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF6200EA), // Primary
      elevation: 4,
      title: Text(
        'Kui',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        _buildStatBadge(Icons.local_fire_department, Colors.orangeAccent, '1'),
        const SizedBox(width: 8),
        _buildStatBadge(Icons.favorite, Colors.redAccent, '5'),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, Color iconColor, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Component Widgets ---

class _UnitSection extends StatelessWidget {
  final Unit unit;

  const _UnitSection({required this.unit});

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
                child: _LevelCard(level: level),
              )),
              // Reward Chest
               _RewardCard(),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: unit.isLocked 
            ? (isDark ? const Color(0xFF374151) : Colors.grey[200]) 
            : unit.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: unit.isLocked ? [] : [
          BoxShadow(
            color: unit.color.withOpacity(0.5),
            offset: const Offset(0, 6),
            blurRadius: 0, 
          )
        ],
        border: unit.isLocked ? Border.all(color: Colors.grey.shade300, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Decoration
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
          
          // Content
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
                  color: unit.isLocked ? Colors.grey[300] : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  unit.isLocked ? Icons.lock : Icons.menu_book,
                  color: unit.isLocked ? Colors.grey[500] : Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelUI level;

  const _LevelCard({required this.level});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Status Logic
    final bool isCompleted = level.status == LevelStatus.completed;
    final bool isActive = level.status == LevelStatus.active;
    final bool isLocked = level.status == LevelStatus.locked;

    // Colors
    final Color borderColor = isActive ? const Color(0xFF6200EA) : (isCompleted ? const Color(0xFF00E676) : Colors.grey.shade300);
    final Color shadowColor = isActive ? const Color(0xFF3700B3) : (isCompleted ? const Color(0xFF00A854) : Colors.grey.shade400);
    final Color iconBg = isActive ? const Color(0xFF6200EA) : (isCompleted ? const Color(0xFF00E676) : Colors.grey.shade300);
    final IconData statusIcon = isActive ? Icons.music_note : (isCompleted ? Icons.check : Icons.lock);
    final Color iconColor = isLocked ? Colors.grey[500]! : Colors.white;
    final double elevation = isLocked ? 0 : 6;

    return GestureDetector(
      onTap: isLocked ? null : () {
        if (level.levelId != null) {
            context.push('/lesson/${level.levelId}', extra: 1); // Mock difficulty 1
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? (isDark ? const Color(0xFF374151).withOpacity(0.5) : Colors.grey[100]) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark && isLocked ? Colors.grey.shade700 : borderColor, width: 2),
            boxShadow: isLocked ? [] : [
               BoxShadow(
                  color: shadowColor,
                  offset: Offset(0, elevation),
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
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                boxShadow: isLocked ? [] : [
                   BoxShadow(
                      color: shadowColor.withOpacity(0.5), // Inner shadow logic mocked slightly
                      offset: const Offset(0, 2),
                      blurRadius: 0
                   )
                ]
              ),
              child: Center(
                child: Icon(statusIcon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isLocked ? Colors.grey[400] : (isDark ? Colors.white : Colors.grey[900]),
                    ),
                  ),
                  if (isCompleted)
                    Row(
                      children: List.generate(3, (index) => const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 16)),
                    ),
                  if (isActive)
                     Text(
                       level.subtitle ?? '¡EN CURSO!',
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

            // Trailing (Active Tag)
            if (isActive)
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                    color: const Color(0xFFB388FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2)
                 ),
                 child: Text(
                    'PRÓXIMO',
                    style: GoogleFonts.nunito(
                       color: const Color(0xFF3700B3),
                       fontWeight: FontWeight.w900,
                       fontSize: 10
                    ),
                 ),
              )
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     return Container(
        decoration: BoxDecoration(
           color: const Color(0xFFFFD600).withOpacity(0.1),
           borderRadius: BorderRadius.circular(24),
           border: Border.all(color: const Color(0xFFFFD600), width: 2),
           boxShadow: const [
              BoxShadow(
                 color: Color(0xFFFBC02D), // rgba(0,0,0,0.1) approx
                 offset: Offset(0, 4),
                 blurRadius: 0
              )
           ]
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
           children: [
              Container(
                 width: 48,
                 height: 48,
                 decoration: const BoxDecoration(
                    color: Color(0xFFFFD600),
                    shape: BoxShape.circle,
                    boxShadow: [
                       BoxShadow(
                          color: Color(0xFFFBC02D),
                          offset: Offset(0, 2)
                       )
                    ]
                 ),
                 child: const Center(
                    child: Icon(Icons.inventory_2_rounded, color: Color(0xFF3E2723), size: 24),
                 ),
              ),
              const SizedBox(width: 16),
               Text(
                 'Cofre de Recompensas',
                 style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF3E2723) 
                 ),
               )
           ],
        ),
     );
  }
}
