import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: judgeCyan),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: judgeMuted)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final p = _profile!;
    final stats = p['stats'] as Map<String, dynamic>? ?? {};
    final isActive = (p['status'] as String?) == 'ACTIVE';

    return RefreshIndicator(
      color: judgeCyan,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: judgeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: judgeBorder),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: judgePurple.withValues(alpha: 0.2),
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: judgePurple,
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
                          color: judgeCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: judgeBg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                    color: judgePurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p['role'] as String? ?? 'JUDGE',
                    style: const TextStyle(
                      color: judgePurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _ProfileRow(label: 'Judge ID', value: p['judge_id'] as String?),
                _ProfileRow(
                  label: 'Role',
                  value: p['role_detail'] as String? ?? 'Judge',
                ),
                _ProfileRow(
                  label: 'Status',
                  valueWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isActive ? judgeGreen : judgeMuted)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p['status'] as String? ?? 'ACTIVE',
                      style: TextStyle(
                        color: isActive ? judgeGreen : judgeMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                _ProfileRow(
                  label: 'Member Since',
                  value: p['member_since_display'] as String? ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'OVERVIEW',
            style: TextStyle(
              color: judgeCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewTile(
                icon: Icons.assignment_rounded,
                value: '${stats['assignments'] ?? 0}',
                label: 'Assignments',
                sublabel: 'Total Assigned',
              ),
              const SizedBox(width: 10),
              _OverviewTile(
                icon: Icons.check_circle_outline_rounded,
                value: '${stats['completed'] ?? 0}',
                label: 'Completed',
                sublabel: 'Scores Submitted',
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
              ),
              const SizedBox(width: 10),
              _OverviewTile(
                icon: Icons.emoji_events_rounded,
                value: '${stats['events_this_month'] ?? 0}',
                label: 'Events',
                sublabel: 'This Month',
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: judgeRed,
                side: const BorderSide(color: judgeRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: judgeMuted)),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
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
  });

  final IconData icon;
  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: judgeCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: judgeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: judgeCyan, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            Text(sublabel, style: const TextStyle(color: judgeMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
