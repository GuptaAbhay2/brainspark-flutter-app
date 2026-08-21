import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/user_provider.dart';
import 'api_service.dart';

class ScoreService {
  static Future<void> submitAndUpdate({
    required WidgetRef ref,
    required int score,
    int hintsUsed = 0,
    bool completed = true,
    int puzzleId = 1,
  }) async {
    if (score <= 0) return;

    // 1. Local state (Riverpod) + Hive local box update karo
    ref.read(userProvider.notifier).addScore(score);

    // 2. Fetch User ID with Hive Fallback
    final box = Hive.box('userBox');
    final userId = ref.read(userProvider).userId ?? box.get('userId');

    // 3. Sync score with Backend DB
    if (userId != null) {
      try {
        final res = await ApiService.submitScore(
          userId: userId,
          puzzleId: puzzleId,
          score: score,
          timeTaken: 0,
          hintsUsed: hintsUsed,
          completed: completed,
        );

        final updatedScore = res['brain_score'] ?? res['user']?['brain_score'];
        final updatedStreak = res['current_streak'] ?? res['user']?['current_streak'];

        if (updatedScore != null || updatedStreak != null) {
          ref.read(userProvider.notifier).syncFromBackend(
            (updatedScore as int?) ?? ref.read(userProvider).brainScore,
            (updatedStreak as int?) ?? ref.read(userProvider).currentStreak,
          );
        }
      } catch (_) {}
    }
  }

  static bool canAffordHint(WidgetRef ref) =>
      ref.read(userProvider).brainScore >= 10;

  static void deductHintPoints(WidgetRef ref) =>
      ref.read(userProvider.notifier).deductPoints(10);
}