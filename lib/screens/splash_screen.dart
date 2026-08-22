import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedInLocal = prefs.getBool('is_logged_in') ?? false;

      final user = ref.read(userProvider);
      final bool isLoggedIn = isLoggedInLocal || user.isLoggedIn;

      if (mounted) {
        context.go(isLoggedIn ? '/home' : '/login');
      }
    } catch (e) {
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
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1E293B),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}