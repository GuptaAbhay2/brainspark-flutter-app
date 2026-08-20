import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _background = Color(0xFF0B0B12);
  static const _surface = Color(0xFF161622);
  static const _surfaceBorder = Color(0xFF232334);
  static const _primary = Color(0xFF8B5CF6); // Modern Violet Accent
  static const _primaryGlow = Color(0x338B5CF6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: _background,
      extendBody: true,

      // ───────────────── APP BAR ─────────────────
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'BRAIN',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'SPARK',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Train your core cognitive skills',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white38,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surfaceBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: _primaryGlow,
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_rounded,
                        color: _primary,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ───────────────── BODY ─────────────────
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1️⃣ DAILY CHALLENGE HERO BANNER (TOP & TALLER)
              _dailyChallengeHeroBanner(context),

              const SizedBox(height: 17),

              // 2️⃣ USER STATS (BELOW DAILY CHALLENGE)
              Row(
                children: [
                  _statCard(
                    value: '${user.currentStreak}',
                    label: 'DAY STREAK',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: const Color(0xFFFF9F43),
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    value: '${user.brainScore}',
                    label: 'BRAIN SCORE',
                    icon: Icons.bolt_rounded,
                    accentColor: _primary,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 3️⃣ TRAINING ARENAS HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Training Arenas',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceBorder),
                    ),
                    child: Text(
                      '4 ARENAS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4️⃣ GAMES GRID
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
                children: [
                  _gameCard(
                    context,
                    title: 'Speed Math',
                    subtitle: 'Calculation speed',
                    assetPath: 'assets/cards/math.png',
                    fallbackIcon: Icons.calculate_rounded,
                    accentColor: const Color(0xFF10B981),
                    route: '/speed-math',
                  ),
                  _gameCard(
                    context,
                    title: 'Pattern Logic',
                    subtitle: 'Logical reasoning',
                    assetPath: 'assets/cards/logic.png',
                    fallbackIcon: Icons.psychology_rounded,
                    accentColor: const Color(0xFF3B82F6),
                    route: '/logic',
                  ),
                  _gameCard(
                    context,
                    title: 'Card Match',
                    subtitle: 'Memory retention',
                    assetPath: 'assets/cards/memory.png',
                    fallbackIcon: Icons.grid_view_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    route: '/memory',
                  ),
                  _gameCard(
                    context,
                    title: 'NumberTap',
                    subtitle: 'Reflex & focus',
                    assetPath: 'assets/cards/reaction.png',
                    fallbackIcon: Icons.speed_rounded,
                    accentColor: const Color(0xFFEC4899),
                    route: '/number-tap',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ───────────────── FLOATING BOTTOM NAV ─────────────────
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        height: 68,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _surfaceBorder),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.grid_view_rounded, // Fixed icon
              label: 'Arenas',
              active: true,
            ),
            _navItem(
              icon: Icons.leaderboard_rounded,
              label: 'Ranks',
              active: false,
            ),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: _navItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── TALL HERO DAILY CHALLENGE BANNER ─────────────────
  Widget _dailyChallengeHeroBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/daily'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF321A5C),
              Color(0xFF170E2B),
            ],
          ),
          border: Border.all(color: _primary.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'DAILY WORKOUT',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+50 XP',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Main Title
            Text(
              "Today's Brain Drill",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Description Subtitle
            Text(
              'Complete 3 quick cognitive rounds to boost your brain score & keep your daily streak alive!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            // Big Full-Width CTA Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'START DAILY DRILL',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── STAT CARD WIDGET ─────────────────
  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── GAME CARD WIDGET ─────────────────
  Widget _gameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String assetPath,
    required IconData fallbackIcon,
    required Color accentColor,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _surfaceBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withOpacity(0.2),
                          _surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        fallbackIcon,
                        size: 48,
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _surface.withOpacity(0.85),
                      _surface,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'START',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── NAV ITEM WIDGET ─────────────────
  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: active ? _primary : Colors.white30,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : Colors.white30,
          ),
        ),
      ],
    );
  }
}