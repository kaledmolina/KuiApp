import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      // If authenticated but user not loaded yet
      if (authProvider.isAuthenticated) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Please log in.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            context.read<AuthProvider>().logout();
          },
        )
      ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              _buildStatCard(context, Icons.favorite, 'Lives', '${user.lives}', Colors.red),
              const SizedBox(height: 16),
              _buildStatCard(context, Icons.local_fire_department, 'Streak', '${user.streakCount} days', Colors.orange),
              const SizedBox(height: 16),
              _buildStatCard(context, Icons.star, 'XP', '${user.xpTotal}', Colors.amber),
              const SizedBox(height: 16),
              _buildStatCard(context, Icons.music_note, 'Gold Notes', '${user.goldNotes}', Colors.yellow.shade800),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(value, style: const TextStyle(fontSize: 20)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
