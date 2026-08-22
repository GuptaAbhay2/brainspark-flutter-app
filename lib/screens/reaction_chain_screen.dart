import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/score_service.dart';

class ReactionChainScreen extends ConsumerStatefulWidget {
  const ReactionChainScreen({super.key});
  @override
  ConsumerState<ReactionChainScreen> createState() => _RCState();
}

class _RCState extends ConsumerState<ReactionChainScreen>
    with TickerProviderStateMixin {

  static const _modes = [
    {'label': 'CLASSIC', 'grid': 5, 'count': 25, 'emoji': '🎯',
     'color': 0xFF38EF7D, 'color2': 0xFF11998E},
    {'label': 'SPEED',   'grid': 5, 'count': 25, 'emoji': '⚡',
     'color': 0xFF3B82F6, 'color2': 0xFF6C63FF},
    {'label': 'CHAOS',   'grid': 6, 'count': 36, 'emoji': '🌀',
     'color': 0xFFE8345A, 'color2': 0xFFFF6B35},
  ];

  int _modeIdx = 0;
  List<int> _grid = [];
  int _next = 1;
  bool _started = false;
  bool _finished = false;
  int _wrongTapped = -1;
  int _correctTapped = -1;

  final _stopwatch = Stopwatch();
  Timer? _uiTimer;
  int _elapsed = 0;
  int _errors = 0;
  List<int> _tapTimes = [];
  int _lastTapMs = 0;

  Map<String, int> _personalBests = {};

  late AnimationController _celebCtrl;
  late AnimationController _errorCtrl;
  late Animation<double> _celebAnim;
  late Animation<double> _errorAnim;

  @override
  void initState() {
    super.initState();
    _celebCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 700));
    _errorCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 300));
    _celebAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_celebCtrl);
    _errorAnim = Tween<double>(begin: 0.0, end: 6.0)
        .chain(CurveTween(curve: Curves.elasticIn)).animate(_errorCtrl);
    _loadBests();
    _generateGrid();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    _celebCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  void _loadBests() {
    final box = Hive.box('userBox');
    _personalBests = {
      'CLASSIC': box.get('rc_best_CLASSIC', defaultValue: 0) as int,
      'SPEED':   box.get('rc_best_SPEED',   defaultValue: 0) as int,
      'CHAOS':   box.get('rc_best_CHAOS',   defaultValue: 0) as int,
    };
  }

  void _generateGrid() {
    final count = _modes[_modeIdx]['count'] as int;
    _grid = List.generate(count, (i) => i + 1)..shuffle(Random());
    setState(() {
      _next = 1; _errors = 0;
      _tapTimes = []; _lastTapMs = 0;
      _wrongTapped = -1; _correctTapped = -1;
      _started = false; _finished = false;
    });
  }

  void _startGame() {
    _generateGrid();
    setState(() => _started = true);
    _stopwatch.reset(); _stopwatch.start();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsedMilliseconds);
    });
  }

  void _tap(int number) {
    if (!_started || _finished) return;

    if (number == _next) {
      HapticFeedback.lightImpact();
      final now = _stopwatch.elapsedMilliseconds;
      if (_lastTapMs > 0) _tapTimes.add(now - _lastTapMs);
      _lastTapMs = now;

      setState(() { _correctTapped = number; });
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _correctTapped = -1);
      });

      _next++;
      final count = _modes[_modeIdx]['count'] as int;
      if (_next > count) {
        _stopwatch.stop(); _uiTimer?.cancel();
        setState(() => _finished = true);
        _saveBest();
        _showResult();
      } else {
        setState(() {});
      }
    } else {
      HapticFeedback.mediumImpact();
      _errorCtrl.forward(from: 0);
      setState(() { _errors++; _wrongTapped = number; });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _wrongTapped = -1);
      });
    }
  }

  void _saveBest() {
    final box  = Hive.box('userBox');
    final mode = _modes[_modeIdx]['label'] as String;
    final key  = 'rc_best_$mode';
    final prev = box.get(key, defaultValue: 0) as int;
    if (prev == 0 || _elapsed < prev) {
      box.put(key, _elapsed);
      _personalBests[mode] = _elapsed;
    }
    // Score = 200 base - errors penalty - time penalty (min 10)
    final score = (200 - (_errors * 20) - (_elapsed ~/ 1000 * 3)).clamp(10, 300);
    ScoreService.submitAndUpdate(
      ref: ref, score: score, completed: true, puzzleId: 5);
  }

  String _fmtTime(int ms) {
    if (ms == 0) return '--';
    final s   = ms ~/ 1000;
    final rem = (ms % 1000) ~/ 10;
    return '$s.${rem.toString().padLeft(2, '0')}s';
  }

  int get _avgTap => _tapTimes.isEmpty
      ? 0 : _tapTimes.reduce((a, b) => a + b) ~/ _tapTimes.length;

  Color get _modeColor  => Color(_modes[_modeIdx]['color']  as int);
  Color get _modeColor2 => Color(_modes[_modeIdx]['color2'] as int);
  int   get _gridSize   => _modes[_modeIdx]['grid']  as int;
  int   get _totalCount => _modes[_modeIdx]['count'] as int;
  String get _modeLabel => _modes[_modeIdx]['label'] as String;

  void _showResult() {
    _celebCtrl.forward(from: 0);
    final box      = Hive.box('userBox');
    final best     = box.get('rc_best_$_modeLabel', defaultValue: 0) as int;
    final isNewBest = _elapsed <= best && best > 0;

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
              border: Border.all(color: _modeColor.withOpacity(0.4)),
              boxShadow: [BoxShadow(
                color: _modeColor.withOpacity(0.2), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_modeColor, _modeColor2]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: _modeColor.withOpacity(0.4), blurRadius: 24)]),
                child: Center(child: Text(
                  isNewBest ? '🏆' : '✅',
                  style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 16),
              Text(isNewBest ? 'New Personal Best!' : 'Completed!',
                style: GoogleFonts.inter(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_errors == 0 ? 'Perfect run — no errors! 🔥'
                : '$_errors error${_errors > 1 ? 's' : ''} made',
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.45))),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _modeColor.withOpacity(0.15),
                    _modeColor2.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _modeColor.withOpacity(0.3))),
                child: Column(children: [
                  Text(_fmtTime(_elapsed),
                    style: GoogleFonts.inter(fontSize: 44,
                      fontWeight: FontWeight.w900, color: _modeColor)),
                  Text('YOUR TIME',
                    style: GoogleFonts.inter(fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.35), letterSpacing: 1)),
                  if (best > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Best: ${_fmtTime(best)}',
                        style: GoogleFonts.inter(fontSize: 12,
                          color: Colors.white.withOpacity(0.4))),
                    ),
                ]),
              ),
              const SizedBox(height: 16),

              Row(children: [
                _dStat('❌', '$_errors', 'ERRORS'),
                const SizedBox(width: 8),
                _dStat('⚡', _avgTap > 0 ? '${_avgTap}ms' : '--', 'AVG TAP'),
                const SizedBox(width: 8),
                _dStat('🎯', '$_totalCount', 'TAPS'),
              ]),
              const SizedBox(height: 20),

              if (isNewBest)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3))),
                  child: Text('🏆 New personal best! Keep practicing!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD700))),
                ),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _startGame(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _modeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
                  child: Text('Play Again 🔄',
                    style: GoogleFonts.inter(fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Back to Home',
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
        Text(em, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(fontSize: 15,
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
      body: SafeArea(
        child: !_started ? _buildStart() : _buildGame(),
      ),
    );
  }

  Widget _buildStart() => Column(children: [
    Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0E17),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16)),
        ),
        const SizedBox(width: 14),
        Text('Number Tap Challenge',
          style: GoogleFonts.inter(fontSize: 18,
            fontWeight: FontWeight.w800, color: Colors.white)),
        const Spacer(),
      ]),
    ),

    Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _modeColor.withOpacity(0.15),
                _modeColor2.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _modeColor.withOpacity(0.3))),
            child: Column(children: [
              Text(_modes[_modeIdx]['emoji'] as String,
                style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Number Tap',
                style: GoogleFonts.inter(fontSize: 24,
                  fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Tap as fast as possible',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13,
                  color: Colors.white.withOpacity(0.6), height: 1.6)),
            ]),
          ),
          const SizedBox(height: 20),

          Text('Select Mode',
            style: GoogleFonts.inter(fontSize: 14,
              fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),

          Row(children: List.generate(_modes.length, (i) {
            final m   = _modes[i];
            final sel = _modeIdx == i;
            final c   = Color(m['color'] as int);
            final best = _personalBests[m['label'] as String] ?? 0;
            return Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _modeIdx = i); _generateGrid(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: i < _modes.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: sel ? c.withOpacity(0.15) : const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? c : Colors.white.withOpacity(0.06),
                      width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(
                      color: c.withOpacity(0.25),
                      blurRadius: 16, offset: const Offset(0, 4))] : []),
                  child: Column(children: [
                    Text(m['emoji'] as String,
                      style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(m['label'] as String,
                      style: GoogleFonts.inter(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? c : Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 2),
                    Text('${m['grid']}×${m['grid']}',
                      style: GoogleFonts.inter(fontSize: 10,
                        color: Colors.white.withOpacity(0.3))),
                    if (best > 0) ...[
                      const SizedBox(height: 4),
                      Text('Best: ${_fmtTime(best)}',
                        style: GoogleFonts.inter(fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFD700))),
                    ],
                  ]),
                ),
              ),
            );
          })),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: _modeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
                shadowColor: _modeColor.withOpacity(0.5), elevation: 8),
              child: Text('Start',
                style: GoogleFonts.inter(fontSize: 18,
                  fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ]),
      ),
    ),
  ]);

  Widget _howRow(String em, String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(em, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Text(txt, style: GoogleFonts.inter(fontSize: 13,
        color: Colors.white.withOpacity(0.5))),
    ]),
  );

  Widget _buildGame() {
    final progress  = (_next - 1) / _totalCount;
    final timerStr  = _fmtTime(_elapsed);
    final best      = _personalBests[_modeLabel] ?? 0;

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          border: Border(bottom: BorderSide(
            color: Colors.white.withOpacity(0.04)))),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_next - 1}/$_totalCount',
              style: GoogleFonts.inter(fontSize: 22,
                fontWeight: FontWeight.w900, color: Colors.white)),
            Text('TAPPED',
              style: GoogleFonts.inter(fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.35), letterSpacing: 0.6)),
          ]),
          const Spacer(),
          Column(children: [
            Text(timerStr,
              style: GoogleFonts.inter(fontSize: 28,
                fontWeight: FontWeight.w900, color: _modeColor)),
            if (best > 0)
              Text('Best: ${_fmtTime(best)}',
                style: GoogleFonts.inter(fontSize: 9,
                  color: const Color(0xFFFFD700))),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$_next',
              style: GoogleFonts.inter(fontSize: 22,
                fontWeight: FontWeight.w900, color: _modeColor)),
            Text('NEXT',
              style: GoogleFonts.inter(fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.35), letterSpacing: 0.6)),
          ]),
        ]),
      ),

      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 5,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFF1C1C2E),
          valueColor: AlwaysStoppedAnimation(_modeColor),
          minHeight: 5),
      ),

      if (_errors > 0)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: const Color(0xFFE8345A).withOpacity(0.1),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('❌ $_errors error${_errors > 1 ? 's' : ''}',
              style: GoogleFonts.inter(fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE8345A))),
          ]),
        ),

      const SizedBox(height: 12),

      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedBuilder(
            animation: _errorAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                _errorAnim.value * (_errorCtrl.value > 0.5 ? -1 : 1), 0),
              child: child),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: _totalCount,
              itemBuilder: (_, i) {
                final num       = _grid[i];
                final isCorrect = num == _correctTapped;
                final isWrong   = num == _wrongTapped;
                final isPassed  = num < _next;

                Color bg; Color textColor;
                if (isCorrect) {
                  bg = _modeColor; textColor = Colors.white;
                } else if (isWrong) {
                  bg = const Color(0xFFE8345A); textColor = Colors.white;
                } else if (isPassed) {
                  bg = _modeColor.withOpacity(0.08);
                  textColor = _modeColor.withOpacity(0.3);
                } else {
                  bg = const Color(0xFF1C1C2E); textColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () => _tap(num),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05), width: 1)),
                    child: Center(
                      child: Text('$num',
                        style: GoogleFonts.inter(
                          fontSize: _gridSize <= 5 ? 18 : 15,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }
}
