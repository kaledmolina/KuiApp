import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../ear_training/data/lesson_repository.dart';
import '../../../../core/api_client.dart';

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
    // Load ranking on init
    final repo = LessonRepository(ApiClient());
    _rankingFuture = repo.getRanking();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      // AppBar removed to use main scaffold AppBar logic if needed, 
      // but strictly speaking this is a main tab so it fits under the main structure.
      // However, usually tabs have their own internal structure or share the main one.
      // We will assume it shares the main one, so no AppBar here.
      body: Column(
        children: [
          // Header / Filter (Mental Placeholder for now)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(
                  "Clasificación Global",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _rankingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Text("No hay datos disponibles."));
                }
                
                final ranking = snapshot.data!;
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    final entry = ranking[index];
                    final isMe = currentUser != null && entry['id'] == currentUser.id;
                    final leagueName = entry['league'] ?? 'Bronce';
                    
                    return Card(
                      elevation: isMe ? 4 : 1,
                      color: isMe ? Colors.yellow.shade50 : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isMe ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRankColor(index + 1),
                          foregroundColor: Colors.white,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          entry['name'] ?? 'Usuario',
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "Liga $leagueName",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry['xp_total']} XP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return Colors.blueGrey.shade200;
  }
}
