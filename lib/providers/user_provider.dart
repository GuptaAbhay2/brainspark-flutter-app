import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';

class UserState {
  final int? userId;
  final String username;
  final String email;
  final String avatar;
  final int brainScore;
  final int currentStreak;
  final int longestStreak;
  final int totalGames;
  final bool isLoading;
  final String? error;

  const UserState({
    this.userId,
    this.username = '',
    this.email = '',
    this.avatar = '🧠',
    this.brainScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalGames = 0,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => userId != null;

  UserState copyWith({
    int? userId,
    String? username,
    String? email,
    String? avatar,
    int? brainScore,
    int? currentStreak,
    int? longestStreak,
    int? totalGames,
    bool? isLoading,
    String? error,
  }) =>
      UserState(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        brainScore: brainScore ?? this.brainScore,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalGames: totalGames ?? this.totalGames,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    // 🔑 FIX: Direct Hive se data read karke initial state return karo
    final box = Hive.box('userBox');
    final userId = box.get('userId');

    if (userId != null) {
      return UserState(
        userId: userId,
        username: box.get('username', defaultValue: ''),
        email: box.get('email', defaultValue: ''),
        avatar: box.get('avatar', defaultValue: '🧠'),
        brainScore: box.get('brainScore', defaultValue: 0),
        currentStreak: box.get('currentStreak', defaultValue: 0),
        longestStreak: box.get('longestStreak', defaultValue: 0),
        totalGames: box.get('totalGames', defaultValue: 0),
      );
    }

    return const UserState();
  }

  // === AUTHENTICATION LOGIC ===

  Future<String?> loginWithPassword(String username, String password,
      {bool isRegister = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      Map<String, dynamic> data;

      if (isRegister) {
        data = await ApiService.registerUser(username, password);
      } else {
        data = await ApiService.loginUser(username, password);
      }

      if (data.containsKey('error')) {
        final errorMsg = data['error'] as String;
        state = state.copyWith(isLoading: false, error: errorMsg);
        return errorMsg;
      }

      final box = Hive.box('userBox');
      final localScore = box.get('brainScore', defaultValue: 0) as int;
      final backendScore = (data['brain_score'] ?? 0) as int;
      final finalScore =
          localScore > backendScore ? localScore : backendScore;

      box.put('userId', data['id']);
      box.put('username', data['username'] ?? username);
      box.put('email', data['email'] ?? '');
      box.put('avatar', data['avatar'] ?? '🧠');
      box.put('brainScore', finalScore);
      box.put('currentStreak', data['current_streak'] ?? 0);
      box.put('longestStreak', data['longest_streak'] ?? 0);
      box.put('totalGames', data['total_games'] ?? 0);
      box.put('savedPassword', password);

      state = state.copyWith(
        userId: data['id'],
        username: data['username'] ?? username,
        email: data['email'] ?? '',
        avatar: data['avatar'] ?? '🧠',
        brainScore: finalScore,
        currentStreak: data['current_streak'] ?? 0,
        longestStreak: data['longest_streak'] ?? 0,
        totalGames: data['total_games'] ?? 0,
        isLoading: false,
        error: null,
      );

      return null;
    } catch (e) {
      const netError = 'Network error! Check your internet connection.';
      state = state.copyWith(isLoading: false, error: netError);
      print("API Exception: $e");
      return netError;
    }
  }

  Future<String?> login(String username) async {
    return loginWithPassword(username, 'default123');
  }

  // === SCORE & STREAK MANAGEMENT ===

  void addScore(int points) {
    final box = Hive.box('userBox');
    final newScore = state.brainScore + points;
    final games = state.totalGames + 1;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastPlayed = box.get('lastPlayed', defaultValue: '') as String;
    int newStreak = state.currentStreak;

    if (lastPlayed == '') {
      newStreak = 1;
    } else if (lastPlayed == today) {
      newStreak = state.currentStreak;
    } else {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      newStreak = lastPlayed == yesterday ? state.currentStreak + 1 : 1;
    }

    final longest =
        newStreak > state.longestStreak ? newStreak : state.longestStreak;

    box.put('brainScore', newScore);
    box.put('totalGames', games);
    box.put('currentStreak', newStreak);
    box.put('longestStreak', longest);
    box.put('lastPlayed', today);

    state = state.copyWith(
      brainScore: newScore,
      totalGames: games,
      currentStreak: newStreak,
      longestStreak: longest,
    );
  }

  void deductPoints(int points) {
    final box = Hive.box('userBox');
    final newScore = (state.brainScore - points).clamp(0, 999999);
    box.put('brainScore', newScore);
    state = state.copyWith(brainScore: newScore);
  }

  void updateScore(int newScore, int streak) {
    final box = Hive.box('userBox');
    final useScore = newScore > state.brainScore ? newScore : state.brainScore;
    final longest =
        streak > state.longestStreak ? streak : state.longestStreak;
    box.put('brainScore', useScore);
    box.put('currentStreak', streak);
    box.put('longestStreak', longest);
    state = state.copyWith(
        brainScore: useScore, currentStreak: streak, longestStreak: longest);
  }

  void syncFromBackend(int score, int streak) {
    final box = Hive.box('userBox');
    final useScore = score > state.brainScore ? score : state.brainScore;
    final longest =
        streak > state.longestStreak ? streak : state.longestStreak;
    box.put('brainScore', useScore);
    box.put('currentStreak', streak);
    box.put('longestStreak', longest);
    state = state.copyWith(
        brainScore: useScore, currentStreak: streak, longestStreak: longest);
  }

  void logout() {
    Hive.box('userBox').clear();
    state = const UserState();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);