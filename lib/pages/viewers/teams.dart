import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import 'auth_service.dart';
import 'bracket.dart';
import 'home.dart';
import 'profile.dart';
import 'rankings.dart';
import 'schedule.dart';
import 'teamdetails.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF0A0B0D);
const _kCard   = Color(0xFF12141A);
const _kBorder = Color(0xFF1E2128);
const _kCyan   = Color(0xFF00C5D9);
const _kMuted  = Color(0xFF4A4C50);

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});
  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(apiUri('/api/events/teams/'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      });
      if (res.statusCode == 200) {
        setState(() {
          _teams = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else { throw Exception('HTTP ${res.statusCode}'); }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _nav(Widget p) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => p));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _header(),
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kCyan))
            : _error != null ? _errorView() : _body()),
      ])),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: _kBg, border: Border(bottom: BorderSide(color: _kBorder))),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ProfilePage())),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _kCard, border: Border.all(color: _kCyan),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.person, color: Color(0xFFFFB083), size: 20),
        ),
      ),
      const SizedBox(width: 12),
      const Text('EVENT TAB', style: TextStyle(color: _kCyan, fontSize: 15,
          fontWeight: FontWeight.w900, letterSpacing: 1)),
      const Spacer(),
      Stack(children: [
        IconButton(onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: _kCyan)),
        Positioned(top: 8, right: 8,
          child: Container(width: 8, height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFFF7A18), shape: BoxShape.circle))),
      ]),
    ]),
  );

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Color(0xFFFF7A18), size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _load,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: _kCyan)),
          child: const Text('Retry', style: TextStyle(color: _kCyan))),
    ]),
  ));

  Widget _body() {
    if (_teams.isEmpty) {
      return const Center(child: Text('No teams found.',
          style: TextStyle(color: Colors.white38)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DEPARTMENT\nTEAMS', style: TextStyle(color: Colors.white,
            fontSize: 32, fontWeight: FontWeight.w900, height: 0.95)),
        const SizedBox(height: 6),
        const Text('Intramural standings and team profiles',
            style: TextStyle(color: _kMuted, fontSize: 13)),
        const SizedBox(height: 28),
        ..._teams.map((t) {
          Color accent = const Color(0xFF00C5D9);
          try { accent = Color(int.parse(
              (t['color'] as String).replaceFirst('#', '0xFF'))); }
          catch (_) {}
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TeamCard(team: t, accent: accent),
          );
        }),
      ]),
    );
  }

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(
      color: _kBg, border: Border(top: BorderSide(color: _kBorder))),
    child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavItem(icon: Icons.home, label: 'HOME', active: false,
            onTap: () => _nav(const HomePage())),
        _NavItem(icon: Icons.emoji_events_outlined, label: 'RANKINGS', active: false,
            onTap: () => _nav(const RankingsPage())),
        _NavItem(icon: Icons.calendar_today, label: 'SCHEDULE', active: false,
            onTap: () => _nav(const SchedulePage())),
        _NavItem(icon: Icons.people_outline, label: 'TEAMS', active: true),
        _NavItem(icon: Icons.account_tree_outlined, label: 'BRACKET', active: false,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BracketPage()))),
      ]),
    )),
  );
}

// ─── Team card (hexagon logo) ─────────────────────────────

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.accent});
  final Map<String, dynamic> team;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final name = team['name'] as String? ?? '';
    final abbr = team['abbreviation'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TeamDetailsPage(team: team))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          // Hexagon logo
          SizedBox(width: 64, height: 64,
              child: CustomPaint(
                painter: _HexPainter(color: accent),
                child: Center(child: Text(abbr,
                    style: TextStyle(color: accent, fontSize: 16,
                        fontWeight: FontWeight.w900))),
              )),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(abbr, style: TextStyle(color: accent, fontSize: 13,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(name, style: const TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w700)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.white54, size: 22),
        ]),
      ),
    );
  }
}

// ─── Hexagon painter ─────────────────────────────────────

class _HexPainter extends CustomPainter {
  const _HexPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.shortestSide / 2 - 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Shared nav ───────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label,
      required this.active, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? _kCyan : _kMuted, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          color: active ? _kCyan : _kMuted,
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }
}
