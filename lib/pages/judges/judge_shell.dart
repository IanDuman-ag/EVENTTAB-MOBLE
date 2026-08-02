import 'package:flutter/material.dart';

import '../auth/judge_auth_service.dart';
import '../auth/login.dart';
import 'jassignment.dart';
import 'jhome.dart';
import 'jnotification.dart';
import 'jprofile.dart';
import 'judge_offline.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';
import 'jviewassignment.dart';

/// Judge app shell — Home / My Events / Profile (+ notification bell).
class JudgeShell extends StatefulWidget {
  const JudgeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<JudgeShell> createState() => _JudgeShellState();
}

class _JudgeShellState extends State<JudgeShell> {
  late int _index;
  int _notificationCount = 0;
  bool _isDark = false;
  String _syncStatus = 'Synced';

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 2);
    JudgeOfflineStore.instance.init();
    JudgeOfflineStore.instance.syncStatusStream.listen((s) {
      if (mounted) setState(() => _syncStatus = s);
    });
  }

  void _toggleTheme() => setState(() => _isDark = !_isDark);

  Future<void> _logout() async {
    await judgeAuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _goToProfile() => setState(() => _index = 2);

  void _onNotificationCount(int count) {
    if (_notificationCount != count) {
      setState(() => _notificationCount = count);
    }
  }

  Widget _themed(Widget child) {
    return JudgeThemeScope(
      isDark: _isDark,
      onToggle: _toggleTheme,
      child: child,
    );
  }

  bool get _showBell => _index == 0 || _index == 1;

  @override
  Widget build(BuildContext context) {
    final colors = _isDark ? JudgePalette.dark : JudgePalette.light;
    final offline = JudgeOfflineStore.instance.isOffline;

    return JudgeThemeScope(
      isDark: _isDark,
      onToggle: _toggleTheme,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (_showBell)
                    JudgePortalHeader(
                      notificationCount: _notificationCount,
                      isDark: _isDark,
                      onToggleTheme: _toggleTheme,
                      onProfile: _goToProfile,
                      onNotifications: () => showJudgeNotifications(context),
                    )
                  else
                    JudgePortalHeader(
                      notificationCount: 0,
                      isDark: _isDark,
                      onToggleTheme: _toggleTheme,
                      onProfile: null,
                      onNotifications: null,
                    ),
                  if (offline || _syncStatus != 'Synced')
                    Container(
                      width: double.infinity,
                      color: offline
                          ? const Color(0xFFE65100)
                          : (_syncStatus == 'Sync Failed'
                              ? judgeRed
                              : judgeGold),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        offline
                            ? 'Offline Mode — drafts saved locally ($_syncStatus)'
                            : 'Sync: $_syncStatus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
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
      ),
    );
  }

  void _openAssignment(Map<String, dynamic> assignment) {
    final eventId = assignment['judging_event_id'] as int?;
    if (eventId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _themed(
          JudgeViewAssignmentPage(judgingEventId: eventId),
        ),
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
