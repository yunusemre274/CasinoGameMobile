import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/casino/casino_page.dart';
import '../../features/casino/games/roulette_page.dart';
import '../../features/casino/games/blackjack_page.dart';
import '../../features/casino/games/horse_race_page.dart';
import '../../features/casino/games/coin_flip_page.dart';
import '../../features/casino/games/slot_machine_page.dart';
import '../../features/casino/games/aviator_page.dart';
import '../../features/casino/games/dev_simulation_page.dart';
import '../../features/inventory/inventory_page.dart';
import '../../features/market/market_page.dart';
import '../../features/buildings/buildings_page.dart';
import '../../features/buildings/home_page.dart';
import '../../features/buildings/hospital_page.dart';
import '../../features/buildings/secure_building_page.dart';
import '../../features/buildings/gang_building_page.dart';
import '../../features/street_jobs/street_jobs_page.dart';
import '../../features/street_jobs/math_quiz_page.dart';
import '../../features/street_jobs/match_samples_page.dart';
import '../../features/street_jobs/code_breaker_page.dart';
import '../../features/street_jobs/guess_game_page.dart';
import '../../features/stats/stats_page.dart';
import '../../shared/widgets/main_shell.dart';

// App Router - Navigation configuration using go_router
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/casino',
    routes: [
      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Casino tab
          GoRoute(
            path: '/casino',
            name: 'casino',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CasinoPage()),
          ),
          // Inventory tab
          GoRoute(
            path: '/inventory',
            name: 'inventory',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InventoryPage()),
          ),
          // Market tab
          GoRoute(
            path: '/market',
            name: 'market',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MarketPage()),
          ),
          // Buildings tab
          GoRoute(
            path: '/buildings',
            name: 'buildings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BuildingsPage()),
          ),
        ],
      ),
      // Street Jobs (full screen)
      GoRoute(
        path: '/street-jobs',
        name: 'street-jobs',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const StreetJobsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Casino Games
      GoRoute(
        path: '/roulette',
        name: 'roulette',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const RoulettePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/blackjack',
        name: 'blackjack',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const BlackjackPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/horse-race',
        name: 'horse-race',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HorseRacePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/coin-flip',
        name: 'coin-flip',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const CoinFlipPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/slot-machine',
        name: 'slot-machine',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SlotMachinePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/aviator',
        name: 'aviator',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AviatorPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Dev Simulation Page (for testing casino odds)
      GoRoute(
        path: '/dev-simulation',
        name: 'dev-simulation',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const DevSimulationPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Math Quiz (full screen - from Street Jobs)
      GoRoute(
        path: '/math-quiz',
        name: 'math-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MathQuizPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Match Samples (full screen - from Street Jobs)
      GoRoute(
        path: '/match-samples',
        name: 'match-samples',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MatchSamplesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Code Breaker (full screen - from Street Jobs)
      GoRoute(
        path: '/code-breaker',
        name: 'code-breaker',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const CodeBreakerPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Guess Game (full screen - from Street Jobs)
      GoRoute(
        path: '/guess-game',
        name: 'guess-game',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const GuessGamePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Home (full screen - from Buildings)
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Hospital (full screen - from Buildings)
      GoRoute(
        path: '/hospital',
        name: 'hospital',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const HospitalPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Secure Building (full screen - from Buildings)
      GoRoute(
        path: '/secure-building',
        name: 'secure-building',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SecureBuildingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Gang Building (full screen - from Buildings)
      GoRoute(
        path: '/gang-building',
        name: 'gang-building',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const GangBuildingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
      // Character Stats (full screen)
      GoRoute(
        path: '/stats',
        name: 'stats',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const StatsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
