import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final name = user.username.isEmpty ? 'Player' : user.username;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Bar ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Brain',
                                style: GoogleFonts.inter(
                                  fontSize: 24, fontWeight: FontWeight.w800,
                                  color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Spark',
                                style: GoogleFonts.inter(
                                  fontSize: 24, fontWeight: FontWeight.w800,
                                  color: const Color(0xFFA78BFA)),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C2E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Center(
                              child: Text(user.avatar,
                                style: const TextStyle(fontSize: 20))),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Streak + Score Bar ───────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${user.currentStreak} Day Streak',
                                style: GoogleFonts.inter(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                              Text("Don't break it today!",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${user.brainScore}',
                              style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: const Color(0xFFA78BFA))),
                            Text('BRAIN SCORE',
                              style: GoogleFonts.inter(
                                fontSize: 9, fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.35))),
                          ],
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Daily Challenge ──────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => context.push('/daily'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE8345A), Color(0xFFFF6B35)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8345A).withOpacity(0.35),
                              blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text('⚡ DAILY CHALLENGE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9, fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.8)),
                                ),
                                const SizedBox(height: 10),
                                Text("Today's Puzzle\nis Live!",
                                  style: GoogleFonts.inter(
                                    fontSize: 20, fontWeight: FontWeight.w800,
                                    color: Colors.white, height: 1.2)),
                                const SizedBox(height: 6),
                                Text('Same for everyone · Tap now',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.65))),
                              ],
                            ),
                          ),
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Games Section ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Games',
                          style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                        Text('4 modes',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: const Color(0xFFA78BFA))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Square Game Grid ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _gameSquare(context,
                          emoji: '⚡', tag: 'SPEED',
                          name: 'Speed\nMath',
                          colors: [const Color(0xFFFF6B35), const Color(0xFFF7971E)],
                          route: '/speed-math', isNew: false),
                        _gameSquare(context,
                          emoji: '🧩', tag: 'LOGIC',
                          name: 'Pattern\nPuzzle',
                          colors: [const Color(0xFF6C63FF), const Color(0xFFA78BFA)],
                          route: '/logic', isNew: false),
                        
                        _gameSquare(context,
                          emoji: '🃏', tag: 'MEMORY',
                          name: 'Card\nMatch',
                          colors: [const Color(0xFFE8345A), const Color(0xFFFF6B6B)],
                          route: '/memory', isNew: true),
                        _gameSquare(context,
                          emoji: '🎯', tag: 'REFLEX',
                          name: 'Number\nTap',
                          colors: [const Color(0xFFF7971E), const Color(0xFFFFD200)],
                          route: '/reaction-chain', isNew: true),
                       
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ── Bottom Nav ───────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _bottomNav(context, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameSquare(BuildContext context, {
    required String emoji,
    required String tag,
    required String name,
    required List<Color> colors,
    required String route,
    required bool isNew,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            // BG circle deco
            Positioned(
              bottom: -16, right: -16,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tag,
                        style: GoogleFonts.inter(
                          fontSize: 8, fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 0.6)),
                      const SizedBox(height: 4),
                      Text(name,
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('NEW',
                    style: GoogleFonts.inter(
                      fontSize: 8, fontWeight: FontWeight.w800,
                      color: colors[0])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _bottomNav(BuildContext context, int active) {
  return Container(
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF0F0E17).withOpacity(0.95),
      border: Border(
        top: BorderSide(color: Colors.white.withOpacity(0.06))),
    ),
    child: Row(
      children: [
        _navItem(context, '🏠', 'HOME', active == 0, '/home'),
        _navItem(context, '🏆', 'RANKS', active == 1, '/leaderboard'),
        _navItem(context, '👤', 'PROFILE', active == 2, '/profile'),
      ],
    ),
  );
}

Widget _navItem(BuildContext ctx, String emoji, String label,
    bool active, String route) {
  return Expanded(
    child: GestureDetector(
      onTap: () => ctx.go(route),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji,
              style: TextStyle(
                fontSize: 22,
                color: active ? Colors.white : Colors.white.withOpacity(0.3))),
            const SizedBox(height: 3),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 9, fontWeight: FontWeight.w600,
                color: active
                  ? const Color(0xFFA78BFA)
                  : Colors.white.withOpacity(0.3))),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 4 : 0,
              height: active ? 4 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFFA78BFA),
                shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    ),
  );
}
