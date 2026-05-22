import 'package:flutter/material.dart';

import 'bracket.dart';
import 'home.dart';
import 'profile.dart';
import 'rankings.dart';
import 'schedule.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  static const List<_TeamCardData> _teams = [
    _TeamCardData(
      name: 'Nova Squad',
      rank: '#01',
      winRate: '92%',
      accentColor: Color(0xFFFF7A18),
      logo: 'NS',
      logoIcon: Icons.auto_awesome,
      franchiseLabel: 'S-TIER FRANCHISE • EST. 2022',
      category: 'Cheer',
      seasonRecord: '15W / 3L',
      standings: '#01',
      trend: [
        _TrendPoint(label: 'WIN', value: 0.78, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'WIN', value: 0.92, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'LOSS', value: 0.60, color: Color(0xFFFF7A18)),
        _TrendPoint(label: 'WIN', value: 0.86, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'WIN', value: 0.82, color: Color(0xFF7CE1EF)),
      ],
      achievements: [
        _AchievementData(
          title: 'Pro League Champions 2025',
          subtitle: 'SEASON 14 • GLOBAL FINALS',
          icon: Icons.emoji_events,
          iconColor: Color(0xFFB7FF00),
          backgroundColor: Color(0xFF202711),
        ),
        _AchievementData(
          title: 'Continental Masters Runner-Up',
          subtitle: 'EMEA REGIONAL 2024',
          icon: Icons.military_tech,
          iconColor: Color(0xFFFF7A18),
          backgroundColor: Color(0xFF241810),
        ),
      ],
    ),
    _TeamCardData(
      name: 'Neon Vanguard',
      rank: '#04',
      winRate: '68%',
      accentColor: Color(0xFF7CE1EF),
      logo: 'NV',
      logoIcon: Icons.shield_outlined,
      franchiseLabel: 'TACTICAL DIVISION • EST. 2021',
      category: 'Valorant',
      seasonRecord: '11W / 7L',
      standings: '#04',
      trend: [
        _TrendPoint(label: 'WIN', value: 0.65, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'LOSS', value: 0.44, color: Color(0xFFFF7A18)),
        _TrendPoint(label: 'WIN', value: 0.74, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'LOSS', value: 0.38, color: Color(0xFFFF7A18)),
        _TrendPoint(label: 'WIN', value: 0.69, color: Color(0xFF7CE1EF)),
      ],
      achievements: [
        _AchievementData(
          title: 'Pacific Showdown Champion',
          subtitle: 'IN-SEASON CUP 2025',
          icon: Icons.bolt,
          iconColor: Color(0xFF7CE1EF),
          backgroundColor: Color(0xFF10242A),
        ),
        _AchievementData(
          title: 'Regional Finals Semi-Finalist',
          subtitle: 'SPRING CIRCUIT 2024',
          icon: Icons.shield_outlined,
          iconColor: Color(0xFF8EDDF0),
          backgroundColor: Color(0xFF101A20),
        ),
      ],
    ),
    _TeamCardData(
      name: 'Apex Predators',
      rank: '#07',
      winRate: '84%',
      accentColor: Color(0xFF6E7177),
      logo: 'AP',
      logoIcon: Icons.pets_outlined,
      franchiseLabel: 'POWERHOUSE UNIT • EST. 2019',
      category: 'Basketball',
      seasonRecord: '13W / 5L',
      standings: '#07',
      trend: [
        _TrendPoint(label: 'WIN', value: 0.88, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'WIN', value: 0.76, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'WIN', value: 0.71, color: Color(0xFF7CE1EF)),
        _TrendPoint(label: 'LOSS', value: 0.52, color: Color(0xFFFF7A18)),
        _TrendPoint(label: 'WIN', value: 0.83, color: Color(0xFF7CE1EF)),
      ],
      achievements: [
        _AchievementData(
          title: 'National Cup Winner',
          subtitle: 'PLAYOFF RUN 2025',
          icon: Icons.workspace_premium,
          iconColor: Color(0xFFB7FF00),
          backgroundColor: Color(0xFF1B2211),
        ),
        _AchievementData(
          title: 'Elite Invitational Top 4',
          subtitle: 'SUMMER CLASSIC 2024',
          icon: Icons.stars,
          iconColor: Color(0xFFFF7A18),
          backgroundColor: Color(0xFF241910),
        ),
      ],
    ),
  ];

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEPARTMENT\nTEAMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ..._teams.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _teams.length - 1 ? 0 : 40,
                        ),
                        child: _TeamListCard(team: team),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        activeLabel: 'TEAMS',
        onNavigate: (page) => _navigateToPage(context, page),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2128), width: 1)),
        color: Color(0xFF0A0B0D),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF12141A),
                border: Border.all(color: const Color(0xFF00C5D9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFFFFB083),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'EVENT TAB',
            style: TextStyle(
              color: Color(0xFF00C5D9),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
            color: const Color(0xFF8B8D91),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _TeamListCard extends StatelessWidget {
  const _TeamListCard({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: team.accentColor, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF14161B),
          border: Border.all(color: const Color(0xFF1E2128)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF090B0E),
                border: Border.all(color: const Color(0xFF23262D)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(team.logoIcon, color: team.accentColor, size: 24),
                  Positioned(
                    bottom: 4,
                    child: Text(
                      team.logo,
                      style: TextStyle(
                        color: team.accentColor.withValues(alpha: 0.8),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'RANK ${team.rank}',
                        style: const TextStyle(
                          color: Color(0xFFFF7A18),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${team.winRate} WIN RATE',
                        style: const TextStyle(
                          color: Color(0xFF7CE1EF),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TeamDetailsPage(team: team),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                side: const BorderSide(color: Color(0xFF5EBFD0)),
                shape: const RoundedRectangleBorder(),
                foregroundColor: const Color(0xFF9CEAF4),
                textStyle: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              child: const Text('VIEW DETAILS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamDetailsPage extends StatelessWidget {
  const _TeamDetailsPage({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF139AF3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamDetailsHeader(team: team),
                _TeamHero(team: team),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _StatsGrid(team: team),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: _TrendSection(team: team),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                  child: _AchievementsSection(team: team),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamDetailsHeader extends StatelessWidget {
  const _TeamDetailsHeader({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.menu, color: Color(0xFF00C5D9)),
            splashRadius: 20,
            tooltip: 'Back',
          ),
          const Text(
            'EVENT TAB',
            style: TextStyle(
              color: Color(0xFF00C5D9),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF12141A),
              border: Border.all(
                color: team.accentColor.withValues(alpha: 0.6),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(team.logoIcon, color: team.accentColor, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF090A0C)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.8),
                  radius: 1.15,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -12,
            top: 8,
            child: Transform.rotate(
              angle: -0.85,
              child: Container(width: 3, height: 185, color: Colors.white70),
            ),
          ),
          Positioned(
            right: -8,
            top: 6,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(width: 3, height: 185, color: Colors.white70),
            ),
          ),
          Positioned(
            left: 16,
            top: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB3122E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 6),
                  const SizedBox(width: 6),
                  Text(
                    team.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.logo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.franchiseLabel,
                  style: TextStyle(
                    color: const Color(0xFF7CE1EF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF10161B),
                  border: Border.all(
                    color: team.accentColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Transform.rotate(
                  angle: -0.8,
                  child: Icon(team.logoIcon, color: team.accentColor, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: 30,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7CE1EF), Color(0xFF3BC3DA)],
                  ),
                ),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF061014),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text(
                    'CHEER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(
              label: 'SEASON RECORD',
              value: team.seasonRecord,
              accentColor: const Color(0xFF7CE1EF),
              isFilled: true,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'WIN RATE',
              value: team.winRate,
              accentColor: const Color(0xFFFF7A18),
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'STANDINGS',
              value: team.standings,
              accentColor: Colors.white,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accentColor,
    this.isFilled = false,
  });

  final String label;
  final String value;
  final Color accentColor;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF121417),
          border: Border(
            left: BorderSide(
              color: isFilled ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B9096),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'PERFORMANCE TREND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Text(
              'LAST ${team.trend.length} MATCHES',
              style: const TextStyle(
                color: Color(0xFF7CE1EF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          color: const Color(0xFF111315),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: team.trend
                .map((point) => Expanded(child: _TrendBar(point: point)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.point});

  final _TrendPoint point;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 56 * point.value,
            decoration: BoxDecoration(color: point.color),
          ),
          const SizedBox(height: 10),
          Text(
            point.label,
            style: const TextStyle(
              color: Color(0xFF8A8F96),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.team});

  final _TeamCardData team;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...team.achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AchievementCard(achievement: achievement),
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final _AchievementData achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131416),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: achievement.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A8F96),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activeLabel, required this.onNavigate});

  final String activeLabel;
  final ValueChanged<Widget> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0B0D),
        border: Border(top: BorderSide(color: Color(0xFF1E2128), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'HOME',
                isActive: activeLabel == 'HOME',
                onTap: () {
                  onNavigate(const HomePage());
                },
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                label: 'RANKINGS',
                isActive: activeLabel == 'RANKINGS',
                onTap: () {
                  onNavigate(const RankingsPage());
                },
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'SCHEDULE',
                isActive: activeLabel == 'SCHEDULE',
                onTap: () {
                  onNavigate(const SchedulePage());
                },
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'TEAMS',
                isActive: activeLabel == 'TEAMS',
              ),
              _NavItem(
                icon: Icons.account_tree_outlined,
                label: 'BRACKET',
                isActive: activeLabel == 'BRACKET',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BracketPage()),
                  );
                },
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF00C5D9) : const Color(0xFF4A4C50),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF00C5D9)
                  : const Color(0xFF4A4C50),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCardData {
  const _TeamCardData({
    required this.name,
    required this.rank,
    required this.winRate,
    required this.accentColor,
    required this.logo,
    required this.logoIcon,
    required this.franchiseLabel,
    required this.category,
    required this.seasonRecord,
    required this.standings,
    required this.trend,
    required this.achievements,
  });

  final String name;
  final String rank;
  final String winRate;
  final Color accentColor;
  final String logo;
  final IconData logoIcon;
  final String franchiseLabel;
  final String category;
  final String seasonRecord;
  final String standings;
  final List<_TrendPoint> trend;
  final List<_AchievementData> achievements;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _AchievementData {
  const _AchievementData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}
