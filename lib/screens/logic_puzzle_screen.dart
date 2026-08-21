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
    'easy': {
      'label': 'EASY',
      'time': 15,
      'pts': 50,
      'color': const Color(0xFF10B981),
      
    },
    'medium': {
      'label': 'MEDIUM',
      'time': 12,
      'pts': 100,
      'color': const Color(0xFF3B82F6),
      
    },
    'hard': {
      'label': 'HARD',
      'time': 10,
      'pts': 150,
      'color': const Color(0xFFF43F5E),
      
    },
  };

  final _puzzleBank = {
    'easy': [
      {'question': 'What comes next in sequence?', 'sequence': [2, 4, 6, 8, '?'], 'options': [9, 10, 11, 12], 'answer': 10, 'hint': 'Add 2 each time'},
      {'question': 'Find the next number', 'sequence': [1, 3, 5, 7, '?'], 'options': [8, 9, 10, 11], 'answer': 9, 'hint': 'Odd numbers in order'},
      {'question': 'What is missing in pattern?', 'sequence': [5, 10, 15, 20, '?'], 'options': [22, 24, 25, 30], 'answer': 25, 'hint': 'Multiply 5 each step'},
      {'question': 'Next term in sequence?', 'sequence': [100, 90, 80, 70, '?'], 'options': [55, 60, 65, 50], 'answer': 60, 'hint': 'Subtract 10 each time'},
      {'question': 'Find the correct pattern', 'sequence': [3, 6, 9, 12, '?'], 'options': [13, 14, 15, 16], 'answer': 15, 'hint': 'Multiples of 3'},
    ],
    'medium': [
      {'question': 'What comes next?', 'sequence': [2, 4, 8, 16, '?'], 'options': [24, 28, 32, 36], 'answer': 32, 'hint': 'Each number doubles'},
      {'question': 'Find the next term', 'sequence': [1, 4, 9, 16, '?'], 'options': [20, 25, 30, 36], 'answer': 25, 'hint': 'Square numbers: 1²,2²,3²...'},
      {'question': 'Missing number?', 'sequence': [3, 6, 12, 24, '?'], 'options': [36, 42, 48, 56], 'answer': 48, 'hint': 'Each number multiplied by 2'},
      {'question': 'What comes next?', 'sequence': [1, 1, 2, 3, 5, '?'], 'options': [6, 7, 8, 9], 'answer': 8, 'hint': 'Add the two previous numbers'},
      {'question': 'Next in pattern?', 'sequence': [2, 6, 12, 20, '?'], 'options': [28, 30, 32, 36], 'answer': 30, 'hint': 'Differences: 4,6,8,10...'},
    ],
    'hard': [
      {'question': 'Find the missing number', 'sequence': [1, 8, 27, 64, '?'], 'options': [100, 121, 125, 144], 'answer': 125, 'hint': 'Cube numbers: 1³,2³,3³...'},
      {'question': 'What comes next?', 'sequence': [2, 3, 5, 7, 11, '?'], 'options': [12, 13, 14, 15], 'answer': 13, 'hint': 'Prime numbers in order'},
      {'question': 'Next term?', 'sequence': [0, 1, 3, 6, 10, '?'], 'options': [13, 14, 15, 16], 'answer': 15, 'hint': 'Triangle numbers'},
      {'question': 'Find the pattern', 'sequence': [2, 5, 10, 17, 26, '?'], 'options': [35, 36, 37, 38], 'answer': 37, 'hint': 'Add 3,5,7,9,11...'},
      {'question': 'Missing number?', 'sequence': [3, 7, 13, 21, 31, '?'], 'options': [41, 42, 43, 44], 'answer': 43, 'hint': 'Differences: 4,6,8,10,12...'},
    ],
  };

  String _difficulty = 'easy';
  Map<String, dynamic>? _puzzle;
  int? _selected;
  bool _answered = false;
  bool _isCorrect = false;
  String _hint = '';
  bool _hintUsed = false;
  int _hintsUsed = 0;
  int _score = 0;
  int _round = 0;
  int _correct = 0;
  int _timer = 15;
  bool _started = false;
  bool _gameOver = false;
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
    _optionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _optionAnim = CurvedAnimation(parent: _optionCtrl, curve: Curves.easeOutBack);
    _celebAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_celebCtrl);
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
      _score = 0;
      _round = 0;
      _correct = 0;
      _hintsUsed = 0;
      _started = true;
      _gameOver = false;
    });
    _loadPuzzle();
  }

  void _loadPuzzle() {
    _countdown?.cancel();
    final bank = _puzzleBank[_difficulty]!;
    final puzzle = bank[_puzzleIndex % bank.length];
    _puzzleIndex++;

    setState(() {
      _puzzle = Map<String, dynamic>.from(puzzle);
      _selected = null;
      _answered = false;
      _hint = '';
      _hintUsed = false;
      _timer = _levels[_difficulty]!['time'] as int;
      _round++;
      _isCorrect = false;
    });
    _optionCtrl.forward(from: 0);

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
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
    setState(() {
      _answered = true;
      _isCorrect = false;
    });
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
        _selected = opt;
        _answered = true;
        _isCorrect = true;
        _score += basePts;
        _correct++;
      });
    } else {
      setState(() {
        _selected = opt;
        _answered = true;
        _isCorrect = false;
      });
    }
    Future.delayed(const Duration(milliseconds: 1200), _nextOrEnd);
  }

  void _nextOrEnd() {
    if (_round >= _totalRounds) {
      setState(() => _gameOver = true);
      _showResultDialog();
      ScoreService.submitAndUpdate(
          ref: ref,
          score: _score,
          completed: _correct >= 3,
          hintsUsed: _hintsUsed,
          puzzleId: 3);
    } else {
      _loadPuzzle();
    }
  }

  void _useHint() {
    if (_answered || _hintUsed) return;

    if (!ScoreService.canAffordHint(ref)) {
      _showNoPointsDialog();
      return;
    }

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
            color: const Color(0xFF131628),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withOpacity(0.15),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text('⚠️', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 16),
              Text(
                'Insufficient Brain Points',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need at least 10 points to unlock a hint.\nPlay more rounds to accumulate score!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Got It',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog() {
    final accuracy =
        _correct > 0 ? ((_correct / _totalRounds) * 100).round() : 0;
    final emoji = _correct >= 5 ? '👑' : _correct >= 3 ? '🎯' : '💡';
    final msg = _correct >= 5
        ? 'Flawless Victory!'
        : _correct >= 3
            ? 'Great Job!'
            : 'Keep Training!';
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131628),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 40)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  msg,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Difficulty: ${_difficulty.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatCard('✨', '$_score', 'SCORE'),
                    const SizedBox(width: 8),
                    _buildStatCard('🎯', '$_correct/$_totalRounds', 'SOLVED'),
                    const SizedBox(width: 8),
                    _buildStatCard('⚡', '$accuracy%', 'ACCURACY'),
                  ],
                ),
                if (_hintsUsed > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Text(
                      '💡 Used $_hintsUsed hint(s) (-${_hintsUsed * 10} pts)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startGame();
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
                        const Icon(Icons.replay, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Play Again',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Return to Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white38,
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

  Widget _buildStatCard(String icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0D17),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D17),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_started ? _buildStartScreen() : _buildGameScreen(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.extension_rounded,
                          color: Color(0xFF818CF8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Logic Suite',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF818CF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2),
                    const Color(0xFF8B5CF6).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🤔', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pattern Master',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Decode the numerical sequences before time expires.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Select Difficulty',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: _levels.entries.map((e) {
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
                            ? color.withOpacity(0.12)
                            : const Color(0xFF131628),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? color
                              : Colors.white.withOpacity(0.05),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Text(
                            e.value['label'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: selected ? color : Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${e.value['pts']} pts',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white38,
                            ),
                          ),
                          Text(
                            '${e.value['time']}s limit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131628),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rules of Engagement',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRuleRow('🔢', 'Analyze the logical pattern in numbers'),
                  _buildRuleRow('⏱️', 'Submit your choice before time runs out'),
                  _buildRuleRow('💡', 'Hints cost 10 points per puzzle'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  elevation: 8,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Game',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    if (_puzzle == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    final levelColor = _levels[_difficulty]!['color'] as Color;
    final maxTime = _levels[_difficulty]!['time'] as int;
    final timerColor = _timer <= 3
        ? const Color(0xFFF43F5E)
        : _timer <= 6
            ? const Color(0xFFF59E0B)
            : levelColor;

    final sequence =
        (_puzzle!['sequence'] as List).map((e) => e.toString()).toList();
    final options =
        (_puzzle!['options'] as List).map((e) => e as int).toList();
    final question = _puzzle!['question'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        children: [
          // Top HUD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131628),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCORE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_score',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: maxTime > 0 ? _timer / maxTime : 0,
                        strokeWidth: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(timerColor),
                      ),
                    ),
                    Text(
                      '$_timer',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ROUND',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_round/$_totalRounds',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Round Progress Line
          Row(
            children: List.generate(
              _totalRounds,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: i < _totalRounds - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < _round - 1
                        ? (_correct > i
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E))
                        : i == _round - 1
                            ? levelColor
                            : Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Question Title
          Text(
            question,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),

          // Sequence Cards Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  levelColor.withOpacity(0.12),
                  const Color(0xFF131628),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: levelColor.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: sequence.map((item) {
                final isUnknown = item == '?';
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUnknown
                        ? levelColor
                        : const Color(0xFF0B0D17),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isUnknown
                          ? levelColor
                          : Colors.white.withOpacity(0.08),
                    ),
                    boxShadow: isUnknown
                        ? [
                            BoxShadow(
                              color: levelColor.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                        color: isUnknown
                          ? Colors.white
                          : Colors.white.withOpacity(0.9),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Animated Hint display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _hint.isNotEmpty
                ? Container(
                    key: ValueKey(_hint),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hint,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 0),
          ),
          const Spacer(),

          // Options Grid
          FadeTransition(
            opacity: _optionAnim,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: options.map((opt) {
                final isSelected = _selected == opt;
                final correct = _puzzle!['answer'] as int;
                final isCorrectOpt = opt == correct;

                Color cardBg = const Color(0xFF131628);
                Color cardBorder = Colors.white.withOpacity(0.06);
                Color textColor = Colors.white;

                if (_answered) {
                  if (isCorrectOpt) {
                    cardBg = const Color(0xFF10B981).withOpacity(0.15);
                    cardBorder = const Color(0xFF10B981);
                    textColor = const Color(0xFF10B981);
                  } else if (isSelected) {
                    cardBg = const Color(0xFFF43F5E).withOpacity(0.15);
                    cardBorder = const Color(0xFFF43F5E);
                    textColor = const Color(0xFFF43F5E);
                  }
                } else if (isSelected) {
                  cardBg = levelColor.withOpacity(0.15);
                  cardBorder = levelColor;
                  textColor = levelColor;
                }

                return GestureDetector(
                  onTap: () => _selectOption(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder, width: 1.5),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_answered && isCorrectOpt)
                            const Text('✅ ', style: TextStyle(fontSize: 16))
                          else if (_answered && isSelected && !isCorrectOpt)
                            const Text('❌ ', style: TextStyle(fontSize: 16)),
                          Text(
                            '$opt',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Hint Action
          if (!_answered)
            GestureDetector(
              onTap: _useHint,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _hintUsed
                      ? Colors.white.withOpacity(0.02)
                      : const Color(0xFF131628),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hintUsed
                        ? Colors.transparent
                        : const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '💡',
                      style: TextStyle(
                        fontSize: 16,
                        color: _hintUsed ? Colors.white24 : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _hintUsed ? 'Hint Activated (-10 pts)' : 'Use Hint (-10 pts)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _hintUsed
                            ? Colors.white24
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}