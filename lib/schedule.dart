import 'package:flutter/material.dart';

import 'bracket.dart';
import 'teams.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _selectedDateIndex = 0;

  static const List<_ScheduleDate> _dates = [
    _ScheduleDate(month: 'OCT', day: '24'),
    _ScheduleDate(month: 'OCT', day: '25'),
    _ScheduleDate(month: 'OCT', day: '26'),
    _ScheduleDate(month: 'OCT', day: '27'),
    _ScheduleDate(month: 'OCT', day: '28'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0D),
      body: SafeArea(
        child: Column(
          children: [
            const _ScheduleHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THE DIGITAL ARENA',
                      style: TextStyle(
                        color: Color(0xFFFF7A18),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SCHEDULE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DateSelector(
                      dates: _dates,
                      selectedIndex: _selectedDateIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedDateIndex = index;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    const _LiveMatchCard(),
                    const SizedBox(height: 18),
                    const _ScheduledMatchCard(
                      time: '18:00',
                      arena: 'STANDARD ARENA',
                      teamA: 'THRESHER',
                      teamB: 'RONIN',
                      iconA: Icons.shield_outlined,
                      iconB: Icons.security_outlined,
                    ),
                    const SizedBox(height: 14),
                    const _ScheduledMatchCard(
                      time: '20:30',
                      arena: 'STANDARD ARENA',
                      teamA: 'CYBER EAGLES',
                      teamB: 'VELOCITY',
                      iconA: Icons.shield_outlined,
                      iconB: Icons.speed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(activeLabel: 'SCHEDULE'),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF080A0D),
        border: Border(
          bottom: BorderSide(color: Color(0xFF00C5D9), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF12141A),
              border: Border.all(color: const Color(0xFF00C5D9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Color(0xFFFFB083), size: 20),
          ),
          const SizedBox(width: 10),
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
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF8B8D91),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.dates,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ScheduleDate> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(dates.length, (index) {
        final date = dates[index];
        final isSelected = index == selectedIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == dates.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 64,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7CE1EF)
                      : const Color(0xFF14171E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7CE1EF)
                        : const Color(0xFF1F232C),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.month,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF061014)
                            : const Color(0xFF76787F),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF061014)
                            : const Color(0xFFE8E8E8),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  const _LiveMatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFFF7A18), width: 4)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11141B),
          border: Border.all(color: const Color(0xFF1E222B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _LiveBadge(),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GRAND FINALS - MAP 5',
                    style: TextStyle(
                      color: Color(0xFF8B8D91),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Text(
                  '24:40 REMAINING',
                  style: TextStyle(
                    color: Color(0xFF00C5D9),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: _TeamBlock(
                    icon: Icons.shield_outlined,
                    name: 'PHOENIX ELITE',
                  ),
                ),
                _ScoreBlock(score: '2:1', label: 'QUARTER 3'),
                Expanded(
                  child: _TeamBlock(
                    icon: Icons.sports_basketball,
                    name: 'IRON WOLVES',
                    accent: Color(0xFFFFD45E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF76787F),
                  size: 13,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'CYBER STADIUM, SEOUL',
                    style: TextStyle(
                      color: Color(0xFF76787F),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF7CE1EF),
                      foregroundColor: const Color(0xFF061014),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'WATCH LIVE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
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

class _ScheduledMatchCard extends StatelessWidget {
  const _ScheduledMatchCard({
    required this.time,
    required this.arena,
    required this.teamA,
    required this.teamB,
    required this.iconA,
    required this.iconB,
  });

  final String time;
  final String arena;
  final String teamA;
  final String teamB;
  final IconData iconA;
  final IconData iconB;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11141B),
        border: Border.all(color: const Color(0xFF1E222B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'LOCAL TIME',
                    style: TextStyle(
                      color: Color(0xFF76787F),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arena,
                    style: const TextStyle(
                      color: Color(0xFF76787F),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C5D9).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF00C5D9)),
                    ),
                    child: const Text(
                      'REMIND ME',
                      style: TextStyle(
                        color: Color(0xFF7CE1EF),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SmallTeam(icon: iconA, name: teamA),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Color(0xFF76787F),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: _SmallTeam(icon: iconB, name: teamB),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({
    required this.icon,
    required this.name,
    this.accent = const Color(0xFF7CE1EF),
  });

  final IconData icon;
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent),
          ),
          child: Icon(icon, color: accent, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _SmallTeam extends StatelessWidget {
  const _SmallTeam({required this.icon, required this.name});

  final IconData icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            border: Border.all(color: const Color(0xFF2B303B)),
          ),
          child: Icon(icon, color: const Color(0xFF9BA0A9), size: 19),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.score, required this.label});

  final String score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF7A18),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activeLabel});

  final String activeLabel;

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
              _NavItem(icon: Icons.home, label: 'HOME', isActive: false),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                label: 'RANKINGS',
                isActive: false,
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'SCHEDULE',
                isActive: activeLabel == 'SCHEDULE',
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'TEAMS',
                isActive: false,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const TeamsPage()));
                },
              ),
              _NavItem(
                icon: Icons.account_tree_outlined,
                label: 'BRACKET',
                isActive: false,
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
            size: 23,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF00C5D9)
                  : const Color(0xFF4A4C50),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDate {
  const _ScheduleDate({required this.month, required this.day});

  final String month;
  final String day;
}
