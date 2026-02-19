
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/ear_training/presentation/ear_training_screen.dart';
import 'features/ear_training/data/lesson_repository.dart';
import 'core/api_client.dart';
import 'features/home/presentation/tabs/levels_tab.dart';
import 'features/home/presentation/tabs/practice_tab.dart';
import 'features/home/presentation/tabs/profile_tab.dart';
import 'features/home/presentation/tabs/ranking_tab.dart';
import 'features/home/presentation/widgets/streak_modal.dart';

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
             final difficulty = state.extra as int? ?? 1;
             return EarTrainingScreen(repository: repository, difficulty: difficulty);
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
      title: 'Kui',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE), // Deep Purple
          brightness: Brightness.light,
          primary: const Color(0xFF6200EE),
          secondary: const Color(0xFF03DAC6),
          tertiary: const Color(0xFFFFD700), // Gold for gamification
        ),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF6200EE),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
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
    RankingTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      appBar: AppBar(
        title: const Text('Kui'),
        actions: [
          _buildStreakBadge(context),
          IconButton(
            icon: const Icon(LineIcons.alternateSignOut),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Theme.of(context).primaryColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: const [
                GButton(
                  icon: LineIcons.music,
                  text: 'Niveles',
                ),
                GButton(
                  icon: LineIcons.stopwatch,
                  text: 'Práctica',
                ),
                GButton(
                  icon: LineIcons.trophy,
                  text: 'Ranking',
                ),
                GButton(
                  icon: LineIcons.user,
                  text: 'Perfil',
                ),
              ],
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final streak = user?.streakCount ?? 0;
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const StreakModal(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(LineIcons.fire, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
