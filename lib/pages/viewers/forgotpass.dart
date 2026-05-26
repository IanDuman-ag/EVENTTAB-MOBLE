import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

/// Two-step forgot-password flow:
///   Step 1 — enter email → request reset token
///   Step 2 — enter reset token + new password → update password
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.onPasswordReset});

  /// Called after a successful password reset so the caller can navigate away.
  final VoidCallback? onPasswordReset;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Step 1 controllers
  final _emailController = TextEditingController();

  // Step 2 controllers
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  /// null = step 1, non-null = step 2 (holds the debug token if returned)
  String? _resetToken;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---- Step 1: request reset ----------------------------------------------

  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await authService.forgotPassword(email: email);
      setState(() {
        _resetToken = ''; // Move to step 2
        _successMessage =
            'Reset code sent to your email. Check your inbox and enter the code below. Code expires in 2 minutes.';
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---- Resend code --------------------------------------------------------

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await authService.forgotPassword(email: email);
      setState(() {
        _successMessage =
            'New code sent! Check your email. Expires in 2 minutes.';
        _tokenController.clear(); // Clear old code
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Try again.');
    } finally {
      setState(() => _isResending = false);
    }
  }

  // ---- Step 2: set new password -------------------------------------------

  Future<void> _resetPassword() async {
    final token = _tokenController.text.trim();
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (token.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
      setState(() => _errorMessage = 'Fill in all fields.');
      return;
    }

    if (newPw != confirmPw) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await authService.resetPassword(
        resetToken: token,
        newPassword: newPw,
        confirmPassword: confirmPw,
      );
      setState(() => _successMessage = 'Password updated. You can now log in.');
      await Future<void>.delayed(const Duration(seconds: 1));
      widget.onPasswordReset?.call();
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0B),
        foregroundColor: const Color(0xFF7DEEFF),
        elevation: 0,
        title: const Text(
          'RESET PASSWORD',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
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
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                      child: _resetToken == null
                          ? _buildStep1()
                          : _buildStep2(),
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

  // ---- Step 1 UI ----------------------------------------------------------

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          'FORGOT YOUR PASSWORD?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF74777B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 48),
        const _FieldLabel('EMAIL ADDRESS'),
        const SizedBox(height: 8),
        _ForgotTextField(
          controller: _emailController,
          hintText: 'YOUR EMAIL',
          keyboardType: TextInputType.emailAddress,
          suffixIcon: Icons.email_outlined,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _StatusText(text: _errorMessage!, isError: true),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          _StatusText(text: _successMessage!, isError: false),
        ],
        const SizedBox(height: 32),
        _ActionButton(
          label: 'SEND RESET CODE',
          isLoading: _isLoading,
          onPressed: _requestReset,
        ),
      ],
    );
  }

  // ---- Step 2 UI ----------------------------------------------------------

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          'SET NEW PASSWORD',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF74777B),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 40),
        const _FieldLabel('RESET CODE (6 DIGITS)'),
        const SizedBox(height: 8),
        _ForgotTextField(
          controller: _tokenController,
          hintText: '000000',
          suffixIcon: Icons.vpn_key_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        const _FieldLabel('NEW PASSWORD'),
        const SizedBox(height: 8),
        _ForgotTextField(
          controller: _newPasswordController,
          hintText: 'NEW PASSWORD',
          obscureText: _obscureNew,
          suffixIcon: _obscureNew
              ? Icons.lock_outline
              : Icons.lock_open_outlined,
          onSuffixPressed: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 24),
        const _FieldLabel('CONFIRM NEW PASSWORD'),
        const SizedBox(height: 8),
        _ForgotTextField(
          controller: _confirmPasswordController,
          hintText: 'CONFIRM NEW PASSWORD',
          obscureText: _obscureConfirm,
          suffixIcon: _obscureConfirm
              ? Icons.lock_outline
              : Icons.lock_open_outlined,
          onSuffixPressed: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _StatusText(text: _errorMessage!, isError: true),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          _StatusText(text: _successMessage!, isError: false),
        ],
        const SizedBox(height: 32),
        _ActionButton(
          label: 'UPDATE PASSWORD',
          isLoading: _isLoading,
          onPressed: _resetPassword,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _resetToken = null;
                _errorMessage = null;
                _successMessage = null;
              }),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF797B81),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'BACK',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            TextButton(
              onPressed: _isResending ? null : _resendCode,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7DEEFF),
                disabledForegroundColor: const Color(
                  0xFF7DEEFF,
                ).withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
              ),
              child: _isResending
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7DEEFF),
                      ),
                    )
                  : const Text(
                      'RESEND CODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

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

class _ForgotTextField extends StatelessWidget {
  const _ForgotTextField({
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

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
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.8,
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isError ? const Color(0xFFFF7A18) : const Color(0xFF4DFFB4),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
