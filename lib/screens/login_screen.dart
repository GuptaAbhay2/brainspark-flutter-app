import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _loading       = false;
  bool _isLogin       = true;
  bool _showPassword  = false;
  String? _errorMsg;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final error = await ref.read(userProvider.notifier).loginWithPassword(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      isRegister: !_isLogin,
    );

    if (mounted) {
      setState(() { _loading = false; _errorMsg = error; });
      if (error == null) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Column(children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 28, offset: const Offset(0, 10))]),
                      child: const Center(
                        child: Text('🧠', style: TextStyle(fontSize: 48))),
                    ),
                    const SizedBox(height: 20),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'Brain',
                        style: GoogleFonts.inter(fontSize: 32,
                          fontWeight: FontWeight.w800, color: Colors.white)),
                      TextSpan(text: 'Spark',
                        style: GoogleFonts.inter(fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFA78BFA))),
                    ])),
                    const SizedBox(height: 6),
                    Text('Train · Compete · Win',
                      style: GoogleFonts.inter(fontSize: 14,
                        color: Colors.white.withOpacity(0.4))),
                  ]),
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_isLogin ? 'Welcome Back!' : 'Create Account',
                        style: GoogleFonts.inter(fontSize: 22,
                          fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_isLogin
                        ? 'Login to continue your streak!'
                        : 'Join BrainSpark and start playing!',
                        style: GoogleFonts.inter(fontSize: 13,
                          color: Colors.white.withOpacity(0.4))),
                      const SizedBox(height: 24),

                      _fieldLabel('Username'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco('Enter username', '👤'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 3) return 'Min 3 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim()))
                            return 'Letters, numbers, underscore only';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _fieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco('Enter password', '🔒').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.4), size: 20),
                            onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v.trim().length < 4) return 'Min 4 characters';
                          return null;
                        },
                      ),

                      if (_errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8345A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE8345A).withOpacity(0.3))),
                          child: Text(_errorMsg!,
                            style: GoogleFonts.inter(fontSize: 13,
                              color: const Color(0xFFE8345A),
                              fontWeight: FontWeight.w600)),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA78BFA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                          child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : Text(_isLogin ? 'Login 🚀' : 'Create Account 🚀',
                                style: GoogleFonts.inter(fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _errorMsg = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                          style: GoogleFonts.inter(fontSize: 14,
                            color: Colors.white.withOpacity(0.5))),
                        Text(
                          _isLogin ? 'Register' : 'Login',
                          style: GoogleFonts.inter(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA78BFA))),
                      ],
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

  Widget _fieldLabel(String text) => Text(text,
    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.6)));

  InputDecoration _deco(String hint, String prefix) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 14,
      color: Colors.white.withOpacity(0.25)),
    prefixText: '$prefix  ',
    prefixStyle: const TextStyle(fontSize: 16),
    filled: true,
    fillColor: const Color(0xFF0F0E17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 2)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE8345A))),
    errorStyle: const TextStyle(color: Color(0xFFE8345A)),
  );
}
