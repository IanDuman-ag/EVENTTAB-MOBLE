import 'package:flutter/material.dart';

class AuthCredentialsStore {
  AuthCredentialsStore._();

  static final Map<String, String> _credentials = <String, String>{};

  static bool get hasCredentials => _credentials.isNotEmpty;

  static bool exists(String identifier) {
    return _credentials.containsKey(_normalize(identifier));
  }

  static void create({required String identifier, required String password}) {
    _credentials[_normalize(identifier)] = password;
  }

  static bool validate({required String identifier, required String password}) {
    return _credentials[_normalize(identifier)] == password;
  }

  static void clear() {
    _credentials.clear();
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.onAccountCreated});

  final VoidCallback? onAccountCreated;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (identifier.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Enter an email or username and password.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (AuthCredentialsStore.exists(identifier)) {
      setState(() {
        _errorMessage = 'This email or username already exists.';
      });
      return;
    }

    AuthCredentialsStore.create(identifier: identifier, password: password);
    widget.onAccountCreated?.call();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0B),
        foregroundColor: const Color(0xFF7DEEFF),
        elevation: 0,
        title: const Text('Create Account'),
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
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            'CREATE YOUR LOGIN CREDENTIALS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF74777B),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 42),
                          const _FormLabel('EMAIL OR USERNAME'),
                          const SizedBox(height: 8),
                          _CredentialTextField(
                            controller: _identifierController,
                            hintText: 'EMAIL OR USERNAME',
                            suffixIcon: Icons.person_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),
                          const _FormLabel('PASSWORD'),
                          const SizedBox(height: 8),
                          _CredentialTextField(
                            controller: _passwordController,
                            hintText: 'PASSWORD',
                            suffixIcon: _obscurePassword
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            obscureText: _obscurePassword,
                            onSuffixPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const _FormLabel('CONFIRM PASSWORD'),
                          const SizedBox(height: 8),
                          _CredentialTextField(
                            controller: _confirmPasswordController,
                            hintText: 'CONFIRM PASSWORD',
                            suffixIcon: _obscureConfirmPassword
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            obscureText: _obscureConfirmPassword,
                            onSuffixPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
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
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 56,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF7CE1EF),
                                    Color(0xFF00C5D9),
                                  ],
                                ),
                              ),
                              child: TextButton(
                                onPressed: _createAccount,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF061014),
                                  shape: const RoundedRectangleBorder(),
                                ),
                                child: const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

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

class _CredentialTextField extends StatelessWidget {
  const _CredentialTextField({
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
