import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'logic_puzzle_screen.dart';
import 'memory_game_screen.dart';
import 'reaction_chain_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyState();
}

class _DailyState extends State<DailyChallengeScreen> {
  Map<String, dynamic>? _challenge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDailyChallenge();
      setState(() {
        _challenge = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // Today's game config based on API 'type' or Day of Week fallback
  _DailyGameConfig _getGameConfig() {
    final type = (_challenge?['type'] ?? _fallbackTypeByDay()).toString().toLowerCase();

    switch (type) {
      case 'memory':
        return _DailyGameConfig(
          gameName: 'Memory Matrix',
          badgeText: 'MEMORY CHALLENGE',
          description: 'Memorize positions and clear the grid with maximum accuracy.',
          icon: Icons.psychology_rounded,
          gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          accentColor: const Color(0xFF8B5CF6),
          targetScreen: MemoryGameScreen(level: _challenge?['level'] ?? 5),
        );

      case 'reaction':
        return _DailyGameConfig(
          gameName: 'Speed Reaction',
          badgeText: 'REACTION TIME',
          description: 'Test your reflex speed! Tap active triggers as fast as possible.',
          icon: Icons.bolt_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
          accentColor: const Color(0xFFF59E0B),
          targetScreen: const ReactionChainScreen(),
        );

      case 'logic':
      default:
        return _DailyGameConfig(
          gameName: 'Logic Puzzle',
          badgeText: 'LOGIC & REASONING',
          description: 'Solve today\'s pattern algorithm using deduction and sequence.',
          icon: Icons.extension_rounded,
          gradient: const [Color(0xFF6366F1), Color(0xFF3B82F6)],
          accentColor: const Color(0xFF6366F1),
          targetScreen: const LogicPuzzleScreen(),
        );
    }
  }

  // Fallback if API doesn't return a game type (rotates based on weekday)
  String _fallbackTypeByDay() {
    final day = DateTime.now().weekday;
    if (day % 3 == 1) return 'logic';
    if (day % 3 == 2) return 'memory';
    return 'reaction';
  }

  @override
  Widget build(BuildContext context) {
    final gameConfig = _getGameConfig();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Challenge',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 3,
              ),
            )
          : _challenge == null
              ? _buildErrorView()
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Featured Dynamic Game Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161622),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: gameConfig.accentColor.withOpacity(0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gameConfig.accentColor.withOpacity(0.15),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Top Icon Badge
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: gameConfig.gradient,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gameConfig.accentColor.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  gameConfig.icon,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Dynamic Game Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: gameConfig.accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  gameConfig.badgeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: gameConfig.accentColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Title
                              Text(
                                gameConfig.gameName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Date Chip
                              if (_challenge!['date'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _challenge!['date'].toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Game Description Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161622),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: gameConfig.accentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: gameConfig.accentColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Objective',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      gameConfig.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Launch Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => gameConfig.targetScreen,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gameConfig.accentColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Play Challenge',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load challenge',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Config Helper Class
class _DailyGameConfig {
  final String gameName;
  final String badgeText;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final Widget targetScreen;

  _DailyGameConfig({
    required this.gameName,
    required this.badgeText,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.targetScreen,
  });
}