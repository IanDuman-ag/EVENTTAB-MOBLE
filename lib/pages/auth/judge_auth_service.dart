import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class JudgeUser {
  const JudgeUser({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
  });

  final int id;
  final String username;
  final String email;
  final String token;

  factory JudgeUser.fromJson(Map<String, dynamic> json, String token) {
    return JudgeUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      token: token,
    );
  }
}

class JudgeAuthException implements Exception {
  const JudgeAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Session (in-memory; swap for shared_preferences/flutter_secure_storage later)
// ---------------------------------------------------------------------------

class JudgeAuthSession {
  JudgeAuthSession._();

  static JudgeUser? _current;

  static JudgeUser? get current => _current;
  static bool get isLoggedIn => _current != null;

  static void set(JudgeUser user) => _current = user;
  static void clear() => _current = null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class JudgeAuthService {
  JudgeAuthService({http.Client? client}) : _client = client ?? http.Client();

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

  // ---- login --------------------------------------------------------------

  /// Authenticates judge with email + password and stores the session.
  Future<JudgeUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          _uri('/api/auth/login/'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'identifier': email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    final body = _decodeBody(response);

    if (response.statusCode != 200) {
      throw JudgeAuthException(_parseError(body));
    }

    final user = JudgeUser.fromJson(
      body['user'] as Map<String, dynamic>,
      body['token'] as String,
    );
    JudgeAuthSession.set(user);
    return user;
  }

  // ---- logout -------------------------------------------------------------

  Future<void> logout() async {
    final token = JudgeAuthSession.current?.token;
    JudgeAuthSession.clear();
    AuthSession.clear();

    if (token == null) return;

    try {
      await _client
          .post(
            _uri('/api/auth/logout/'),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);
    } catch (_) {
      // Best-effort — session is already cleared locally.
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

final judgeAuthService = JudgeAuthService();
