import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../../core/api_client.dart';

const Color primaryPurple = Color(0xFF7C3AED);
const Color secondaryGold = Color(0xFFFBBF24);
const Color bgLight = Color(0xFFF3F4F6);
const Color textDark = Color(0xFF1F2937);
const Color accentGreen = Color(0xFF58CC02);
const Color accentRed = Color(0xFFEF4444);

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  late Future<List<Map<String, dynamic>>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    final repo = LessonRepository(ApiClient());
    _rankingFuture = repo.getRanking();
  }

  int _daysUntilEndOfMonth() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final ranking = snapshot.data ?? [];
          final myLeague = currentUser?.league ?? 'Bronce';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(myLeague, currentUser?.lives ?? 0, currentUser?.xpTotal ?? 0),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      if (ranking.isNotEmpty) _buildPodium(ranking),
                      const SizedBox(height: 24),
                      if (ranking.length > 3) _buildListSection(ranking.sublist(3), currentUser?.id),
                      const SizedBox(height: 24),
                      _buildDaysRemainingCard(),
                      const SizedBox(height: 100), // Padding for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String league, int lives, int xpTotal) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Kui Logo & Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kui',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Liga $league',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top 5 avanzan a la siguiente liga',
            style: GoogleFonts.nunito(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Trophy Image
          SizedBox(
            width: 120,
            height: 120,
            child: Icon(Icons.emoji_events_rounded, size: 100, color: secondaryGold),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> ranking) {
    final top3 = ranking.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top3.length > 1) _buildPodiumItem(top3[1], 2, 100, Colors.grey.shade400, Colors.grey.shade200),
        if (top3.isNotEmpty) _buildPodiumItem(top3[0], 1, 140, secondaryGold, Colors.yellow.shade100),
        if (top3.length > 2) _buildPodiumItem(top3[2], 3, 80, Colors.orange.shade400, Colors.orange.shade100),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double height, Color color, Color bgLight) {
    String initials = (user['name'] ?? 'U').substring(0, 1).toUpperCase();
    int xp = user['xp_monthly'] ?? user['xp_total'] ?? 0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: rank == 1 ? 36 : 28,
                backgroundColor: color,
                child: CircleAvatar(
                  radius: rank == 1 ? 32 : 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: rank == 1 ? 24 : 18),
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              if (rank == 1)
                 const Positioned(
                    top: -20,
                    child: Icon(Icons.emoji_events_rounded, color: secondaryGold, size: 30),
                 ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user['name'] ?? 'User',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
          ),
          Text(
            '$xp XP',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 12, color: primaryPurple),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(top: BorderSide(color: color, width: 4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(List<Map<String, dynamic>> restOfRanking, int? myUserId) {
    return Column(
      children: [
        _buildZoneHeader('Zona de Ascenso', Icons.arrow_upward_rounded, accentGreen, Colors.green.shade100),
        for (var i = 0; i < restOfRanking.length; i++)
          if (i < 2) 
             _buildListTile(restOfRanking[i], i + 4, myUserId, opacity: 1.0)
          else if (i == 2)
            ...[
             const SizedBox(height: 16),
             _buildZoneHeader('Zona de Descenso', Icons.arrow_downward_rounded, accentRed, Colors.red.shade100),
             _buildListTile(restOfRanking[i], i + 4, myUserId, opacity: 0.8)
            ]
          else 
            _buildListTile(restOfRanking[i], i + 4, myUserId, opacity: 0.6)
      ],
    );
  }

  Widget _buildZoneHeader(String title, IconData icon, Color color, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 12, color: color, letterSpacing: 1.0),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: bgColor)),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> user, int rank, int? myUserId, {double opacity = 1.0}) {
    bool isMe = user['id'] == myUserId;
    String initials = (user['name'] ?? 'U').substring(0, 1).toUpperCase();
    int xp = user['xp_monthly'] ?? user['xp_total'] ?? 0;
    String league = user['league'] ?? 'Bronce';

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardLight,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? Border.all(color: primaryPurple.withOpacity(0.3), width: 2) : Border.all(color: Colors.transparent),
          boxShadow: const [
            BoxShadow(color: Color(0xFFE5E7EB), offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                rank.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.grey.shade400, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? 'Tú' : (user['name'] ?? 'Usuario'),
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, 
                      color: isMe ? primaryPurple : textDark, 
                      fontSize: 16
                    ),
                  ),
                  Text(
                    'Liga $league',
                    style: GoogleFonts.nunito(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '$xp XP',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: textDark, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysRemainingCard() {
    int days = _daysUntilEndOfMonth();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
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
                  '¡Quedan $days días!',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                ),
                Text(
                  'La liga termina a fin de mes',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: Colors.blue.shade100, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Text('Jugar ahora', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          )
        ],
      ),
    );
  }
}
