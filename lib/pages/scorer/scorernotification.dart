import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';

/// Modern phone-style notification popup (bottom sheet).
Future<void> showScorerNotifications(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return const _ScorerNotificationSheet();
    },
  );
}

class _ScorerNotificationSheet extends StatefulWidget {
  const _ScorerNotificationSheet();

  @override
  State<_ScorerNotificationSheet> createState() =>
      _ScorerNotificationSheetState();
}

class _ScorerNotificationSheetState extends State<_ScorerNotificationSheet> {
  List<Map<String, dynamic>> _notifications = [];
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
        setState(() {
          _notifications = (data['notifications'] as List? ?? [])
              .cast<Map<String, dynamic>>();
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

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: scorerCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scorerBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: scorerNavy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_notifications.isNotEmpty)
                  Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      color: scorerGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: scorerMuted),
                ),
              ],
            ),
          ),
          const Divider(color: scorerBorder, height: 1),
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: scorerGold),
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: scorerMuted),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              style: FilledButton.styleFrom(
                                backgroundColor: scorerGold,
                                foregroundColor: scorerBg,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _notifications.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  color: scorerMuted,
                                  size: 40,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    color: scorerNavy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'New match assignments will show up here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: scorerMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: scorerGold,
                            onRefresh: _load,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _NotificationTile(
                                  notification: _notifications[index],
                                );
                              },
                            ),
                          ),
          ),
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
    final isUnread = notification['is_unread'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scorerBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? scorerGold.withValues(alpha: 0.55) : scorerBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scorerGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: scorerGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String? ?? '',
                  style: const TextStyle(
                    color: scorerNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if ((notification['body'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] as String,
                    style: const TextStyle(color: scorerMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            notification['time_display'] as String? ?? '',
            style: const TextStyle(color: scorerMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Kept for any older navigation paths; opens the same popup.
class ScorerNotificationPage extends StatelessWidget {
  const ScorerNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showScorerNotifications(context);
    });
    return const Scaffold(
      backgroundColor: scorerBg,
      body: Center(child: CircularProgressIndicator(color: scorerGold)),
    );
  }
}
