import 'package:flutter/material.dart';

import '../auth/judge_auth_service.dart';
import '../auth/login.dart';
import 'jassignment.dart';
import 'jhome.dart';
import 'jprofile.dart';
import 'jscorehistory.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';
import 'jviewassignment.dart';

/// Judge app shell with Dashboard / Assignments / History / Profile.
class JudgeShell extends StatefulWidget {
  const JudgeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<JudgeShell> createState() => _JudgeShellState();
}

class _JudgeShellState extends State<JudgeShell> {
  late int _index;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  Future<void> _logout() async {
    await judgeAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _goToProfile() => setState(() => _index = 3);

  void _onNotificationCount(int count) {
    if (_notificationCount != count) {
      setState(() => _notificationCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: judgeBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: JudgePortalHeader(
              notificationCount: _notificationCount,
              onProfile: _goToProfile,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                JudgeDashboardBody(
                  onViewAllAssignments: () => setState(() => _index = 1),
                  onOpenAssignment: _openAssignment,
                  onNotificationCount: _onNotificationCount,
                ),
                JudgeAssignmentsBody(onOpenAssignment: _openAssignment),
                const JudgeScoreHistoryPage(),
                JudgeProfileBody(onLogout: _logout),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: JudgeBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  void _openAssignment(Map<String, dynamic> assignment) {
    final eventId = assignment['judging_event_id'] as int?;
    if (eventId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JudgeViewAssignmentPage(judgingEventId: eventId),
      ),
    );
  }
}

/// Kept for backwards compatibility with login route name.
class JudgeHomePage extends StatelessWidget {
  const JudgeHomePage({super.key});

  @override
  Widget build(BuildContext context) => const JudgeShell();
}
