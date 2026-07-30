import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NumberTapScreen extends StatefulWidget {
  const NumberTapScreen({super.key});
  @override State<NumberTapScreen> createState() => _NumberTapState();
}

class _NumberTapState extends State<NumberTapScreen> {
  final _rng = Random();
  List<int> _numbers = [];
  int _target = 0;
  int _score = 0;
  int _timer = 30;
  bool _started = false;
  bool _finished = false;
  Timer? _tick;
  bool _showWrong = false;

  void _start() {
    setState(() {
      _score = 0; _timer = 30;
      _started = true; _finished = false;
    });
    _newRound();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timer <= 0) {
        _tick?.cancel();
        setState(() => _finished = true);
      } else {
        setState(() => _timer--);
      }
    });
  }

  void _newRound() {
    final nums = List.generate(9, (_) => _rng.nextInt(9) + 1)..shuffle();
    final t = nums[_rng.nextInt(9)];
    setState(() { _numbers = nums; _target = t; });
  }

  void _tap(int n) {
    if (!_started || _finished) return;
    if (n == _target) {
      setState(() => _score += 10);
      _newRound();
    } else {
      setState(() => _showWrong = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showWrong = false);
      });
    }
  }

  @override
  void dispose() { _tick?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: !_started ? _buildStart() :
               _finished  ? _buildDone()  : _buildGame(),
      ),
    );
  }

  Widget _buildStart() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🎯', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 80)),
        const SizedBox(height: 20),
        Text('Number Tap', textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(height: 8),
        Text('Tap the correct number as fast as possible!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14,
            color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF7971E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16))),
          child: Text('Start Game 🚀',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Back', style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.4))),
        ),
      ],
    ),
  );

  Widget _buildGame() {
    final timerColor = _timer <= 5 ? const Color(0xFFE8345A)
        : _timer <= 15 ? const Color(0xFFF7971E)
        : const Color(0xFFA78BFA);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score: $_score',
                style: GoogleFonts.inter(fontSize: 20,
                  fontWeight: FontWeight.w800, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: timerColor.withOpacity(0.3))),
                child: Text('⏱ $_timer',
                  style: GoogleFonts.inter(fontSize: 18,
                    fontWeight: FontWeight.w800, color: timerColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LinearProgressIndicator(
            value: _timer / 30,
            backgroundColor: const Color(0xFF1C1C2E),
            valueColor: AlwaysStoppedAnimation(timerColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 40),
        Text('Tap the number:',
          style: GoogleFonts.inter(fontSize: 14,
            color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showWrong
                ? [const Color(0xFFE8345A), const Color(0xFFFF6B6B)]
                : [const Color(0xFFF7971E), const Color(0xFFFFD200)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: (_showWrong
                ? const Color(0xFFE8345A)
                : const Color(0xFFF7971E)).withOpacity(0.4),
              blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: Text('$_target',
              style: GoogleFonts.inter(fontSize: 44,
                fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              children: _numbers.map((n) => GestureDetector(
                onTap: () => _tap(n),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06))),
                  child: Center(
                    child: Text('$n',
                      style: GoogleFonts.inter(fontSize: 32,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDone() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_score >= 150 ? '🏆' : _score >= 80 ? '🥇' : '💪',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text('$_score pts', textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(height: 8),
        Text(_score >= 150 ? 'Incredible reflexes!' :
             _score >= 80  ? 'Great job!' : 'Keep practicing!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 15,
            color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF7971E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16))),
          child: const Text('Play Again 🔄'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Back to Home', style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.4))),
        ),
      ],
    ),
  );
}
