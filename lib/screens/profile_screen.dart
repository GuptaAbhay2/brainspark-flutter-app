import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    // Badges Data
    final List<Map<String, dynamic>> badges = [
      {
        'em': '🎮',
        'nm': 'FIRST GAME',
        'desc': 'Played your very first game on BrainSpark',
        'req': 'Play 1 game',
        'earned': user.totalGames >= 1,
      },
      {
        'em': '🔥',
        'nm': '3 DAYS',
        'desc': 'Maintained a 3-day training streak',
        'req': '3 days streak',
        'earned': user.longestStreak >= 3,
      },
      {
        'em': '⚡',
        'nm': '7 DAYS',
        'desc': 'Trained continuously for a whole week',
        'req': '7 days streak',
        'earned': user.longestStreak >= 7,
      },
      {
        'em': '👑',
        'nm': '30 DAYS',
        'desc': 'Ultimate dedication! 30 days unbroken streak',
        'req': '30 days streak',
        'earned': user.longestStreak >= 30,
      },
      {
        'em': '💯',
        'nm': 'SCORE 100',
        'desc': 'Reached a Brain Score of 100 points',
        'req': 'Score 100+ PTS',
        'earned': user.brainScore >= 100,
      },
      {
        'em': '🚀',
        'nm': 'SCORE 1K',
        'desc': 'Reached 1,000 Brain Score threshold',
        'req': 'Score 1000+ PTS',
        'earned': user.brainScore >= 1000,
      },
      {
        'em': '✨',
        'nm': 'PERFECT',
        'desc': 'Scored 100% accuracy in a speed quiz round',
        'req': '100% Accuracy in a game',
        'earned': false,
      },
      {
        'em': '🧠',
        'nm': 'MASTER',
        'desc': 'Became an elite Brain Training Master',
        'req': 'Score 5000+ PTS',
        'earned': user.brainScore >= 5000,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Profile Header with App Icon Image ──────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // App Logo Avatar
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                'assets/icon/app_icon.png', // App logo image asset path
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.psychology_rounded,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Username & Email
                        Text(
                          user.username.isEmpty ? 'Player' : user.username,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email.isEmpty ? 'player@brainspark.app' : user.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Global Competitor Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA78BFA).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFA78BFA).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '🏆 Global Competitor',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFA78BFA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stats Row ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _statCard('🧠', '${user.brainScore}', 'BRAIN SCORE'),
                        const SizedBox(width: 10),
                        _statCard('🔥', '${user.currentStreak}', 'STREAK'),
                        const SizedBox(width: 10),
                        _statCard('🎮', '${user.totalGames}', 'GAMES'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Badges Section ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Badges',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${badges.where((b) => b['earned'] as bool).length}/${badges.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFA78BFA),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Badges Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: badges.map((b) {
                            final earned = b['earned'] as bool;
                            return GestureDetector(
                              onTap: () => _showBadgeDetails(context, b),
                              child: Opacity(
                                opacity: earned ? 1.0 : 0.25,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C2E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: earned
                                          ? const Color(0xFFA78BFA).withOpacity(0.3)
                                          : Colors.white.withOpacity(0.04),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        b['em'] as String,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        b['nm'] as String,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Logout Action ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(userProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8345A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE8345A).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE8345A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE8345A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Spacing for floating navbar
                ],
              ),
            ),

            // ── Floating Rounded Bottom Navigation Bar (App Standard) ──
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildFloatingBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget
  Widget _statCard(String em, String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Text(em, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              lbl,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Badge Details Sheet
  void _showBadgeDetails(BuildContext context, Map<String, dynamic> badge) {
    final earned = badge['earned'] as bool;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge['em'], style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                badge['nm'],
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge['desc'],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: earned
                      ? const Color(0xFF4ADE80).withOpacity(0.12)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: earned
                        ? const Color(0xFF4ADE80).withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  earned ? '✅ Unlocked' : '🔒 Requirement: ${badge['req']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: earned ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Floating Pill Navigation Bar ───────────────────────────
  Widget _buildFloatingBottomNav(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF18172B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context: context,
            icon: Icons.grid_view_rounded,
            label: 'Arenas',
            isActive: false,
            route: '/home',
          ),
          _navItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            label: 'Ranks',
            isActive: false,
            route: '/leaderboard',
          ),
          _navItem(
            context: context,
            icon: Icons.person_rounded,
            label: 'Profile',
            isActive: true,
            route: '/profile',
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required String route,
  }) {
    final activeColor = const Color(0xFFA78BFA);
    final inactiveColor = Colors.white.withOpacity(0.4);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            context.go(route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}