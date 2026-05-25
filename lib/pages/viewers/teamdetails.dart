import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import 'auth_service.dart';
import 'matchdetails.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF0A0B0D);
const _kCard   = Color(0xFF12141A);
const _kBorder = Color(0xFF1E2128);
const _kCyan   = Color(0xFF00C5D9);
const _kOrange = Color(0xFFFF7A18);
const _kMuted  = Color(0xFF4A4C50);

class TeamDetailsPage extends StatefulWidget {
  const TeamDetailsPage({super.key, required this.team});
  final Map<String, dynamic> team;

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadMatches(); }

  Future<void> _loadMatches() async {
    try {
      final token = AuthSession.current?.token;
      final id    = widget.team['id'];
      final res   = await http.get(
        apiUri('/api/events/teams/$id/matches/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _matches = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t     = widget.team;
    final name  = t['name']  as String? ?? '';
    final abbr  = t['abbreviation'] as String? ?? '';
    Color accent = const Color(0xFF00C5D9);
    try { accent = Color(int.parse(
        (t['color'] as String).replaceFirst('#', '0xFF'))); }
    catch (_) {}

    // Derive stats from matches
    final wins   = _matches.where((m) {
      final wa = m['winner'];
      return wa != null && wa['id'] == t['id'];
    }).length;
    final losses = _matches.where((m) {
      final wa = m['winner'];
      return wa != null && wa['id'] != t['id'];
    }).length;
    final winRate = _matches.isEmpty ? '—'
        : '${(wins / _matches.length * 100).round()}%';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        // ── App bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop()),
            const Expanded(child: Text('TEAM DETAILS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800, letterSpacing: 1))),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
              onPressed: () {}),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Hero card ──
            _HeroCard(abbr: abbr, name: name, accent: accent,
                wins: wins, losses: losses, winRate: winRate),
            const SizedBox(height: 16),
            // ── Stats row ──
            _StatsRow(matches: _matches.length, wins: wins),
            const SizedBox(height: 20),
            // ── Recent matches ──
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: _kCyan)))
            else if (_matches.isNotEmpty) ...[
              Row(children: [
                const Text('RECENT MATCHES', style: TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const Spacer(),
                Text('View All', style: const TextStyle(color: _kCyan,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              ..._matches.take(5).map((m) => _MatchResultRow(
                  match: m, teamId: t['id'] as int? ?? 0)),
            ],
          ]),
        )),
        // ── Bottom action bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: _kCard, border: Border(top: BorderSide(color: _kBorder))),
          child: Row(children: [
            Expanded(child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.favorite_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('1.2K', style: TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w900)),
              ]),
            )),
            const SizedBox(width: 12),
            Expanded(child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('VIEW MATCHES', style: TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ]),
            )),
          ]),
        ),
      ])),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.abbr, required this.name, required this.accent,
      required this.wins, required this.losses, required this.winRate});
  final String abbr, name, winRate;
  final Color accent;
  final int wins, losses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.1),
            blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Hexagon
          SizedBox(width: 72, height: 72,
              child: CustomPaint(
                painter: _HexPainter(color: accent),
                child: Center(child: Text(abbr,
                    style: TextStyle(color: accent, fontSize: 18,
                        fontWeight: FontWeight.w900))),
              )),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(abbr, style: TextStyle(color: accent,
                    fontSize: 11, fontWeight: FontWeight.w900))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.15),
                  border: Border.all(color: _kOrange),
                  borderRadius: BorderRadius.circular(4)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star, color: _kOrange, size: 10),
                  SizedBox(width: 4),
                  Text('TOP SEED', style: TextStyle(color: _kOrange,
                      fontSize: 9, fontWeight: FontWeight.w900)),
                ])),
            ]),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RANK', style: TextStyle(color: _kMuted,
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            Text('#01', style: TextStyle(color: accent,
                fontSize: 22, fontWeight: FontWeight.w900)),
          ])),
          Container(width: 1, height: 40, color: _kBorder),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('WIN RATE', style: TextStyle(color: _kMuted,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text(winRate, style: TextStyle(color: accent,
                  fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
          )),
        ]),
        const SizedBox(height: 8),
        const Text('Strong performance across all events.',
            style: TextStyle(color: _kMuted, fontSize: 12)),
      ]),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.matches, required this.wins});
  final int matches, wins;

  @override
  Widget build(BuildContext context) {
    final losses = matches - wins;
    return Row(children: [
      _StatBox(icon: Icons.emoji_events_outlined,
          label: 'OVERALL RECORD', value: '$wins - $losses'),
      const SizedBox(width: 10),
      _StatBox(icon: Icons.sports_outlined,
          label: 'SPORTS ENTERED', value: '3'),
      const SizedBox(width: 10),
      _StatBox(icon: Icons.trending_up,
          label: 'WIN STREAK', value: '6 WINS'),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder)),
      child: Column(children: [
        Icon(icon, color: _kCyan, size: 20),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted, fontSize: 8,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w900)),
      ]),
    ));
  }
}

// ─── Match result row ─────────────────────────────────────

class _MatchResultRow extends StatelessWidget {
  const _MatchResultRow({required this.match, required this.teamId});
  final Map<String, dynamic> match;
  final int teamId;

  @override
  Widget build(BuildContext context) {
    final teamA  = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB  = match['team_b'] as Map<String, dynamic>? ?? {};
    final scoreA = match['score_a'];
    final scoreB = match['score_b'];
    final winner = match['winner'] as Map<String, dynamic>?;
    final won    = winner != null && winner['id'] == teamId;
    final sport  = match['sport'] as String? ?? '';

    final raw = match['scheduled_time'] as String? ?? '';
    String dateStr = '';
    if (raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
        dateStr = '${months[dt.month-1]} ${dt.day}';
      }
    }

    final opponent = teamA['id'] == teamId ? teamB : teamA;
    final myScore  = teamA['id'] == teamId ? scoreA : scoreB;
    final oppScore = teamA['id'] == teamId ? scoreB : scoreA;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder)),
        child: Row(children: [
          Icon(_sportIcon(sport), color: _kMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('vs ${opponent['name'] ?? ''}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w600))),
          if (myScore != null && oppScore != null)
            Text('$myScore - $oppScore',
                style: TextStyle(
                  color: won ? _kCyan : const Color(0xFFFF5252),
                  fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: won
                  ? _kCyan.withValues(alpha: 0.15)
                  : const Color(0xFFFF5252).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text(won ? 'W' : 'L',
                style: TextStyle(
                  color: won ? _kCyan : const Color(0xFFFF5252),
                  fontSize: 11, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 8),
          Text(dateStr, style: const TextStyle(color: _kMuted, fontSize: 11)),
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
      ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

IconData _sportIcon(dynamic sport) {
  switch (sport) {
    case 'basketball': return Icons.sports_basketball;
    case 'volleyball': return Icons.sports_volleyball;
    case 'football':   return Icons.sports_soccer;
    default:           return Icons.sports_esports;
  }
}
