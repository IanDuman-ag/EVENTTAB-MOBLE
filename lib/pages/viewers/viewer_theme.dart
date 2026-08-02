import 'package:flutter/material.dart';

// Shared viewer palette (dark cyan intramurals look)
const viewerBg = Color(0xFF060A10);
const viewerCard = Color(0xFF0D1520);
const viewerBorder = Color(0xFF1C2A3A);
const viewerCyan = Color(0xFF00C5D9);
const viewerCyanLt = Color(0xFF7CE1EF);
const viewerOrange = Color(0xFFFF7A18);
const viewerMuted = Color(0xFF7A8494);
const viewerGreen = Color(0xFF2E9B4F);
const viewerRed = Color(0xFFE53935);

class ViewerHeader extends StatelessWidget {
  const ViewerHeader({
    super.key,
    this.title,
    this.showBell = false,
    this.notificationCount = 0,
    this.onNotifications,
    this.showBack = false,
    this.onBack,
  });

  final String? title;
  final bool showBell;
  final int notificationCount;
  final VoidCallback? onNotifications;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: viewerBorder)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          const Icon(Icons.emoji_events_outlined, color: viewerCyan, size: 20),
          const SizedBox(width: 8),
          Text(
            title ?? 'EVENT TAB',
            style: const TextStyle(
              color: viewerCyan,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          if (showBell)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: viewerRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class ViewerBottomNav extends StatelessWidget {
  const ViewerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: viewerBg,
        border: Border(top: BorderSide(color: viewerBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.home_rounded, 'HOME', 0),
              _item(Icons.sports_rounded, 'EVENTS', 1),
              _item(Icons.leaderboard_rounded, 'LEADERBOARD', 2),
              _item(Icons.more_horiz_rounded, 'MORE', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? viewerCyan : viewerMuted, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? viewerCyan : viewerMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 2,
            width: active ? 22 : 0,
            color: viewerCyan,
          ),
        ],
      ),
    );
  }
}

class ViewerStatusChip extends StatelessWidget {
  const ViewerStatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color color = viewerMuted;
    String label = status;
    if (s.contains('live') || s == 'ongoing' || s == 'active') {
      color = viewerRed;
      label = s == 'active' ? 'Live' : status[0].toUpperCase() + status.substring(1);
    } else if (s.contains('upcoming') || s.contains('schedul')) {
      color = viewerOrange;
    } else if (s.contains('complet')) {
      color = viewerGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
