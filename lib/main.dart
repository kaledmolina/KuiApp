
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/ear_training/presentation/ear_training_screen.dart';
import 'features/ear_training/data/lesson_repository.dart';
import 'core/api_client.dart';
import 'features/home/presentation/tabs/levels_tab.dart';
import 'features/home/presentation/tabs/practice_tab.dart';
import 'features/home/presentation/tabs/profile_tab.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // We need to access the AuthProvider to set up the router's refreshListenable
    // Since we are in initState, we can access the provider context.
    final authProvider = context.read<AuthProvider>();

    _router = GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/home', // Optimistic, let redirect handle logic
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
             final apiClient = ApiClient();
             final repository = LessonRepository(apiClient);
             return EarTrainingScreen(repository: repository);
          },
        ),
      ],
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        
        // If not logged in and not on login page, go to login
        if (!isLoggedIn && !isLoggingIn) return '/login';
        
        // If logged in and on login page, go to home
        if (isLoggedIn && isLoggingIn) return '/home';
        
        return null; 
      },
    );
  }

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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    LevelsTab(),
    PracticeTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Levels',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
