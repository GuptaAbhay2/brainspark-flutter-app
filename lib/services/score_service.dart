import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // addScore updates streak + points + games
    ref.read(userProvider.notifier).addScore(score);

    // Try backend sync
    try {
      final user = ref.read(userProvider);
      if (user.userId != null) {
        final res = await ApiService.submitScore(
          userId: user.userId!,
          puzzleId: puzzleId,
          score: score,
          timeTaken: 0,
          hintsUsed: hintsUsed,
          completed: completed,
        );
        ref.read(userProvider.notifier).syncFromBackend(
          res['brain_score']    ?? user.brainScore,
          res['current_streak'] ?? user.currentStreak,
        );
      }
    } catch (_) {}
  }

  static bool canAffordHint(WidgetRef ref) =>
      ref.read(userProvider).brainScore >= 10;

  static void deductHintPoints(WidgetRef ref) =>
      ref.read(userProvider.notifier).deductPoints(10);
}
