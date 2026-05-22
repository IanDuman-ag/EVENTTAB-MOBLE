import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'judge_auth_service.dart';
import 'judge_nav.dart';
import 'jevent_detail.dart';

// ─── colour palette ──────────────────────────────────────────────────────────
const _kBg = Color(0xFF0B0B12);
const _kCard = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kPurpleDark = Color(0xFF6B22D8);
const _kMuted = Color(0xFF7F7890);
const _kHero = Color(0xFF1A6B5A); // teal-ish hero matching image

// ─── category meta ───────────────────────────────────────────────────────────
const _categoryMeta = {
  'academic': (
    icon: Icons.school_rounded,
    color: Color(0xFF2196F3),
  ),
  'esports': (
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF9C27B0),
  ),
  'sports': (
    icon: Icons.sports_soccer_rounded,
    color: Color(0xFF4CAF50),
  ),
  'socio_cultural': (
    icon: Icons.theater_comedy_rounded,
    color: Color(0xFFE91E63),
  ),
};

// ─── JEventPage ──────────────────────────────────────────────────────────────
class JEventPage extends StatefulWidget {
  const JEventPage({super.key});

  @override
  State<JEventPage> createState() => _JEventPageState();
}

class _JEventPageState extends State<JEventPage> {
  List<dynamic> _categories = [];
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
        Uri.parse('http://127.0.0.1:8000/api/events/categories/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() { _categories = jsonDecode(res.body); _isLoading = false; });
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
            _JudgeHeader(),
            Expanded(child: _body()),
          ],
        ),
      ),
      bottomNavigationBar: _JudgeBottomNav(current: 1),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D5C4A), Color(0xFF1A8C6E)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DISCOVERY',
                    style: TextStyle(color: Color(0xFFB2EFE0), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Event\nCategories',
                    style: TextStyle(color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 12),
                Text('Navigate through specialized sectors of competition and engagement.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.all(20),
            child: _categories.isEmpty
                ? const Center(child: Text('No categories found.',
                    style: TextStyle(color: _kMuted)))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final meta = _categoryMeta[cat['category_type']] ??
                          (icon: Icons.event_rounded, color: _kPurple);
                      return _CategoryCard(
                        icon: meta.icon,
                        iconColor: meta.color,
                        title: cat['name'],
                        subtitle: cat['description'] ?? '',
                        eventCount: cat['event_count'] ?? 0,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JEventListPage(
                              categoryId: cat['id'],
                              categoryName: cat['name'],
                              categoryType: cat['category_type'],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.eventCount,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int eventCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _kMuted, fontSize: 11)),
              const Spacer(),
              if (eventCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text('$eventCount ACTIVE\nASSIGNED',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _kPurple, fontSize: 9,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── JEventListPage ───────────────────────────────────────────────────────────
class JEventListPage extends StatefulWidget {
  const JEventListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
  });

  final int categoryId;
  final String categoryName;
  final String categoryType;

  @override
  State<JEventListPage> createState() => _JEventListPageState();
}

class _JEventListPageState extends State<JEventListPage> {
  List<dynamic> _events = [];
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
        Uri.parse('http://127.0.0.1:8000/api/events/categories/${widget.categoryId}/events/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() { _events = jsonDecode(res.body); _isLoading = false; });
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[widget.categoryType] ??
        (icon: Icons.event_rounded, color: _kPurple);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _JudgeHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D5C4A), Color(0xFF1A8C6E)],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back_rounded,
                                    color: Color(0xFFB2EFE0), size: 18),
                                const SizedBox(width: 6),
                                const Text('CATEGORY',
                                    style: TextStyle(color: Color(0xFFB2EFE0),
                                        fontSize: 11, fontWeight: FontWeight.w700,
                                        letterSpacing: 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(widget.categoryName,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 34, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('Navigate through specialized sectors of competition and engagement.',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13, height: 1.5)),
                        ],
                      ),
                    ),
                    // Events list
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: _kPurple)),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: Colors.white70)),
                      )
                    else if (_events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('No events in this category.',
                            style: TextStyle(color: _kMuted))),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _events.map((ev) => _EventListCard(
                            event: ev,
                            categoryIcon: meta.icon,
                            categoryColor: meta.color,
                            onViewDetails: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JEventDetailPage(eventId: ev['id']),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _JudgeBottomNav(current: 1),
    );
  }
}

// ─── Event List Card ──────────────────────────────────────────────────────────
class _EventListCard extends StatelessWidget {
  const _EventListCard({
    required this.event,
    required this.categoryIcon,
    required this.categoryColor,
    required this.onViewDetails,
  });

  final Map<String, dynamic> event;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final date = event['date'] ?? '';
    final time = event['time'] ?? '';
    final venue = event['venue'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(event['title'] ?? '',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaChip(label: date),
              const SizedBox(width: 8),
              _MetaChip(label: time),
              const SizedBox(width: 8),
              _MetaChip(label: venue),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A62),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
              child: const Text('VIEW DETAILS'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: const TextStyle(color: _kMuted, fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 0.5));
  }
}

// ─── Shared Header ────────────────────────────────────────────────────────────
class _JudgeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A102D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: _kPurple, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('EVENTTAB',
              style: TextStyle(color: _kPurple, fontSize: 17,
                  fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _kPurple),
            onPressed: () {},
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A102D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPurple, width: 2),
            ),
            child: const Icon(Icons.person, color: _kPurple, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Bottom Nav ────────────────────────────────────────────────────────
class _JudgeBottomNav extends StatelessWidget {
  const _JudgeBottomNav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: current == 0,
                onTap: () {
                  if (current != 0) JudgeNav.toHome(context);
                },
              ),
              _NavItem(
                icon: Icons.event_rounded,
                label: 'Events',
                active: current == 1,
                onTap: () {
                  if (current != 1) JudgeNav.toEvents(context);
                },
              ),
              _NavItem(
                icon: Icons.star_rounded,
                label: 'Scoring',
                active: current == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _kPurple : const Color(0xFF5A5266);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
