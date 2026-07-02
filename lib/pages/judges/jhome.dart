import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

class JudgeDashboardBody extends StatefulWidget {
  const JudgeDashboardBody({
    super.key,
    required this.onViewAllAssignments,
    required this.onOpenAssignment,
    this.onNotificationCount,
  });

  final VoidCallback onViewAllAssignments;
  final ValueChanged<Map<String, dynamic>> onOpenAssignment;
  final ValueChanged<int>? onNotificationCount;

  @override
  State<JudgeDashboardBody> createState() => JudgeDashboardBodyState();
}

class JudgeDashboardBodyState extends State<JudgeDashboardBody> {
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

    final data = await JudgeApi.getJson('/api/events/judge/dashboard/');
    if (!mounted) return;

    if (data != null) {
      widget.onNotificationCount?.call(
        data['notification_count'] as int? ?? 0,
      );
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
  }

  String _actionLabel(String status) {
    if (status == 'ongoing') return 'Start Scoring';
    return 'View Details';
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: judgeCyan),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final greetingName = _data!['greeting_name'] as String? ?? 'Judge';
    final todays = (_data!['todays_assignments'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final upcoming = (_data!['upcoming_events'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      color: judgeCyan,
      onRefresh: _load,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${judgeGreeting()}, $greetingName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ready to evaluate and make every performance count.',
                  style: TextStyle(color: judgeMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          JudgeSectionHeader(
            title: "TODAY'S ASSIGNMENTS",
            onViewAll: widget.onViewAllAssignments,
          ),
          if (todays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'No assignments scheduled for today.',
                style: TextStyle(color: judgeMuted),
              ),
            )
          else
            ...todays.map(
              (a) => _DashboardAssignmentTile(
                assignment: a,
                actionLabel: _actionLabel(a['status'] as String? ?? ''),
                onTap: () => widget.onOpenAssignment(a),
              ),
            ),
          JudgeSectionHeader(title: 'OVERVIEW'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                JudgeStatTile(
                  icon: Icons.assignment_turned_in_rounded,
                  value: '${stats['assigned'] ?? 0}',
                  label: 'Assigned',
                ),
                const SizedBox(width: 10),
                JudgeStatTile(
                  icon: Icons.schedule_rounded,
                  value: '${stats['pending'] ?? 0}',
                  label: 'Pending',
                ),
                const SizedBox(width: 10),
                JudgeStatTile(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${stats['completed'] ?? 0}',
                  label: 'Completed',
                ),
              ],
            ),
          ),
          JudgeSectionHeader(
            title: 'UPCOMING EVENTS',
            onViewAll: widget.onViewAllAssignments,
          ),
          if (upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                'No upcoming events.',
                style: TextStyle(color: judgeMuted),
              ),
            )
          else
            ...upcoming.map(
              (a) => _DashboardAssignmentTile(
                assignment: a,
                actionLabel: 'View Details',
                onTap: () => widget.onOpenAssignment(a),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DashboardAssignmentTile extends StatelessWidget {
  const _DashboardAssignmentTile({
    required this.assignment,
    required this.actionLabel,
    required this.onTap,
  });

  final Map<String, dynamic> assignment;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = assignment['status'] as String? ?? 'upcoming';
    final icon = judgeCategoryIcon(assignment['category_icon'] as String?);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: judgeCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: judgeBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: judgePurple.withValues(alpha: 0.2),
                  child: Icon(icon, color: judgePurple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignment['title'] as String? ?? 'Event',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          JudgeStatusBadge(status: status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment['subtitle'] as String? ?? '',
                        style: const TextStyle(color: judgeMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${assignment['time_display'] ?? ''} | ${assignment['venue'] ?? ''}',
                        style: const TextStyle(color: judgeMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onTap,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      color: judgeCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
