import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';

class ScorerProfilePage extends StatelessWidget {
  const ScorerProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const ScorerProfileBody();
}

class ScorerProfileBody extends StatefulWidget {
  const ScorerProfileBody({
    super.key,
    this.onLogout,
    this.onGoToAssignments,
  });

  final VoidCallback? onLogout;
  final VoidCallback? onGoToAssignments;

  @override
  State<ScorerProfileBody> createState() => _ScorerProfileBodyState();
}

class _ScorerProfileBodyState extends State<ScorerProfileBody> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ScorerApi.get('/api/events/scorer/profile/');
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _profile = jsonDecode(res.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load profile.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server.';
          _isLoading = false;
        });
      }
    }
  }

  String get _initials {
    final name = _profile?['display_name'] as String? ?? 'S';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: scorerPurple),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final p = _profile!;
    final stats = p['stats'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      color: scorerPurple,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View your account summary.',
            style: TextStyle(color: scorerMuted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scorerPurple.withValues(alpha: 0.25),
                  scorerCard,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scorerBorder),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: scorerPurple.withValues(alpha: 0.2),
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: scorerPurple,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: scorerPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p['display_name'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scorerPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p['role'] as String? ?? 'SCORER',
                    style: const TextStyle(
                      color: scorerPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                if ((p['location'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: scorerMuted),
                      const SizedBox(width: 4),
                      Text(
                        p['location'] as String,
                        style: const TextStyle(color: scorerMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                icon: Icons.assignment_rounded,
                value: '${stats['matches_scored'] ?? 0}',
                label: 'Matches Scored',
                color: scorerPurple,
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.check_circle_outline_rounded,
                value: '${stats['completed'] ?? 0}',
                label: 'Completed',
                color: scorerGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatTile(
                icon: Icons.schedule_rounded,
                value: '${stats['pending'] ?? 0}',
                label: 'Pending',
                color: scorerOrange,
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.emoji_events_rounded,
                value: '${stats['events'] ?? 0}',
                label: 'Events',
                color: scorerBlue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scorerCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scorerBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user_rounded,
                    color: scorerPurple, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Your account is all set!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can focus on scoring and view your match assignments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scorerMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: widget.onGoToAssignments,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scorerPurple,
                    side: const BorderSide(color: scorerPurple),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.assignment_rounded),
                  label: const Text('Go to My Assignments'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: scorerRed,
                side: const BorderSide(color: scorerRed),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scorerCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scorerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: const TextStyle(color: scorerMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
