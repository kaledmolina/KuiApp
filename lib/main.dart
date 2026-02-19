
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/ear_training/presentation/ear_training_screen.dart';
import 'features/ear_training/data/lesson_repository.dart';
import 'core/api_client.dart';
import 'features/home/presentation/tabs/levels_tab.dart';
import 'features/home/presentation/tabs/practice_tab.dart';
import 'features/home/presentation/tabs/profile_tab.dart';
import 'features/home/presentation/tabs/ranking_tab.dart';
import 'features/home/presentation/tabs/store_tab.dart';
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
             final levelId = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
             return EarTrainingScreen(
               repository: repository, 
               levelId: levelId,
               difficulty: difficulty
             );
          },
        ),
      ],
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        print('DEBUG: redirect check. Auth: $isLoggedIn, Loc: ${state.matchedLocation}');
        
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
        fontFamily: GoogleFonts.nunito().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA), // Primary
          brightness: Brightness.light,
          primary: const Color(0xFF6200EA),
          secondary: const Color(0xFF00E676),
          tertiary: const Color(0xFFFFD700),
          background: const Color(0xFFF3F4F6),
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6200EA),
          foregroundColor: Colors.white,
          elevation: 4, // shadow-lg
          shadowColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    StoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      appBar: AppBar(
        title: Text(
          'Kui',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false, // HTML has title on left
        actions: [
          Row(
            children: [
               _buildBadge(Icons.local_fire_department_rounded, Colors.orangeAccent, '1'),
               const SizedBox(width: 8),
               _buildBadge(Icons.favorite_rounded, Colors.redAccent, '5'),
            ],
          ),
          const SizedBox(width: 16),
          // Removed Logout button from header to match design strictly, or can keep it in Profile tab
        ],
      ),
      bottomNavigationBar: Container(
        height: 90 + MediaQuery.of(context).padding.bottom,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 65 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildNavItem(0, Icons.music_note_rounded, 'Niveles'),
                  _buildNavItem(1, Icons.timer_rounded, 'Práctica'),
                  _buildNavItem(2, Icons.emoji_events_rounded, 'Ranking'),
                  _buildNavItem(3, Icons.person_rounded, 'Perfil'),
                  _buildNavItem(4, Icons.storefront_rounded, 'Tienda'),
                ]
              ),
            )
          ]
        )
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final color = const Color(0xFF8B5CF6); // Theme purple to match UI

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              margin: EdgeInsets.only(bottom: isActive ? 4 : 18), 
              padding: EdgeInsets.all(isActive ? 12 : 0),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.transparent, 
                  width: isActive ? 4 : 0
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive ? color.withOpacity(0.3) : Colors.transparent,
                    blurRadius: isActive ? 8 : 0,
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Icon(
                icon, 
                color: isActive ? Colors.white : Colors.grey.shade400, 
                size: 26
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isActive ? 16 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: isActive 
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: GoogleFonts.nunito(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: isActive ? 8 : 0), 
          ],
        )
      )
    );
  }

  Widget _buildBadge(IconData icon, Color iconColor, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // bg-black/20
        borderRadius: BorderRadius.circular(20), // rounded-full
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
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
