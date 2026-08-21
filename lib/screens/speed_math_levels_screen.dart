import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'speed_math_game_screen.dart';

class SpeedMathLevelsScreen extends StatelessWidget {
  const SpeedMathLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('userBox');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Speed Math Levels',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box userBox, _) {
          final unlockedLevel = userBox.get('speedmath_unlocked', defaultValue: 1) as int;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final levelNumber = index + 1;
              final isUnlocked = levelNumber <= unlockedLevel;
              final stars = userBox.get('speedmath_level_${levelNumber}_stars', defaultValue: 0) as int;

              return _LevelCard(
                levelNumber: levelNumber,
                isUnlocked: isUnlocked,
                stars: stars,
                onTap: () {
                  if (isUnlocked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpeedMathGameScreen(levelNumber: levelNumber),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Level ${levelNumber - 1} complete karo pehle!',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: const Color(0xFF2D2B55),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int levelNumber;
  final bool isUnlocked;
  final int stars;
  final VoidCallback onTap;

  const _LevelCard({
    required this.levelNumber,
    required this.isUnlocked,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF1C1C2E) : const Color(0xFF141424),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? const Color(0xFF6C5CE7).withOpacity(0.6) : Colors.white10,
            width: 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked) ...[
              const Icon(Icons.lock_rounded, color: Colors.white24, size: 26),
              const SizedBox(height: 6),
              Text(
                'Lvl $levelNumber',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white24,
                ),
              ),
            ] else ...[
              Text(
                'Lvl $levelNumber',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (starIndex) {
                  final isEarned = starIndex < stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 18,
                      color: isEarned ? const Color(0xFFFFD15C) : Colors.white24,
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}