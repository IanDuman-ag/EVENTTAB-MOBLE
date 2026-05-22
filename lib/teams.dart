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
    ),
    _TeamCardData(
      name: 'Neon Vanguard',
      rank: '#04',
      winRate: '68%',
      accentColor: Color(0xFF7CE1EF),
      logo: 'NV',
      logoIcon: Icons.shield_outlined,
    ),
    _TeamCardData(
      name: 'Apex Predators',
      rank: '#07',
      winRate: '84%',
      accentColor: Color(0xFF6E7177),
      logo: 'AP',
      logoIcon: Icons.pets_outlined,
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
              onPressed: () {},
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
  });

  final String name;
  final String rank;
  final String winRate;
  final Color accentColor;
  final String logo;
  final IconData logoIcon;
}
