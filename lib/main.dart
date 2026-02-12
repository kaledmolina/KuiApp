
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/ear_training/presentation/ear_training_screen.dart';
import 'features/ear_training/data/lesson_repository.dart';
import 'core/api_client.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
      ],
      child: const MyApp(),
    ),
  );
}

// Router configuration
final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) {
         // Simple DI for now
         final apiClient = ApiClient();
         final repository = LessonRepository(apiClient);
         return EarTrainingScreen(repository: repository);
      },
    ),
  ],
  redirect: (context, state) {
    // Simple redirect logic
    // final authProvider = context.read<AuthProvider>();
    // if (!authProvider.isAuthenticated && state.matchedLocation != '/login') {
    //   return '/login';
    // }
    return null; 
  },
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kui App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      routerConfig: _router,
    );
  }
}

// Simple Home Screen for redirection test
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome! You are logged in.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                 context.push('/lesson/1');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Start Lesson 1 (Ear Training)', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                 context.read<AuthProvider>().logout();
                 context.go('/login');
              },
              child: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}
