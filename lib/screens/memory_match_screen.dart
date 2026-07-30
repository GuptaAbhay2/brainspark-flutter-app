import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});
  @override State<MemoryMatchScreen> createState() => _MemoryState();
}

class _MemoryState extends State<MemoryMatchScreen> {
  final List<String> _emojis = ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼'];
  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int? _first;
  bool _canFlip = true;
  int _moves = 0;
  int _matches = 0;
  bool _started = false;
  bool _finished = false;
  int _timer = 0;
  Timer? _tick;

  void _start() {
    _cards = [..._emojis, ..._emojis]..shuffle(Random());
    setState(() {
      _flipped = List.filled(16, false);
      _matched = List.filled(16, false);
      _moves = 0; _matches = 0; _started = true;
      _finished = false; _first = null; _timer = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timer++);
    });
  }

  void _tap(int i) {
    if (!_canFlip || _flipped[i] || _matched[i]) return;
    setState(() => _flipped[i] = true);
    if (_first == null) {
      _first = i;
    } else {
      _moves++;
      _canFlip = false;
      if (_cards[_first!] == _cards[i]) {
        setState(() {
          _matched[_first!] = true;
          _matched[i] = true;
          _matches++;
          _first = null;
          _canFlip = true;
        });
        if (_matches == 8) {
          _tick?.cancel();
          setState(() => _finished = true);
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() {
            _flipped[_first!] = false;
            _flipped[i] = false;
            _first = null;
            _canFlip = true;
          });
        });
      }
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
        const Text('🃏', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 80)),
        const SizedBox(height: 20),
        Text('Card Match', textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(height: 8),
        Text('Flip cards and find all matching pairs!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14,
            color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8345A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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

  Widget _buildGame() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text('Card Match',
              style: GoogleFonts.inter(fontSize: 18,
                fontWeight: FontWeight.w700, color: Colors.white)),
            const Spacer(),
            _chip('⏱ ${_timer}s'),
            const SizedBox(width: 8),
            _chip('🎯 $_moves moves'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: LinearProgressIndicator(
            value: _matches / 8,
            backgroundColor: const Color(0xFF1C1C2E),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE8345A)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          )),
          const SizedBox(width: 12),
          Text('$_matches/8',
            style: GoogleFonts.inter(fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5))),
        ]),
      ),
      const SizedBox(height: 20),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: 16,
            itemBuilder: (_, i) {
              final isFlipped = _flipped[i] || _matched[i];
              return GestureDetector(
                onTap: () => _tap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _matched[i]
                      ? const Color(0xFFE8345A).withOpacity(0.2)
                      : isFlipped
                        ? const Color(0xFF1C1C2E)
                        : const Color(0xFF2C2C3E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _matched[i]
                        ? const Color(0xFFE8345A).withOpacity(0.5)
                        : Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Text(
                      isFlipped ? _cards[i] : '?',
                      style: TextStyle(
                        fontSize: isFlipped ? 28 : 22,
                        color: isFlipped
                          ? null : Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );

  Widget _buildDone() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🎉', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text('You Won!', textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800,
            color: Colors.white)),
        const SizedBox(height: 8),
        Text('Completed in $_moves moves & ${_timer}s',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14,
            color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _start,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8345A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C2E),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: Text(text, style: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
  );
}
