import 'package:flutter/material.dart';

import 'viewer_events.dart';
import 'viewer_home.dart';
import 'viewer_leaderboard.dart';
import 'viewer_more.dart';
import 'viewer_notifications.dart';
import 'viewer_theme.dart';

/// Viewer app shell — Home / Events / Leaderboard / More.
class ViewerShell extends StatefulWidget {
  const ViewerShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ViewerShell> createState() => _ViewerShellState();
}

class _ViewerShellState extends State<ViewerShell> {
  late int _index;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
  }

  void _onNotifCount(int n) {
    if (_notificationCount != n) setState(() => _notificationCount = n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              showBell: _index == 0,
              notificationCount: _notificationCount,
              onNotifications: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ViewerNotificationsPage(),
                  ),
                );
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  ViewerHomeBody(
                    onOpenEvents: () => setState(() => _index = 1),
                    onOpenLeaderboard: () => setState(() => _index = 2),
                    onNotificationCount: _onNotifCount,
                  ),
                  const ViewerEventsBody(),
                  const ViewerLeaderboardBody(),
                  const ViewerMoreBody(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ViewerBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Guest / viewer entry used by login "Continue as Guest".
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const ViewerShell();
}
