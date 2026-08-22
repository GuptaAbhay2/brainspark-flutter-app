import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isLogin = true;
  bool _showPassword = false;
  String? _errorMsg;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final error =
          await ref.read(userProvider.notifier).loginWithPassword(
                _usernameCtrl.text.trim(),
                _passwordCtrl.text.trim(),
                isRegister: !_isLogin,
              );

      if (mounted) {
        if (error == null) {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setBool('is_logged_in', true);
          await prefs.setString(
            'username',
            _usernameCtrl.text.trim(),
          );

          if (mounted) {
            context.go('/home');
          }
        } else {
          setState(() {
            _errorMsg = error;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = "ACTUAL ERROR: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF090D16);
    const cardColor = Color(0xFF111827);
    const inputFillColor = Color(0xFF0F172A);

    const accentGradient = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Header Widget Part
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: accentGradient,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.psychology_rounded,
                                    size: 38,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Brain',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Spark',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFA78BFA),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Train · Compete · Win',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Main Auth Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Control Switcher
                        Container(
                          height: 46,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: inputFillColor,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (!_isLogin) {
                                      setState(() {
                                        _isLogin = true;
                                        _errorMsg = null;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLogin
                                          ? cardColor
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: _isLogin
                                          ? Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.1),
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: _isLogin
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: _isLogin
                                            ? Colors.white
                                            : const Color(
                                                0xFF64748B,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_isLogin) {
                                      setState(() {
                                        _isLogin = false;
                                        _errorMsg = null;
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_isLogin
                                          ? cardColor
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: !_isLogin
                                          ? Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.1),
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: !_isLogin
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: !_isLogin
                                            ? Colors.white
                                            : const Color(
                                                0xFF64748B,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          _isLogin
                              ? 'Welcome back'
                              : 'Create an account',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _isLogin
                              ? 'Enter your details to continue your streak'
                              : 'Join BrainSpark to start cognitive training',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Username Field
                        _fieldLabel('Username'),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _usernameCtrl,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: _deco(
                            'Enter username',
                            Icons.person_outline_rounded,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Username is required';
                            }

                            if (v.trim().length < 3) {
                              return 'Min 3 characters required';
                            }

                            if (!RegExp(
                              r'^[a-zA-Z0-9_]+$',
                            ).hasMatch(v.trim())) {
                              return 'Letters, numbers, underscore only';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        _fieldLabel('Password'),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: _deco(
                            'Enter password',
                            Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Password is required';
                            }

                            if (v.trim().length < 4) {
                              return 'Min 4 characters required';
                            }

                            return null;
                          },
                        ),

                        // Error Banner
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEF4444)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    _errorMsg!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color:
                                          const Color(0xFFFCA5A5),
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // CTA Button
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: accentGradient,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1)
                                    .withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.transparent,
                              shadowColor:
                                  Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin
                                        ? 'Sign In'
                                        : 'Create Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: Colors.white,
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
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
        ),
      );

  InputDecoration _deco(
    String hint,
    IconData icon,
  ) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF475569),
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF8B5CF6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        errorStyle: GoogleFonts.inter(
          color: const Color(0xFFEF4444),
          fontSize: 11,
        ),
      );
}