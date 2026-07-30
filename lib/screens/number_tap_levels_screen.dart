import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'number_tap_game_screen.dart';

class NumberTapLevelsScreen extends StatefulWidget {
  const NumberTapLevelsScreen({super.key});
  @override State<NumberTapLevelsScreen> createState() => _NTLevelsState();
}

class _NTLevelsState extends State<NumberTapLevelsScreen> {
  late Box _box;
  int _unlockedUpTo = 1;
  static const _totalLevels = 30;
  final _scrollCtrl = ScrollController();

  static Map<String, dynamic> levelConfig(int level) {
    // Grid size grows
    int gridSize;
    if (level <= 5)       gridSize = 9;  // 3x3
    else if (level <= 10) gridSize = 12; // 3x4
    else if (level <= 20) gridSize = 16; // 4x4
    else                  gridSize = 20; // 4x5

    // Timer shrinks
    int timer;
    if (level <= 5)       timer = 30;
    else if (level <= 10) timer = 25;
    else if (level <= 20) timer = 20;
    else                  timer = 15;

    // Number range grows — harder to spot correct one
    int maxNumber;
    if (level <= 5)       maxNumber = 9;
    else if (level <= 10) maxNumber = 15;
    else if (level <= 20) maxNumber = 25;
    else                  maxNumber = 50;

    // Points per correct tap
    int pts;
    if (level <= 5)       pts = 10;
    else if (level <= 10) pts = 15;
    else if (level <= 20) pts = 20;
    else                  pts = 30;

    // Target score to pass
    int targetScore;
    if (level <= 5)       targetScore = 50;
    else if (level <= 10) targetScore = 80;
    else if (level <= 20) targetScore = 120;
    else                  targetScore = 150;

    String icon; Color color; Color color2;
    if (level <= 5)       { icon = '🎯'; color = const Color(0xFF38EF7D); color2 = const Color(0xFF11998E); }
    else if (level <= 10) { icon = '⚡'; color = const Color(0xFF3B82F6); color2 = const Color(0xFF6C63FF); }
    else if (level <= 15) { icon = '🔥'; color = const Color(0xFFF7971E); color2 = const Color(0xFFFF6B35); }
    else if (level <= 20) { icon = '💎'; color = const Color(0xFFA78BFA); color2 = const Color(0xFF6C63FF); }
    else if (level <= 25) { icon = '🌀'; color = const Color(0xFFE8345A); color2 = const Color(0xFFFF6B6B); }
    else                  { icon = '👑'; color = const Color(0xFFFFD700); color2 = const Color(0xFFF7971E); }

    int crossAxisCount = gridSize == 9 ? 3 : gridSize == 12 ? 3 : gridSize == 16 ? 4 : 4;

    return {
      'gridSize': gridSize, 'timer': timer, 'maxNumber': maxNumber,
      'pts': pts, 'targetScore': targetScore, 'icon': icon,
      'color': color, 'color2': color2, 'crossAxisCount': crossAxisCount,
      'timerLabel': '${timer}s',
    };
  }

  @override
  void initState() {
    super.initState();
    _box = Hive.box('userBox');
    _unlockedUpTo = _box.get('numbertap_unlocked', defaultValue: 1);
  }

  void _refresh() {
    setState(() => _unlockedUpTo = _box.get('numbertap_unlocked', defaultValue: 1));
  }

  double _xOffsetFor(int idx) {
    final pattern = [0.0, 65.0, -65.0, 0.0, -55.0, 55.0];
    return pattern[idx % pattern.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(children: [
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
                Text('Number Tap', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('$_unlockedUpTo/$_totalLevels levels unlocked',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.4))),
              ]),
              const Spacer(),
              const Text('🎯', style: TextStyle(fontSize: 26)),
            ]),
          ),

          Expanded(
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _StarPainter())),
              SingleChildScrollView(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.only(top: 40, bottom: 90),
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      CustomPaint(
                        size: Size(double.infinity, _totalLevels * 110.0),
                        painter: _PathPainter(
                          totalLevels: _totalLevels,
                          unlockedUpTo: _unlockedUpTo,
                          xOffsetFor: _xOffsetFor,
                        ),
                      ),
                      Column(
                        children: List.generate(_totalLevels, (i) {
                          final level = _totalLevels - i;
                          final levelFromBottom = level - 1;
                          final xOffset = _xOffsetFor(levelFromBottom);
                          final config = levelConfig(level);
                          final unlocked = level <= _unlockedUpTo;
                          final isCurrent = level == _unlockedUpTo;
                          final completed = level < _unlockedUpTo;
                          final stars = _box.get('numbertap_${level}_stars', defaultValue: 0) as int;
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
                                      builder: (_) => NumberTapGameScreen(level: level)));
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
                                    level: level, icon: config['icon'] as String,
                                    color: color, color2: color2,
                                    unlocked: unlocked, isCurrent: isCurrent,
                                    completed: completed, stars: stars,
                                    targetScore: config['targetScore'] as int,
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
  final Color color, color2;
  final bool unlocked, isCurrent, completed;
  final int stars, targetScore;

  const _LevelNode({
    required this.level, required this.icon,
    required this.color, required this.color2,
    required this.unlocked, required this.isCurrent,
    required this.completed, required this.stars,
    required this.targetScore,
  });

  @override State<_LevelNode> createState() => _LevelNodeState();
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
      builder: (_, child) => Transform.scale(
        scale: widget.isCurrent ? 1.0 + (_ctrl.value * 0.07) : 1.0,
        child: child),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.isCurrent)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 8)]),
            child: Text('PLAY NOW',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: widget.color2)),
          ),
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            gradient: widget.unlocked
              ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [widget.color, widget.color2])
              : null,
            color: widget.unlocked ? null : const Color(0xFF1C1C2E),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isCurrent ? Colors.white
                : widget.unlocked ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
              width: widget.isCurrent ? 3 : 2),
            boxShadow: widget.unlocked ? [BoxShadow(
              color: widget.color.withOpacity(0.4),
              blurRadius: widget.isCurrent ? 20 : 10,
              offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: widget.unlocked
              ? Text(widget.icon, style: TextStyle(fontSize: widget.isCurrent ? 30 : 24))
              : Text('🔒', style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.15))),
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
                  color: i < widget.stars ? null : Colors.white.withOpacity(0.15))))),
          ),
      ]),
    );
  }
}

class _PathPainter extends CustomPainter {
  final int totalLevels, unlockedUpTo;
  final double Function(int) xOffsetFor;

  _PathPainter({required this.totalLevels, required this.unlockedUpTo, required this.xOffsetFor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const rowH = 110.0;

    for (int i = 0; i < totalLevels - 1; i++) {
      final level = i + 1;
      final r1 = totalLevels - 1 - i;
      final r2 = totalLevels - 2 - i;
      final y1 = r1 * rowH + rowH / 2;
      final y2 = r2 * rowH + rowH / 2;
      final x1 = cx + xOffsetFor(i);
      final x2 = cx + xOffsetFor(i + 1);

      final unlocked = level < unlockedUpTo;
      final paint = Paint()
        ..color = unlocked ? const Color(0xFFF7971E).withOpacity(0.4) : Colors.white.withOpacity(0.06)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(x1, y1);
      final midY = (y1 + y2) / 2;
      path.quadraticBezierTo(x1, midY, (x1 + x2) / 2, midY);
      path.quadraticBezierTo(x2, midY, x2, y2);
      _drawDashed(canvas, path, paint);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dw = 6.0; const ds = 8.0;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + min(dw, m.length - d)), paint);
        d += dw + ds;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.unlockedUpTo != unlockedUpTo;
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(99);
    final p = Paint()..color = Colors.white.withOpacity(0.03);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height), rnd.nextDouble() * 1.5 + 0.5, p);
    }
  }
  @override bool shouldRepaint(_) => false;
}
