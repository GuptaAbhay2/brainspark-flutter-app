import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/speed_math_levels_screen.dart';
import '../screens/logic_puzzle_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/memory_levels_screen.dart';
import '../screens/reaction_chain_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',         builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login',          builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/home',           builder: (c, s) => const HomeScreen()),
    GoRoute(path: '/speed-math',     builder: (c, s) => const SpeedMathLevelsScreen()),
    GoRoute(path: '/logic',          builder: (c, s) => const LogicPuzzleScreen()),
    GoRoute(path: '/daily',          builder: (c, s) => const DailyChallengeScreen()),
    GoRoute(path: '/leaderboard',    builder: (c, s) => const LeaderboardScreen()),
    GoRoute(path: '/profile',        builder: (c, s) => const ProfileScreen()),
    GoRoute(path: '/memory',         builder: (c, s) => const MemoryLevelsScreen()),
    GoRoute(path: '/number-tap', builder: (c, s) => const ReactionChainScreen()),
  ],
);
