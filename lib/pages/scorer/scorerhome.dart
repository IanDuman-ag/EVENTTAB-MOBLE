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
        child: CircularProgressIndicator(color: scorerPurple),
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
              style: FilledButton.styleFrom(backgroundColor: scorerPurple),
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
    final notifications = (_data!['notifications'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return RefreshIndicator(
      color: scorerPurple,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scorerGreeting()}, $name! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening today.",
                  style: TextStyle(color: scorerMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ScorerStatCard(
                  icon: Icons.assignment_rounded,
                  value: '${stats['assigned_matches'] ?? 0}',
                  label: 'Assigned Matches',
                  color: scorerPurple,
                ),
                const SizedBox(width: 10),
                ScorerStatCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${stats['completed_matches'] ?? 0}',
                  label: 'Completed',
                  color: scorerGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ScorerStatCard(
                  icon: Icons.schedule_rounded,
                  value: '${stats['live_matches'] ?? 0}',
                  label: 'Live Match',
                  color: scorerOrange,
                ),
                const SizedBox(width: 10),
                ScorerStatCard(
                  icon: Icons.event_rounded,
                  value: '${stats['upcoming_matches'] ?? 0}',
                  label: 'Upcoming',
                  color: scorerBlue,
                ),
              ],
            ),
          ),
          ScorerSectionHeader(
            title: "TODAY'S SCHEDULE",
            trailing: widget.onViewAllAssignments != null
                ? GestureDetector(
                    onTap: widget.onViewAllAssignments,
                    child: const Text(
                      'View All >',
                      style: TextStyle(color: scorerMuted, fontSize: 12),
                    ),
                  )
                : null,
          ),
          if (schedule.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No matches scheduled for today.',
                style: TextStyle(color: scorerMuted),
              ),
            )
          else
            ...schedule.map(
              (m) => ScorerAssignmentCard(
                match: m,
                compact: true,
                onTap: () => _editMatch(m),
              ),
            ),
          ScorerSectionHeader(title: 'NOTIFICATIONS'),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No notifications.',
                style: TextStyle(color: scorerMuted),
              ),
            )
          else
            ...notifications.map((n) => _NotificationTile(notification: n)),
          const ScorerReminderBox(),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scorerCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scorerBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if ((notification['body'] as String?)?.isNotEmpty == true)
                    Text(
                      notification['body'] as String,
                      style: const TextStyle(color: scorerMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              notification['time_display'] as String? ?? '',
              style: const TextStyle(color: scorerMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
