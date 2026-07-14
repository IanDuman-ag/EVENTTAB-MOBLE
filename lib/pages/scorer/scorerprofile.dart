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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: scorerGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: scorerMuted)),
      );
    }

    final p = _profile!;
    final stats = p['stats'] as Map<String, dynamic>? ?? {};
    final name = p['display_name'] as String? ?? 'Scorer';

    return ColoredBox(
      color: scorerBg,
      child: RefreshIndicator(
        color: scorerGold,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                color: scorerNavy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View your account summary.',
              style: TextStyle(color: scorerMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),

            // Navy profile banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scorerNavy, Color(0xFF2A2668)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Opacity(
                      opacity: 0.12,
                      child: Image.asset(
                        'assets/Finallogo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: scorerWhite,
                            child: Icon(Icons.person_rounded,
                                color: scorerNavy, size: 40),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: scorerGold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: scorerWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: scorerWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16133F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p['role'] as String? ?? 'SCORER',
                                style: const TextStyle(
                                  color: scorerGold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  color: scorerGold,
                  iconBg: scorerGold.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  icon: Icons.check_circle_rounded,
                  value: '${stats['completed'] ?? 0}',
                  label: 'Completed',
                  color: scorerGreen,
                  iconBg: scorerGreen.withValues(alpha: 0.15),
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
                  color: scorerGold,
                  iconBg: scorerGold.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: '${stats['events'] ?? 0}',
                  label: 'Events',
                  color: scorerBlue,
                  iconBg: scorerBlue.withValues(alpha: 0.15),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scorerCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scorerGold.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: scorerGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: scorerWhite,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your account is all set!',
                    style: TextStyle(
                      color: scorerNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You can focus on scoring and view your match assignments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scorerMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: widget.onGoToAssignments,
                style: FilledButton.styleFrom(
                  backgroundColor: scorerGold,
                  foregroundColor: scorerWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.assignment_rounded),
                label: const Text(
                  'Go to My Assignments',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scorerRed,
                  side: const BorderSide(color: scorerRed, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
    required this.iconBg,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scorerWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scorerNavy.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: scorerMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
