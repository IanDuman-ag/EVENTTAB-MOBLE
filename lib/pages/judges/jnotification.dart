import 'package:flutter/material.dart';

const _kBg = Color(0xFF0B0B12);
const _kCard = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kMuted = Color(0xFF7F7890);

class JNotificationPage extends StatelessWidget {
  const JNotificationPage({super.key});

  static final List<_NotifData> _items = [
    _NotifData(
      icon: Icons.event_available_rounded,
      iconColor: Color(0xFF0D7A62),
      title: 'New Event Assigned',
      body: 'You have been assigned to judge "Mr. & Ms. USTP 2026".',
      time: '2 min ago',
      isUnread: true,
    ),
    _NotifData(
      icon: Icons.lock_rounded,
      iconColor: Color(0xFF9F66FF),
      title: 'Score Locked',
      body: 'Your scores for Candidate #1 (Leborn James) have been locked.',
      time: '1 hr ago',
      isUnread: true,
    ),
    _NotifData(
      icon: Icons.info_rounded,
      iconColor: Color(0xFF2196F3),
      title: 'Event Reminder',
      body: 'Modern Dance Competition starts in 30 minutes.',
      time: '3 hr ago',
      isUnread: false,
    ),
    _NotifData(
      icon: Icons.check_circle_rounded,
      iconColor: Color(0xFF4CAF50),
      title: 'Submission Confirmed',
      body: 'Your scores for Academic Quiz Bowl 2026 were submitted successfully.',
      time: 'Yesterday',
      isUnread: false,
    ),
  ];

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
                    onPressed: () {},
                    child: const Text('Mark all read',
                        style: TextStyle(color: _kPurple, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _NotifCard(data: _items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifData {
  const _NotifData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isUnread;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.data});
  final _NotifData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isUnread
            ? _kPurple.withValues(alpha: 0.07)
            : _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.isUnread
              ? _kPurple.withValues(alpha: 0.3)
              : _kBorder,
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
                                ? FontWeight.w800
                                : FontWeight.w600,
                          )),
                    ),
                    if (data.isUnread)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: _kPurple,
                          shape: BoxShape.circle,
                        ),
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
