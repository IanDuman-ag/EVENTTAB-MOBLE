import 'package:flutter/material.dart';

import '../judges/jhome.dart';
import 'judge_auth_service.dart';
import 'auth_service.dart';
import '../viewers/home.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg      = Color(0xFF060A10);
const _kCyan    = Color(0xFF00C5D9);
const _kField   = Color(0xFF0E1520);
const _kBorder  = Color(0xFF1C2A3A);
const _kMuted   = Color(0xFF8B8D91);

/// Single login page for all roles.
/// Backend returns { role: "judge" | "viewer" } — judges go to JudgeHomePage,
/// viewers go to HomePage. "Continue as Guest" skips auth and goes to HomePage.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onLogin});
  final VoidCallback? onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accountCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscurePassword = true;
  bool    _rememberMe      = false;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Login ─────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final identifier = _accountCtrl.text.trim();
    final password   = _passwordCtrl.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email or username and password.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final user = await authService.login(
          identifier: identifier, password: password);

      if (!mounted) return;

      if (user.isJudge) {
        JudgeAuthSession.set(JudgeUser(
          id: user.id,
          username: user.username,
          email: user.email,
          token: user.token,
        ));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/judge/home'),
            builder: (_) => const JudgeHomePage(),
          ),
        );
      } else if (widget.onLogin != null) {
        widget.onLogin!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    AuthSession.clear();
    JudgeAuthSession.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Stadium background ──
          Positioned.fill(child: _StadiumBackground()),
          // ── Scrollable form ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 48),
                              // ── Logo ──
                              const _Logo(),
                              const SizedBox(height: 10),
                              // ── Brand name ──
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                  children: [
                                    TextSpan(text: 'EVENT',
                                        style: TextStyle(color: Colors.white)),
                                    TextSpan(text: 'TAB',
                                        style: TextStyle(color: _kCyan)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'EVENT LEADERBOARD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _kMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 36),
                              // ── Welcome text ──
                              const Text(
                                'Welcome Back!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sign in to continue to your account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _kMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // ── Email / Username ──
                              const _FieldLabel('EMAIL OR USERNAME'),
                              const SizedBox(height: 8),
                              _RoundedField(
                                controller: _accountCtrl,
                                hint: 'Enter your email or username',
                                prefixIcon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              // ── Password ──
                              const _FieldLabel('PASSWORD'),
                              const SizedBox(height: 8),
                              _RoundedField(
                                controller: _passwordCtrl,
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              // ── Error ──
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF5252),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // ── Remember me ──
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 20, height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? _kCyan
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: _rememberMe
                                              ? _kCyan
                                              : const Color(0xFF4A5568),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check,
                                              size: 13,
                                              color: Color(0xFF060A10))
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              // ── LOG IN button ──
                              _LogInButton(
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin),
                              const SizedBox(height: 20),
                              // ── OR divider ──
                              Row(
                                children: [
                                  const Expanded(
                                      child: Divider(
                                          color: Color(0xFF1C2A3A), height: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    child: Text('OR',
                                        style: TextStyle(
                                          color: _kMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        )),
                                  ),
                                  const Expanded(
                                      child: Divider(
                                          color: Color(0xFF1C2A3A), height: 1)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // ── CONTINUE AS GUEST ──
                              _GuestButton(onPressed: _continueAsGuest),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stadium background ───────────────────────────────────

class _StadiumBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark base
        Container(color: _kBg),
        // Radial glow top-left (stadium lights)
        Positioned(
          top: -60, left: -40,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A4A6E).withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Radial glow top-right
        Positioned(
          top: -40, right: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0D3A5C).withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Subtle grid lines (stadium feel)
        Positioned.fill(
          child: CustomPaint(painter: _GridPainter()),
        ),
        // Bottom fade to solid dark
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _kBg.withValues(alpha: 0.95),
                  _kBg,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D2035).withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    // Horizontal lines (top half only)
    for (double y = 0; y < size.height * 0.55; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines (top half only)
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.55), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Logo ─────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 100, height: 100,
        child: CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Outer glow
    canvas.drawCircle(center, r,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF13C8FF).withValues(alpha: 0.35),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: center, radius: r)));

    // Ring
    canvas.drawCircle(center, r * 0.74,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..shader = SweepGradient(colors: const [
            Color(0xFF1176FF), Color(0xFF7EF0FF),
            Color(0xFF112B76), Color(0xFF1176FF),
          ]).createShader(Rect.fromCircle(center: center, radius: r * 0.74)));

    // Inner fill
    canvas.drawCircle(center, r * 0.64,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF06336B), Color(0xFF0B0B0D), Color(0xFF041E45)],
          ).createShader(Rect.fromCircle(center: center, radius: r * 0.64)));

    // Wing shape
    final wing = Paint()
      ..shader = const LinearGradient(
              colors: [Color(0xFF00D9FF), Color(0xFF0A53CC)])
          .createShader(Rect.fromLTWH(
              size.width * 0.15, size.height * 0.35,
              size.width * 0.45, size.height * 0.35));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.27, size.height * 0.38)
        ..lineTo(size.width * 0.60, size.height * 0.38)
        ..lineTo(size.width * 0.52, size.height * 0.47)
        ..lineTo(size.width * 0.29, size.height * 0.47)
        ..lineTo(size.width * 0.22, size.height * 0.58)
        ..lineTo(size.width * 0.55, size.height * 0.58)
        ..lineTo(size.width * 0.47, size.height * 0.68)
        ..lineTo(size.width * 0.18, size.height * 0.68)
        ..close(),
      wing,
    );

    // Slash shape
    final slash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFF9FA8B8), Color(0xFF18224A)],
      ).createShader(Rect.fromLTWH(
          size.width * 0.50, size.height * 0.30,
          size.width * 0.36, size.height * 0.44));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.58, size.height * 0.32)
        ..lineTo(size.width * 0.86, size.height * 0.32)
        ..lineTo(size.width * 0.74, size.height * 0.42)
        ..lineTo(size.width * 0.68, size.height * 0.72)
        ..lineTo(size.width * 0.53, size.height * 0.72)
        ..lineTo(size.width * 0.63, size.height * 0.43)
        ..lineTo(size.width * 0.50, size.height * 0.43)
        ..close(),
      slash,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Field label ──────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          color: _kCyan,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ));
  }
}

// ─── Rounded input field ──────────────────────────────────

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: _kCyan,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: _kField,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF4A5568), size: 20),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixTap,
                icon: Icon(suffixIcon, color: const Color(0xFF4A5568), size: 20),
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kCyan, width: 1.5),
        ),
      ),
    );
  }
}

// ─── LOG IN button ────────────────────────────────────────

class _LogInButton extends StatelessWidget {
  const _LogInButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C5D9), Color(0xFF0080FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C5D9).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white54,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('LOG IN',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        )),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── CONTINUE AS GUEST button ─────────────────────────────

class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kCyan,
          side: const BorderSide(color: _kCyan, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
        label: const Text(
          'CONTINUE AS GUEST',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
