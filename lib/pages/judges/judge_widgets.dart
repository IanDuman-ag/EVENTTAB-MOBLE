import 'package:flutter/material.dart';

import 'judge_theme.dart';

class JudgePortalHeader extends StatelessWidget {
  const JudgePortalHeader({
    super.key,
    this.notificationCount = 0,
    this.onNotifications,
    this.onProfile,
    this.showBack = false,
    this.onBack,
  });

  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: judgeCard,
        border: Border(bottom: BorderSide(color: judgeBorder)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: judgeCyan, size: 20),
            )
          else
            Image.asset('assets/Finallogo.png', width: 32, height: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVENTTAB',
                  style: TextStyle(
                    color: judgeCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'JUDGE PORTAL',
                  style: TextStyle(
                    color: judgeMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: judgeRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A102D),
              child: const Icon(Icons.person, color: judgePurple, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class JudgeSectionHeader extends StatelessWidget {
  const JudgeSectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: judgeCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All >',
                style: TextStyle(
                  color: judgeMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class JudgeStatTile extends StatelessWidget {
  const JudgeStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: judgeCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: judgeBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: judgeCyan, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: judgeMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JudgeStatusBadge extends StatelessWidget {
  const JudgeStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = judgeStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class JudgeAssignmentCard extends StatelessWidget {
  const JudgeAssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
    this.showCriteria = false,
    this.actionLabel,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onTap;
  final bool showCriteria;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final status = assignment['status'] as String? ?? 'upcoming';
    final categoryIcon =
        judgeCategoryIcon(assignment['category_icon'] as String?);
    final categoryLabel =
        assignment['category_label'] as String? ?? 'EVENT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Material(
        color: judgeCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: judgeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: judgePurple.withValues(alpha: 0.2),
                          child: Icon(categoryIcon, color: judgePurple),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          categoryLabel,
                          style: const TextStyle(
                            color: judgeMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: judgePurple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  (assignment['assignment_type'] as String? ??
                                          'EVENT')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: judgePurple,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              JudgeStatusBadge(status: status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            assignment['title'] as String? ?? 'Event',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if ((assignment['subtitle'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 4),
                            Text(
                              assignment['subtitle'] as String,
                              style: const TextStyle(
                                color: judgeMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.calendar_today_rounded,
                            text: assignment['date_display'] as String? ?? '',
                          ),
                          const SizedBox(height: 4),
                          _MetaRow(
                            icon: Icons.access_time_rounded,
                            text: assignment['time_display'] as String? ?? '',
                          ),
                          const SizedBox(height: 4),
                          _MetaRow(
                            icon: Icons.location_on_outlined,
                            text: assignment['venue'] as String? ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1520),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${assignment['participant_count'] ?? 0} ${assignment['participant_label'] ?? 'Participants'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${assignment['criteria_count'] ?? 0} Criteria',
                        style: const TextStyle(
                          color: judgeMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: judgeCyan,
                        foregroundColor: judgeBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
                if (showCriteria &&
                    (assignment['criteria_names'] as List?)?.isNotEmpty ==
                        true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Criteria: ${(assignment['criteria_names'] as List).join(', ')}',
                    style: const TextStyle(
                      color: judgeMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 13, color: judgeMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: judgeMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class JudgeBottomNav extends StatelessWidget {
  const JudgeBottomNav({
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
        color: judgeCard,
        border: Border(top: BorderSide(color: judgeBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.assignment_rounded,
                label: 'Assignments',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? judgeCyan : judgeMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
