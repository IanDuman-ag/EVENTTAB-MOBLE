// Scorer session — mirrors judge_auth_service.dart for scorer role pages.

class ScorerUser {
  const ScorerUser({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
    this.label,
  });

  final int id;
  final String username;
  final String email;
  final String token;
  final String? label;
}

class ScorerAuthSession {
  ScorerAuthSession._();

  static ScorerUser? _current;

  static ScorerUser? get current => _current;
  static bool get isLoggedIn => _current != null;

  static void set(ScorerUser user) => _current = user;
  static void clear() => _current = null;
}
