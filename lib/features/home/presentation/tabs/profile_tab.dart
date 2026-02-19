import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';

const Color primaryPurpleProfile = Color(0xFF6200EA);
const Color bgLightProfile = Color(0xFFF3F4F6);
const Color cardLightProfile = Color(0xFFFFFFFF);
const Color textDarkProfile = Color(0xFF374151);
const Color accentYellow = Color(0xFFFFC107);
const Color accentRed = Color(0xFFFF5252);
const Color accentOrange = Color(0xFFFF9800);
const Color accentBlue = Color(0xFF448AFF);

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (authProvider.isAuthenticated) {
        return const Center(child: CircularProgressIndicator(color: primaryPurpleProfile));
      }
      return const Center(child: Text('Por favor inicia sesión.'));
    }

    return Scaffold(
      backgroundColor: bgLightProfile,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // User Header Info
            _buildUserInfo(user),
            const SizedBox(height: 32),

            // Stats Grid
            _buildStatsGrid(user),
            const SizedBox(height: 32),

            // Achievements
            _buildAchievementsSection(),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => authProvider.logout(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: Colors.grey.shade600,
                ),
                child: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 100), // Padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
    // Determine level loosely based on XP or unlocked level to match "Lv. 10" in mockup
    int level = user.maxUnlockedLevel ?? 1;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.shade100,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Icon(Icons.person, size: 60, color: Colors.indigo.shade300),
            ),
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bgLightProfile, width: 4),
                ),
                child: Text(
                  'Lv. $level',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: textDarkProfile),
        ),
        Text(
          user.email,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              'Se unió recientemente',
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
            )
          ],
        )
      ],
    );
  }

  Widget _buildStatsGrid(dynamic user) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(Icons.favorite_rounded, accentRed, '${user.lives}', 'Vidas'),
        _buildStatCard(Icons.local_fire_department_rounded, accentOrange, '${user.streakCount}', 'Días Racha'),
        _buildStatCard(Icons.star_rounded, accentYellow, '${user.xpTotal}', 'XP Total'),
        _buildStatCard(Icons.music_note_rounded, accentBlue, '${user.goldNotes}', 'Notas Oro'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, Color iconColor, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: cardLightProfile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFE5E7EB), offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: textDarkProfile),
          ),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Logros',
              style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: textDarkProfile),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Ver todo',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: primaryPurpleProfile),
              ),
            )
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardLightProfile,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ]
          ),
          child: Column(
            children: [
              _buildAchievementItem(
                title: 'Oído de Oro',
                description: 'Completa 10 lecciones sin errores.',
                icon: Icons.hearing_rounded,
                color: Colors.amber,
                progress: 1.0,
              ),
              const SizedBox(height: 24),
              _buildAchievementItem(
                title: 'Racha de 7 días',
                description: 'Practica todos los días por una semana.',
                icon: Icons.whatshot_rounded,
                color: Colors.orange,
                progress: 0.14,
              ),
              const SizedBox(height: 24),
              _buildAchievementItem(
                title: 'Maestro del Ritmo',
                description: 'Consigue 50 Notas de Oro.',
                icon: Icons.emoji_events_rounded,
                color: Colors.grey.shade400,
                progress: 0.24,
                isGrayscale: true,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required double progress,
    bool isGrayscale = false,
  }) {
    return Opacity(
      opacity: isGrayscale ? 0.6 : 1.0,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border(bottom: BorderSide(color: color.withOpacity(0.3), width: 4)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: isGrayscale ? Colors.grey.shade600 : textDarkProfile),
                ),
                Text(
                  description,
                  style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
