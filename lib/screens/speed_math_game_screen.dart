import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../services/api_service.dart';
import '../../providers/user_provider.dart';

class SpeedMathGameScreen extends ConsumerStatefulWidget {
  final int levelNumber;

  const SpeedMathGameScreen({super.key, required this.levelNumber});

  @override
  ConsumerState<SpeedMathGameScreen> createState() => _SpeedMathGameScreenState();
}

class _SpeedMathGameScreenState extends ConsumerState<SpeedMathGameScreen> {
  final Random _random = Random();

  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;

  late int _totalTime;
  late int _timeLeft;
  Timer? _timer;

  bool _isGameOver = false;
  String _inputAnswer = '';

  @override
  void initState() {
    super.initState();
    _totalTime = _getTimerForLevel(widget.levelNumber);
    _timeLeft = _totalTime;
    _generateLevelQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Exact Level Timings: 1-10 -> 30s | 11-20 -> 20s | 21-30 -> 15s
  int _getTimerForLevel(int level) {
    if (level <= 10) return 30;
    if (level <= 20) return 20;
    return 15;
  }

  void _generateLevelQuestions() {
    const int questionCount = 10;
    final int maxNum = 5 + (widget.levelNumber * 3);

    _questions = List.generate(questionCount, (_) {
      final a = _random.nextInt(maxNum) + 2;
      final b = _random.nextInt(maxNum) + 2;
      final isAddition = _random.nextBool();

      return {
        'question': isAddition ? '$a + $b' : '${a + b} - $a',
        'answer': isAddition ? (a + b) : b,
      };
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _onNumpadTap(String val) {
    if (_isGameOver) return;

    setState(() {
      if (val == 'C') {
        _inputAnswer = '';
      } else if (val == '⌫') {
        if (_inputAnswer.isNotEmpty) {
          _inputAnswer = _inputAnswer.substring(0, _inputAnswer.length - 1);
        }
      } else {
        if (_inputAnswer.length < 4) {
          _inputAnswer += val;
        }
      }
    });

    _checkAnswer();
  }

  void _checkAnswer() {
    final input = int.tryParse(_inputAnswer.trim());
    if (input == null) return;

    final correctAnswer = _questions[_currentIndex]['answer'] as int;

    if (input == correctAnswer) {
      HapticFeedback.lightImpact();
      _score += 10 + (widget.levelNumber * 2);
      _correctAnswers++;
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    _inputAnswer = '';
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    setState(() => _isGameOver = true);

    // Calculate Stars
    int starsEarned = 0;
    if (_correctAnswers >= 8) {
      starsEarned = 3;
    } else if (_correctAnswers >= 5) {
      starsEarned = 2;
    } else if (_correctAnswers >= 3) {
      starsEarned = 1;
    }

    // 1. Local Hive Level & Stars Save
    final box = Hive.box('userBox');
    final currentStars = box.get('speedmath_level_${widget.levelNumber}_stars', defaultValue: 0) as int;
    if (starsEarned > currentStars) {
      await box.put('speedmath_level_${widget.levelNumber}_stars', starsEarned);
    }

    if (starsEarned > 0) {
      final unlockedLevel = box.get('speedmath_unlocked', defaultValue: 1) as int;
      if (widget.levelNumber >= unlockedLevel) {
        await box.put('speedmath_unlocked', widget.levelNumber + 1);
      }
    }

    // 2. UserProvider State & Streak Sync (Local Hive + State Update)
    if (_score > 0) {
      ref.read(userProvider.notifier).addScore(_score);
    }

    // 3. Backend Direct Sync using ApiService.submitScore
    final userState = ref.read(userProvider);
    if (userState.userId != null && _score > 0) {
      try {
        await ApiService.submitScore(
          userId: userState.userId!,
          puzzleId: widget.levelNumber,
          score: _score,
          timeTaken: _totalTime - _timeLeft,
          hintsUsed: 0,
          completed: starsEarned > 0,
        );
      } catch (e) {
        debugPrint("Backend Score Submit Error: $e");
      }
    }

    if (mounted) {
      _showResultDialog(starsEarned);
    }
  }

  void _showResultDialog(int stars) {
    final bool isPassed = stars > 0;
    final userState = ref.watch(userProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isPassed ? const Color(0xFF6C5CE7) : const Color(0xFFFF4757).withOpacity(0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPassed ? const Color(0xFF6C5CE7) : const Color(0xFFFF4757)).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isPassed ? const Color(0xFF6C5CE7) : const Color(0xFFFF4757)).withOpacity(0.15),
                ),
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
                  size: 44,
                  color: isPassed ? const Color(0xFFFFD15C) : const Color(0xFFFF4757),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isPassed ? 'Level Cleared!' : 'Try Again!',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPassed ? 'Awesome speed! Next level unlocked.' : 'Get at least 3 correct answers to pass.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 20),

              // Star Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final earned = i < stars;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (i * 100)),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: earned ? const Color(0xFFFFD15C) : Colors.white24,
                      size: 44,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Pro Stats Dashboard
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatTile('SCORE', '+$_score', const Color(0xFF6C5CE7)),
                    Container(height: 28, width: 1, color: Colors.white10),
                    _buildStatTile('ACCURACY', '$_correctAnswers/10', const Color(0xFF00B894)),
                    Container(height: 28, width: 1, color: Colors.white10),
                    _buildStatTile('STREAK', '🔥 ${userState.currentStreak}', Colors.orangeAccent),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text('Levels', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF6C5CE7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentIndex = 0;
                          _score = 0;
                          _correctAnswers = 0;
                          _timeLeft = _totalTime;
                          _isGameOver = false;
                          _inputAnswer = '';
                        });
                        _generateLevelQuestions();
                        _startTimer();
                      },
                      child: Text('Replay', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 0.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final double timerProgress = _timeLeft / _totalTime;
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Level ${widget.levelNumber}',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _headerChip(
                    icon: Icons.timer_outlined,
                    iconColor: Colors.amber,
                    text: '${_timeLeft}s',
                    textColor: Colors.amber,
                  ),
                  _headerChip(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orangeAccent,
                    text: '${userState.currentStreak}d',
                    textColor: Colors.orangeAccent,
                  ),
                  _headerChip(
                    icon: Icons.stars_rounded,
                    iconColor: const Color(0xFF6C5CE7),
                    text: '$_score',
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: timerProgress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1C1C2E),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _timeLeft < 5 ? const Color(0xFFFF4757) : const Color(0xFF6C5CE7),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Question Card Container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1C2E), Color(0xFF161626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'QUESTION ${_currentIndex + 1} OF 10',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentQ['question'],
                    style: GoogleFonts.inter(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                  ),
                  const SizedBox(height: 22),

                  // Display Answer Field
                  Container(
                    width: 140,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _inputAnswer.isNotEmpty ? const Color(0xFF6C5CE7) : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _inputAnswer.isEmpty ? '?' : _inputAnswer,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _inputAnswer.isNotEmpty ? const Color(0xFF6C5CE7) : Colors.white24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // On-Screen Keypad
            _buildNumpad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _headerChip({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(color: textColor, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
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
            final isSpecial = key == 'C' || key == '⌫';
            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onNumpadTap(key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 80,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSpecial ? const Color(0xFF25253E) : const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Text(
                      key,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isSpecial ? const Color(0xFFFF6B6B) : Colors.white,
                      ),
                    ),
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