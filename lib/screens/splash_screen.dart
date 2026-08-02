import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Local check ke liye added
import '../providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    try {
      // 1. Phone memory se check karo ki pehle login ho chuka hai ya nahi
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedInLocal = prefs.getBool('is_logged_in') ?? false;

      // 2. Riverpod User Provider check
      final user = ref.read(userProvider);
      final bool isLoggedIn = isLoggedInLocal || user.isLoggedIn;

      if (mounted) {
        context.go(isLoggedIn ? '/home' : '/login');
      }
    } catch (e) {
      // 3. Agar koi bhi error aaye, toh buffering hone ki bajaye safely /login par bhej do
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF185FA5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: const Text('🧠', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 20),
            const Text('BrainSpark',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('Train Your Brain Daily',
              style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white54)),
          ],
        ),
      ),
    );
  }
}