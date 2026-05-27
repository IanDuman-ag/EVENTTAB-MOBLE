import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import '../auth/server_url_dialog.dart';
import 'bracket.dart';
import 'profile.dart';
import 'rankings.dart';
import 'schedule.dart';
import 'teams.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF060A10);
const _kCard   = Color(0xFF0D1520);
const _kBorder = Color(0xFF1C2A3A);
const _kCyan   = Color(0xFF00C5D9);
const _kCyanLt = Color(0xFF7CE1EF);
const _kOrange = Color(0xFFFF7A18);
const _kMuted  = Color(0xFF4A5568);

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Data ─────────────────────────────────────────────
  List<Map<String, dynamic>> _allMatches   = [];
  List<Map<String, dynamic>> _allTeams     = [];
  bool    _isLoading   = true;
  String? _errorMessage;

  // ── Derived counts ───────────────────────────────────
  int get _liveCount      => _allMatches.where((m) => m['status'] == 'live').length;
  int get _upcomingCount  => _allMatches.where((m) => m['status'] == 'upcoming').length;
  int get _completedCount => _allMatches.where((m) => m['status'] == 'completed').length;

  List<Map<String, dynamic>> get _upcomingMatches =>
      _allMatches.where((m) => m['status'] == 'upcoming').toList()
        ..sort((a, b) => (a['scheduled_time'] as String)
            .compareTo(b['scheduled_time'] as String));

  @override
  void initState() { super.initState(); _loadData(); }

  // ── API ──────────────────────────────────────────────

  Map<String, String> get _headers {
    final token = AuthSession.current?.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait([
        http.get(apiUri('/api/events/matches/'), headers: _headers),
        http.get(apiUri('/api/events/teams/'),   headers: _headers),
      ]);

      if (!mounted) return;

      final matchRes = results[0];
      final teamRes  = results[1];

      setState(() {
        if (matchRes.statusCode == 200) {
          _allMatches = (jsonDecode(matchRes.body) as List)
              .cast<Map<String, dynamic>>();
        }
        if (teamRes.statusCode == 200) {
          _allTeams = (jsonDecode(teamRes.body) as List)
              .cast<Map<String, dynamic>>();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _errorMsg(e);
        _isLoading = false;
      });
    }
  }

  String _errorMsg(Object e) {
    if (e is SocketException) {
      return 'Could not reach the server at $defaultApiBaseUrl.\n'
          'Make sure Django is running.';
    }
    return 'Failed to load data: $e';
  }

  void _nav(Widget page) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        body: const Center(child: CircularProgressIndicator(color: _kCyan)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_errorMessage != null) _errorBanner(),
              _heroBanner(),
              const SizedBox(height: 16),
              _statsRow(),
              const SizedBox(height: 24),
              _upcomingEventsSection(),
              const SizedBox(height: 24),
              _topRankingsSection(),
              const SizedBox(height: 80),
            ]),
          )),
        ]),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ── Header ────────────────────────────────────────────

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _kCard,
              border: Border.all(color: _kCyan, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: _kCyan, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        const Text('EVENT TAB',
            style: TextStyle(color: _kCyan, fontSize: 18,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Spacer(),
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _kCyan),
            onPressed: () {},
          ),
          Positioned(top: 8, right: 8,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                  color: _kOrange, shape: BoxShape.circle),
            )),
        ]),
      ]),
    );
  }

  // ── Error banner ──────────────────────────────────────

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: 0.1),
        border: Border.all(color: _kOrange),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.wifi_off_outlined, color: _kOrange, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Could not load some data',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, children: [
          OutlinedButton(
            onPressed: _loadData,
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kOrange),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
          OutlinedButton(
            onPressed: () async {
              final saved = await showServerUrlDialog(context);
              if (saved && mounted) _loadData();
            },
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kCyan),
                foregroundColor: _kCyan,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            child: const Text('Server URL', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ]),
    );
  }

  // ── Hero banner ───────────────────────────────────────

  Widget _heroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2A3A), Color(0xFF0D4A5A), Color(0xFF0A1A2A)],
        ),
        border: Border.all(color: _kCyan.withValues(alpha: 0.3)),
      ),
      child: Stack(children: [
        // Decorative arcs
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(painter: _ArcPainter()),
        )),
        // Sparkle dots
        Positioned(top: 24, right: 60,
          child: Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: _kCyan, shape: BoxShape.circle))),
        Positioned(top: 40, right: 40,
          child: Container(width: 4, height: 4,
            decoration: BoxDecoration(
                color: _kCyan.withValues(alpha: 0.5), shape: BoxShape.circle))),
        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text('Hello,', style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const Text('Welcome!', style: TextStyle(
                color: _kCyan, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Discover upcoming events and\nstay updated with campus activities.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _nav(const SchedulePage()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _kCyan,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Explore Events',
                      style: TextStyle(color: Color(0xFF060A10),
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF060A10), size: 12),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Stats row ─────────────────────────────────────────

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: _StatCard(
          icon: Icons.radio_button_checked_rounded,
          iconColor: _kCyan,
          label: 'LIVE',
          count: _liveCount,
          subtitle: 'Matches Live',
          onTap: () => _nav(const SchedulePage()),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF7CE1EF),
          label: 'UPCOMING',
          count: _upcomingCount,
          subtitle: 'Events',
          onTap: () => _nav(const SchedulePage()),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF4CAF50),
          label: 'COMPLETED',
          count: _completedCount,
          subtitle: 'Matches',
          onTap: () => _nav(const SchedulePage()),
        )),
      ]),
    );
  }

  // ── Upcoming Events section ───────────────────────────

  Widget _upcomingEventsSection() {
    final matches = _upcomingMatches.take(5).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 3, height: 18, color: _kCyan,
              margin: const EdgeInsets.only(right: 10)),
          const Text('UPCOMING EVENTS',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => _nav(const SchedulePage()),
            child: const Text('See All',
                style: TextStyle(color: _kCyan, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      if (matches.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No upcoming events.',
              style: TextStyle(color: Colors.white38)),
        )
      else
        ...matches.map((m) => _UpcomingEventRow(match: m)),
    ]);
  }

  // ── Top Rankings section ──────────────────────────────

  Widget _topRankingsSection() {
    // Build a simple win/loss table from completed matches
    final stats = <int, _TeamStat>{};
    for (final t in _allTeams) {
      final id = t['id'] as int;
      stats[id] = _TeamStat(team: t);
    }
    for (final m in _allMatches.where((m) => m['status'] == 'completed')) {
      final winner = m['winner'] as Map<String, dynamic>?;
      final teamA  = m['team_a'] as Map<String, dynamic>?;
      final teamB  = m['team_b'] as Map<String, dynamic>?;
      if (teamA == null || teamB == null) continue;
      final idA = teamA['id'] as int;
      final idB = teamB['id'] as int;
      stats[idA] ??= _TeamStat(team: teamA);
      stats[idB] ??= _TeamStat(team: teamB);
      stats[idA]!.played++;
      stats[idB]!.played++;
      if (winner != null) {
        final winnerId = winner['id'] as int;
        if (winnerId == idA) { stats[idA]!.wins++; stats[idB]!.losses++; }
        else                 { stats[idB]!.wins++; stats[idA]!.losses++; }
      }
    }
    final ranked = stats.values.toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));
    final top = ranked.take(5).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 3, height: 18, color: _kOrange,
              margin: const EdgeInsets.only(right: 10)),
          const Text('TOP RANKINGS',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => _nav(const RankingsPage()),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('View Full Rankings',
                  style: TextStyle(color: _kCyan, fontSize: 12,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: _kCyan, size: 10),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      // Column headers
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: const [
          SizedBox(width: 44, child: Text('RANK',
              style: TextStyle(color: _kMuted, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1))),
          Expanded(child: Text('TEAM',
              style: TextStyle(color: _kMuted, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1))),
          SizedBox(width: 32, child: Text('W', textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1))),
          SizedBox(width: 32, child: Text('L', textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1))),
          SizedBox(width: 48, child: Text('PCT', textAlign: TextAlign.right,
              style: TextStyle(color: _kMuted, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1))),
        ]),
      ),
      const SizedBox(height: 8),
      if (top.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('No ranking data yet.',
              style: TextStyle(color: Colors.white38)),
        )
      else
        ...top.asMap().entries.map((e) =>
            _RankingRow(rank: e.key + 1, stat: e.value)),
    ]);
  }

  // ── Bottom nav ────────────────────────────────────────

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _NavItem(icon: Icons.home, label: 'HOME', active: true),
          _NavItem(icon: Icons.emoji_events_outlined, label: 'RANKINGS',
              active: false, onTap: () => _nav(const RankingsPage())),
          _NavItem(icon: Icons.calendar_today, label: 'SCHEDULE',
              active: false, onTap: () => _nav(const SchedulePage())),
          _NavItem(icon: Icons.people_outline, label: 'TEAMS',
              active: false, onTap: () => _nav(const TeamsPage())),
          _NavItem(icon: Icons.account_tree_outlined, label: 'BRACKET',
              active: false,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BracketPage()))),
        ]),
      )),
    );
  }
}

// ─── Arc background painter ───────────────────────────────

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00C5D9).withValues(alpha: 0.18);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.5),
          width: size.height * 1.4, height: size.height * 1.4),
      -1.2, 2.4, false, paint);

    paint.color = const Color(0xFF00C5D9).withValues(alpha: 0.10);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(size.width * 0.85, size.height * 0.5),
          width: size.height * 1.9, height: size.height * 1.9),
      -1.0, 2.0, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Stat card ────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label, subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const Spacer(),
            const Icon(Icons.chevron_right, color: _kMuted, size: 14),
          ]),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: _kMuted, fontSize: 8,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text('$count',
              style: const TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(subtitle,
              style: const TextStyle(color: _kMuted, fontSize: 9)),
        ]),
      ),
    );
  }
}

// ─── Upcoming event row ───────────────────────────────────

class _UpcomingEventRow extends StatelessWidget {
  const _UpcomingEventRow({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final raw   = match['scheduled_time'] as String? ?? '';
    final dt    = DateTime.tryParse(raw)?.toLocal();
    final sport = match['sport'] as String? ?? '';
    final title = match['title'] as String? ?? '';
    final venue = match['venue'] as String? ?? '';

    String dateStr = '', timeStr = '';
    if (dt != null) {
      const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                      'JUL','AUG','SEP','OCT','NOV','DEC'];
      dateStr = '${months[dt.month-1]} ${dt.day}';
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        // Date + time
        SizedBox(
          width: 64,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dateStr,
                style: const TextStyle(color: _kCyan, fontSize: 11,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(timeStr,
                style: const TextStyle(color: Colors.white70, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 12),
        // Sport icon
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _sportColor(sport).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_sportIcon(sport), color: _sportColor(sport), size: 20),
        ),
        const SizedBox(width: 12),
        // Title + sport
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.location_on_outlined, color: _kMuted, size: 11),
            const SizedBox(width: 3),
            Expanded(child: Text(venue,
                style: const TextStyle(color: _kMuted, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        const SizedBox(width: 8),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kCyan.withValues(alpha: 0.12),
            border: Border.all(color: _kCyan.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('UPCOMING',
              style: TextStyle(color: _kCyan, fontSize: 8,
                  fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
      ]),
    );
  }

  static Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return const Color(0xFFFF7A18);
      case 'volleyball': return const Color(0xFF9C27B0);
      case 'football':   return const Color(0xFF4CAF50);
      default:           return const Color(0xFF00C5D9);
    }
  }

  static IconData _sportIcon(String sport) {
    switch (sport) {
      case 'basketball': return Icons.sports_basketball;
      case 'volleyball': return Icons.sports_volleyball;
      case 'football':   return Icons.sports_soccer;
      default:           return Icons.emoji_events_outlined;
    }
  }
}

// ─── Ranking row ──────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.rank, required this.stat});
  final int rank;
  final _TeamStat stat;

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    Color accent = const Color(0xFF4A5568);
    if (rank == 1) accent = const Color(0xFFFFD700);
    if (rank == 2) accent = const Color(0xFFBDBDBD);
    if (rank == 3) accent = const Color(0xFFCD7F32);

    final abbr  = stat.team['abbreviation'] as String? ?? '?';
    final name  = stat.team['name'] as String? ?? '';
    final color = _teamColor(stat.team['color']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isFirst
            ? const Color(0xFFFFD700).withValues(alpha: 0.3)
            : _kBorder),
      ),
      child: Row(children: [
        // Rank badge
        SizedBox(
          width: 44,
          child: isFirst
              ? const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700), size: 22)
              : Text('$rank',
                  style: TextStyle(color: accent, fontSize: 14,
                      fontWeight: FontWeight.w900)),
        ),
        // Team logo + name
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(child: Text(abbr.length > 2 ? abbr.substring(0, 2) : abbr,
              style: TextStyle(color: color, fontSize: 9,
                  fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(abbr,
              style: const TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800)),
          Text(name,
              style: const TextStyle(color: _kMuted, fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        // W
        SizedBox(width: 32, child: Text('${stat.wins}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700))),
        // L
        SizedBox(width: 32, child: Text('${stat.losses}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13,
                fontWeight: FontWeight.w700))),
        // PCT
        SizedBox(width: 48, child: Text(
            stat.played == 0 ? '—' : '.${(stat.pct * 1000).round().toString().padLeft(3, '0')}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isFirst ? const Color(0xFFFFD700) : _kCyan,
              fontSize: 13, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  static Color _teamColor(dynamic raw) {
    try { return Color(int.parse((raw as String).replaceFirst('#', '0xFF'))); }
    catch (_) { return const Color(0xFF00C5D9); }
  }
}

// ─── Team stat model ──────────────────────────────────────

class _TeamStat {
  _TeamStat({required this.team});
  final Map<String, dynamic> team;
  int wins = 0, losses = 0, played = 0;
  double get pct => played == 0 ? 0 : wins / played;
}

// ─── Nav item ─────────────────────────────────────────────

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
