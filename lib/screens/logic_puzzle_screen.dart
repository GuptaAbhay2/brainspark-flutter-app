import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/score_service.dart';

class LogicPuzzleScreen extends ConsumerStatefulWidget {
  const LogicPuzzleScreen({super.key});
  @override
  ConsumerState<LogicPuzzleScreen> createState() => _LogicState();
}

class _LogicState extends ConsumerState<LogicPuzzleScreen>
    with TickerProviderStateMixin {

  final _levels = {
    'easy':   {'label': 'EASY',   'time': 15, 'pts': 50,  'color': const Color(0xFF38EF7D), 'emoji': '😊'},
    'medium': {'label': 'MEDIUM', 'time': 12, 'pts': 100, 'color': const Color(0xFF3B82F6), 'emoji': '🤔'},
    'hard':   {'label': 'HARD',   'time': 10, 'pts': 150, 'color': const Color(0xFFE8345A), 'emoji': '🔥'},
  };

  final _puzzleBank = {
    'easy': [
      {'question': 'What comes next?',     'sequence': [2,4,6,8,'?'],      'options': [9,10,11,12],  'answer': 10, 'hint': 'Add 2 each time'},
      {'question': 'Find the next number', 'sequence': [1,3,5,7,'?'],      'options': [8,9,10,11],   'answer': 9,  'hint': 'Odd numbers in order'},
      {'question': 'What is missing?',     'sequence': [5,10,15,20,'?'],   'options': [22,24,25,30], 'answer': 25, 'hint': 'Multiply 5 each step'},
      {'question': 'Next in sequence?',    'sequence': [100,90,80,70,'?'], 'options': [55,60,65,50], 'answer': 60, 'hint': 'Subtract 10 each time'},
      {'question': 'Find the pattern',     'sequence': [3,6,9,12,'?'],     'options': [13,14,15,16], 'answer': 15, 'hint': 'Multiples of 3'},
    ],
    'medium': [
      {'question': 'What comes next?',   'sequence': [2,4,8,16,'?'],    'options': [24,28,32,36], 'answer': 32, 'hint': 'Each number doubles'},
      {'question': 'Find the next term', 'sequence': [1,4,9,16,'?'],    'options': [20,25,30,36], 'answer': 25, 'hint': 'Square numbers: 1²,2²,3²...'},
      {'question': 'Missing number?',    'sequence': [3,6,12,24,'?'],   'options': [36,42,48,56], 'answer': 48, 'hint': 'Each number multiplied by 2'},
      {'question': 'What comes next?',   'sequence': [1,1,2,3,5,'?'],   'options': [6,7,8,9],    'answer': 8,  'hint': 'Add the two previous numbers'},
      {'question': 'Next in pattern?',   'sequence': [2,6,12,20,'?'],   'options': [28,30,32,36],'answer': 30, 'hint': 'Differences: 4,6,8,10...'},
    ],
    'hard': [
      {'question': 'Find the missing number', 'sequence': [1,8,27,64,'?'],    'options': [100,121,125,144], 'answer': 125, 'hint': 'Cube numbers: 1³,2³,3³...'},
      {'question': 'What comes next?',        'sequence': [2,3,5,7,11,'?'],   'options': [12,13,14,15],    'answer': 13,  'hint': 'Prime numbers in order'},
      {'question': 'Next term?',              'sequence': [0,1,3,6,10,'?'],   'options': [13,14,15,16],    'answer': 15,  'hint': 'Triangle numbers'},
      {'question': 'Find the pattern',        'sequence': [2,5,10,17,26,'?'], 'options': [35,36,37,38],    'answer': 37,  'hint': 'Add 3,5,7,9,11...'},
      {'question': 'Missing number?',         'sequence': [3,7,13,21,31,'?'], 'options': [41,42,43,44],    'answer': 43,  'hint': 'Differences: 4,6,8,10,12...'},
    ],
  };

  String _difficulty = 'easy';
  Map<String, dynamic>? _puzzle;
  int? _selected;
  bool _answered  = false;
  bool _isCorrect = false;
  String _hint    = '';
  bool _hintUsed  = false;
  int _hintsUsed  = 0;
  int _score      = 0;
  int _round      = 0;
  int _correct    = 0;
  int _timer      = 15;
  bool _started   = false;
  bool _gameOver  = false;
  final int _totalRounds = 5;
  Timer? _countdown;
  int _puzzleIndex = 0;

  late AnimationController _optionCtrl;
  late AnimationController _celebCtrl;
  late Animation<double> _optionAnim;
  late Animation<double> _celebAnim;

  @override
  void initState() {
    super.initState();
    _optionCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 400));
    _celebCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    _optionAnim = CurvedAnimation(parent: _optionCtrl, curve: Curves.easeOut);
    _celebAnim  = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_celebCtrl);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _optionCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    _puzzleIndex = 0;
    setState(() {
      _score = 0; _round = 0; _correct = 0;
      _hintsUsed = 0; _started = true; _gameOver = false;
    });
    _loadPuzzle();
  }

  void _loadPuzzle() {
    _countdown?.cancel();
    final bank   = _puzzleBank[_difficulty]!;
    final puzzle = bank[_puzzleIndex % bank.length];
    _puzzleIndex++;

    setState(() {
      _puzzle   = Map<String, dynamic>.from(puzzle);
      _selected = null; _answered = false;
      _hint = ''; _hintUsed = false;
      _timer = _levels[_difficulty]!['time'] as int;
      _round++; _isCorrect = false;
    });
    _optionCtrl.forward(from: 0);

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _handleTimeUp();
      } else {
        setState(() => _timer--);
        if (_timer <= 3) HapticFeedback.lightImpact();
      }
    });
  }

  void _handleTimeUp() {
    if (_answered) return;
    setState(() { _answered = true; _isCorrect = false; });
    Future.delayed(const Duration(milliseconds: 800), _nextOrEnd);
  }

  void _selectOption(int opt) {
    if (_answered) return;
    _countdown?.cancel();
    final correct = _puzzle!['answer'] as int;
    final isRight = opt == correct;
    HapticFeedback.mediumImpact();

    if (isRight) {
      _celebCtrl.forward(from: 0);
      final basePts = _levels[_difficulty]!['pts'] as int;
      setState(() {
        _selected = opt; _answered = true; _isCorrect = true;
        _score += basePts; _correct++;
      });
    } else {
      setState(() { _selected = opt; _answered = true; _isCorrect = false; });
    }
    Future.delayed(const Duration(milliseconds: 1200), _nextOrEnd);
  }

  void _nextOrEnd() {
    if (_round >= _totalRounds) {
      setState(() => _gameOver = true);
      _showResultDialog();
      // Save score
      ScoreService.submitAndUpdate(
        ref: ref, score: _score, completed: _correct >= 3,
        hintsUsed: _hintsUsed, puzzleId: 3);
    } else {
      _loadPuzzle();
    }
  }

  void _useHint() {
    if (_answered || _hintUsed) return;

    // Check if player can afford hint
    if (!ScoreService.canAffordHint(ref)) {
      _showNoPointsDialog();
      return;
    }

    // Deduct 10 points
    ScoreService.deductHintPoints(ref);
    setState(() {
      _hint = _puzzle!['hint'] as String;
      _hintUsed = true;
      _hintsUsed++;
    });
    HapticFeedback.selectionClick();
  }

  void _showNoPointsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8345A).withOpacity(0.4))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Not Enough Points!',
              style: GoogleFonts.inter(fontSize: 18,
                fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('You need 10 points to use a hint.\nPlay more games to earn points!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13,
                color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
                child: Text('OK', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showResultDialog() {
    final accuracy = _correct > 0
        ? ((_correct / _totalRounds) * 100).round() : 0;
    final emoji = _correct >= 5 ? '🏆' : _correct >= 3 ? '🎯' : '💪';
    final msg   = _correct >= 5 ? 'Perfect Score!'
        : _correct >= 3 ? 'Well done!' : 'Keep practicing!';
    final color = _levels[_difficulty]!['color'] as Color;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => ScaleTransition(
        scale: _celebAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withOpacity(0.4)),
              boxShadow: [BoxShadow(
                color: color.withOpacity(0.2), blurRadius: 40)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)]),
                child: Center(child: Text(emoji,
                  style: const TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 16),
              Text(msg, style: GoogleFonts.inter(fontSize: 22,
                fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('$_correct/$_totalRounds correct',
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 20),
              Row(children: [
                _dStat('⭐', '$_score', 'SCORE'),
                const SizedBox(width: 8),
                _dStat('✅', '$_correct', 'CORRECT'),
                const SizedBox(width: 8),
                _dStat('🎯', '$accuracy%', 'ACC'),
              ]),
              const SizedBox(height: 20),
              if (_hintsUsed > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7971E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF7971E).withOpacity(0.3))),
                  child: Text(
                    '💡 $_hintsUsed hint${_hintsUsed > 1 ? 's' : ''} used — ${_hintsUsed * 10} pts charged',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12,
                      color: const Color(0xFFF7971E))),
                ),
              ],
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _startGame(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: Text('Play Again 🔄',
                    style: GoogleFonts.inter(fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: Text('Back to Home',
                  style: GoogleFonts.inter(fontSize: 14,
                    color: Colors.white.withOpacity(0.4))),
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
        Text(val, style: GoogleFonts.inter(fontSize: 18,
          fontWeight: FontWeight.w800, color: Colors.white)),
        Text(lbl, style: GoogleFonts.inter(fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.35))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(child: !_started ? _buildStart() : _buildGame()),
    );
  }

  Widget _buildStart() => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32))),
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
                  color: Colors.white, size: 16)),
            ),
          ]),
          const SizedBox(height: 20),
          const Text('🧩', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Logic Puzzles', style: GoogleFonts.inter(
            fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Find the pattern. Beat the clock.',
            style: GoogleFonts.inter(fontSize: 14,
              color: Colors.white.withOpacity(0.7))),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('How to Play', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 14),
              _howRow('🔢', 'Look at the number sequence'),
              _howRow('🧠', 'Find the pattern'),
              _howRow('👆', 'Tap the correct answer'),
              _howRow('💡', 'Hint costs 10 brain points'),
              _howRow('⏱', 'Answer before time runs out!'),
            ]),
          ),
          const SizedBox(height: 20),

          Text('Select Difficulty', style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),

          Row(children: _levels.entries.map((e) {
            final sel   = _difficulty == e.key;
            final color = e.value['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _difficulty = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: e.key != 'hard' ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: sel ? color.withOpacity(0.15) : const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel ? color : Colors.white.withOpacity(0.06),
                      width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 16, offset: const Offset(0, 4))] : []),
                  child: Column(children: [
                    Text(e.value['emoji'] as String,
                      style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(e.value['label'] as String,
                      style: GoogleFonts.inter(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? color : Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 2),
                    Text('+${e.value['pts']} pts',
                      style: GoogleFonts.inter(fontSize: 10,
                        color: Colors.white.withOpacity(0.3))),
                    Text('${e.value['time']}s',
                      style: GoogleFonts.inter(fontSize: 10,
                        color: Colors.white.withOpacity(0.3))),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Hint = 10 brain points charged',
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.5))),
            ]),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
                shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
                elevation: 8),
              child: Text('Start Game 🧩',
                style: GoogleFonts.inter(fontSize: 18,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ]),
      ),
    ]),
  );

  Widget _howRow(String em, String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(em, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(txt, style: GoogleFonts.inter(
        fontSize: 13, color: Colors.white.withOpacity(0.5))),
    ]),
  );

  Widget _buildGame() {
    if (_puzzle == null) return const Center(
      child: CircularProgressIndicator(color: Color(0xFFA78BFA)));

    final levelColor = _levels[_difficulty]!['color'] as Color;
    final maxTime    = _levels[_difficulty]!['time'] as int;
    final timerColor = _timer <= 3
        ? const Color(0xFFE8345A)
        : _timer <= 6 ? const Color(0xFFF7971E) : levelColor;
    final sequence = (_puzzle!['sequence'] as List).map((e) => e.toString()).toList();
    final options  = (_puzzle!['options']  as List).map((e) => e as int).toList();
    final question = _puzzle!['question'] as String;

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          border: Border(bottom: BorderSide(
            color: Colors.white.withOpacity(0.04)))),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE', style: GoogleFonts.inter(fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.35), letterSpacing: 0.6)),
            Text('$_score', style: GoogleFonts.inter(fontSize: 24,
              fontWeight: FontWeight.w900, color: Colors.white)),
          ]),
          const Spacer(),
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                value: maxTime > 0 ? _timer / maxTime : 0,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(timerColor))),
            Text('$_timer', style: GoogleFonts.inter(fontSize: 18,
              fontWeight: FontWeight.w900, color: timerColor)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ROUND', style: GoogleFonts.inter(fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.35), letterSpacing: 0.6)),
            Text('$_round/$_totalRounds', style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalRounds, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i < _round - 1 ? 24 : i == _round - 1 ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i < _round - 1
                ? (_correct > i
                    ? const Color(0xFF38EF7D)
                    : const Color(0xFFE8345A))
                : i == _round - 1
                  ? levelColor
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          )),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(question, style: GoogleFonts.inter(fontSize: 15,
          color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 16),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              levelColor.withOpacity(0.15), levelColor.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: levelColor.withOpacity(0.2))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sequence.map((item) {
              final isQ = item == '?';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isQ ? levelColor : const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isQ ? [BoxShadow(
                    color: levelColor.withOpacity(0.4), blurRadius: 12)] : []),
                child: Text(item, style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 16),

      if (_hint.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7971E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF7971E).withOpacity(0.3))),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(_hint, style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFF7971E)))),
            ]),
          ),
        ),

      const SizedBox(height: 12),

      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: _optionAnim,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10, crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: options.map((opt) {
                final isSelected   = _selected == opt;
                final correct      = _puzzle!['answer'] as int;
                final isCorrectOpt = opt == correct;
                Color bg     = const Color(0xFF1C1C2E);
                Color border = Colors.white.withOpacity(0.06);
                Color text   = Colors.white;
                if (_answered) {
                  if (isCorrectOpt) {
                    bg = const Color(0xFF38EF7D).withOpacity(0.15);
                    border = const Color(0xFF38EF7D);
                    text = const Color(0xFF38EF7D);
                  } else if (isSelected) {
                    bg = const Color(0xFFE8345A).withOpacity(0.15);
                    border = const Color(0xFFE8345A);
                    text = const Color(0xFFE8345A);
                  }
                } else if (isSelected) {
                  bg = levelColor.withOpacity(0.15);
                  border = levelColor;
                  text = levelColor;
                }
                return GestureDetector(
                  onTap: () => _selectOption(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 1.5)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_answered && isCorrectOpt)
                          const Text('✅ ', style: TextStyle(fontSize: 16))
                        else if (_answered && isSelected && !isCorrectOpt)
                          const Text('❌ ', style: TextStyle(fontSize: 16)),
                        Text('$opt', style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800, color: text)),
                      ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),

      if (!_answered)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GestureDetector(
            onTap: _useHint,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _hintUsed
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hintUsed
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF7971E).withOpacity(0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('💡', style: TextStyle(fontSize: 16,
                  color: _hintUsed ? Colors.white.withOpacity(0.2) : null)),
                const SizedBox(width: 8),
                Text(
                  _hintUsed ? 'Hint used (-10 pts)' : 'Use Hint (-10 pts)',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _hintUsed
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFF7971E))),
              ]),
            ),
          ),
        ),
    ]);
  }
}
