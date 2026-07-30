import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'number_tap_levels_screen.dart';

Map<String, dynamic> numberTapLevelConfig(int level) {
  int gridSize;
  if (level <= 5)       gridSize = 9;
  else if (level <= 10) gridSize = 12;
  else if (level <= 20) gridSize = 16;
  else                  gridSize = 20;

  int timer;
  if (level <= 5)       timer = 30;
  else if (level <= 10) timer = 25;
  else if (level <= 20) timer = 20;
  else                  timer = 15;

  int maxNumber;
  if (level <= 5)       maxNumber = 9;
  else if (level <= 10) maxNumber = 15;
  else if (level <= 20) maxNumber = 25;
  else                  maxNumber = 50;

  int pts;
  if (level <= 5)       pts = 10;
  else if (level <= 10) pts = 15;
  else if (level <= 20) pts = 20;
  else                  pts = 30;

  int targetScore;
  if (level <= 5)       targetScore = 50;
  else if (level <= 10) targetScore = 80;
  else if (level <= 20) targetScore = 120;
  else                  targetScore = 150;

  String icon; Color color; Color color2;
  if (level <= 5)       { icon = '🎯'; color = const Color(0xFF38EF7D); color2 = const Color(0xFF11998E); }
  else if (level <= 10) { icon = '⚡'; color = const Color(0xFF3B82F6); color2 = const Color(0xFF6C63FF); }
  else if (level <= 15) { icon = '🔥'; color = const Color(0xFFF7971E); color2 = const Color(0xFFFF6B35); }
  else if (level <= 20) { icon = '💎'; color = const Color(0xFFA78BFA); color2 = const Color(0xFF6C63FF); }
  else if (level <= 25) { icon = '🌀'; color = const Color(0xFFE8345A); color2 = const Color(0xFFFF6B6B); }
  else                  { icon = '👑'; color = const Color(0xFFFFD700); color2 = const Color(0xFFF7971E); }

  int crossAxisCount = gridSize <= 9 ? 3 : gridSize <= 12 ? 3 : 4;

  return {
    'gridSize': gridSize, 'timer': timer, 'maxNumber': maxNumber,
    'pts': pts, 'targetScore': targetScore, 'icon': icon,
    'color': color, 'color2': color2, 'crossAxisCount': crossAxisCount,
  };
}

class NumberTapGameScreen extends StatefulWidget {
  final int level;
  const NumberTapGameScreen({super.key, required this.level});
  @override State<NumberTapGameScreen> createState() => _NTGameState();
}

class _NTGameState extends State<NumberTapGameScreen> with TickerProviderStateMixin {
  final _rng = Random();
  late Map<String, dynamic> _config;
  List<int> _numbers = [];
  int _target = 0;
  int _score = 0;
  int _timer = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _finished = false;
  Timer? _tick;
  bool _showWrong = false;
  bool _showCorrect = false;

  // Combo
  int _combo = 0;
  int _maxCombo = 0;
  bool _showCombo = false;

  late AnimationController _celebCtrl;
  late AnimationController _comboCtrl;
  late AnimationController _wrongCtrl;
  late Animation<double> _celebAnim;
  late Animation<double> _comboAnim;
  late Animation<double> _wrongAnim;

  @override
  void initState() {
    super.initState();
    _config = numberTapLevelConfig(widget.level);
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _wrongCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _celebAnim = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_celebCtrl);
    _comboAnim = Tween<double>(begin: 0.5, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut)).animate(_comboCtrl);
    _wrongAnim = Tween<double>(begin: 0.0, end: 8.0)
        .chain(CurveTween(curve: Curves.elasticIn)).animate(_wrongCtrl);
    _startGame();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _celebCtrl.dispose(); _comboCtrl.dispose(); _wrongCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0; _correct = 0; _wrong = 0;
      _combo = 0; _maxCombo = 0;
      _timer = _config['timer'] as int;
      _finished = false;
    });
    _newRound();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timer <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _finished = true);
        _showResult();
      } else {
        setState(() => _timer--);
        if (_timer <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _newRound() {
    final maxN = _config['maxNumber'] as int;
    final gridSize = _config['gridSize'] as int;
    final nums = List.generate(gridSize, (_) => _rng.nextInt(maxN) + 1);
    final target = nums[_rng.nextInt(gridSize)];
    setState(() { _numbers = nums; _target = target; });
  }

  void _tap(int n) {
    if (_finished) return;
    if (n == _target) {
      HapticFeedback.lightImpact();
      final pts = _config['pts'] as int;
      setState(() {
        _score += pts; _correct++; _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        _showCorrect = true;
      });
      if (_combo >= 3) {
        setState(() => _showCombo = true);
        _comboCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _showCombo = false);
        });
      }
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showCorrect = false);
      });
      _newRound();
    } else {
      HapticFeedback.mediumImpact();
      _wrongCtrl.forward(from: 0);
      setState(() { _wrong++; _combo = 0; _showWrong = true; });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showWrong = false);
      });
    }
  }

  int _calcStars() {
    final target = _config['targetScore'] as int;
    if (_score >= target * 1.5) return 3;
    if (_score >= target) return 2;
    if (_score >= target * 0.6) return 1;
    return 0;
  }

  bool _isPassed() => _score >= (_config['targetScore'] as int) * 0.6;

  void _unlockNext() {
    final box = Hive.box('userBox');
    final current = box.get('numbertap_unlocked', defaultValue: 1) as int;
    final stars = _calcStars();
    box.put('numbertap_${widget.level}_stars', stars);
    if (_isPassed() && widget.level >= current) {
      box.put('numbertap_unlocked', widget.level + 1);
    }
  }

  void _showResult() {
    _unlockNext();
    final passed = _isPassed();
    if (passed) _celebCtrl.forward(from: 0);
    final stars = _calcStars();
    final color = _config['color'] as Color;
    final target = _config['targetScore'] as int;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.88),
      builder: (_) => ScaleTransition(
        scale: passed ? _celebAnim : const AlwaysStoppedAnimation(1.0),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: passed ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
              boxShadow: [BoxShadow(
                color: (passed ? color : Colors.white).withOpacity(0.15), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: passed ? [color, (color).withOpacity(0.7)]
                      : [const Color(0xFF2C2C3E), const Color(0xFF1C1C2E)]),
                  shape: BoxShape.circle,
                  boxShadow: passed ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 24)] : [],
                ),
                child: Center(child: Text(
                  passed ? (_score >= target * 1.5 ? '🏆' : '🎯') : '⏱',
                  style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 16),
              Text(passed ? 'Level ${widget.level} Complete!' : "Time's Up!",
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text(passed ? 'Next level unlocked! 🔓'
                : 'Need ${target} pts to pass — you got $_score',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.45))),
              const SizedBox(height: 20),
              if (passed) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(i < stars ? '⭐' : '☆',
                    style: TextStyle(fontSize: 32,
                      color: i < stars ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.15))),
                )),
              ),
              if (passed) const SizedBox(height: 20),
              Row(children: [
                _dStat('⭐', '$_score', 'SCORE'),
                const SizedBox(width: 8),
                _dStat('✅', '$_correct', 'CORRECT'),
                const SizedBox(width: 8),
                _dStat('🔥', '$_maxCombo', 'COMBO'),
              ]),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (passed ? color : const Color(0xFFF7971E)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (passed ? color : const Color(0xFFF7971E)).withOpacity(0.3))),
                child: Text(
                  passed
                    ? stars == 3 ? '🔥 Insane reflexes! Legendary!'
                      : stars == 2 ? '💪 Great speed! Keep it up!'
                      : '✅ Level cleared! Go faster next time!'
                    : '💡 Tap faster! You almost had it!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                    color: passed ? color : const Color(0xFFF7971E))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _startGame(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('Try Again 🔄',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
                        builder: (_) => NumberTapGameScreen(level: widget.level + 1)));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('Next Level →',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: Text('Back to Levels',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.35))),
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
      decoration: BoxDecoration(color: const Color(0xFF0F0E17), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(em, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(lbl, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.35))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final color    = _config['color'] as Color;
    final maxTime  = _config['timer'] as int;
    final target   = _config['targetScore'] as int;
    final crossCnt = _config['crossAxisCount'] as int;
    final timerColor = _timer <= 5 ? const Color(0xFFE8345A)
        : _timer <= 10 ? const Color(0xFFF7971E) : color;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04)))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3))),
                  child: Text('LVL ${widget.level}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                ),
                const Spacer(),
                Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 56, height: 56,
                    child: CircularProgressIndicator(
                      value: _timer / maxTime, strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(timerColor)),
                  ),
                  Text('$_timer', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w900, color: timerColor)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$_score',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('/$target pts', style: GoogleFonts.inter(fontSize: 9,
                    color: Colors.white.withOpacity(0.35))),
                ]),
              ]),
            ),

            // Score progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_score / target).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1C1C2E),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 7),
              ),
            ),

            const SizedBox(height: 16),

            // Target display
            AnimatedBuilder(
              animation: _wrongAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_wrongAnim.value * (_wrongCtrl.value > 0.5 ? -1 : 1), 0),
                child: child),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showWrong
                      ? [const Color(0xFFE8345A), const Color(0xFFFF6B6B)]
                      : _showCorrect
                        ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                        : [color.withOpacity(0.15), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showWrong ? const Color(0xFFE8345A).withOpacity(0.5)
                      : _showCorrect ? const Color(0xFF38EF7D).withOpacity(0.5)
                      : color.withOpacity(0.3))),
                child: Column(children: [
                  Text('TAP THIS NUMBER',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('$_target',
                    style: GoogleFonts.inter(fontSize: 52, fontWeight: FontWeight.w900,
                      color: _showWrong ? Colors.white : _showCorrect ? Colors.white : color)),
                  if (_combo >= 3)
                    Text('🔥 ${_combo}x combo',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD700))),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Number grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCnt,
                    mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: _numbers.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _tap(_numbers[i]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06))),
                      child: Center(
                        child: Text('${_numbers[i]}',
                          style: GoogleFonts.inter(fontSize: 26,
                            fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]),

          // Combo popup
          if (_showCombo)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: ScaleTransition(
                    scale: _comboAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF7971E)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 24)]),
                      child: Text('🔥 ${_combo}x COMBO!',
                        style: GoogleFonts.inter(fontSize: 22,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
