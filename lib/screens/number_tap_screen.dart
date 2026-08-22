import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ============================================================================
// 1. MAIN START / HOME SCREEN
// ============================================================================
class NumberTapScreen extends StatefulWidget {
  const NumberTapScreen({super.key});

  @override
  State<NumberTapScreen> createState() => _NumberTapScreenState();
}

class _NumberTapScreenState extends State<NumberTapScreen> {
  late Box _box;
  int _unlockedUpTo = 1;
  int _totalStars = 0;
  int _selectedMode = 0; // 0: Classic, 1: Speed, 2: Chaos

  final List<Map<String, dynamic>> _modes = [
    {
      'title': 'Classic',
      'grid': '5×5',
      'desc': 'Target number tap challenge',
      'color': const Color(0xFF10B981),
      'color2': const Color(0xFF059669),
    },
    {
      'title': 'Speed',
      'grid': '5×5',
      'desc': 'Fast reaction timer',
      'color': const Color(0xFF3B82F6),
      'color2': const Color(0xFF1D4ED8),
    },
    {
      'title': 'Chaos',
      'grid': '6×6',
      'desc': 'High density numbers',
      'color': const Color(0xFFA855F7),
      'color2': const Color(0xFF7E22CE),
    },
  ];

  @override
  void initState() {
    super.initState();
    _box = Hive.box('userBox');
    _loadData();
  }

  void _loadData() {
    setState(() {
      _unlockedUpTo = _box.get('numbertap_unlocked', defaultValue: 1);
      int stars = 0;
      for (int i = 1; i <= 30; i++) {
        stars += (_box.get('numbertap_${i}_stars', defaultValue: 0) as int);
      }
      _totalStars = stars;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _modes[_selectedMode]['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF080711),
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP HEADER BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Number Tap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131124),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$_totalStars/90',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- CONTENT BODY ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Banner Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            activeColor.withOpacity(0.18),
                            const Color(0xFF131126),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: activeColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  activeColor,
                                  _modes[_selectedMode]['color2'] as Color,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _modes[_selectedMode]['icon'] as String,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Reaction',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _modes[_selectedMode]['desc'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Tips Chips
                    Text(
                      'QUICK TIPS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _ruleChip('🎯 Tap Target Number', Colors.blue),
                          _ruleChip('⏱️ Speed builds multiplier', Colors.amber),
                          _ruleChip('❌ Wrong tap resets combo', Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Mode Selection
                    Text(
                      'SELECT MODE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: List.generate(_modes.length, (i) {
                        final mode = _modes[i];
                        final isSelected = _selectedMode == i;
                        final color = mode['color'] as Color;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedMode = i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                right: i == _modes.length - 1 ? 0 : 10,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withOpacity(0.12) : const Color(0xFF121022),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? color : Colors.white.withOpacity(0.06),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    mode['icon'] as String,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    mode['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mode['grid'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? color : Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // --- BOTTOM ACTIONS ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0B1A),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NumberTapGameScreen(
                              level: _unlockedUpTo > 30 ? 30 : _unlockedUpTo,
                            ),
                          ),
                        );
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Start Game (Lvl ${_unlockedUpTo > 30 ? 30 : _unlockedUpTo})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NumberTapLevelsScreen()),
                        );
                        _loadData();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Select Level Map 🗺️',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleChip(String label, Color dotColor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131124),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. LEVEL MAP SCREEN
// ============================================================================
class NumberTapLevelsScreen extends StatefulWidget {
  const NumberTapLevelsScreen({super.key});

  @override
  State<NumberTapLevelsScreen> createState() => _NumberTapLevelsScreenState();
}

class _NumberTapLevelsScreenState extends State<NumberTapLevelsScreen> {
  late Box _box;
  int _unlockedUpTo = 1;
  static const int _totalLevels = 30;
  final ScrollController _scrollCtrl = ScrollController();

  static Map<String, dynamic> levelConfig(int level) {
    int gridSize = level <= 5 ? 9 : level <= 10 ? 12 : level <= 20 ? 16 : 20;
    int timer = level <= 5 ? 30 : level <= 10 ? 25 : level <= 20 ? 20 : 15;
    int maxNumber = level <= 5 ? 9 : level <= 10 ? 15 : level <= 20 ? 25 : 50;
    int pts = level <= 5 ? 10 : level <= 10 ? 15 : level <= 20 ? 20 : 30;
    int targetScore = level <= 5 ? 50 : level <= 10 ? 80 : level <= 20 ? 120 : 150;

    String icon; Color color; Color color2;
    if (level <= 5)       { icon = '🎯'; color = const Color(0xFF10B981); color2 = const Color(0xFF059669); }
    else if (level <= 10) { icon = '⚡'; color = const Color(0xFF3B82F6); color2 = const Color(0xFF1D4ED8); }
    else if (level <= 15) { icon = '🔥'; color = const Color(0xFFF59E0B); color2 = const Color(0xFFD97706); }
    else if (level <= 20) { icon = '💎'; color = const Color(0xFF8B5CF6); color2 = const Color(0xFF6D28D9); }
    else if (level <= 25) { icon = '🌀'; color = const Color(0xFFEC4899); color2 = const Color(0xFFBE185D); }
    else                  { icon = '👑'; color = const Color(0xFFFACE15); color2 = const Color(0xFFEAB308); }

    int crossAxisCount = (gridSize == 9 || gridSize == 12) ? 3 : 4;

    return {
      'gridSize': gridSize, 'timer': timer, 'maxNumber': maxNumber,
      'pts': pts, 'targetScore': targetScore, 'icon': icon,
      'color': color, 'color2': color2, 'crossAxisCount': crossAxisCount,
    };
  }

  @override
  void initState() {
    super.initState();
    _box = Hive.box('userBox');
    _unlockedUpTo = _box.get('numbertap_unlocked', defaultValue: 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final targetOffset = ((_totalLevels - _unlockedUpTo) * 110.0) - 200;
        _scrollCtrl.animateTo(
          max(0, targetOffset),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _refresh() {
    setState(() {
      _unlockedUpTo = _box.get('numbertap_unlocked', defaultValue: 1);
    });
  }

  double _xOffsetFor(int idx) {
    final pattern = [0.0, 70.0, -70.0, 0.0, -60.0, 60.0];
    return pattern[idx % pattern.length];
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0914),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF131124),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level Map',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _unlockedUpTo / _totalLevels,
                                  backgroundColor: Colors.white.withOpacity(0.08),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$_unlockedUpTo/$_totalLevels',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _BackgroundStarPainter())),
                  SingleChildScrollView(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.only(top: 40, bottom: 90),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          CustomPaint(
                            size: Size(double.infinity, _totalLevels * 110.0),
                            painter: _LevelPathPainter(
                              totalLevels: _totalLevels,
                              unlockedUpTo: _unlockedUpTo,
                              xOffsetFor: _xOffsetFor,
                            ),
                          ),
                          Column(
                            children: List.generate(_totalLevels, (i) {
                              final level = _totalLevels - i;
                              final levelFromBottom = level - 1;
                              final xOffset = _xOffsetFor(levelFromBottom);
                              final config = levelConfig(level);
                              final unlocked = level <= _unlockedUpTo;
                              final isCurrent = level == _unlockedUpTo;
                              final completed = level < _unlockedUpTo;
                              final stars = _box.get('numbertap_${level}_stars', defaultValue: 0) as int;

                              return SizedBox(
                                height: 110,
                                child: Center(
                                  child: Transform.translate(
                                    offset: Offset(xOffset, 0),
                                    child: GestureDetector(
                                      onTap: unlocked
                                          ? () async {
                                              HapticFeedback.lightImpact();
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => NumberTapGameScreen(level: level),
                                                ),
                                              );
                                              _refresh();
                                            }
                                          : () {
                                              HapticFeedback.mediumImpact();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '🔒 Complete Level ${level - 1} to unlock!',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: const Color(0xFF1E1B4B),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                              );
                                            },
                                      child: _LevelNodeItem(
                                        level: level,
                                        icon: config['icon'] as String,
                                        color: config['color'] as Color,
                                        color2: config['color2'] as Color,
                                        unlocked: unlocked,
                                        isCurrent: isCurrent,
                                        completed: completed,
                                        stars: stars,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. GAMEPLAY SCREEN
// ============================================================================
class NumberTapGameScreen extends StatefulWidget {
  final int level;
  const NumberTapGameScreen({super.key, required this.level});

  @override
  State<NumberTapGameScreen> createState() => _NumberTapGameScreenState();
}

class _NumberTapGameScreenState extends State<NumberTapGameScreen> with TickerProviderStateMixin {
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
    _config = _NumberTapLevelsScreenState.levelConfig(widget.level);
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
    _celebCtrl.dispose();
    _comboCtrl.dispose();
    _wrongCtrl.dispose();
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
              color: const Color(0xFF131124),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: passed ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: passed
                          ? [color, color.withOpacity(0.7)]
                          : [const Color(0xFF23203F), const Color(0xFF131124)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      passed ? '🏆' : '⏱️',
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  passed ? 'Level ${widget.level} Cleared!' : "Time's Up!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (passed)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 32,
                          color: i < stars ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Play Again 🔄',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                    'Back to Menu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
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

  @override
  Widget build(BuildContext context) {
    final color = _config['color'] as Color;
    final maxTime = _config['timer'] as int;
    final target = _config['targetScore'] as int;
    final crossCnt = _config['crossAxisCount'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0914),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131124),
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'LVL ${widget.level}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '⏱️ $_timer s',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_score/$target',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Target Display
                AnimatedBuilder(
                  animation: _wrongAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_wrongAnim.value * (_wrongCtrl.value > 0.5 ? -1 : 1), 0),
                    child: child,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _showWrong
                          ? const Color(0xFFEF4444)
                          : _showCorrect
                              ? const Color(0xFF10B981)
                              : color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TAP THIS NUMBER',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_target',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCnt,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: _numbers.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _tap(_numbers[i]),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF181629),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Center(
                            child: Text(
                              '${_numbers[i]}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. HELPER COMPONENTS & PAINTERS
// ============================================================================
class _LevelNodeItem extends StatelessWidget {
  final int level;
  final String icon;
  final Color color, color2;
  final bool unlocked, isCurrent, completed;
  final int stars;

  const _LevelNodeItem({
    required this.level,
    required this.icon,
    required this.color,
    required this.color2,
    required this.unlocked,
    required this.isCurrent,
    required this.completed,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCurrent ? 68.0 : 56.0,
          height: isCurrent ? 68.0 : 56.0,
          decoration: BoxDecoration(
            gradient: unlocked ? LinearGradient(colors: [color, color2]) : null,
            color: unlocked ? null : const Color(0xFF181629),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? Colors.white : Colors.white.withOpacity(0.15),
              width: isCurrent ? 3 : 2,
            ),
          ),
          child: Center(
            child: unlocked
                ? Text(icon, style: TextStyle(fontSize: isCurrent ? 26 : 20))
                : Icon(Icons.lock_rounded, size: 18, color: Colors.white.withOpacity(0.2)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lvl $level',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: unlocked ? color : Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

class _LevelPathPainter extends CustomPainter {
  final int totalLevels, unlockedUpTo;
  final double Function(int) xOffsetFor;

  _LevelPathPainter({
    required this.totalLevels,
    required this.unlockedUpTo,
    required this.xOffsetFor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const rowH = 110.0;

    for (int i = 0; i < totalLevels - 1; i++) {
      final level = i + 1;
      final r1 = totalLevels - 1 - i;
      final r2 = totalLevels - 2 - i;
      final y1 = r1 * rowH + rowH / 2;
      final y2 = r2 * rowH + rowH / 2;
      final x1 = cx + xOffsetFor(i);
      final x2 = cx + xOffsetFor(i + 1);

      final unlocked = level < unlockedUpTo;

      final paint = Paint()
        ..color = unlocked ? const Color(0xFF6366F1).withOpacity(0.6) : Colors.white.withOpacity(0.06)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(x1, y1);
      final midY = (y1 + y2) / 2;
      path.quadraticBezierTo(x1, midY, (x1 + x2) / 2, midY);
      path.quadraticBezierTo(x2, midY, x2, y2);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelPathPainter old) => old.unlockedUpTo != unlockedUpTo;
}

class _BackgroundStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
        rand.nextDouble() * 1.5 + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}