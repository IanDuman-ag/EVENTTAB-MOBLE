import 'package:flutter/material.dart';

import 'home.dart';
import 'profile.dart';
import 'rankings.dart';
import 'schedule.dart';
import 'teams.dart';

class BracketPage extends StatefulWidget {
  const BracketPage({super.key});

  @override
  State<BracketPage> createState() => _BracketPageState();
}

class _BracketPageState extends State<BracketPage> {
  static const List<String> _categories = ['MEN', 'WOMEN', 'MIXED', 'OPEN'];

  static const List<_BracketSportCardData> _sports = [
    _BracketSportCardData(
      name: 'SOCCER',
      accentColor: Color(0xFF7CE1EF),
      icon: Icons.sports_soccer,
      isPrimary: true,
    ),
    _BracketSportCardData(
      name: 'MOBILE LEGEND',
      accentColor: Color(0xFFFF7A18),
      icon: Icons.sports_esports,
    ),
    _BracketSportCardData(
      name: 'TENNIS',
      accentColor: Color(0xFF7CE1EF),
      icon: Icons.sports_tennis,
    ),
    _BracketSportCardData(
      name: 'VOLLEYBALL',
      accentColor: Color(0xFFFF7A18),
      icon: Icons.sports_volleyball,
    ),
  ];

  String? _selectedCategory;

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openCategoryFilter() async {
    final selectedCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF14161B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECT CATEGORY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a category first before opening the event bracket.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ..._categories.map((category) {
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      tileColor: const Color(0xFF1A1D24),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF00C5D9)
                              : const Color(0xFF2A2D34),
                        ),
                      ),
                      title: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF00C5D9),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF76787F),
                            ),
                      onTap: () {
                        Navigator.of(context).pop(category);
                      },
                    ),
                  );
                }),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop('');
                    },
                    child: const Text(
                      'CLEAR CATEGORY',
                      style: TextStyle(
                        color: Color(0xFFFF7A18),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedCategory == null) {
      return;
    }

    setState(() {
      _selectedCategory = selectedCategory.isEmpty ? null : selectedCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            const _BracketHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 28, 8, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0),
                      child: Text(
                        'COMPETITIVE ECOSYSTEM',
                        style: TextStyle(
                          color: Color(0xFFFF7A18),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SELECT SPORT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      color: const Color(0xFF7CE1EF),
                    ),
                    const SizedBox(height: 18),
                    _CategoryFilterBar(
                      selectedCategory: _selectedCategory,
                      onTap: _openCategoryFilter,
                    ),
                    const SizedBox(height: 28),
                    if (_selectedCategory == null)
                      const _CategoryRequiredPanel()
                    else ...[
                      _SelectedCategoryBanner(category: _selectedCategory!),
                      const SizedBox(height: 18),
                      _FeaturedBracketCard(category: _selectedCategory!),
                      const SizedBox(height: 26),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sports.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 18,
                              mainAxisExtent: 128,
                            ),
                        itemBuilder: (context, index) {
                          return _BracketSportCard(team: _sports[index]);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        activeLabel: 'BRACKET',
        onNavigate: (page) => _navigateToPage(context, page),
      ),
    );
  }
}

class _BracketHeader extends StatelessWidget {
  const _BracketHeader();

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

class _FeaturedBracketCard extends StatelessWidget {
  const _FeaturedBracketCard({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFFF7A18), width: 4)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        height: 142,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1E2128)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A252B), Color(0xFF0E1216)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFF7CE1EF).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 6,
              bottom: 8,
              child: Icon(
                Icons.sports_basketball,
                size: 108,
                color: const Color(0xFF7CE1EF).withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 12,
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: const Color(0xFF7CE1EF),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BRACKET',
                          style: TextStyle(
                            color: Color(0xFF061014),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 10,
                          color: Color(0xFF061014),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BASKETBALL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$category PRO LEAGUE ACTIVE',
                    style: const TextStyle(
                      color: Color(0xFF00C5D9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketSportCard extends StatelessWidget {
  const _BracketSportCard({required this.team});

  final _BracketSportCardData team;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF17191D),
        border: Border(bottom: BorderSide(color: team.accentColor, width: 1.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(team.icon, color: team.accentColor, size: 24),
            const SizedBox(height: 10),
            Text(
              team.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: team.isPrimary
                  ? DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7CE1EF), Color(0xFF4CBBD1)],
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF061014),
                          shape: const RoundedRectangleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'BRACKET',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: team.accentColor),
                        shape: const RoundedRectangleBorder(),
                        foregroundColor: team.accentColor,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                      child: Text('BRACKET'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onTap,
  });

  final String? selectedCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF14161B),
              border: Border.all(color: const Color(0xFF242831)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFF00C5D9), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CATEGORY FILTER',
                        style: TextStyle(
                          color: Color(0xFF76787F),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCategory ??
                            'Select a category to unlock brackets',
                        style: TextStyle(
                          color: selectedCategory == null
                              ? Colors.white.withValues(alpha: 0.72)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00C5D9)),
              shape: const RoundedRectangleBorder(),
              foregroundColor: const Color(0xFF7CE1EF),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text(
              'FILTER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRequiredPanel extends StatelessWidget {
  const _CategoryRequiredPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        border: Border.all(color: const Color(0xFF242831)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_outlined,
            color: const Color(0xFF00C5D9).withValues(alpha: 0.9),
            size: 42,
          ),
          const SizedBox(height: 14),
          const Text(
            'SELECT A CATEGORY FIRST',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the filter button above before viewing the event bracket and sport options.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCategoryBanner extends StatelessWidget {
  const _SelectedCategoryBanner({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00C5D9).withValues(alpha: 0.14),
            const Color(0xFFFF7A18).withValues(alpha: 0.09),
          ],
        ),
        border: Border.all(color: const Color(0xFF242831)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: Color(0xFF00C5D9),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing brackets for $category category',
              style: const TextStyle(
                color: Colors.white,
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
                onTap: () {
                  onNavigate(const TeamsPage());
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'BRACKET',
                isActive: activeLabel == 'BRACKET',
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
            size: 22,
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

class _BracketSportCardData {
  const _BracketSportCardData({
    required this.name,
    required this.accentColor,
    required this.icon,
    this.isPrimary = false,
  });

  final String name;
  final Color accentColor;
  final IconData icon;
  final bool isPrimary;
}
