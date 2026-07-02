import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/login.dart';
import '../auth/scorer_auth_service.dart';
import 'scorer_theme.dart';
import 'scorer_widgets.dart';
import 'scorerhome.dart';
import 'scorermyassignment.dart';
import 'scorerhistory.dart';
import 'scorerprofile.dart';
import 'scorerscores.dart';

class ScorerShell extends StatefulWidget {
  const ScorerShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ScorerShell> createState() => _ScorerShellState();
}

class _ScorerShellState extends State<ScorerShell> {
  late int _index;
  int _notificationCount = 0;
  final _assignmentsKey = GlobalKey<ScorerMyAssignmentsBodyState>();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  Future<void> _logout() async {
    await authService.logout();
    ScorerAuthSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _onNotificationCount(int count) {
    if (_notificationCount != count) {
      setState(() => _notificationCount = count);
    }
  }

  void _editMatch(Map<String, dynamic> match) async {
    final tab = await openScorerLiveScoring(
      context,
      match: match,
      onSaved: () {
        _assignmentsKey.currentState?.reload();
      },
    );
    if (!mounted) return;
    if (tab != null) {
      setState(() => _index = tab);
    }
    _assignmentsKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scorerBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ScorerPortalHeader(
              notificationCount: _notificationCount,
              onProfile: () => setState(() => _index = 3),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                ScorerHomeBody(
                  onViewAllAssignments: () => setState(() => _index = 1),
                  onEditMatch: _editMatch,
                  onNotificationCount: _onNotificationCount,
                ),
                ScorerMyAssignmentsBody(
                  key: _assignmentsKey,
                  onEditMatch: _editMatch,
                ),
                const ScorerHistoryBody(),
                ScorerProfileBody(
                  onLogout: _logout,
                  onGoToAssignments: () => setState(() => _index = 1),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ScorerBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
