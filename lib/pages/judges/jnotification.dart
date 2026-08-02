import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';
import 'judge_theme.dart';

/// Modern phone-style notification popup (bottom sheet).
Future<void> showJudgeNotifications(BuildContext context) {
  final scope = JudgeThemeScope.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final sheet = const _JudgeNotificationSheet();
      if (scope == null) return sheet;
      return JudgeThemeScope(
        isDark: scope.isDark,
        onToggle: scope.onToggle,
        child: sheet,
      );
    },
  );
}

class _Notif {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isUnread;

  const _Notif({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
  });

  factory _Notif.fromJson(Map<String, dynamic> j) {
    return _Notif(
      id: j['id']?.toString() ?? '',
      icon: _iconFromName(j['icon'] ?? ''),
      iconColor: _colorFromHex(j['icon_color'] ?? '#F5A900'),
      title: j['title'] ?? '',
      body: j['body'] ?? '',
      time: _formatTime(j['time'] ?? ''),
      isUnread: j['is_unread'] == true,
    );
  }

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'event_available':
        return Icons.event_available_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return judgeGold;
    }
  }

  static String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return iso;
    }
  }
}

class _JudgeNotificationSheet extends StatefulWidget {
  const _JudgeNotificationSheet();

  @override
  State<_JudgeNotificationSheet> createState() =>
      _JudgeNotificationSheetState();
}

class _JudgeNotificationSheetState extends State<_JudgeNotificationSheet> {
  List<_Notif> _items = [];
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
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.get(
        apiUri('/api/events/judge-notifications/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _items = list.map((j) => _Notif.fromJson(j as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load notifications.';
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    final c = JudgeThemeScope.paletteOf(context);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_items.isNotEmpty)
                  Text(
                    '${_items.length}',
                    style: const TextStyle(
                      color: judgeGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                TextButton(
                  onPressed: _isLoading ? null : _load,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(
                      color: judgeGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: c.muted),
                ),
              ],
            ),
          ),
          Divider(color: c.border, height: 1),
          Flexible(child: _body(c)),
        ],
      ),
    );
  }

  Widget _body(JudgePalette c) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: judgeGold)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: judgeGold,
                foregroundColor: judgeWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, color: c.muted, size: 48),
            const SizedBox(height: 12),
            Text(
              'No notifications yet.',
              style: TextStyle(
                color: c.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'New assignment alerts will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: judgeGold,
      onRefresh: _load,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _NotifCard(data: _items[index]),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.data});

  final _Notif data;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: data.isUnread
              ? judgeGold.withValues(alpha: 0.55)
              : c.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
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
                        data.title,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 13,
                          fontWeight:
                              data.isUnread ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (data.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: judgeGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (data.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.body,
                    style: TextStyle(color: c.muted, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  data.time,
                  style: TextStyle(
                    color: c.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for older navigation paths; opens the same popup.
class JNotificationPage extends StatelessWidget {
  const JNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showJudgeNotifications(context);
    });
    return Scaffold(
      backgroundColor: JudgeThemeScope.paletteOf(context).bg,
      body: const Center(child: CircularProgressIndicator(color: judgeGold)),
    );
  }
}
