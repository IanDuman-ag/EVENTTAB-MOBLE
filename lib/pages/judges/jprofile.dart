import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';

class JudgeProfilePage extends StatelessWidget {
  const JudgeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: judgeBg,
      body: SafeArea(child: JudgeProfileBody()),
    );
  }
}

class JudgeProfileBody extends StatefulWidget {
  const JudgeProfileBody({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<JudgeProfileBody> createState() => _JudgeProfileBodyState();
}

class _JudgeProfileBodyState extends State<JudgeProfileBody> {
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

    final data = await JudgeApi.getJson('/api/events/judge/profile/');
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Could not load profile.';
        _isLoading = false;
      });
    }
  }

  String get _initials {
    final name = _profile?['display_name'] as String? ?? 'J';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'J';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: judgeGold),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: c.text,
                foregroundColor: c.surface,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final p = _profile!;
    final stats = p['stats'] as Map<String, dynamic>? ?? {};
    final isActive = (p['status'] as String?) == 'ACTIVE';

    return ColoredBox(
      color: c.bg,
      child: RefreshIndicator(
        color: judgeGold,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              'My Profile',
              style: TextStyle(
                color: c.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: c.isDark
                            ? judgeGold.withValues(alpha: 0.2)
                            : const Color(0xFFFFE8D6),
                        child: Text(
                          _initials,
                          style: TextStyle(
                            color: c.text,
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
                            color: judgeGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: judgeWhite),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p['display_name'] as String? ?? '',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: judgeGold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p['role'] as String? ?? 'JUDGE',
                      style: const TextStyle(
                        color: judgeGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileRow(
                    icon: Icons.badge_rounded,
                    label: 'Judge ID',
                    value: p['judge_id'] as String?,
                  ),
                  _ProfileRow(
                    icon: Icons.gavel_rounded,
                    label: 'Role',
                    value: p['role_detail'] as String? ??
                        'Criteria-Based Judge',
                  ),
                  _ProfileRow(
                    icon: Icons.verified_rounded,
                    label: 'Status',
                    valueWidget: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isActive ? judgeGreen : c.muted)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '● ${p['status'] as String? ?? 'ACTIVE'}',
                        style: TextStyle(
                          color: isActive ? judgeGreen : c.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  _ProfileRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Member Since',
                    value: p['member_since_display'] as String? ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERVIEW',
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    color: judgeGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _OverviewTile(
                  icon: Icons.assignment_rounded,
                  value: '${stats['assignments'] ?? 0}',
                  label: 'Assignments',
                  sublabel: 'Total Assigned',
                  color: judgeGold,
                ),
                const SizedBox(width: 10),
                _OverviewTile(
                  icon: Icons.check_circle_rounded,
                  value: '${stats['completed'] ?? 0}',
                  label: 'Completed',
                  sublabel: 'Scores Submitted',
                  color: judgeGreen,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _OverviewTile(
                  icon: Icons.schedule_rounded,
                  value: '${stats['pending'] ?? 0}',
                  label: 'Pending',
                  sublabel: 'Under Review',
                  color: judgeBlue,
                ),
                const SizedBox(width: 10),
                _OverviewTile(
                  icon: Icons.emoji_events_rounded,
                  value: '${stats['events_this_month'] ?? 0}',
                  label: 'Events',
                  sublabel: 'This Month',
                  color: judgePurple,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: judgeGold,
                  side: const BorderSide(color: judgeGold, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: judgeGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: judgeGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: c.muted, fontSize: 11)),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value ?? '—',
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.06),
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
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: c.text,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(color: c.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
