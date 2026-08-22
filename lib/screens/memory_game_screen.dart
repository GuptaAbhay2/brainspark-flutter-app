import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/score_service.dart';

// ── Level config (standalone so both screens can use it) ─────────────────────
Map<String, dynamic> memoryLevelConfig(int level) {
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

  double b;
  if (level <= 5)       b = 2.2;
  else if (level <= 10) b = 2.0;
  else if (level <= 15) b = 1.8;
  else if (level <= 20) b = 1.6;
  else if (level <= 25) b = 1.45;
  else                  b = 1.3;

  final maxMoves = (pairs * b).ceil();

  String icon; Color color; Color color2;
  if (level <= 5)       { icon='🌱'; color=const Color(0xFF38EF7D); color2=const Color(0xFF11998E); }
  else if (level <= 10) { icon='⚡'; color=const Color(0xFF3B82F6); color2=const Color(0xFF6C63FF); }
  else if (level <= 15) { icon='🔥'; color=const Color(0xFFF7971E); color2=const Color(0xFFFF6B35); }
  else if (level <= 20) { icon='💎'; color=const Color(0xFFA78BFA); color2=const Color(0xFF6C63FF); }
  else if (level <= 25) { icon='🌀'; color=const Color(0xFFE8345A); color2=const Color(0xFFFF6B6B); }
  else                  { icon='👑'; color=const Color(0xFFFFD700); color2=const Color(0xFFF7971E); }

  final cx = pairs<=4?4:pairs<=6?4:pairs<=8?4:pairs<=10?5:pairs<=12?4:5;

  return {
    'pairs': pairs, 'timer': timer, 'maxMoves': maxMoves,
    'pts': level * 15, 'icon': icon, 'color': color, 'color2': color2,
    'crossAxisCount': cx,
  };
}

// ── Game screen ───────────────────────────────────────────────────────────────
class MemoryGameScreen extends ConsumerStatefulWidget {
  final int level;
  const MemoryGameScreen({super.key, required this.level});
  @override
  ConsumerState<MemoryGameScreen> createState() => _MemGameState();
}

class _MemGameState extends ConsumerState<MemoryGameScreen>
    with TickerProviderStateMixin {

  final List<String> _emojiPool = [
    '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼',
    '🐨','🐯','🦁','🐮','🐷','🐸','🐵','🐔',
    '🦄','🐙','🦋','🐝','🦀','🐠','🐳','🦒',
  ];

  late Map<String, dynamic> _config;
  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _first;
  bool _canFlip = true;
  int _movesUsed = 0;
  int _movesLeft = 0;
  int _matches = 0;
  int _score = 0;
  bool _finished = false;
  Timer? _tick;
  int _timer = 0;

  int _combo = 0;
  int _maxCombo = 0;
  bool _showCombo = false;

  late AnimationController _celebCtrl;
  late AnimationController _comboCtrl;
  late Animation<double> _celebAnim;
  late Animation<double> _comboAnim;

  @override
  void initState() {
    super.initState();
    _config = memoryLevelConfig(widget.level);
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _celebAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_celebCtrl);
    _comboAnim = Tween<double>(begin: 0.5, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_comboCtrl);
    _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _celebCtrl.dispose();
    _comboCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final pairs = _config['pairs'] as int;
    final selected = (_emojiPool.toList()..shuffle()).take(pairs).toList();
    _cards = [...selected, ...selected]..shuffle(Random());

    setState(() {
      _flipped  = List.filled(pairs * 2, false);
      _matched  = List.filled(pairs * 2, false);
      _movesUsed = 0;
      _movesLeft = _config['maxMoves'] as int;
      _matches = 0; _score = 0;
      _finished = false; _first = null;
      _timer = _config['timer'] as int;
      _combo = 0; _maxCombo = 0;
    });

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _finished = true);
        _showResultDialog(reason: 'time');
      } else {
        setState(() => _timer--);
        if (_timer <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _tap(int i) {
    if (!_canFlip || _flipped[i] || _matched[i] || _finished) return;
    if (_movesLeft <= 0) return;

    HapticFeedback.selectionClick();
    setState(() => _flipped[i] = true);

    if (_first == null) {
      _first = i;
    } else {
      _canFlip = false;
      final isMatch = _cards[_first!] == _cards[i];
      setState(() { _movesUsed++; _movesLeft--; });

      if (isMatch) {
        HapticFeedback.lightImpact();
        setState(() {
          _matched[_first!] = true; _matched[i] = true;
          _matches++; _first = null; _canFlip = true;
          _score += 20;
          _combo++;
          if (_combo > _maxCombo) _maxCombo = _combo;
        });

        if (_combo >= 2) {
          setState(() => _showCombo = true);
          _comboCtrl.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) setState(() => _showCombo = false);
          });
        }

        final pairs = _config['pairs'] as int;
        if (_matches == pairs) {
          _tick?.cancel();
          setState(() => _finished = true);
          _showResultDialog(reason: 'won');
        }
      } else {
        setState(() { _combo = 0; });
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() {
              _flipped[_first!] = false; _flipped[i] = false;
              _first = null; _canFlip = true;
            });
            if (_movesLeft <= 0 && _matches < (_config['pairs'] as int)) {
              _tick?.cancel();
              setState(() => _finished = true);
              HapticFeedback.heavyImpact();
              _showResultDialog(reason: 'moves');
            }
          }
        });
      }
    }
  }

  int _calcStars(bool won) {
    if (!won) return 0;
    final pairs = _config['pairs'] as int;
    if (_movesUsed <= pairs + (pairs * 0.15)) return 3;
    final maxMoves = _config['maxMoves'] as int;
    final efficiency = (maxMoves - _movesUsed) / (maxMoves - pairs).clamp(1, maxMoves);
    if (efficiency >= 0.4) return 2;
    return 1;
  }

  void _unlockNext(bool won) {
    final box     = Hive.box('userBox');
    final current = box.get('memory_unlocked', defaultValue: 1) as int;
    final stars   = _calcStars(won);
    if (won) {
      box.put('memlevel_${widget.level}_stars', stars);
      ScoreService.submitAndUpdate(
        ref: ref, score: _score, completed: true, puzzleId: 4);
    }
    if (won && widget.level >= current) {
      box.put('memory_unlocked', widget.level + 1);
    }
  }

void _showResultDialog({required String reason}) {
    final won = reason == 'won';
    _unlockNext(won);
    if (won) _celebCtrl.forward(from: 0);
    final stars = _calcStars(won);
    final color = _config['color'] as Color;

    final title = won
        ? 'Level ${widget.level} Cleared!'
        : reason == 'moves'
            ? 'Out of Moves!'
            : "Time's Up!";
    final subtitle = won
        ? 'Great performance! Next level unlocked.'
        : reason == 'moves'
            ? 'You ran out of moves before finding all pairs.'
            : 'Timer expired before all pairs were matched.';

    final mainIcon = won
        ? Icons.emoji_events_rounded
        : reason == 'moves'
            ? Icons.ads_click_rounded
            : Icons.timer_off_rounded;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => ScaleTransition(
        scale: won ? _celebAnim : const AlwaysStoppedAnimation(1.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: won ? color.withOpacity(0.35) : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (won ? color : Colors.black).withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      colors: won
                          ? [color, color.withOpacity(0.6)]
                          : [const Color(0xFF2A2A3C), const Color(0xFF1E1E2C)],
                    ),
                    boxShadow: won
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    mainIcon,
                    size: 38,
                    color: won ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Stars Row
                if (won) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 36,
                          color: i < stars ? const Color(0xFFFFB800) : Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Stats Section
                Row(
                  children: [
                    _dStat(
                      Icons.ads_click_rounded,
                      '${_movesUsed}/${_config['maxMoves']}',
                      'MOVES',
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    _dStat(
                      Icons.style_rounded,
                      '${_matches}/${_config['pairs']}',
                      'PAIRS',
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _dStat(
                      Icons.local_fire_department_rounded,
                      '$_maxCombo',
                      'COMBO',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Feedback Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (won ? color : const Color(0xFFF59E0B)).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (won ? color : const Color(0xFFF59E0B)).withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    won
                        ? (stars == 3
                            ? 'Flawless memory! Outstanding work.'
                            : stars == 2
                                ? 'Great job! Keep up the accuracy.'
                                : 'Level cleared! Try fewer moves next time.')
                        : (reason == 'moves'
                            ? 'Plan your flips carefully on your next try.'
                            : 'So close! Give it another shot.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: won ? color : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons
                if (won && widget.level < 30) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryGameScreen(level: widget.level + 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Level',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _start();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _start();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  label: Text(
                    'Back to Levels',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dStat(IconData icon, String val, String lbl, Color accentColor) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(height: 6),
              Text(
                val,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lbl,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final color    = _config['color'] as Color;
    final maxTime  = _config['timer'] as int;
    final maxMoves = _config['maxMoves'] as int;
    final timerColor = _timer <= 5 ? const Color(0xFFE8345A)
        : _timer <= 15 ? const Color(0xFFF7971E) : color;
    final movesColor = _movesLeft <= 2 ? const Color(0xFFE8345A)
        : _movesLeft <= (maxMoves * 0.3).ceil() ? const Color(0xFFF7971E) : color;
    final crossAxisCount = _config['crossAxisCount'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                border: Border(bottom: BorderSide(
                  color: Colors.white.withOpacity(0.04)))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3))),
                  child: Text('LVL ${widget.level}',
                    style: GoogleFonts.inter(fontSize: 11,
                      fontWeight: FontWeight.w800, color: color)),
                ),
                const Spacer(),
                Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 52, height: 52,
                    child: CircularProgressIndicator(
                      value: maxTime > 0 ? _timer / maxTime : 0,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(timerColor)),
                  ),
                  Text('$_timer', style: GoogleFonts.inter(fontSize: 13,
                    fontWeight: FontWeight.w900, color: timerColor)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    Text('$_movesLeft',
                      style: GoogleFonts.inter(fontSize: 22,
                        fontWeight: FontWeight.w900, color: movesColor)),
                    Text(' left', style: GoogleFonts.inter(fontSize: 11,
                      color: Colors.white.withOpacity(0.35))),
                  ]),
                  Text('MOVES', style: GoogleFonts.inter(fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.35), letterSpacing: 0.6)),
                ]),
              ]),
            ),

            // Moves progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: maxMoves > 0 ? _movesLeft / maxMoves : 0,
                  backgroundColor: const Color(0xFF1C1C2E),
                  valueColor: AlwaysStoppedAnimation(movesColor),
                  minHeight: 8),
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_matches}/${_config['pairs']} pairs found',
                    style: GoogleFonts.inter(fontSize: 12,
                      color: Colors.white.withOpacity(0.4))),
                  if (_combo >= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text('🔥 ${_combo}x combo',
                        style: GoogleFonts.inter(fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD700))),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8, crossAxisSpacing: 8),
                  itemCount: _cards.length,
                  itemBuilder: (_, i) {
                    final isFlipped = _flipped[i] || _matched[i];
                    return GestureDetector(
                      onTap: () => _tap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _matched[i]
                            ? color.withOpacity(0.2)
                            : isFlipped
                              ? const Color(0xFF1C1C2E)
                              : const Color(0xFF2C2C3E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _matched[i]
                              ? color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.05))),
                        child: Center(
                          child: Text(
                            isFlipped ? _cards[i] : '?',
                            style: TextStyle(
                              fontSize: isFlipped ? 22 : 18,
                              color: isFlipped
                                ? null : Colors.white.withOpacity(0.2))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]),

          // Combo popup overlay
          if (_showCombo)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: _comboAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF7971E)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 24)]),
                      child: Text('🔥 ${_combo}x COMBO!',
                        style: GoogleFonts.inter(fontSize: 20,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}