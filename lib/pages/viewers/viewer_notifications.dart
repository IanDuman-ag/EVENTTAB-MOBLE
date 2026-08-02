import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_event_detail.dart';
import 'viewer_leaderboard.dart';
import 'viewer_theme.dart';

class ViewerNotificationsPage extends StatefulWidget {
  const ViewerNotificationsPage({super.key});

  @override
  State<ViewerNotificationsPage> createState() => _ViewerNotificationsPageState();
}

class _ViewerNotificationsPageState extends State<ViewerNotificationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(
        apiUri('/api/events/viewer/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['notifications'] as List? ?? []);
        setState(() {
          _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Map<String, dynamic> n) {
    final ref = n['event_ref'];
    if (ref is Map) {
      final type = '${ref['type'] ?? ''}';
      if (type == 'leaderboard') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: viewerBg,
              body: SafeArea(
                child: Column(
                  children: [
                    ViewerHeader(
                      title: 'Leaderboard',
                      showBack: true,
                      onBack: () => Navigator.pop(context),
                    ),
                    const Expanded(child: ViewerLeaderboardBody()),
                  ],
                ),
              ),
            ),
          ),
        );
        return;
      }
      if (type == 'match' || type == 'criteria') {
        openViewerEvent(context, {
          'id': ref['id'],
          'source': ref['source'] ?? (type == 'criteria' ? 'judging' : 'bracket'),
          'event_type': type,
          'judging_event_id': type == 'criteria' ? ref['id'] : null,
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: 'Notifications',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: viewerCyan))
                  : _items.isEmpty
                      ? const Center(
                          child: Text('No notifications.',
                              style: TextStyle(color: viewerMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            final unread = n['is_unread'] == true;
                            return InkWell(
                              onTap: () => _open(n),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: viewerCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: unread ? viewerCyan : viewerBorder,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _iconFor('${n['type'] ?? ''}'),
                                      color: unread ? viewerCyan : viewerMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${n['title'] ?? 'Notification'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${n['body'] ?? ''}',
                                            style: const TextStyle(
                                              color: viewerMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${n['time_display'] ?? ''}',
                                            style: const TextStyle(
                                              color: viewerCyan,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'live':
        return Icons.sensors;
      case 'result':
        return Icons.sports_score_outlined;
      case 'leaderboard':
        return Icons.leaderboard_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
