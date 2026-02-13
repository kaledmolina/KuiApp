import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/auth_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  @override
  void initState() {
    super.initState();
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
              
              // Ranking Section Removed as per request
            ],
          ),
        ),
      ),
    );
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
