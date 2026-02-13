import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';
// Import Repository
import '../../../ear_training/data/lesson_repository.dart';
import '../../../../core/api_client.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<List<Map<String, dynamic>>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    // Load ranking on init
    final repo = LessonRepository(ApiClient());
    // Use user's league or default to null (server handles default?) or "Bronce"
    // For now, let's fetch global or specific league if we had it in user profile properly
    // The user provider might not be ready in initState if not careful, but we can just fetch default
    _rankingFuture = repo.getRanking();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (authProvider.isAuthenticated) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Por favor inicia sesión.'));
    }

    return Scaffold(
      // AppBar removed
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Info
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              
              // Stats Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, Icons.favorite, 'Vidas', '${user.lives}', Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(context, Icons.local_fire_department, 'Racha', '${user.streakCount} días', Colors.orange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(context, Icons.star, 'XP Total', '${user.xpTotal}', Colors.amber)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard(context, Icons.music_note, 'Notas Oro', '${user.goldNotes}', Colors.yellow.shade800)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Ranking Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          "Liga ${user.league ?? 'Bronce'}",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900),
                        ),
                        Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 32),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _rankingFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                           return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                           return Text("Error al cargar ranking: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                           return const Text("No hay datos de ranking disponibles.");
                        }
                        
                        final ranking = snapshot.data!;
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ranking.length,
                          itemBuilder: (context, index) {
                            final entry = ranking[index];
                            final isMe = entry['id'] == user.id;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.yellow.shade100 : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: isMe ? Border.all(color: Colors.amber) : null,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRankColor(index + 1),
                                  foregroundColor: Colors.white,
                                  radius: 14,
                                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(
                                  entry['name'] ?? 'Usuario',
                                  style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                                ),
                                trailing: Text(
                                  '${entry['xp_total']} XP',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.deepPurple.shade200;
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
