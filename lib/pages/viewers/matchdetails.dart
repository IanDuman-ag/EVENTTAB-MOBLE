import 'dart:async';
import 'package:flutter/material.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF0A0B0D);
const _kCard   = Color(0xFF12141A);
const _kBorder = Color(0xFF1E2128);
const _kCyan   = Color(0xFF00C5D9);
const _kOrange = Color(0xFFFF7A18);
const _kMuted  = Color(0xFF4A4C50);

class MatchDetailsPage extends StatefulWidget {
  const MatchDetailsPage({super.key, required this.match});
  final Map<String, dynamic> match;

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _calcRemaining());
    });
  }

  void _calcRemaining() {
    final raw = widget.match['scheduled_time'] as String? ?? '';
    final dt  = DateTime.tryParse(raw);
    if (dt == null) return;
    final diff = dt.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final m     = widget.match;
    final teamA = m['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = m['team_b'] as Map<String, dynamic>? ?? {};
    final title = (m['title'] as String? ?? '').toUpperCase();
    final venue = m['venue'] as String? ?? '';
    final sport = m['sport'] as String? ?? '';
    final status = m['status'] as String? ?? 'upcoming';

    final raw = m['scheduled_time'] as String? ?? '';
    String dateStr = '', timeStr = '', weekdayStr = '';
    if (raw.isNotEmpty) {
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
        const days   = ['Monday','Tuesday','Wednesday','Thursday',
                        'Friday','Saturday','Sunday'];
        dateStr   = '${months[dt.month-1]} ${dt.day}, ${dt.year}';
        weekdayStr = days[dt.weekday - 1];
        final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final min = dt.minute.toString().padLeft(2, '0');
        timeStr = '$h:$min ${dt.hour >= 12 ? 'PM' : 'AM'}';
      }
    }

    final colorA = _teamColor(teamA['color']);
    final colorB = _teamColor(teamB['color']);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          // ── App bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.of(context).pop()),
              const Expanded(child: Text('MATCH DETAILS',
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
              // ── Hero ──
              _HeroCard(
                teamA: teamA, teamB: teamB,
                colorA: colorA, colorB: colorB,
                title: title, sportIcon: _sportIcon(sport),
              ),
              const SizedBox(height: 20),
              // ── Date / time row ──
              Row(children: [
                Expanded(child: _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  top: dateStr, bottom: weekdayStr)),
                const SizedBox(width: 12),
                Expanded(child: _InfoTile(
                  icon: Icons.access_time,
                  top: timeStr, bottom: 'Local Time')),
              ]),
              const SizedBox(height: 12),
              // ── Venue ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCard, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, color: _kCyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(venue, style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    const Text('USTP Oroquieta Campus',
                        style: TextStyle(color: _kMuted, fontSize: 11)),
                  ])),
                ]),
              ),
              const SizedBox(height: 12),
              // ── Stage + status badges ──
              Row(children: [
                _Badge(label: 'SEMIFINAL', color: _kOrange),
                const SizedBox(width: 10),
                _Badge(label: status.toUpperCase(), color: _kCyan, outlined: true),
              ]),
              const SizedBox(height: 20),
              // ── Countdown ──
              if (_remaining > Duration.zero) _Countdown(remaining: _remaining),
              const SizedBox(height: 20),
              // ── Action buttons ──
              Row(children: [
                Expanded(child: _ActionBtn(
                  icon: Icons.notifications_outlined,
                  label: 'REMIND ME',
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00C5D9), Color(0xFF0080FF)]),
                  onTap: () {},
                )),
                const SizedBox(width: 12),
                Expanded(child: _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'SHARE',
                  outlined: true,
                  onTap: () {},
                )),
              ]),
              const SizedBox(height: 20),
              // ── Info rows ──
              _InfoRow(icon: Icons.info_outline,
                  title: 'Match Info', subtitle: 'Semifinal – Best of 1'),
              _InfoRow(icon: Icons.location_on_outlined,
                  title: 'Venue', subtitle: '$venue, USTP Oroquieta Campus'),
              _InfoRow(icon: Icons.note_outlined,
                  title: 'Notes', subtitle: 'Please arrive 30 mins before the match.'),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.teamA, required this.teamB,
      required this.colorA, required this.colorB,
      required this.title, required this.sportIcon});
  final Map<String, dynamic> teamA, teamB;
  final Color colorA, colorB;
  final String title;
  final IconData sportIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A0A), Color(0xFF0A0B0D)]),
      ),
      child: Stack(children: [
        // Background glow
        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: RadialGradient(
              center: Alignment.center, radius: 1.2,
              colors: [
                const Color(0xFF8B0000).withValues(alpha: 0.3),
                Colors.transparent,
              ]),
          ),
        )),
        // Sport label
        Positioned(top: 14, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(sportIcon, color: _kCyan, size: 14),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: _kCyan, fontSize: 11,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ]),
        ),
        // Teams
        Positioned.fill(child: Padding(
          padding: const EdgeInsets.only(top: 36),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center, children: [
            _HeroTeam(abbr: teamA['abbreviation'] ?? '?',
                name: teamA['name'] ?? '', color: colorA),
            const Text('VS', style: TextStyle(color: Colors.white,
                fontSize: 26, fontWeight: FontWeight.w900)),
            _HeroTeam(abbr: teamB['abbreviation'] ?? '?',
                name: teamB['name'] ?? '', color: colorB),
          ]),
        )),
      ]),
    );
  }
}

class _HeroTeam extends StatelessWidget {
  const _HeroTeam({required this.abbr, required this.name, required this.color});
  final String abbr, name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.25),
          border: Border.all(color: color, width: 2.5),
        ),
        child: Center(child: Text(abbr,
            style: TextStyle(color: color, fontSize: 20,
                fontWeight: FontWeight.w900))),
      ),
      const SizedBox(height: 8),
      Text(abbr, style: const TextStyle(color: Colors.white,
          fontSize: 13, fontWeight: FontWeight.w800)),
    ]);
  }
}

// ─── Info tile ────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.top, required this.bottom});
  final IconData icon;
  final String top, bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder)),
      child: Row(children: [
        Icon(icon, color: _kCyan, size: 18),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(top, style: const TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.w700)),
          Text(bottom, style: const TextStyle(color: _kMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.outlined = false});
  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color,
          fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}

// ─── Countdown ────────────────────────────────────────────

class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final hrs  = remaining.inHours.toString().padLeft(2, '0');
    final mins = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final ms   = ((remaining.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder)),
      child: Column(children: [
        const Text('MATCH STARTS IN', style: TextStyle(color: _kCyan,
            fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _CountUnit(value: hrs,  label: 'HRS'),
          _Colon(),
          _CountUnit(value: mins, label: 'MINS'),
          _Colon(),
          _CountUnit(value: secs, label: 'SECS'),
          _Colon(),
          _CountUnit(value: ms,   label: 'MS'),
        ]),
      ]),
    );
  }
}

class _CountUnit extends StatelessWidget {
  const _CountUnit({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: _kCyan,
          fontSize: 32, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: _kMuted,
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    ]);
  }
}

class _Colon extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Text(':', style: TextStyle(color: _kCyan,
          fontSize: 28, fontWeight: FontWeight.w900));
}

// ─── Action button ────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label,
      this.gradient, this.outlined = false, required this.onTap});
  final IconData icon;
  final String label;
  final Gradient? gradient;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: outlined ? null : gradient,
          color: outlined ? Colors.transparent : null,
          border: outlined ? Border.all(color: Colors.white54) : null,
          borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white,
              fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder)),
      child: Row(children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: _kMuted, fontSize: 11)),
        ])),
        const Icon(Icons.chevron_right, color: _kMuted, size: 18),
      ]),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────

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
