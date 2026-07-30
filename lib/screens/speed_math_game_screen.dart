import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/score_service.dart';
import 'speed_math_levels_screen.dart';

class SpeedMathGameScreen extends ConsumerStatefulWidget {
  final int level;
  const SpeedMathGameScreen({super.key, required this.level});
  @override
  ConsumerState<SpeedMathGameScreen> createState() => _GameState();
}

class _GameState extends ConsumerState<SpeedMathGameScreen>
    with TickerProviderStateMixin {
  final _rng = Random();
  final _ansCtrl = TextEditingController();
  final _focusNode = FocusNode();

  late Map<String, dynamic> _config;
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score   = 0;
  int _correct = 0;
  int _wrong   = 0;
  int _timer   = 0;
  bool _started  = false;
  bool _finished = false;
  bool _showCorrect = false;
  bool _showWrong   = false;
  Timer? _countdown;

  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _celebCtrl;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _celebAnim;

  @override
  void initState() {
    super.initState();
    _config = levelConfig(widget.level);
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeCtrl);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeOut)).animate(_pulseCtrl);
    _celebAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_celebCtrl);
    _startGame();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _ansCtrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> levelConfig(int level) {
    int timer;
    if (level <= 5)       timer = 120;
    else if (level <= 10) timer = 90;
    else if (level <= 25) timer = 60;
    else                  timer = 15;

    int qCount;
    if (level <= 5)       qCount = 5;
    else if (level <= 15) qCount = 7;
    else                  qCount = 10;

    String diff;
    if (level <= 5)       diff = 'easy';
    else if (level <= 15) diff = 'medium';
    else                  diff = 'hard';

    String icon; Color color;
    if (level <= 5)       { icon = '🌱'; color = const Color(0xFF38EF7D); }
    else if (level <= 10) { icon = '⚡'; color = const Color(0xFF3B82F6); }
    else if (level <= 15) { icon = '🔥'; color = const Color(0xFFF7971E); }
    else if (level <= 20) { icon = '💎'; color = const Color(0xFFA78BFA); }
    else if (level <= 25) { icon = '🌀'; color = const Color(0xFFE8345A); }
    else                  { icon = '👑'; color = const Color(0xFFFFD700); }

    return {
      'timer': timer, 'qCount': qCount, 'diff': diff,
      'pts': level * 10, 'icon': icon, 'color': color,
      'timerLabel': timer >= 60
          ? '${timer ~/ 60}:${(timer % 60).toString().padLeft(2, '0')}'
          : '${timer}s',
    };
  }

  List<Map<String, dynamic>> _generateQuestions() {
    final diff  = _config['diff'] as String;
    final count = _config['qCount'] as int;
    final q = <Map<String, dynamic>>[];
    for (var i = 0; i < count; i++) {
      int a, b, ans; String op;
      if (diff == 'easy') {
        a = _rng.nextInt(9) + 1; b = _rng.nextInt(9) + 1;
        op = ['+', '-'][_rng.nextInt(2)];
      } else if (diff == 'medium') {
        a = _rng.nextInt(25) + 5; b = _rng.nextInt(12) + 2;
        op = ['+', '-', '×'][_rng.nextInt(3)];
      } else {
        a = _rng.nextInt(50) + 15; b = _rng.nextInt(20) + 5;
        op = ['+', '-', '×'][_rng.nextInt(3)];
      }
      switch (op) {
        case '+': ans = a + b; break;
        case '-': if (a < b) { final t = a; a = b; b = t; } ans = a - b; break;
        case '×': ans = a * b; break;
        default:  ans = a + b;
      }
      q.add({'q': '$a $op $b', 'a': ans});
    }
    return q;
  }

  void _startGame() {
    _questions = _generateQuestions();
    setState(() {
      _current = 0; _score = 0; _correct = 0; _wrong = 0;
      _timer = _config['timer'] as int;
      _started = true; _finished = false;
      _showCorrect = false; _showWrong = false;
    });
    _ansCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100),
        () => _focusNode.requestFocus());
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _finished = true);
        _saveScore();
        _showResultDialog();
      } else {
        setState(() => _timer--);
        if (_timer <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _checkAnswer() {
    if (_current >= _questions.length || _finished) return;
    final input   = int.tryParse(_ansCtrl.text.trim());
    final correct = _questions[_current]['a'] as int;
    _ansCtrl.clear();

    if (input == correct) {
      HapticFeedback.lightImpact();
      _pulseCtrl.forward(from: 0).then((_) => _pulseCtrl.reverse());
      setState(() {
        _score += _config['pts'] as int;
        _correct++; _current++;
        _showCorrect = true; _showWrong = false;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _showCorrect = false);
      });
    } else {
      HapticFeedback.mediumImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _wrong++; _current++;
        _showWrong = true; _showCorrect = false;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _showWrong = false);
      });
    }

    if (_current >= _questions.length) {
      _countdown?.cancel();
      setState(() => _finished = true);
      _saveScore();
      _showResultDialog();
    }
    _focusNode.requestFocus();
  }

  Future<void> _saveScore() async {
    if (_score <= 0) return;
    await ScoreService.submitAndUpdate(
      ref: ref, score: _score,
      completed: _correct >= (_questions.length * 0.5).ceil(),
      puzzleId: 1,
    );
  }

  int _calcStars() {
    final total = _questions.length;
    if (total == 0) return 0;
    final pct = _correct / total;
    if (pct >= 0.9) return 3;
    if (pct >= 0.6) return 2;
    if (pct >= 0.3) return 1;
    return 0;
  }

  bool _isLevelPassed() =>
      _correct >= (_questions.length * 0.5).ceil();

  void _unlockNext() {
    final box     = Hive.box('userBox');
    final current = box.get('speedmath_unlocked', defaultValue: 1) as int;
    final stars   = _calcStars();
    box.put('level_${widget.level}_stars', stars);
    if (_isLevelPassed() && widget.level >= current) {
      box.put('speedmath_unlocked', widget.level + 1);
    }
  }

  void _showResultDialog() {
    _unlockNext();
    _celebCtrl.forward(from: 0);
    final passed   = _isLevelPassed();
    final stars    = _calcStars();
    final color    = _config['color'] as Color;
    final accuracy = _questions.isNotEmpty
        ? ((_correct / _questions.length) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) => ScaleTransition(
        scale: _celebAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: passed ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
              boxShadow: [BoxShadow(
                color: (passed ? color : Colors.white).withOpacity(0.15),
                blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: passed
                      ? [color, color.withOpacity(0.7)]
                      : [const Color(0xFF2C2C3E), const Color(0xFF1C1C2E)]),
                  shape: BoxShape.circle,
                  boxShadow: passed ? [BoxShadow(
                    color: color.withOpacity(0.4), blurRadius: 24)] : [],
                ),
                child: Center(child: Text(
                  passed ? '🏆' : '⏱',
                  style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 16),
              Text(passed ? 'Level ${widget.level} Complete!' : "Time's Up!",
                style: GoogleFonts.inter(fontSize: 20,
                  fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(passed ? 'Next level unlocked! 🔓'
                : 'Get ${(_questions.length * 0.5).ceil()} correct to pass',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.45))),
              const SizedBox(height: 20),
              if (passed) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(i < stars ? '⭐' : '☆',
                    style: TextStyle(fontSize: 32,
                      color: i < stars
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.15))),
                )),
              ),
              if (passed) const SizedBox(height: 20),
              Row(children: [
                _dStat('✅', '$_correct/${_questions.length}', 'CORRECT'),
                const SizedBox(width: 8),
                _dStat('🎯', '$accuracy%', 'ACCURACY'),
                const SizedBox(width: 8),
                _dStat('⭐', '$_score', 'SCORE'),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (passed ? color : const Color(0xFFF7971E)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (passed ? color : const Color(0xFFF7971E)).withOpacity(0.3))),
                child: Text(
                  passed
                    ? stars == 3 ? '🔥 Perfect! You nailed it!'
                      : stars == 2 ? '💪 Great job! Keep pushing!'
                      : '✅ Level cleared!'
                    : '💡 You got this! Try again!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: passed ? color : const Color(0xFFF7971E))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _startGame(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: Text('Try Again 🔄',
                    style: GoogleFonts.inter(fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              if (passed && widget.level < 30)
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (_) => SpeedMathGameScreen(level: widget.level + 1)));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                    child: Text('Next Level →',
                      style: GoogleFonts.inter(fontSize: 16,
                        fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Back to Levels',
                  style: GoogleFonts.inter(fontSize: 14,
                    color: Colors.white.withOpacity(0.35))),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dStat(String em, String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E17),
        borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(em, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(fontSize: 16,
          fontWeight: FontWeight.w800, color: Colors.white)),
        Text(lbl, style: GoogleFonts.inter(fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.35))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final color   = _config['color'] as Color;
    final maxTime = _config['timer'] as int;
    final timerColor = _timer <= 5
        ? const Color(0xFFE8345A)
        : _timer <= 10 ? const Color(0xFFF7971E) : color;
    final q = _current < _questions.length
        ? _questions[_current]['q'] as String : '...';
    final timerLabel = maxTime >= 60
        ? '${_timer ~/ 60}:${(_timer % 60).toString().padLeft(2, '0')}'
        : '$_timer';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(children: [
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
                  style: GoogleFonts.inter(fontSize: 12,
                    fontWeight: FontWeight.w800, color: color)),
              ),
              const Spacer(),
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(
                    value: maxTime > 0 ? _timer / maxTime : 0,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(timerColor)),
                ),
                Text(timerLabel,
                  style: GoogleFonts.inter(fontSize: 15,
                    fontWeight: FontWeight.w900, color: timerColor)),
              ]),
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnim,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$_score',
                    style: GoogleFonts.inter(fontSize: 22,
                      fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('SCORE',
                    style: GoogleFonts.inter(fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 0.6)),
                ]),
              ),
            ]),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Q ${_current + 1}/${_questions.length}',
                  style: GoogleFonts.inter(fontSize: 12,
                    color: Colors.white.withOpacity(0.35))),
                Row(children: [
                  Text('✅ $_correct  ',
                    style: GoogleFonts.inter(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38EF7D))),
                  Text('❌ $_wrong',
                    style: GoogleFonts.inter(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8345A))),
                ]),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _questions.isNotEmpty
                    ? _current / _questions.length : 0,
                  backgroundColor: const Color(0xFF1C1C2E),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Question card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                  _shakeAnim.value * (_shakeCtrl.value > 0.5 ? -1 : 1), 0),
                child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 44),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: _showCorrect
                      ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                      : _showWrong
                        ? [const Color(0xFFE8345A), const Color(0xFFFF6B6B)]
                        : [const Color(0xFF1C1C2E), const Color(0xFF2C2C3E)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _showCorrect
                      ? const Color(0xFF38EF7D).withOpacity(0.5)
                      : _showWrong
                        ? const Color(0xFFE8345A).withOpacity(0.5)
                        : color.withOpacity(0.2),
                    width: 1.5),
                ),
                child: Center(
                  child: _showCorrect
                    ? Text('✅  Correct!',
                        style: GoogleFonts.inter(fontSize: 22,
                          fontWeight: FontWeight.w800, color: Colors.white))
                    : _showWrong
                      ? Text('❌  Wrong!',
                          style: GoogleFonts.inter(fontSize: 22,
                            fontWeight: FontWeight.w800, color: Colors.white))
                      : Text(q,
                          style: GoogleFonts.inter(fontSize: 46,
                            fontWeight: FontWeight.w900, color: Colors.white,
                            letterSpacing: -1)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ansCtrl,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 26,
                    fontWeight: FontWeight.w800, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Answer?',
                    hintStyle: GoogleFonts.inter(fontSize: 18,
                      color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C2E),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: color, width: 2)),
                  ),
                  onSubmitted: (_) => _checkAnswer(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _checkAnswer,
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 30),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Number pad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  ...[1,2,3,4,5,6,7,8,9].map((n) => _numKey('$n', color)),
                  _numKey('⌫', color, isDelete: true),
                  _numKey('0', color),
                  _numKey('✓', color, isEnter: true),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _numKey(String label, Color color,
      {bool isDelete = false, bool isEnter = false}) {
    Color bg = const Color(0xFF1C1C2E);
    Color fg = Colors.white;
    if (isDelete) { bg = const Color(0xFF2C1C1E); fg = const Color(0xFFE8345A); }
    if (isEnter)  { bg = color; fg = Colors.white; }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (isEnter) {
          _checkAnswer();
        } else if (isDelete) {
          if (_ansCtrl.text.isNotEmpty) {
            _ansCtrl.text = _ansCtrl.text.substring(0, _ansCtrl.text.length - 1);
          }
        } else {
          _ansCtrl.text += label;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Center(child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700, color: fg))),
      ),
    );
  }
}
