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

  @override
  Widget build(BuildContext context) {
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
            Text(_error!, style: TextStyle(color: JudgeThemeScope.paletteOf(context).muted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: JudgeThemeScope.paletteOf(context).text,
                foregroundColor: JudgeThemeScope.paletteOf(context).surface,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final c = JudgeThemeScope.paletteOf(context);
    final greetingName = _data!['greeting_name'] as String? ?? 'Judge';
    bool isCriteria(Map<String, dynamic> a) =>
        (a['assignment_type'] as String?) == 'CRITERIA BASED' &&
        ((a['criteria_count'] as num?)?.toInt() ?? 0) > 0;

    final todays = (_data!['todays_assignments'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where(isCriteria)
        .toList();
    final upcoming = (_data!['upcoming_events'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where(isCriteria)
        .toList();
    final stats = _data!['stats'] as Map<String, dynamic>? ?? {};

    return ColoredBox(
      color: c.surface,
      child: RefreshIndicator(
        color: judgeGold,
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${judgeGreeting()},',
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Judge $greetingName',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Evaluate assigned criteria-based events securely.',
                    style: TextStyle(color: c.muted, fontSize: 14),
                  ),
                ],
              ),
            ),

            if (todays.isEmpty)
              JudgeInfoCard(
                label: "TODAY'S ASSIGNED EVENTS",
                message: 'No events assigned for today.',
                watermarkIcon: Icons.calendar_month_rounded,
                onViewAll: widget.onViewAllAssignments,
              )
            else ...[
              JudgeSectionHeader(
                title: "TODAY'S ASSIGNED EVENTS",
                onViewAll: widget.onViewAllAssignments,
              ),
              ...todays.map(
                (a) => JudgeAssignmentCard(
                  assignment: a,
                  onTap: () => widget.onOpenAssignment(a),
                  actionLabel: (a['status'] as String?) == 'ongoing'
                      ? 'Continue Scoring'
                      : (a['status'] as String?) == 'completed'
                          ? 'View Submitted Scores'
                          : 'Open Event',
                ),
              ),
            ],

            const JudgeSectionHeader(title: 'SUMMARY'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      JudgeStatTile(
                        icon: Icons.assignment_rounded,
                        value: '${stats['assigned'] ?? 0}',
                        label: 'Assigned Events',
                        color: judgeGold,
                      ),
                      const SizedBox(width: 10),
                      JudgeStatTile(
                        icon: Icons.people_alt_rounded,
                        value: '${stats['pending'] ?? 0}',
                        label: 'Pending Contestants',
                        color: judgeBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      JudgeStatTile(
                        icon: Icons.edit_note_rounded,
                        value: '${stats['draft'] ?? 0}',
                        label: 'Draft Scores',
                        color: judgeGold,
                      ),
                      const SizedBox(width: 10),
                      JudgeStatTile(
                        icon: Icons.check_circle_rounded,
                        value: '${stats['submitted'] ?? stats['completed'] ?? 0}',
                        label: 'Submitted Scores',
                        color: judgeGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (upcoming.isNotEmpty) ...[
              JudgeSectionHeader(
                title: 'UPCOMING EVENTS',
                onViewAll: widget.onViewAllAssignments,
              ),
              ...upcoming.map(
                (a) => JudgeAssignmentCard(
                  assignment: a,
                  onTap: () => widget.onOpenAssignment(a),
                  actionLabel: 'Open Event',
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
