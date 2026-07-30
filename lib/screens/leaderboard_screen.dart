import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:go_router/go_router.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override State<LeaderboardScreen> createState() => _LBState();
}

class _LBState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _global = [], _weekly = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final g = await ApiService.getGlobalLeaderboard();
      final w = await ApiService.getWeeklyLeaderboard();
      setState(() { _global = g; _weekly = w; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(
          children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Leaderboard 🏆',
                      style: GoogleFonts.inter(fontSize: 26,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('Top brains worldwide',
                      style: GoogleFonts.inter(fontSize: 13,
                        color: Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(14)),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                          color: const Color(0xFFA78BFA),
                          borderRadius: BorderRadius.circular(10)),
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor:
                          Colors.white.withOpacity(0.35),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700),
                        tabs: const [
                          Tab(text: 'ALL TIME'),
                          Tab(text: 'THIS WEEK'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFFA78BFA)))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _list(_global, 'brain_score'),
                        _list(_weekly, 'weekly_score'),
                      ],
                    ),
              ),
            ]),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _bottomNavBar(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List data, String key) {
    if (data.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🎮', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Play games to appear here!',
            style: GoogleFonts.inter(fontSize: 15,
              color: Colors.white.withOpacity(0.4))),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final u = data[i];
        final rank = u['rank'] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 1
                ? const Color(0xFFFFD700).withOpacity(0.4)
                : rank == 2
                  ? const Color(0xFFC0C0C0).withOpacity(0.3)
                  : rank == 3
                    ? const Color(0xFFCD7F32).withOpacity(0.3)
                    : Colors.white.withOpacity(0.04)),
          ),
          child: Row(children: [
            SizedBox(width: 32,
              child: Text(
                rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉'
                  : '#$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rank <= 3 ? 20 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.5)))),
            const SizedBox(width: 10),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
                borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(u['avatar'] ?? '🧠',
                  style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['username'] ?? 'Player',
                    style: GoogleFonts.inter(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                  if (u['current_streak'] != null)
                    Text('🔥 ${u['current_streak']} day streak',
                      style: GoogleFonts.inter(fontSize: 11,
                        color: Colors.white.withOpacity(0.35))),
                ],
              ),
            ),
            Text('${u[key] ?? 0}',
              style: GoogleFonts.inter(fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFA78BFA))),
          ]),
        );
      },
    );
  }
}

Widget _bottomNavBar(BuildContext context) {
  return Container(
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF0F0E17).withOpacity(0.95),
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
    ),
    child: Row(children: [
      _ni(context, '🏠', 'HOME', false, '/home'),
      _ni(context, '🏆', 'RANKS', true, '/leaderboard'),
      _ni(context, '👤', 'PROFILE', false, '/profile'),
    ]),
  );
}

Widget _ni(BuildContext ctx, String em, String lb, bool active, String route) {
  return Expanded(
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
}
