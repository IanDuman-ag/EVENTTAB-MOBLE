import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
    required this.role,
    this.label,
  });

  final int id;
  final String username;
  final String email;
  final String token;
  /// 'judge', 'scorer', or 'viewer'
  final String role;
  final String? label;

  bool get isJudge => role == 'judge';
  bool get isScorer => role == 'scorer';

  factory AuthUser.fromJson(Map<String, dynamic> json, String token, String role) {
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      token: token,
      role: role,
      label: json['label'] as String?,
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Session (in-memory; swap for shared_preferences/flutter_secure_storage later)
// ---------------------------------------------------------------------------

class AuthSession {
  AuthSession._();

  static AuthUser? _current;

  static AuthUser? get current => _current;
  static bool get isLoggedIn => _current != null;

  static void set(AuthUser user) => _current = user;
  static void clear() => _current = null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  // ---- helpers ------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('$defaultApiBaseUrl$path');

  Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Parses a DRF error response into a human-readable string.
  String _parseError(Map<String, dynamic> body) {
    // DRF can return { "detail": "..." } or { "field": ["msg"] }
    if (body.containsKey('detail')) {
      return body['detail'].toString();
    }
    final messages = <String>[];
    for (final entry in body.entries) {
      final value = entry.value;
      if (value is List) {
        messages.add(value.join(' '));
      } else {
        messages.add(value.toString());
      }
    }
    return messages.join('\n');
  }

  // ---- register -----------------------------------------------------------

  /// Creates a new account and stores the session.
  Future<AuthUser> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/register/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'confirm_password': confirmPassword,
          }),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 201) {
      throw AuthException(_parseError(body));
    }

    final user = AuthUser.fromJson(
      body['user'] as Map<String, dynamic>,
      body['token'] as String,
      body['role'] as String? ?? 'viewer',
    );
    AuthSession.set(user);
    return user;
  }

  // ---- login --------------------------------------------------------------

  /// Authenticates with username/email + password and stores the session.
  Future<AuthUser> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/login/'),
          headers: _jsonHeaders,
          body: jsonEncode({'identifier': identifier, 'password': password}),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_parseError(body));
    }

    final user = AuthUser.fromJson(
      body['user'] as Map<String, dynamic>,
      body['token'] as String,
      body['role'] as String? ?? 'viewer',
    );
    AuthSession.set(user);
    return user;
  }

  // ---- access code login --------------------------------------------------

  /// Authenticates with an admin-issued access code and stores the session.
  Future<AuthUser> loginWithAccessCode({required String accessCode}) async {
    final normalizedCode =
        accessCode.trim().replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const AuthException('Access code is required.');
    }

    final response = await _client
        .post(
          apiUri('/api/auth/access-code/'),
          headers: _jsonHeaders,
          body: jsonEncode({'access_code': normalizedCode}),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_parseError(body));
    }

    final role = body['role'] as String? ?? '';
    if (role != 'judge' && role != 'scorer') {
      throw const AuthException('Invalid access code.');
    }

    final userJson = Map<String, dynamic>.from(
      body['user'] as Map<String, dynamic>,
    );
    final label = body['label'];
    if (label is String && label.isNotEmpty) {
      userJson['label'] = label;
    }

    final user = AuthUser.fromJson(
      userJson,
      body['token'] as String,
      role,
    );
    return user;
  }

  // ---- logout -------------------------------------------------------------

  Future<void> logout() async {
    final token = AuthSession.current?.token;
    AuthSession.clear();

    if (token == null) return;

    try {
      await _client
          .post(
            _uri('/api/auth/logout/'),
            headers: {..._jsonHeaders, 'Authorization': 'Token $token'},
          )
          .timeout(_timeout);
    } catch (_) {
      // Best-effort — session is already cleared locally.
    }
  }

  // ---- forgot password ----------------------------------------------------

  /// Sends a password-reset request. The reset code is sent to the user's email.
  Future<void> forgotPassword({required String email}) async {
    final response = await _client
        .post(
          _uri('/api/auth/forgot-password/'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email}),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_parseError(body));
    }
  }

  // ---- reset password -----------------------------------------------------

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/reset-password/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'reset_token': resetToken,
            'new_password': newPassword,
            'confirm_password': confirmPassword,
          }),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw AuthException(_parseError(body));
    }
  }

  // ---- helpers ------------------------------------------------------------

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'detail': response.body};
    } catch (_) {
      return {'detail': 'Unexpected server response.'};
    }
  }
}

// ---------------------------------------------------------------------------
// Singleton convenience accessor
// ---------------------------------------------------------------------------

final authService = AuthService();
