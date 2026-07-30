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
    final badges = [
      {'em': '🎮', 'nm': 'FIRST GAME',  'earned': user.totalGames >= 1},
      {'em': '🔥', 'nm': '3 DAYS',      'earned': user.longestStreak >= 3},
      {'em': '⚡', 'nm': '7 DAYS',      'earned': user.longestStreak >= 7},
      {'em': '👑', 'nm': '30 DAYS',     'earned': user.longestStreak >= 30},
      {'em': '💯', 'nm': 'SCORE 100',   'earned': user.brainScore >= 100},
      {'em': '🚀', 'nm': 'SCORE 1K',    'earned': user.brainScore >= 1000},
      {'em': '✨', 'nm': 'PERFECT',     'earned': false},
      {'em': '🧠', 'nm': 'MASTER',      'earned': user.brainScore >= 5000},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                // ── Profile Top ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Center(child: Text(user.avatar,
                        style: const TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 14),
                    Text(user.username.isEmpty ? 'Player' : user.username,
                      style: GoogleFonts.inter(fontSize: 22,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(user.email,
                      style: GoogleFonts.inter(fontSize: 13,
                        color: Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA78BFA).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFA78BFA).withOpacity(0.3))),
                      child: Text('🏆 Global Rank #–',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA78BFA))),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Stats ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _statCard('🧠', '${user.brainScore}', 'BRAIN SCORE'),
                    const SizedBox(width: 10),
                    _statCard('🔥', '${user.currentStreak}', 'STREAK'),
                    const SizedBox(width: 10),
                    _statCard('🎮', '${user.totalGames}', 'GAMES'),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Badges ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Badges',
                        style: GoogleFonts.inter(fontSize: 16,
                          fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 10, crossAxisSpacing: 10,
                        children: badges.map((b) {
                          final earned = b['earned'] as bool;
                          return Opacity(
                            opacity: earned ? 1.0 : 0.25,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: earned
                                    ? const Color(0xFFA78BFA).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.04))),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(b['em'] as String,
                                    style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 5),
                                  Text(b['nm'] as String,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.5))),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Logout ──────────────────────────────
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
                          color: const Color(0xFFE8345A).withOpacity(0.3))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                            color: Color(0xFFE8345A), size: 18),
                          const SizedBox(width: 8),
                          Text('Logout',
                            style: GoogleFonts.inter(fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE8345A))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ]),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _profNav(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String em, String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
        child: Column(children: [
          Text(em, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(val, style: GoogleFonts.inter(fontSize: 18,
            fontWeight: FontWeight.w800, color: Colors.white)),
          Text(lbl, style: GoogleFonts.inter(fontSize: 8,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.35))),
        ]),
      ),
    );
  }
}

Widget _profNav(BuildContext context) {
  return Container(
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF0F0E17).withOpacity(0.95),
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
    ),
    child: Row(children: [
      _pni(context, '🏠', 'HOME', false, '/home'),
      _pni(context, '🏆', 'RANKS', false, '/leaderboard'),
      _pni(context, '👤', 'PROFILE', true, '/profile'),
    ]),
  );
}

Widget _pni(BuildContext ctx, String em, String lb, bool active, String route) =>
  Expanded(
    child: GestureDetector(
      onTap: () => ctx.go(route),
      child: Container(
        color: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(em, style: TextStyle(fontSize: 22,
            color: active ? Colors.white : Colors.white.withOpacity(0.3))),
          const SizedBox(height: 3),
          Text(lb, style: GoogleFonts.inter(fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFFA78BFA) : Colors.white.withOpacity(0.3))),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 4 : 0, height: active ? 4 : 0,
            decoration: const BoxDecoration(
              color: Color(0xFFA78BFA), shape: BoxShape.circle)),
        ]),
      ),
    ),
  );
