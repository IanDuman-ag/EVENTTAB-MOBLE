import 'package:flutter/material.dart';

import 'judge_theme.dart';

class JudgePortalHeader extends StatelessWidget {
  const JudgePortalHeader({
    super.key,
    this.notificationCount = 0,
    this.onNotifications,
    this.onProfile,
    this.onToggleTheme,
    this.isDark = false,
    this.showBack = false,
    this.onBack,
  });

  final int notificationCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.headerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: c.text, size: 20),
                )
              else
                Image.asset('assets/Finallogo.png', width: 34, height: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EVENTTAB',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Text(
                      'JUDGE PORTAL',
                      style: TextStyle(
                        color: judgeGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleTheme != null) ...[
                GestureDetector(
                  onTap: onToggleTheme,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: c.text,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onNotifications != null)
                GestureDetector(
                  onTap: onNotifications,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          color: c.text, size: 26),
                      if (notificationCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: judgeGold,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: judgeWhite,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onProfile,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: c.isDark ? judgeGold : judgeNavy,
                  child: Icon(
                    Icons.person,
                    color: c.isDark ? judgeNavy : judgeWhite,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 2, color: judgeGold.withValues(alpha: 0.55)),
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
    final c = JudgeThemeScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: c.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 42,
                height: 3,
                decoration: BoxDecoration(
                  color: judgeGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: const Text(
                'View All →',
                style: TextStyle(
                  color: judgeGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class JudgeInfoCard extends StatelessWidget {
  const JudgeInfoCard({
    super.key,
    required this.label,
    required this.message,
    required this.watermarkIcon,
    this.onViewAll,
  });

  final String label;
  final String message;
  final IconData watermarkIcon;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              bottom: -6,
              child: Icon(
                watermarkIcon,
                size: 72,
                color: c.text.withValues(alpha: 0.06),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: judgeGold),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: judgeGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: judgeGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View All →',
                        style: TextStyle(
                          color: judgeGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -14,
              child: Icon(
                Icons.waves_rounded,
                size: 48,
                color: color.withValues(alpha: 0.12),
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
    final c = JudgeThemeScope.paletteOf(context);
    final status = assignment['status'] as String? ?? 'upcoming';
    final categoryIcon =
        judgeCategoryIcon(assignment['category_icon'] as String?);
    final categoryLabel =
        assignment['category_label'] as String? ?? 'EVENT';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: judgeGold),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        judgeGold.withValues(alpha: 0.14),
                                    child: Icon(categoryIcon,
                                        color: judgeGold, size: 20),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: judgeGold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      categoryLabel.toUpperCase(),
                                      style: const TextStyle(
                                        color: judgeGold,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: c.text.withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (assignment['assignment_type']
                                                        as String? ??
                                                    'CRITERIA BASED')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: c.text,
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
                                      style: TextStyle(
                                        color: c.text,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if ((assignment['subtitle'] as String?)
                                            ?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        assignment['subtitle'] as String,
                                        style: TextStyle(
                                          color: c.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    _MetaRow(
                                      icon: Icons.calendar_today_rounded,
                                      text: assignment['date_display']
                                              as String? ??
                                          '',
                                    ),
                                    const SizedBox(height: 4),
                                    _MetaRow(
                                      icon: Icons.access_time_rounded,
                                      text: assignment['time_display']
                                              as String? ??
                                          '',
                                    ),
                                    const SizedBox(height: 4),
                                    _MetaRow(
                                      icon: Icons.location_on_outlined,
                                      text:
                                          assignment['venue'] as String? ?? '',
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
                              color: c.chip,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${assignment['participant_count'] ?? 0} ${assignment['participant_label'] ?? 'Participants'}',
                                  style: TextStyle(
                                    color: c.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${assignment['criteria_count'] ?? 0} Criteria',
                                  style: const TextStyle(
                                    color: judgeGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                                  backgroundColor: judgeGold,
                                  foregroundColor: judgeWhite,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                              (assignment['criteria_names'] as List?)
                                      ?.isNotEmpty ==
                                  true) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Criteria: ${(assignment['criteria_names'] as List).join(', ')}',
                              style: TextStyle(
                                color: c.muted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    final c = JudgeThemeScope.paletteOf(context);
    return Row(
      children: [
        Icon(icon, size: 13, color: c.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: c.muted, fontSize: 12),
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
    final c = JudgeThemeScope.paletteOf(context);
    return Container(
      decoration: BoxDecoration(
        color: c.headerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.4 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.event_note_rounded,
                label: 'My Events',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
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
    final c = JudgeThemeScope.paletteOf(context);
    final color = isActive ? judgeGold : c.text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? judgeGold.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: 3),
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: judgeGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
