import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import '../auth/server_url_dialog.dart';
import 'bracket.dart';
import 'home.dart';
import 'matchdetails.dart';
import 'profile.dart';
import 'rankings.dart';
import 'teams.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF0A0B0D);
const _kCard   = Color(0xFF12141A);
const _kBorder = Color(0xFF1E2128);
const _kCyan   = Color(0xFF00C5D9);
const _kOrange = Color(0xFFFF7A18);
const _kMuted  = Color(0xFF4A4C50);

// ─── sport filter chips ───────────────────────────────────
const _kSports = [
  ('all',        'All',        null),
  ('basketball', 'Basketball', Icons.sports_basketball),
  ('volleyball', 'Volleyball', Icons.sports_volleyball),
  ('other',      'E-Sports',   Icons.sports_esports),
];

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _allMatches = [];
  List<_Day> _days = [];
  int  _selectedDayIndex  = 0;
  String _selectedSport   = 'all';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(apiUri('/api/events/matches/'), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      });
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      // Build sorted unique day list
      final seen = <String>{};
      final days = <_Day>[];
      for (final m in list) {
        final raw = m['scheduled_time'] as String? ?? '';
        final dt  = DateTime.tryParse(raw)?.toLocal();
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month}-${dt.day}';
        if (seen.add(key)) days.add(_Day(dt));
      }
      days.sort((a, b) => a.dt.compareTo(b.dt));
      setState(() {
        _allMatches = list;
        _days = days;
        _selectedDayIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _buildLoadErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _buildLoadErrorMessage(Object error) {
    if (error is SocketException) {
      return 'Could not reach the server at $defaultApiBaseUrl.\n'
          'On a phone, use your computer IP and make sure Django is running on '
          '0.0.0.0:8000.';
    }

    return error.toString();
  }

  List<Map<String, dynamic>> get _filtered {
    final day = _days.isEmpty ? null : _days[_selectedDayIndex];
    return _allMatches.where((m) {
      final raw = m['scheduled_time'] as String? ?? '';
      final dt  = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) return false;
      final dayOk = day == null ||
          (dt.day == day.dt.day && dt.month == day.dt.month && dt.year == day.dt.year);
      final sportOk = _selectedSport == 'all' || m['sport'] == _selectedSport;
      return dayOk && sportOk;
    }).toList();
  }

  void _nav(Widget p) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => p));

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kCyan))
                : _error != null ? _errorView() : _body()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() => Container(
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
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _kCard, border: Border.all(color: _kCyan),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.person, color: Color(0xFFFFB083), size: 20),
        ),
      ),
      const SizedBox(width: 10),
      const Text('EVENT TAB', style: TextStyle(color: _kCyan, fontSize: 15,
          fontWeight: FontWeight.w900, letterSpacing: 1)),
      const Spacer(),
      Stack(children: [
        IconButton(onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: _kCyan)),
        Positioned(top: 8, right: 8,
          child: Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle))),
      ]),
    ]),
  );

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: _kOrange, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton(onPressed: _load,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _kCyan)),
              child: const Text('RETRY', style: TextStyle(color: _kCyan))),
          OutlinedButton(
            onPressed: () async {
              final didSave = await showServerUrlDialog(context);
              if (didSave && mounted) {
                _load();
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kOrange),
            ),
            child: const Text('SERVER URL', style: TextStyle(color: _kOrange)),
          ),
        ],
      ),
    ]),
  ));

  Widget _body() {
    final matches = _filtered;
    final featured = matches.where((m) => m['is_featured'] == true).toList();
    final upNext   = featured.isNotEmpty ? featured.first
        : matches.where((m) => m['status'] == 'upcoming').firstOrNull;
    final rest     = matches.where((m) => m != upNext).toList();

    // Date range label
    String dateRange = '';
    if (_days.isNotEmpty) {
      final first = _days.first;
      final last  = _days.last;
      dateRange = '${_monthName(first.dt.month)} ${first.dt.day} – '
          '${_monthName(last.dt.month)} ${last.dt.day}, ${last.dt.year}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SCHEDULE', style: TextStyle(color: Colors.white,
            fontSize: 28, fontWeight: FontWeight.w900)),
        if (dateRange.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(dateRange, style: const TextStyle(color: _kMuted, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        // Day selector
        if (_days.isNotEmpty) _daySelector(),
        const SizedBox(height: 14),
        // Sport filter chips
        _sportChips(),
        const SizedBox(height: 20),
        // UP NEXT featured card
        if (upNext != null) ...[
          const Text('UP NEXT', style: TextStyle(color: _kMuted, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          _FeaturedCard(match: upNext),
          const SizedBox(height: 24),
        ],
        // ALL MATCHES list
        if (rest.isNotEmpty) ...[
          const Text('ALL MATCHES', style: TextStyle(color: _kMuted, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ...rest.map((m) => _MatchRow(match: m)),
        ],
        if (matches.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No matches on this date.',
                style: TextStyle(color: Colors.white38)),
          )),
      ]),
    );
  }

  Widget _daySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_days.length, (i) {
          final d   = _days[i];
          final sel = i == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 10),
              width: 60, height: 72,
              decoration: BoxDecoration(
                color: sel ? _kCyan : _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? _kCyan : _kBorder),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(d.monthAbbr, style: TextStyle(
                  color: sel ? _kBg : _kMuted,
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(d.dayStr, style: TextStyle(
                  color: sel ? _kBg : Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w900)),
                Text(d.weekday, style: TextStyle(
                  color: sel ? _kBg : _kMuted,
                  fontSize: 9, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _sportChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _kSports.map((s) {
          final sel = _selectedSport == s.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedSport = s.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _kCyan.withValues(alpha: 0.15) : Colors.transparent,
                border: Border.all(color: sel ? _kCyan : _kBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (s.$3 != null) ...[
                  Icon(s.$3, color: sel ? _kCyan : _kMuted, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(s.$2, style: TextStyle(
                  color: sel ? _kCyan : Colors.white70,
                  fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bottomNav() => Container(
    decoration: const BoxDecoration(
      color: _kBg,
      border: Border(top: BorderSide(color: _kBorder, width: 1)),
    ),
    child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavItem(icon: Icons.home, label: 'HOME', active: false,
            onTap: () => _nav(const HomePage())),
        _NavItem(icon: Icons.emoji_events_outlined, label: 'RANKINGS', active: false,
            onTap: () => _nav(const RankingsPage())),
        _NavItem(icon: Icons.calendar_today, label: 'SCHEDULE', active: true),
        _NavItem(icon: Icons.people_outline, label: 'TEAMS', active: false,
            onTap: () => _nav(const TeamsPage())),
        _NavItem(icon: Icons.account_tree_outlined, label: 'BRACKET', active: false,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BracketPage()))),
      ]),
    )),
  );

  static String _monthName(int m) {
    const n = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return n[m - 1];
  }
}

// ─── Day model ────────────────────────────────────────────

class _Day {
  final DateTime dt;
  _Day(this.dt);
  String get monthAbbr {
    const n = ['JAN','FEB','MAR','APR','MAY','JUN',
                'JUL','AUG','SEP','OCT','NOV','DEC'];
    return n[dt.month - 1];
  }
  String get dayStr => dt.day.toString().padLeft(2, '0');
  String get weekday {
    const w = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    return w[dt.weekday - 1];
  }
}

// ─── Featured "UP NEXT" card ──────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final teamA = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = match['team_b'] as Map<String, dynamic>? ?? {};
    final title = (match['title'] as String? ?? '').toUpperCase();
    final venue = match['venue'] as String? ?? '';
    final raw   = match['scheduled_time'] as String? ?? '';
    String timeStr = '';
    if (raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt != null) {
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        timeStr = '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
    }

    Color accentA = _teamColor(teamA['color']);
    Color accentB = _teamColor(teamB['color']);

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C2A3A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Sport label + stage badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(_sportIcon(match['sport']), color: _kCyan, size: 14),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: _kCyan, fontSize: 11,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.15),
                border: Border.all(color: _kOrange),
                borderRadius: BorderRadius.circular(4)),
              child: const Text('SEMIFINAL', style: TextStyle(color: _kOrange,
                  fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ]),
        ),
        // Teams VS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _TeamCircle(abbr: teamA['abbreviation'] ?? '?',
                name: teamA['name'] ?? '', color: accentA),
            const Text('VS', style: TextStyle(color: Colors.white,
                fontSize: 22, fontWeight: FontWeight.w900)),
            _TeamCircle(abbr: teamB['abbreviation'] ?? '?',
                name: teamB['name'] ?? '', color: accentB),
          ]),
        ),
        // Time + venue
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            const Icon(Icons.access_time, color: _kMuted, size: 14),
            const SizedBox(width: 4),
            Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Icons.location_on_outlined, color: _kMuted, size: 14),
            const SizedBox(width: 4),
            Expanded(child: Text(venue,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis)),
          ]),
        ),
        // MATCH DETAILS button
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MatchDetailsPage(match: match))),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00C5D9), Color(0xFF0080FF)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('MATCH DETAILS', style: TextStyle(color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Match row (ALL MATCHES list) ────────────────────────

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});
  final Map<String, dynamic> match;

  @override
  Widget build(BuildContext context) {
    final teamA = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = match['team_b'] as Map<String, dynamic>? ?? {};
    final title = (match['title'] as String? ?? '').toUpperCase();
    final venue = match['venue'] as String? ?? '';
    final raw   = match['scheduled_time'] as String? ?? '';
    String timeStr = '--:--';
    if (raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt != null) {
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final m = dt.minute.toString().padLeft(2, '0');
        timeStr = '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailsPage(match: match))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          // Sport icon + title
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_sportIcon(match['sport']), color: _kCyan, size: 12),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(color: _kCyan, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _SmallCircle(abbr: teamA['abbreviation'] ?? '?',
                  color: _teamColor(teamA['color'])),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(color: Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              _SmallCircle(abbr: teamB['abbreviation'] ?? '?',
                  color: _teamColor(teamB['color'])),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text(teamA['abbreviation'] ?? '', style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
              const SizedBox(width: 28),
              Text(teamB['abbreviation'] ?? '', style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
            ]),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(timeStr, style: const TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, color: _kMuted, size: 12),
              const SizedBox(width: 2),
              Text(venue, style: const TextStyle(color: _kMuted, fontSize: 11)),
            ]),
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: _kMuted, size: 18),
        ]),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────

class _TeamCircle extends StatelessWidget {
  const _TeamCircle({required this.abbr, required this.name, required this.color});
  final String abbr, name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(child: Text(abbr,
            style: TextStyle(color: color, fontSize: 18,
                fontWeight: FontWeight.w900))),
      ),
      const SizedBox(height: 6),
      Text(abbr, style: const TextStyle(color: Colors.white,
          fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _SmallCircle extends StatelessWidget {
  const _SmallCircle({required this.abbr, required this.color});
  final String abbr;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(child: Text(abbr,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w900))),
    );
  }
}

Color _teamColor(dynamic raw) {
  try { return Color(int.parse((raw as String).replaceFirst('#', '0xFF'))); }
  catch (_) { return const Color(0xFF00C5D9); }
}

IconData _sportIcon(dynamic sport) {
  switch (sport) {
    case 'basketball': return Icons.sports_basketball;
    case 'volleyball': return Icons.sports_volleyball;
    case 'football':   return Icons.sports_soccer;
    default:           return Icons.sports_esports;
  }
}

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
