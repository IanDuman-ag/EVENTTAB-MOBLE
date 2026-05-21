import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'forgotpass.dart';
import 'signin.dart';
import 'terms.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onLogin,
    this.onCreateAccount,
    this.onForgotPassword,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onCreateAccount;

  /// If null, tapping "Forgot Password?" pushes [ForgotPasswordPage] directly.
  final VoidCallback? onForgotPassword;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _accountController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = 'Enter your email or username and password.',
      );
      return;
    }

    if (!_agreedToTerms) {
      setState(
        () => _errorMessage =
            'You must agree to the Terms & Conditions to log in.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authService.login(identifier: identifier, password: password);
      widget.onLogin?.call();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignInPage()));
  }

  Future<void> _openTerms() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TermsAndConditionsPage(
          onAgree: () => setState(() => _agreedToTerms = true),
        ),
      ),
    );
    if (agreed == true) {
      setState(() => _agreedToTerms = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _EventtabLogo(),
                          const SizedBox(height: 52),
                          const Text(
                            'EVENTTAB',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF7EEBFF),
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'EVENT LEADERBOARD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF74777B),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 48),
                          const _FieldLabel('EMAIL OR USERNAME'),
                          const SizedBox(height: 8),
                          _LoginTextField(
                            controller: _accountController,
                            hintText: 'EMAIL OR USERNAME',
                            keyboardType: TextInputType.emailAddress,
                            suffixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              const Expanded(child: _FieldLabel('PASSWORD')),
                              _SmallTextButton(
                                label: 'FORGOT PASSWORD?',
                                onPressed: _handleForgotPassword,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LoginTextField(
                            controller: _passwordController,
                            hintText: 'PASSWORD',
                            obscureText: _obscurePassword,
                            suffixIcon: _obscurePassword
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            onSuffixPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF7A18),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          _LoginButton(
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _SmallTextButton(
                              label: 'FORGOT PASSWORD?',
                              onPressed: _handleForgotPassword,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _TermsCheckbox(
                            agreed: _agreedToTerms,
                            onTap: _openTerms,
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            "DON'T HAVE AN ACCOUNT?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8B8D91),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CreateAccountButton(onPressed: _handleCreateAccount),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets (unchanged visual design)
// ---------------------------------------------------------------------------

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF7A18),
          side: const BorderSide(color: Color(0xFFFF7A18)),
          shape: const RoundedRectangleBorder(),
        ),
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EventtabLogo extends StatelessWidget {
  const _EventtabLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 132,
        height: 132,
        child: CustomPaint(painter: _EventtabLogoPainter()),
      ),
    );
  }
}

class _EventtabLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF13C8FF).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF1176FF),
          Color(0xFF7EF0FF),
          Color(0xFF112B76),
          Color(0xFF1176FF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.72));
    canvas.drawCircle(center, radius * 0.72, outerRing);

    final innerFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF06336B), Color(0xFF0B0B0D), Color(0xFF041E45)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.62));
    canvas.drawCircle(center, radius * 0.62, innerFill);

    final wingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00D9FF), Color(0xFF0A53CC)],
      ).createShader(Rect.fromLTWH(22, 36, 58, 48));

    final wing = Path()
      ..moveTo(size.width * 0.27, size.height * 0.38)
      ..lineTo(size.width * 0.60, size.height * 0.38)
      ..lineTo(size.width * 0.52, size.height * 0.47)
      ..lineTo(size.width * 0.29, size.height * 0.47)
      ..lineTo(size.width * 0.22, size.height * 0.58)
      ..lineTo(size.width * 0.55, size.height * 0.58)
      ..lineTo(size.width * 0.47, size.height * 0.68)
      ..lineTo(size.width * 0.18, size.height * 0.68)
      ..close();
    canvas.drawPath(wing, wingPaint);

    final slashPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFF9FA8B8), Color(0xFF18224A)],
      ).createShader(Rect.fromLTWH(58, 30, 50, 62));

    final slash = Path()
      ..moveTo(size.width * 0.58, size.height * 0.32)
      ..lineTo(size.width * 0.86, size.height * 0.32)
      ..lineTo(size.width * 0.74, size.height * 0.42)
      ..lineTo(size.width * 0.68, size.height * 0.72)
      ..lineTo(size.width * 0.53, size.height * 0.72)
      ..lineTo(size.width * 0.63, size.height * 0.43)
      ..lineTo(size.width * 0.50, size.height * 0.43)
      ..close();
    canvas.drawPath(slash, slashPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'EVENT TAB',
        style: TextStyle(
          color: Color(0xFFEBFBFF),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.69),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7DEEFF),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.onSuffixPressed,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        cursorColor: const Color(0xFF7DEEFF),
        style: const TextStyle(
          color: Color(0xFFE6F9FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF515359),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          suffixIcon: IconButton(
            tooltip: hintText,
            onPressed: onSuffixPressed,
            icon: Icon(suffixIcon, size: 17),
          ),
          suffixIconColor: const Color(0xFF62656B),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF34363A)),
            borderRadius: BorderRadius.zero,
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF13D5EE)),
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF797B81),
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 18),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7CE1EF), Color(0xFF00C5D9)],
          ),
        ),
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF061014),
            disabledForegroundColor: const Color(
              0xFF061014,
            ).withValues(alpha: 0.5),
            shape: const RoundedRectangleBorder(),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF061014),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LOG IN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.agreed, required this.onTap});

  final bool agreed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF2B2D31), height: 1)),
          const SizedBox(width: 12),
          // Non-interactive checkbox (display only)
          IgnorePointer(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: agreed ? const Color(0xFF7CE1EF) : Colors.transparent,
                border: Border.all(
                  color: agreed
                      ? const Color(0xFF7CE1EF)
                      : const Color(0xFF76787F),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: agreed
                  ? const Icon(Icons.check, size: 14, color: Color(0xFF061014))
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'TERMS & CONDITION',
            style: TextStyle(
              color: Color(0xFF76787F),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF76787F),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Color(0xFF2B2D31), height: 1)),
        ],
      ),
    );
  }
}
