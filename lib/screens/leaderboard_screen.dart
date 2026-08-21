import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/user_provider.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _globalData = [];
  List<dynamic> _weeklyData = [];
  bool _isLoading = true;

  static const _background = Color(0xFF0B0B12);
  static const _surface = Color(0xFF161622);
  static const _surfaceBorder = Color(0xFF232334);
  static const _primary = Color(0xFF8B5CF6);
  static const _gold = Color(0xFFFFD700);
  static const _silver = Color(0xFFC0C0C0);
  static const _bronze = Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaderboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final global = await ApiService.getGlobalLeaderboard();
      final weekly = await ApiService.getWeeklyLeaderboard();
      
      final currentUser = ref.read(userProvider);

      if (mounted) {
        setState(() {
          _globalData = _mergeLocalUserScore(global, currentUser, 'brain_score');
          _weeklyData = _mergeLocalUserScore(weekly, currentUser, 'weekly_score');
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Live Sync Helper: Local state aur backend score me jo bada hai usko live render karta hai
  List<dynamic> _mergeLocalUserScore(
      List<dynamic> rawList, dynamic currentUser, String scoreKey) {
    if (currentUser.username.isEmpty && currentUser.userId == null) return rawList;

    List<dynamic> merged = List.from(rawList);
    bool found = false;

    for (int i = 0; i < merged.length; i++) {
      var user = Map<String, dynamic>.from(merged[i]);
      if (user['username'] == currentUser.username || user['id'] == currentUser.userId) {
        found = true;
        int backendScore = (user[scoreKey] ?? 0) as int;
        
        // Agar local score bada hai toh UI par live update dikhao aur background me backend sync triggering karo
        if (currentUser.brainScore > backendScore) {
          user[scoreKey] = currentUser.brainScore;
          if (currentUser.userId != null) {
            ApiService.submitScore(
              userId: currentUser.userId!,
              puzzleId: 1,
              score: currentUser.brainScore,
              timeTaken: 0,
              hintsUsed: 0,
              completed: true,
            );
          }
        }
        merged[i] = user;
        break;
      }
    }

    // Agar current user list me nahi hai par score > 0 hai
    if (!found && currentUser.brainScore > 0) {
      merged.add({
        'id': currentUser.userId,
        'username': currentUser.username,
        'avatar': currentUser.avatar,
        scoreKey: currentUser.brainScore,
        'current_streak': currentUser.currentStreak,
        'rank': merged.length + 1,
      });
    }

    // Sort by Score descending
    merged.sort((a, b) => ((b[scoreKey] ?? 0) as int).compareTo((a[scoreKey] ?? 0) as int));

    // Re-assign ranks
    for (int i = 0; i < merged.length; i++) {
      var item = Map<String, dynamic>.from(merged[i]);
      item['rank'] = i + 1;
      merged[i] = item;
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEADERBOARD 🏆',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Top cognitive performers worldwide',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _fetchLeaderboardData,
                        icon: const Icon(Icons.refresh_rounded, color: _primary),
                        style: IconButton.styleFrom(
                          backgroundColor: _surface,
                          side: const BorderSide(color: _surfaceBorder),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _surfaceBorder),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLeaderboardList(_globalData, 'brain_score'),
                        _buildLeaderboardList(_weeklyData, 'weekly_score'),
                      ],
                    ),
            ),
            _floatingBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<dynamic> data, String scoreKey) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No scores yet. Play games to rank up!',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final top3 = data.take(3).toList();
    final remaining = data.skip(3).toList();
    final currentUser = ref.watch(userProvider);

    return RefreshIndicator(
      onRefresh: _fetchLeaderboardData,
      color: _primary,
      backgroundColor: _surface,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          if (top3.isNotEmpty) _podiumSection(top3, scoreKey),
          const SizedBox(height: 16),
          ...remaining.map((u) {
            final isCurrentUser = u['username'] == currentUser.username ||
                u['id'] == currentUser.userId;
            return _rankTile(u, scoreKey, isCurrentUser);
          }),
        ],
      ),
    );
  }

  Widget _podiumSection(List<dynamic> top3, String scoreKey) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null) Expanded(child: _podiumCard(second, 2, _silver, scoreKey)),
        const SizedBox(width: 8),
        if (first != null) Expanded(child: _podiumCard(first, 1, _gold, scoreKey)),
        const SizedBox(width: 8),
        if (third != null) Expanded(child: _podiumCard(third, 3, _bronze, scoreKey)),
      ],
    );
  }

  Widget _podiumCard(Map<dynamic, dynamic> user, int rank, Color badgeColor, String scoreKey) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: rank == 1 ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(rank == 1 ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rank == 1 ? '🥇 1ST' : rank == 2 ? '🥈 2ND' : '🥉 3RD',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
            ),
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            radius: rank == 1 ? 22 : 18,
            backgroundColor: badgeColor.withOpacity(0.2),
            child: Text(user['avatar'] ?? '🧠', style: TextStyle(fontSize: rank == 1 ? 20 : 16)),
          ),
          const SizedBox(height: 6),
          Text(
            user['username'] ?? 'Player',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Text(
            '${user[scoreKey] ?? 0} pts',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _rankTile(Map<dynamic, dynamic> user, String scoreKey, bool isCurrentUser) {
    final rank = user['rank'] ?? 4;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? _primary.withOpacity(0.15) : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? _primary : _surfaceBorder,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white38),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _surfaceBorder),
            ),
            child: Center(child: Text(user['avatar'] ?? '🧠', style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['username'] ?? 'Player',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                        child: Text('YOU', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                if (user['current_streak'] != null)
                  Text('🔥 ${user['current_streak']} day streak', style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
          Text(
            '${user[scoreKey] ?? 0}',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _floatingBottomNavBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      height: 64,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, icon: Icons.grid_view_rounded, label: 'HOME', active: false, route: '/home'),
          _navItem(context, icon: Icons.leaderboard_rounded, label: 'RANKS', active: true, route: '/leaderboard'),
          _navItem(context, icon: Icons.person_rounded, label: 'PROFILE', active: false, route: '/profile'),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool active, required String route}) {
    return GestureDetector(
      onTap: () {
        if (!active) context.go(route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: active ? _primary : Colors.white30),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? Colors.white : Colors.white30)),
        ],
      ),
    );
  }
}