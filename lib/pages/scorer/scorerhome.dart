import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import 'scorer_widgets.dart';
import 'scorerscores.dart';

class ScorerHomePage extends StatelessWidget {
  const ScorerHomePage({super.key});

  @override
  Widget build(BuildContext context) => const ScorerHomeBody();
}

class ScorerHomeBody extends StatefulWidget {
  const ScorerHomeBody({
    super.key,
    this.onViewAllAssignments,
    this.onEditMatch,
    this.onNotificationCount,
  });

  final VoidCallback? onViewAllAssignments;
  final ValueChanged<Map<String, dynamic>>? onEditMatch;
  final ValueChanged<int>? onNotificationCount;

  @override
  State<ScorerHomeBody> createState() => _ScorerHomeBodyState();
}

class _ScorerHomeBodyState extends State<ScorerHomeBody> {
  Map<String, dynamic>? _data;
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
      final res = await ScorerApi.get('/api/events/scorer/dashboard/');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final notifications =
            (data['notifications'] as List? ?? []).length;
        widget.onNotificationCount?.call(notifications);
        setState(() {
          _data = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load dashboard.';
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

  void _editMatch(Map<String, dynamic> match) {
    if (widget.onEditMatch != null) {
      widget.onEditMatch!(match);
      return;
    }
    openScorerLiveScoring(context, match: match, onSaved: _load);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: scorerMuted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: scorerNavy,
                foregroundColor: scorerWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};
    final name = _data!['greeting_name'] as String? ?? 'Scorer';
    final schedule = (_data!['todays_schedule'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return RefreshIndicator(
      color: scorerGold,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Navy hero with greeting + metric cards
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scorerNavy, Color(0xFF2A2668)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: 10,
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/Finallogo.png',
                      width: 180,
                      height: 180,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${scorerGreeting()}, ',
                              style: const TextStyle(
                                color: scorerWhite,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: '$name! 👋',
                              style: const TextStyle(
                                color: scorerGold,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Here's what's happening today.",
                        style: TextStyle(
                          color: scorerWhite.withValues(alpha: 0.75),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ScorerStatCard(
                            icon: Icons.assignment_rounded,
                            value: '${stats['assigned_matches'] ?? 0}',
                            label: 'Assigned Matches',
                            color: scorerNavy,
                          ),
                          const SizedBox(width: 10),
                          ScorerStatCard(
                            icon: Icons.check_circle_rounded,
                            value: '${stats['completed_matches'] ?? 0}',
                            label: 'Completed',
                            color: scorerGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ScorerStatCard(
                            icon: Icons.schedule_rounded,
                            value: '${stats['live_matches'] ?? 0}',
                            label: 'Live Match',
                            color: scorerGold,
                          ),
                          const SizedBox(width: 10),
                          ScorerStatCard(
                            icon: Icons.event_rounded,
                            value: '${stats['upcoming_matches'] ?? 0}',
                            label: 'Upcoming',
                            color: scorerNavy,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // White schedule sheet overlapping navy
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: const BoxDecoration(
                color: scorerWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScorerSectionHeader(
                    title: "TODAY'S SCHEDULE",
                    trailing: widget.onViewAllAssignments != null
                        ? GestureDetector(
                            onTap: widget.onViewAllAssignments,
                            child: const Text(
                              'View All >',
                              style: TextStyle(
                                color: scorerNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (schedule.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: scorerBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'No matches scheduled for today.',
                                style: TextStyle(
                                  color: scorerMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 42,
                              color: scorerNavy.withValues(alpha: 0.18),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...schedule.asMap().entries.map(
                          (e) => ScorerAssignmentCard(
                            match: e.value,
                            compact: true,
                            accentNavy: e.key.isOdd,
                            onTap: () => _editMatch(e.value),
                          ),
                        ),
                  const ScorerReminderBox(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
