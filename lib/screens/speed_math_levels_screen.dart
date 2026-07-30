import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'speed_math_game_screen.dart';

class SpeedMathLevelsScreen extends StatefulWidget {
  const SpeedMathLevelsScreen({super.key});
  @override State<SpeedMathLevelsScreen> createState() => _LevelsState();
}

class _LevelsState extends State<SpeedMathLevelsScreen> {
  late Box _box;
  int _unlockedUpTo = 1; // level 1 always unlocked

  // Level config
  static const _totalLevels = 30;

  static Box getBox() => Hive.box('userBox');

  static Map<String, dynamic> levelConfig(int level) {
    // Timer
    int timer;
    if (level <= 5)       timer = 120; // 2 min
    else if (level <= 10) timer = 90;  // 1:30
    else if (level <= 25) timer = 60;  // 1 min
    else                  timer = 15;  // 15 sec

    // Questions count
    int qCount;
    if (level <= 5)       qCount = 5;
    else if (level <= 15) qCount = 7;
    else                  qCount = 10;

    // Difficulty
    String diff;
    if (level <= 5)       diff = 'easy';
    else if (level <= 15) diff = 'medium';
    else                  diff = 'hard';

    // Points
    int pts = level * 10;

    // Icon & color — unique per group
    String icon; Color color; String bg;
    if (level <= 5) {
      icon = '🌱'; color = const Color(0xFF38EF7D); bg = 'easy';
    } else if (level <= 10) {
      icon = '⚡'; color = const Color(0xFF3B82F6); bg = 'medium';
    } else if (level <= 15) {
      icon = '🔥'; color = const Color(0xFFF7971E); bg = 'medium';
    } else if (level <= 20) {
      icon = '💎'; color = const Color(0xFFA78BFA); bg = 'hard';
    } else if (level <= 25) {
      icon = '🌀'; color = const Color(0xFFE8345A); bg = 'hard';
    } else {
      icon = '👑'; color = const Color(0xFFFFD700); bg = 'expert';
    }

    return {
      'timer': timer,
      'qCount': qCount,
      'diff': diff,
      'pts': pts,
      'icon': icon,
      'color': color,
      'bg': bg,
      'timerLabel': timer >= 60
          ? '${timer ~/ 60}:${(timer % 60).toString().padLeft(2,'0')}'
          : '${timer}s',
    };
  }

  @override
  void initState() {
    super.initState();
    _box = Hive.box('userBox');
    _unlockedUpTo = _box.get('speedmath_unlocked', defaultValue: 1);
  }

  void _refreshUnlocked() {
    setState(() {
      _unlockedUpTo = _box.get('speedmath_unlocked', defaultValue: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              border: Border(bottom: BorderSide(
                color: Colors.white.withOpacity(0.04)))),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0E17),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Speed Math',
                  style: GoogleFonts.inter(fontSize: 20,
                    fontWeight: FontWeight.w800, color: Colors.white)),
                Text('$_unlockedUpTo/$_totalLevels levels unlocked',
                  style: GoogleFonts.inter(fontSize: 12,
                    color: Colors.white.withOpacity(0.4))),
              ]),
              const Spacer(),
              const Text('⚡', style: TextStyle(fontSize: 28)),
            ]),
          ),

          // ── Legend ────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(children: [
              _legend('🌱', 'Starter', const Color(0xFF38EF7D)),
              _legend('⚡', 'Easy', const Color(0xFF3B82F6)),
              _legend('🔥', 'Medium', const Color(0xFFF7971E)),
              _legend('💎', 'Hard', const Color(0xFFA78BFA)),
              _legend('🌀', 'Expert', const Color(0xFFE8345A)),
              _legend('👑', 'Master', const Color(0xFFFFD700)),
            ]),
          ),

          // ── Level Grid ────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _totalLevels,
              itemBuilder: (_, i) {
                final level   = i + 1;
                final config  = levelConfig(level);
                final unlocked = level <= _unlockedUpTo;
                final completed = level < _unlockedUpTo;
                final color   = config['color'] as Color;
                final stars   = _box.get('level_${level}_stars', defaultValue: 0) as int;

                return GestureDetector(
                  onTap: unlocked ? () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SpeedMathGameScreen(level: level),
                    ));
                    _refreshUnlocked();
                  } : () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔒 Complete level ${level - 1} to unlock!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFF1C1C2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: unlocked
                        ? color.withOpacity(completed ? 0.15 : 0.1)
                        : const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: unlocked
                          ? color.withOpacity(completed ? 0.6 : 0.3)
                          : Colors.white.withOpacity(0.05),
                        width: level == _unlockedUpTo ? 2 : 1),
                      boxShadow: level == _unlockedUpTo ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 16, offset: const Offset(0, 4))
                      ] : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top — level number
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: unlocked
                                    ? color.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Text('$level',
                                  style: GoogleFonts.inter(
                                    fontSize: 11, fontWeight: FontWeight.w800,
                                    color: unlocked
                                      ? color : Colors.white.withOpacity(0.2))),
                              ),
                              if (completed && stars > 0)
                                Row(children: List.generate(3, (si) =>
                                  Text(si < stars ? '⭐' : '☆',
                                    style: const TextStyle(fontSize: 8)))),
                            ],
                          ),

                          // Middle — icon
                          Text(
                            unlocked ? config['icon'] as String : '🔒',
                            style: TextStyle(
                              fontSize: 32,
                              color: unlocked ? null : Colors.white.withOpacity(0.15)),
                          ),

                          // Bottom — timer + current tag
                          Column(children: [
                            Text(config['timerLabel'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: unlocked
                                  ? color : Colors.white.withOpacity(0.2))),
                            if (level == _unlockedUpTo)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6)),
                                child: Text('PLAY',
                                  style: GoogleFonts.inter(
                                    fontSize: 8, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _legend(String icon, String label, Color color) => Container(
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
