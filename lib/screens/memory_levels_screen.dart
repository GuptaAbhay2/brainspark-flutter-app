import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'memory_game_screen.dart';

class MemoryLevelsScreen extends StatefulWidget {
  const MemoryLevelsScreen({super.key});
  @override State<MemoryLevelsScreen> createState() => _MemLevelsState();
}

class _MemLevelsState extends State<MemoryLevelsScreen> {
  late Box _box;
  int _unlockedUpTo = 1;
  static const _totalLevels = 30;
  final _scrollCtrl = ScrollController();

  static Map<String, dynamic> levelConfig(int level) {
    int pairs;
    if (level <= 5)       pairs = 4;
    else if (level <= 10) pairs = 6;
    else if (level <= 15) pairs = 8;
    else if (level <= 20) pairs = 10;
    else if (level <= 25) pairs = 12;
    else                  pairs = 15;

    int timer;
    if (level <= 5)       timer = 120;
    else if (level <= 10) timer = 90;
    else if (level <= 25) timer = 60;
    else                  timer = 45;

    double bufferMultiplier;
    if (level <= 5)       bufferMultiplier = 2.2;
    else if (level <= 10) bufferMultiplier = 2.0;
    else if (level <= 15) bufferMultiplier = 1.8;
    else if (level <= 20) bufferMultiplier = 1.6;
    else if (level <= 25) bufferMultiplier = 1.45;
    else                  bufferMultiplier = 1.3;

    final maxMoves = (pairs * bufferMultiplier).ceil();

    String icon; Color color; Color color2;
    if (level <= 5)       { icon = '🌱'; color = const Color(0xFF38EF7D); color2 = const Color(0xFF11998E); }
    else if (level <= 10) { icon = '⚡'; color = const Color(0xFF3B82F6); color2 = const Color(0xFF6C63FF); }
    else if (level <= 15) { icon = '🔥'; color = const Color(0xFFF7971E); color2 = const Color(0xFFFF6B35); }
    else if (level <= 20) { icon = '💎'; color = const Color(0xFFA78BFA); color2 = const Color(0xFF6C63FF); }
    else if (level <= 25) { icon = '🌀'; color = const Color(0xFFE8345A); color2 = const Color(0xFFFF6B6B); }
    else                  { icon = '👑'; color = const Color(0xFFFFD700); color2 = const Color(0xFFF7971E); }

    int crossAxisCount = pairs <= 4 ? 4 : pairs <= 6 ? 4 : pairs <= 8 ? 4 : pairs <= 10 ? 5 : pairs <= 12 ? 4 : 5;

    return {
      'pairs': pairs, 'timer': timer, 'maxMoves': maxMoves,
      'pts': level * 15, 'icon': icon, 'color': color, 'color2': color2,
      'crossAxisCount': crossAxisCount,
      'timerLabel': timer >= 60
          ? '${timer ~/ 60}:${(timer % 60).toString().padLeft(2,'0')}'
          : '${timer}s',
    };
  }

  @override
  void initState() {
    super.initState();
    _box = Hive.box('userBox');
    _unlockedUpTo = _box.get('memory_unlocked', defaultValue: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
  }

  void _scrollToCurrentLevel() {
    // Start at bottom (Level 1) — user scrolls up to see more levels
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(0); // 0 = bottom kyunki reverse: true hai
      }
    });
  }

  void _refresh() {
    setState(() => _unlockedUpTo = _box.get('memory_unlocked', defaultValue: 1));
  }

  // x-offset pattern for winding path: center, left, right, center, left, right...
  double _xOffsetFor(int levelFromBottom) {
    final pattern = [0.0, -70.0, 70.0, 0.0, -55.0, 55.0];
    return pattern[levelFromBottom % pattern.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0E17),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Card Match', style: GoogleFonts.inter(fontSize: 18,
                  fontWeight: FontWeight.w800, color: Colors.white)),
                Text('$_unlockedUpTo/$_totalLevels levels unlocked',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.4))),
              ]),
              const Spacer(),
              const Text('🃏', style: TextStyle(fontSize: 26)),
            ]),
          ),

          // Path journey — scrollable, bottom = level 1, top = level 30
          Expanded(
            child: Stack(children: [
              // Background decorations
              Positioned.fill(child: CustomPaint(painter: _StarFieldPainter())),

              SingleChildScrollView(
                controller: _scrollCtrl,
                reverse: true, // start scrolled to bottom (level 1)
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Connecting path painter
                      CustomPaint(
                        size: Size(double.infinity, _totalLevels * 110.0),
                        painter: _PathPainter(
                          totalLevels: _totalLevels,
                          unlockedUpTo: _unlockedUpTo,
                          xOffsetFor: _xOffsetFor,
                        ),
                      ),
                      // Level nodes
                      Column(
                        children: List.generate(_totalLevels, (i) {
                          final level = _totalLevels - i; // top = 30, bottom = 1
                          final levelFromBottom = level - 1;
                          final xOffset = _xOffsetFor(levelFromBottom);
                          final config = levelConfig(level);
                          final unlocked = level <= _unlockedUpTo;
                          final isCurrent = level == _unlockedUpTo;
                          final completed = level < _unlockedUpTo;
                          final stars = _box.get('memlevel_${level}_stars', defaultValue: 0) as int;
                          final color = config['color'] as Color;
                          final color2 = config['color2'] as Color;

                          return SizedBox(
                            height: 110,
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(xOffset, 0),
                                child: GestureDetector(
                                  onTap: unlocked ? () async {
                                    HapticFeedback.lightImpact();
                                    await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => MemoryGameScreen(level: level)));
                                    _refresh();
                                  } : () {
                                    HapticFeedback.mediumImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('🔒 Complete level ${level - 1} to unlock!',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                      backgroundColor: const Color(0xFF1C1C2E),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ));
                                  },
                                  child: _LevelNode(
                                    level: level,
                                    icon: config['icon'] as String,
                                    color: color,
                                    color2: color2,
                                    unlocked: unlocked,
                                    isCurrent: isCurrent,
                                    completed: completed,
                                    stars: stars,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LevelNode extends StatefulWidget {
  final int level;
  final String icon;
  final Color color;
  final Color color2;
  final bool unlocked;
  final bool isCurrent;
  final bool completed;
  final int stars;

  const _LevelNode({
    required this.level, required this.icon, required this.color,
    required this.color2, required this.unlocked, required this.isCurrent,
    required this.completed, required this.stars,
  });

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCurrent ? 70.0 : 58.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final pulse = widget.isCurrent ? 1.0 + (_ctrl.value * 0.08) : 1.0;
        return Transform.scale(scale: pulse, child: child);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 8)],
              ),
              child: Text('PLAY NOW',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                  color: widget.color2)),
            ),
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              gradient: widget.unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [widget.color, widget.color2])
                : null,
              color: widget.unlocked ? null : const Color(0xFF1C1C2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isCurrent
                  ? Colors.white
                  : widget.unlocked
                    ? Colors.white.withOpacity(0.25)
                    : Colors.white.withOpacity(0.06),
                width: widget.isCurrent ? 3 : 2),
              boxShadow: widget.unlocked ? [
                BoxShadow(color: widget.color.withOpacity(0.4),
                  blurRadius: widget.isCurrent ? 20 : 10,
                  offset: const Offset(0, 4)),
              ] : [],
            ),
            child: Center(
              child: widget.unlocked
                ? Text(widget.icon, style: TextStyle(fontSize: widget.isCurrent ? 30 : 24))
                : Stack(alignment: Alignment.center, children: [
                    Text('🔒', style: TextStyle(fontSize: 20,
                      color: Colors.white.withOpacity(0.15))),
                  ]),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: widget.unlocked ? widget.color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10)),
            child: Text('${widget.level}',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800,
                color: widget.unlocked ? widget.color : Colors.white.withOpacity(0.2))),
          ),
          if (widget.completed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Text(
                  i < widget.stars ? '⭐' : '☆',
                  style: TextStyle(fontSize: 9,
                    color: i < widget.stars ? null : Colors.white.withOpacity(0.15)))),
              ),
            ),
        ],
      ),
    );
  }
}

// Painter for the winding dotted path connecting all level nodes
class _PathPainter extends CustomPainter {
  final int totalLevels;
  final int unlockedUpTo;
  final double Function(int) xOffsetFor;

  _PathPainter({required this.totalLevels, required this.unlockedUpTo, required this.xOffsetFor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final rowHeight = 110.0;

    for (int i = 0; i < totalLevels - 1; i++) {
      final levelFromBottom = i;
      final nextLevelFromBottom = i + 1;
      final level = levelFromBottom + 1;

      // y position: row index from top. Bottom-most level (1) is last row.
      final rowFromTop1 = totalLevels - 1 - levelFromBottom;
      final rowFromTop2 = totalLevels - 1 - nextLevelFromBottom;

      final y1 = rowFromTop1 * rowHeight + rowHeight / 2;
      final y2 = rowFromTop2 * rowHeight + rowHeight / 2;
      final x1 = centerX + xOffsetFor(levelFromBottom);
      final x2 = centerX + xOffsetFor(nextLevelFromBottom);

      final unlocked = level < unlockedUpTo;
      final paint = Paint()
        ..color = unlocked ? const Color(0xFFA78BFA).withOpacity(0.4) : Colors.white.withOpacity(0.06)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(x1, y1);
      final midY = (y1 + y2) / 2;
      path.quadraticBezierTo(x1, midY, (x1 + x2) / 2, midY);
      path.quadraticBezierTo(x2, midY, x2, y2);

      // Dashed effect
      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = min(dashWidth, metric.length - distance);
        canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
    oldDelegate.unlockedUpTo != unlockedUpTo;
}

// Subtle decorative starfield background
class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final paint = Paint()..color = Colors.white.withOpacity(0.03);
    for (int i = 0; i < 40; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
