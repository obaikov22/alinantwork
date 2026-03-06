import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signIn(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      // GoRouter redirect handles navigation on success
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = switch (e.code) {
            'user-not-found' || 'wrong-password' || 'invalid-credential' =>
              'Invalid email or password.',
            'user-disabled' => 'This account has been disabled.',
            'network-request-failed' => 'No internet connection.',
            _ => 'Error: ${e.code}',
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unexpected error: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background image ──────────────────────────────────
          Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Dark gradient overlay: transparent top → #0b0c18 bottom ───────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.65],
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),

          // ── Form content pushed to bottom ─────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    0,
                    32,
                    bottomInset > 0 ? bottomInset + 24 : 48,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.gradient.createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'Alina',
                              style: GoogleFonts.sora(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'NTWork',
                            style: GoogleFonts.sora(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Team Leave Tracker',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email field
                      _InputField(
                        controller: _emailCtrl,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      _InputField(
                        controller: _passCtrl,
                        hint: 'Password',
                        obscure: true,
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 24),

                      // Sign In button
                      GestureDetector(
                        onTap: _loading ? null : _signIn,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _loading ? null : AppColors.gradient,
                            color: _loading ? AppColors.surface2 : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      // Error message
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AppColors.sickLeave,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0fffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18ffffff)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction:
            obscure ? TextInputAction.done : TextInputAction.next,
        onSubmitted: onSubmitted,
        style: GoogleFonts.sora(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(
            fontSize: 14,
            color: const Color(0x55ffffff),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
