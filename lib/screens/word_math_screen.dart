import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordMathScreen extends StatefulWidget {
  const WordMathScreen({super.key});
  @override State<WordMathScreen> createState() => _WordMathState();
}

class _WordMathState extends State<WordMathScreen> {
  final _words = ['zero','one','two','three','four','five',
                  'six','seven','eight','nine','ten'];
  final _rng = Random();
  String _question = '';
  List<String> _options = [];
  String _correct = '';
  int _score = 0;
  int _round = 0;
  bool? _answered;
  String? _selected;

  @override
  void initState() { super.initState(); _newQuestion(); }

  void _newQuestion() {
    final a = _rng.nextInt(5) + 1;
    final b = _rng.nextInt(5) + 1;
    final ops = ['+', '-'];
    final op = ops[_rng.nextInt(2)];
    int ans;
    if (op == '+') {
      ans = a + b;
    } else {
      ans = (a - b).abs();
    }
    final q = '${_words[a].toUpperCase()} $op ${_words[b].toUpperCase()} = ?';
    final correct = _words[ans];
    final wrongs = List.generate(10, (i) => i)
      ..remove(ans);
    wrongs.shuffle();
    final opts = [correct, _words[wrongs[0]], _words[wrongs[1]], _words[wrongs[2]]]
      ..shuffle();
    setState(() {
      _question = q; _correct = correct;
      _options = opts; _answered = null; _selected = null;
    });
  }

  void _select(String opt) {
    if (_answered != null) return;
    final ok = opt == _correct;
    setState(() {
      _selected = opt;
      _answered = ok;
      if (ok) { _score += 20; _round++; }
      else _round++;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _newQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
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
                Text('Word Math',
                  style: GoogleFonts.inter(fontSize: 18,
                    fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF834d9b).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF834d9b).withOpacity(0.4))),
                  child: Text('$_score pts',
                    style: GoogleFonts.inter(fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFd04ed6))),
                ),
              ]),
              const SizedBox(height: 16),
              Text('Round $_round',
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.35))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF834d9b), Color(0xFFd04ed6)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF834d9b).withOpacity(0.4),
                    blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Text(_question, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 26,
                    fontWeight: FontWeight.w800, color: Colors.white,
                    height: 1.4)),
              ),
              const SizedBox(height: 32),
              const Text('Choose the correct word:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              ..._options.map((opt) {
                Color bg = const Color(0xFF1C1C2E);
                Color border = Colors.white.withOpacity(0.06);
                if (_selected == opt) {
                  bg = (_answered! ? const Color(0xFF11998E) : const Color(0xFFE8345A))
                      .withOpacity(0.2);
                  border = _answered!
                    ? const Color(0xFF11998E) : const Color(0xFFE8345A);
                } else if (_answered != null && opt == _correct) {
                  bg = const Color(0xFF11998E).withOpacity(0.15);
                  border = const Color(0xFF11998E).withOpacity(0.5);
                }
                return GestureDetector(
                  onTap: () => _select(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border)),
                    child: Text(opt.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                );
              }),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
