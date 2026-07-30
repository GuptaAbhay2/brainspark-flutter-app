import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'https://brainspark-backend-production-22d9.up.railway.app/api';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static Future<Map<String, dynamic>> registerUser(
      String username, String password) async {
    try {
      final res = await _dio.post('/users/register/',
          data: {'username': username, 'password': password});
      return res.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final msg = data['error'] ?? data['detail'] ?? 'Registration failed!';
          return {'error': msg.toString()};
        }
      }
      return {'error': 'Network error! Check your internet connection.'};
    } catch (e) {
      return {'error': 'An unexpected error occurred.'};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String username, String password) async {
    try {
      final res = await _dio.post('/users/login/',
          data: {'username': username, 'password': password});
      return res.data;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        // Backend se aaye hue specific message ko check karo
        if (data is Map<String, dynamic>) {
          if (data.containsKey('error')) return {'error': data['error'].toString()};
          if (data.containsKey('detail')) return {'error': data['detail'].toString()};
        }

        // Standard Status Codes Handling
        if (statusCode == 404) {
          return {'error': 'User not registered!'};
        } else if (statusCode == 400 || statusCode == 401) {
          return {'error': 'Invalid username or password!'};
        }
      }
      return {'error': 'Network error! Check your internet connection.'};
    } catch (e) {
      return {'error': 'An unexpected error occurred.'};
    }
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final res = await _dio.get('/users/profile/$userId/');
    return res.data;
  }

  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    final username = email.replaceAll('@brainspark.app', '');
    final res = await _dio.get('/users/by-email/',
        queryParameters: {'email': email, 'username': username});
    return res.data;
  }

  static Future<Map<String, dynamic>> getPuzzle(
      String type, String difficulty) async {
    final res = await _dio.get('/puzzles/',
        queryParameters: {'type': type, 'difficulty': difficulty});
    return res.data;
  }

  static Future<Map<String, dynamic>> verifySolution(
      int puzzleId, dynamic answer) async {
    final res = await _dio.post('/puzzles/verify/',
        data: {'puzzle_id': puzzleId, 'answer': answer});
    return res.data;
  }

  static Future<Map<String, dynamic>> submitScore({
    required int userId,
    required int puzzleId,
    required int score,
    required int timeTaken,
    required int hintsUsed,
    required bool completed,
  }) async {
    final res = await _dio.post('/sessions/submit/', data: {
      'user_id':    userId,
      'puzzle_id':  puzzleId,
      'score':      score,
      'time_taken': timeTaken,
      'hints_used': hintsUsed,
      'completed':  completed,
    });
    return res.data;
  }

  static Future<List<dynamic>> getGlobalLeaderboard() async {
    final res = await _dio.get('/leaderboard/global/');
    return res.data;
  }

  static Future<List<dynamic>> getWeeklyLeaderboard() async {
    final res = await _dio.get('/leaderboard/weekly/');
    return res.data;
  }

  static Future<Map<String, dynamic>> getUserRank(int userId) async {
    final res = await _dio.get('/leaderboard/rank/$userId/');
    return res.data;
  }

  static Future<Map<String, dynamic>> getDailyChallenge() async {
    final res = await _dio.get('/daily/');
    return res.data;
  }

  static Future<String> getHint(int puzzleId, String userAnswer) async {
    final res = await _dio.post('/hints/',
        data: {'puzzle_id': puzzleId, 'user_answer': userAnswer});
    return res.data['hint'] ?? 'Think carefully about the pattern!';
  }
}