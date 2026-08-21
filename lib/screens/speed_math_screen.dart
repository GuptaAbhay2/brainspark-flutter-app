import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Tumhare project structure ke according import path adjust kar lena:
// import '../../services/api_service.dart';
// import '../../providers/user_provider.dart';

class SpeedMathScreen extends ConsumerStatefulWidget {
  const SpeedMathScreen({super.key});

  @override
  ConsumerState<SpeedMathScreen> createState() => _SpeedMathScreenState();
}

class _SpeedMathScreenState extends ConsumerState<SpeedMathScreen> {
  final TextEditingController _ansCtrl = TextEditingController();
  final Random _random = Random();

  String _difficulty = 'Easy';
  int _score = 0;
  int _correct = 0;
  int _wrong = 0;
  int _current = 0;
  int _timeLeft = 15;
  bool _started = false;
  bool _finished = false;
  Timer? _countdown;

  List<Map<String, dynamic>> _questions = [];

  final Map<String, Map<String, dynamic>> _difficultyConfig = {
    'Easy': {'time': 15, 'count': 10, 'max': 10, 'pts': 10},
    'Medium': {'time': 12, 'count': 15, 'max': 25, 'pts': 20},
    'Hard': {'time': 10, 'count': 20, 'max': 50, 'pts': 30},
  };

  @override
  void dispose() {
    _countdown?.cancel();
    _ansCtrl.dispose();
    super.dispose();
  }

  void _generateQuestions() {
    final cfg = _difficultyConfig[_difficulty]!;
    final count = cfg['count'] as int;
    final maxNum = cfg['max'] as int;

    _questions = List.generate(count, (_) {
      final a = _random.nextInt(maxNum) + 1;
      final b = _random.nextInt(maxNum) + 1;
      final isAdd = _random.nextBool();
      return {
        'q': isAdd ? '$a + $b' : '${a + b} - $a',
        'a': isAdd ? (a + b) : b,
      };
    });
  }

  void _startGame() {
    _generateQuestions();
    setState(() {
      _score = 0;
      _correct = 0;
      _wrong = 0;
      _current = 0;
      _timeLeft = _difficultyConfig[_difficulty]!['time'] as int;
      _started = true;
      _finished = false;
    });
    _ansCtrl.clear();
    _startTimer();
  }

  void _startTimer() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        _timerExpired();
      }
    });
  }

  void _timerExpired() {
    _countdown?.cancel();
    setState(() {
      _timeLeft = 0;
      _finished = true;
    });
    _saveScore();
    _showResultDialog();
  }

  void _onNumpadTap(String val) {
    if (!_started || _finished) return;

    if (val == 'C') {
      _ansCtrl.clear();
    } else if (val == '⌫') {
      if (_ansCtrl.text.isNotEmpty) {
        _ansCtrl.text = _ansCtrl.text.substring(0, _ansCtrl.text.length - 1);
      }
    } else {
      if (_ansCtrl.text.length < 4) {
        _ansCtrl.text += val;
      }
    }
    _checkAnswer();
  }

  void _checkAnswer() {
    final input = int.tryParse(_ansCtrl.text.trim());
    if (input == null) return;

    final correct = _questions[_current]['a'] as int;

    if (input == correct) {
      HapticFeedback.lightImpact();
      final pts = _difficultyConfig[_difficulty]!['pts'] as int;
      _score += pts;
      _correct++;
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    _ansCtrl.clear();
    if (_current < _questions.length - 1) {
      setState(() => _current++);
    } else {
      _countdown?.cancel();
      setState(() => _finished = true);
      _saveScore();
      _showResultDialog();
    }
  }

  Future<void> _saveScore() async {
    try {
      // Direct Backend Sync
      // await ApiService.submitScore(game: 'speed_math_arcade', score: _score);
      // ref.read(userProvider.notifier).fetchUserProfile();
    } catch (e) {
      debugPrint('Error syncing arcade score: $e');
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Arcade Mode Completed!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$_score', style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontSize: 36, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statColumn('Correct', '$_correct', Colors.greenAccent),
                _statColumn('Total Qs', '${_questions.length}', Colors.white70),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _started = false);
            },
            child: Text('Menu', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: Text('Play Again', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Speed Math Arcade', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: !_started ? _buildStartMenu() : _buildGameplay(),
      ),
    );
  }

  Widget _buildStartMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt_rounded, size: 72, color: Color(0xFF6C5CE7)),
          const SizedBox(height: 16),
          Text(
            'Arcade Challenge',
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Select difficulty and answer as many questions as you can before time runs out!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 36),

          // Difficulty Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Easy', 'Medium', 'Hard'].map((diff) {
              final isSelected = _difficulty == diff;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(diff, style: TextStyle(color: isSelected ? Colors.white : Colors.white54)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6C5CE7),
                  backgroundColor: const Color(0xFF1C1C2E),
                  onSelected: (_) => setState(() => _difficulty = diff),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startGame,
              child: Text('Start Game', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameplay() {
    final currentQ = _questions[_current];

    return Column(
      children: [
        // Stats bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⏱️ ${_timeLeft}s', style: GoogleFonts.inter(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Score: $_score', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const Spacer(),

        // Question
        Text(
          currentQ['q'],
          style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
        ),

        const SizedBox(height: 20),

        // Display Answer Box (ReadOnly - Prevent Native Keyboard)
        Container(
          width: 180,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C5CE7), width: 1.5),
          ),
          child: Text(
            _ansCtrl.text.isEmpty ? '?' : _ansCtrl.text,
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),

        const Spacer(),

        // On-Screen Numpad
        _buildNumpad(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: InkWell(
                onTap: () => _onNumpadTap(key),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 75,
                  height: 55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    key,
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}