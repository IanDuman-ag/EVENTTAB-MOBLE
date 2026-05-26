import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';
import 'jevent.dart';
import 'jprofile.dart';
import '../auth/judge_auth_service.dart';

const _categoryMeta = {
  'academic':       (icon: Icons.school_rounded,          color: Color(0xFF2196F3)),
  'esports':        (icon: Icons.sports_esports_rounded,  color: Color(0xFF9C27B0)),
  'sports':         (icon: Icons.sports_soccer_rounded,   color: Color(0xFF4CAF50)),
  'socio_cultural': (icon: Icons.theater_comedy_rounded,  color: Color(0xFFE91E63)),
};

class JudgeHomePage extends StatefulWidget {
  const JudgeHomePage({super.key});
  @override
  State<JudgeHomePage> createState() => _JudgeHomePageState();
}

class _JudgeHomePageState extends State<JudgeHomePage> {
  int _liveEventCount = 0;
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final headers = {'Authorization': 'Token $token'};

      final catRes = await http.get(
        apiUri('/api/events/categories/'),
        headers: headers,
      );
      final evRes = await http.get(
        apiUri('/api/events/judging-events/'),
        headers: headers,
      );

      if (mounted) {
        setState(() {
          if (catRes.statusCode == 200) {
            _categories = jsonDecode(catRes.body) as List;
          }
          if (evRes.statusCode == 200) {
            final events = jsonDecode(evRes.body) as List;
            _liveEventCount = events
                .where((e) => e['status'] == 'active')
                .length;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B12),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF17131F),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF2A2433), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A102D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Color(0xFF9F66FF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('EVENTTAB',
                      style: TextStyle(color: Color(0xFF9F66FF), fontSize: 18,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    color: const Color(0xFF9F66FF),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A102D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF9F66FF), width: 2),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const JudgeProfilePage())),
                      child: const Icon(Icons.person, color: Color(0xFF9F66FF), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9F66FF)))
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6B22D8),
                            const Color(0xFF9F66FF).withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HOME',
                                style: TextStyle(color: Color(0xFFE5DFFF), fontSize: 12,
                                    fontWeight: FontWeight.w700, letterSpacing: 2)),
                            const SizedBox(height: 8),
                            const Text('Home Activities',
                                style: TextStyle(color: Colors.white, fontSize: 36,
                                    fontWeight: FontWeight.w900, height: 1.1)),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: '/judge/events'),
                                    builder: (_) => const JEventPage(),
                                  )),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.rocket_launch_rounded,
                                          color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ACTIVE NOW',
                                              style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                  fontSize: 11, fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.2)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$_liveEventCount Live Event${_liveEventCount != 1 ? 's' : ''}',
                                            style: const TextStyle(color: Colors.white,
                                                fontSize: 22, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Event Categories Section — from API
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _categories.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No categories yet.',
                                    style: TextStyle(color: Color(0xFF7F7890))),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (ctx, i) {
                                final cat = _categories[i];
                                final meta = _categoryMeta[cat['category_type']] ??
                                    (icon: Icons.event_rounded, color: const Color(0xFF9F66FF));
                                return _EventCategoryCard(
                                  icon: meta.icon,
                                  iconColor: meta.color,
                                  title: cat['name'] ?? '',
                                  subtitle: cat['description'] ?? '',
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const JEventPage())),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF17131F),
          border: Border(top: BorderSide(color: Color(0xFF2A2433), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(icon: Icons.home_rounded, label: 'Home', active: true),
                _BottomNavItem(
                  icon: Icons.event_rounded,
                  label: 'Events',
                  active: false,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/judge/events'),
                        builder: (_) => const JEventPage(),
                      )),
                ),
                _BottomNavItem(icon: Icons.star_rounded, label: 'Scoring', active: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Bottom nav item -------------------------------------

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF9F66FF) : const Color(0xFF5A5266);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// --- Event category card ----------------------------------

class _EventCategoryCard extends StatelessWidget {
  const _EventCategoryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF17131F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2433)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: const TextStyle(color: Color(0xFF7F7890),
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
