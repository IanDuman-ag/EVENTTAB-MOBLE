import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';

const _kBg     = Color(0xFF0B0B12);
const _kCard   = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kMuted  = Color(0xFF7F7890);

// ─── Model ───────────────────────────────────────────────

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
      iconColor: _colorFromHex(j['icon_color'] ?? '#9F66FF'),
      title: j['title'] ?? '',
      body: j['body'] ?? '',
      time: _formatTime(j['time'] ?? ''),
      isUnread: j['is_unread'] == true,
    );
  }

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'event_available':   return Icons.event_available_rounded;
      case 'rocket_launch':     return Icons.rocket_launch_rounded;
      case 'lock':              return Icons.lock_rounded;
      case 'check_circle':      return Icons.check_circle_rounded;
      case 'info':              return Icons.info_rounded;
      default:                  return Icons.notifications_rounded;
    }
  }

  static Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _kPurple;
    }
  }

  static String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24)   return '${diff.inHours} hr ago';
      if (diff.inDays == 1)    return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Page ────────────────────────────────────────────────

class JNotificationPage extends StatefulWidget {
  const JNotificationPage({super.key});

  @override
  State<JNotificationPage> createState() => _JNotificationPageState();
}

class _JNotificationPageState extends State<JNotificationPage> {
  List<_Notif> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.get(
        apiUri('/api/events/judge-notifications/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _items = list.map((j) => _Notif.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kCard,
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _kPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Notifications',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Refresh',
                        style: TextStyle(color: _kPurple, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, color: _kMuted, size: 48),
            SizedBox(height: 12),
            Text('No notifications yet.',
                style: TextStyle(color: _kMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _NotifCard(data: _items[i]),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.data});
  final _Notif data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isUnread ? _kPurple.withValues(alpha: 0.07) : _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isUnread ? _kPurple.withValues(alpha: 0.3) : _kBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(data.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: data.isUnread
                                ? FontWeight.w800 : FontWeight.w600,
                          )),
                    ),
                    if (data.isUnread)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: _kPurple, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(data.body,
                    style: const TextStyle(color: _kMuted, fontSize: 12,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(data.time,
                    style: const TextStyle(color: _kMuted, fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
