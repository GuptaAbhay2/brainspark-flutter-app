import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class SpeedMathScreen extends ConsumerStatefulWidget {
  const SpeedMathScreen({super.key});
  @override
  ConsumerState<SpeedMathScreen> createState() => _SpeedMathState();
}

class _SpeedMathState extends ConsumerState<SpeedMathScreen>
    with TickerProviderStateMixin {
  final _ansCtrl  = TextEditingController();
  final _focusNode = FocusNode();
  final _rng = Random();

  // Game state
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score   = 0;
  int _correct = 0;
  int _wrong   = 0;
  int _timer   = 15;
  bool _started  = false;
  bool _finished = false;
  bool _showCorrect = false;
  bool _showWrong   = false;
  String _difficulty = 'easy';
  Timer? _countdown;

  // Animations
  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _popCtrl;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _popAnim;

  // Level config
  final _levels = {
    'easy':   {'label': 'EASY',   'pts': 5,  'time': 15, 'color': const Color(0xFF38EF7D), 'emoji': '😊'},
    'medium': {'label': 'MEDIUM', 'pts': 10, 'time': 12, 'color': const Color(0xFF3B82F6), 'emoji': '🤔'},
    'hard':   {'label': 'HARD',   'pts': 15, 'time': 10, 'color': const Color(0xFFE8345A), 'emoji': '🔥'},
  };

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _popCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_pulseCtrl);
    _popAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_popCtrl);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _ansCtrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _generateQuestions(String diff) {
    final q = <Map<String, dynamic>>[];
    for (var i = 0; i < 40; i++) {
      int a, b, ans; String op;
      if (diff == 'easy') {
        a = _rng.nextInt(9) + 1; b = _rng.nextInt(9) + 1;
        op = ['+', '-', '×'][_rng.nextInt(3)];
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
    final time = _levels[_difficulty]!['time'] as int;
    _questions = _generateQuestions(_difficulty);
    setState(() {
      _current = 0; _score = 0; _correct = 0; _wrong = 0;
      _timer = time; _started = true; _finished = false;
      _showCorrect = false; _showWrong = false;
    });
    _ansCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () => _focusNode.requestFocus());

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _finished = true);
        _showTimeUpDialog();
        _saveScore();
      } else {
        setState(() => _timer--);
        if (_timer <= 3) HapticFeedback.lightImpact();
      }
    });
  }

  void _checkAnswer() {
    if (_current >= _questions.length || !_started || _finished) return;
    final input   = int.tryParse(_ansCtrl.text.trim());
    final correct = _questions[_current]['a'] as int;
    _ansCtrl.clear();

    if (input == correct) {
      final pts = _levels[_difficulty]!['pts'] as int;
      HapticFeedback.lightImpact();
      _pulseCtrl.forward(from: 0).then((_) => _pulseCtrl.reverse());
      setState(() {
        _score += pts; _correct++; _current++;
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
      _showTimeUpDialog();
      _saveScore();
    }
    _focusNode.requestFocus();
  }

  void _showTimeUpDialog() {
    final emoji = _score >= 80 ? '🏆' : _score >= 40 ? '🎯' : '💪';
    final msg   = _score >= 80 ? 'Incredible!' : _score >= 40 ? 'Nice work!' : 'Keep going!';
    final accuracy = (_correct + _wrong) > 0
        ? ((_correct / (_correct + _wrong)) * 100).round() : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA78BFA).withOpacity(0.2),
                blurRadius: 40, spreadRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Watch emoji big
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 20)],
                ),
                child: const Center(
                  child: Text('⏱', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 16),
              Text("Your Time's Up!",
                style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(msg, style: GoogleFonts.inter(
                fontSize: 14, color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 24),

              // Stats row
              Row(children: [
                _dialogStat(emoji, '$_score', 'SCORE'),
                const SizedBox(width: 8),
                _dialogStat('✅', '$_correct', 'CORRECT'),
                const SizedBox(width: 8),
                _dialogStat('🎯', '$accuracy%', 'ACC'),
              ]),
              const SizedBox(height: 24),

              // Try again button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: Text('Try Again 🔄',
                    style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Back to Home',
                  style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.white.withOpacity(0.4))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogStat(String em, String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E17),
        borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(em, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(lbl, style: GoogleFonts.inter(
          fontSize: 9, fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.35))),
      ]),
    ),
  );

  Future<void> _saveScore() async {
    final user = ref.read(userProvider);
    if (user.userId == null) return;
    try {
      final res = await ApiService.submitScore(
        userId: user.userId!, puzzleId: 1, score: _score,
        timeTaken: (_levels[_difficulty]!['time'] as int) - _timer,
        hintsUsed: 0, completed: true,
      );
      ref.read(userProvider.notifier)
          .updateScore(res['brain_score'], res['current_streak']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: !_started ? _buildStart() : _buildGame(),
      ),
    );
  }

  // ── START SCREEN ──────────────────────────────────────────────────────
  Widget _buildStart() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B35), Color(0xFFF7971E)]),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32)),
          ),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            const Text('⚡', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text('Speed Math',
              style: GoogleFonts.inter(fontSize: 30,
                fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            Text('How fast can you solve?',
              style: GoogleFonts.inter(fontSize: 14,
                color: Colors.white.withOpacity(0.7))),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // How to play card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.06))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to Play',
                    style: GoogleFonts.inter(fontSize: 15,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 14),
                  _howRow('⚡', 'Timer starts immediately'),
                  _howRow('🔢', 'Type your answer & press Enter'),
                  _howRow('✅', 'Correct = points'),
                  _howRow('❌', 'Wrong = skip, next question'),
                  _howRow('⏱', 'Max 15 seconds — go fast!'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text('Pick your level',
              style: GoogleFonts.inter(fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),

            // Level cards
            Row(children: _levels.entries.map((e) {
              final selected = _difficulty == e.key;
              final color = e.value['color'] as Color;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _difficulty = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: e.key != 'hard' ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: selected
                        ? color.withOpacity(0.15)
                        : const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? color : Colors.white.withOpacity(0.06),
                        width: selected ? 2 : 1),
                      boxShadow: selected ? [BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 16, offset: const Offset(0, 4))] : [],
                    ),
                    child: Column(children: [
                      Text(e.value['emoji'] as String,
                        style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(e.value['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: selected ? color : Colors.white.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      Text('+${e.value['pts']} pts',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.3))),
                      Text('${e.value['time']}s',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.3))),
                    ]),
                  ),
                ),
              );
            }).toList()),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                  shadowColor: const Color(0xFFFF6B35).withOpacity(0.5),
                  elevation: 8,
                ),
                child: Text('Start Now ⚡',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _howRow(String em, String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(em, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(txt, style: GoogleFonts.inter(
        fontSize: 13, color: Colors.white.withOpacity(0.5))),
    ]),
  );

  // ── GAME SCREEN ───────────────────────────────────────────────────────
  Widget _buildGame() {
    final levelColor = _levels[_difficulty]!['color'] as Color;
    final maxTime    = _levels[_difficulty]!['time'] as int;
    final timerColor = _timer <= 3
        ? const Color(0xFFE8345A)
        : _timer <= 6
          ? const Color(0xFFF7971E)
          : levelColor;
    final q = _current < _questions.length
        ? _questions[_current]['q'] as String : '...';

    return Column(children: [

      // ── Top bar ────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
        child: Row(children: [
          // Score
          ScaleTransition(
            scale: _pulseAnim,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SCORE',
                style: GoogleFonts.inter(fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 0.6)),
              Text('$_score',
                style: GoogleFonts.inter(fontSize: 24,
                  fontWeight: FontWeight.w900, color: Colors.white)),
            ]),
          ),
          const Spacer(),

          // Timer circle
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                value: _timer / maxTime,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(timerColor),
              ),
            ),
            Text('$_timer',
              style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: timerColor)),
          ]),

          const Spacer(),
          // Correct / wrong
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('✅ $_correct',
              style: GoogleFonts.inter(fontSize: 14,
                fontWeight: FontWeight.w700, color: const Color(0xFF38EF7D))),
            Text('❌ $_wrong',
              style: GoogleFonts.inter(fontSize: 14,
                fontWeight: FontWeight.w700, color: const Color(0xFFE8345A))),
          ]),
        ]),
      ),

      // ── Question number ────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          Text('Q ${_current + 1}',
            style: GoogleFonts.inter(fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.3))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (_levels[_difficulty]!['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
            child: Text(
              (_levels[_difficulty]!['label'] as String),
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: _levels[_difficulty]!['color'] as Color)),
          ),
        ]),
      ),

      const SizedBox(height: 20),

      // ── Question Card ──────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              _shakeAnim.value * (_shakeCtrl.value > 0.5 ? -1 : 1), 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _showCorrect
                  ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                  : _showWrong
                    ? [const Color(0xFFE8345A), const Color(0xFFFF6B6B)]
                    : [const Color(0xFF1C1C2E), const Color(0xFF2C2C3E)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _showCorrect
                  ? const Color(0xFF38EF7D).withOpacity(0.5)
                  : _showWrong
                    ? const Color(0xFFE8345A).withOpacity(0.5)
                    : Colors.white.withOpacity(0.06),
                width: 1.5),
              boxShadow: _showCorrect || _showWrong ? [
                BoxShadow(
                  color: (_showCorrect
                    ? const Color(0xFF38EF7D)
                    : const Color(0xFFE8345A)).withOpacity(0.3),
                  blurRadius: 24, spreadRadius: 0)
              ] : [],
            ),
            child: Column(children: [
              if (_showCorrect)
                Text('✅  Correct!',
                  style: GoogleFonts.inter(fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white))
              else if (_showWrong)
                Text('❌  Wrong!',
                  style: GoogleFonts.inter(fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white))
              else
                Text(q,
                  style: GoogleFonts.inter(
                    fontSize: 48, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: -1)),
            ]),
          ),
        ),
      ),

      const SizedBox(height: 28),

      // ── Input ──────────────────────────────────────────────────────
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
                hintStyle: GoogleFonts.inter(
                  fontSize: 18, color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: const Color(0xFF1C1C2E),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFA78BFA), width: 2)),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFF7971E)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 30),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 20),

      // ── Number pad ────────────────────────────────────────────────
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: [
              ...[1,2,3,4,5,6,7,8,9].map((n) => _numKey('$n')),
              _numKey('⌫', isDelete: true),
              _numKey('0'),
              _numKey('✓', isEnter: true),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _numKey(String label, {bool isDelete = false, bool isEnter = false}) {
    Color bg = const Color(0xFF1C1C2E);
    Color fg = Colors.white;
    if (isDelete) { bg = const Color(0xFF2C1C1E); fg = const Color(0xFFE8345A); }
    if (isEnter)  { bg = const Color(0xFFFF6B35); fg = Colors.white; }

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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: Center(
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: isEnter ? 22 : isDelete ? 22 : 20,
              fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}
