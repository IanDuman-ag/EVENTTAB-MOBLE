import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_event_detail.dart';
import 'viewer_theme.dart';

/// Home tab — welcome, ongoing/upcoming, latest results, top 3 leaderboard.
class ViewerHomeBody extends StatefulWidget {
  const ViewerHomeBody({
    super.key,
    required this.onOpenEvents,
    required this.onOpenLeaderboard,
    this.onNotificationCount,
  });

  final VoidCallback onOpenEvents;
  final VoidCallback onOpenLeaderboard;
  final ValueChanged<int>? onNotificationCount;

  @override
  State<ViewerHomeBody> createState() => _ViewerHomeBodyState();
}

class _ViewerHomeBodyState extends State<ViewerHomeBody> {
  bool _loading = true;
  String? _error;
  String _welcome = 'Welcome to EventTab';
  String _banner = 'Intramurals — Live Results & Standings';
  String _search = '';
  List<Map<String, dynamic>> _ongoing = [];
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _top = [];

  Map<String, String> get _headers {
    final token = AuthSession.current?.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        apiUri('/api/events/viewer/dashboard/'),
        headers: _headers,
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _error = 'Could not load dashboard (${res.statusCode})';
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _welcome = (data['welcome_title'] as String?) ?? _welcome;
        _banner = (data['intramurals_banner'] as String?) ?? _banner;
        _ongoing = _list(data['ongoing']);
        _upcoming = _list(data['upcoming']);
        _results = _list(data['latest_results']);
        _top = _list(data['top_rankings']);
        _loading = false;
      });
      widget.onNotificationCount?.call(
        (data['notification_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((m) {
      final hay = [
        m['event_name'],
        m['match_title'],
        m['title'],
        m['venue'],
        m['teams_label'],
        m['sport'],
      ].map((e) => '${e ?? ''}'.toLowerCase()).join(' ');
      return hay.contains(q);
    }).toList();
  }

  void _openEvent(Map<String, dynamic> item) {
    openViewerEvent(context, item);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: viewerCyan));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: viewerMuted), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final ongoing = _filter(_ongoing);
    final upcoming = _filter(_upcoming);
    final results = _filter(_results);

    return RefreshIndicator(
      color: viewerCyan,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _welcomeBanner(),
          const SizedBox(height: 12),
          _intramuralsBanner(),
          const SizedBox(height: 14),
          _searchBar(),
          const SizedBox(height: 22),
          _sectionTitle('Ongoing Events', onSeeAll: widget.onOpenEvents),
          const SizedBox(height: 10),
          if (ongoing.isEmpty)
            _empty('No ongoing events right now.')
          else
            ...ongoing.map(_ongoingCard),
          const SizedBox(height: 22),
          _sectionTitle('Upcoming Events', onSeeAll: widget.onOpenEvents),
          const SizedBox(height: 10),
          if (upcoming.isEmpty)
            _empty('No upcoming events.')
          else
            ...upcoming.map(_upcomingCard),
          const SizedBox(height: 22),
          _sectionTitle('Latest Results'),
          const SizedBox(height: 10),
          if (results.isEmpty)
            _empty('No published results yet.')
          else
            ...results.take(5).map(_resultCard),
          const SizedBox(height: 22),
          _sectionTitle('Leaderboard Preview'),
          const SizedBox(height: 10),
          _leaderboardPreview(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onOpenLeaderboard,
              style: OutlinedButton.styleFrom(
                foregroundColor: viewerCyan,
                side: const BorderSide(color: viewerCyan),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'View Full Leaderboard',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3A42), Color(0xFF0D1520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: viewerCyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _welcome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Browse published events, brackets, and official standings.',
            style: TextStyle(color: viewerMuted, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _intramuralsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: viewerOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: viewerOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: viewerOrange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _banner,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search events, venues…',
        hintStyle: const TextStyle(color: viewerMuted),
        prefixIcon: const Icon(Icons.search, color: viewerMuted),
        filled: true,
        fillColor: viewerCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: viewerBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: viewerBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: viewerCyan),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all', style: TextStyle(color: viewerCyan, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(msg, style: const TextStyle(color: viewerMuted, fontSize: 13)),
      );

  Widget _ongoingCard(Map<String, dynamic> m) {
    final name = m['event_name'] ?? m['match_title'] ?? m['title'] ?? 'Event';
    final type = m['event_classification'] ??
        (m['source'] == 'judging' ? 'Criteria-Based' : 'Match-Based');
    final venue = m['venue'] ?? 'TBD';
    final stage = m['period_label'] ?? m['round_label_display'] ?? m['teams_label'] ?? '—';
    final status = '${m['status'] ?? 'ongoing'}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              ViewerStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          _meta(Icons.category_outlined, '$type'),
          _meta(Icons.place_outlined, '$venue'),
          _meta(Icons.sports_score_outlined, 'Current: $stage'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _openEvent(m),
              style: TextButton.styleFrom(foregroundColor: viewerCyan),
              child: const Text('View', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(Map<String, dynamic> m) {
    final name = m['event_name'] ?? m['match_title'] ?? m['title'] ?? 'Event';
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                _meta(Icons.calendar_today_outlined, '${m['date_display'] ?? 'TBD'}'),
                _meta(Icons.access_time, '${m['time_display'] ?? '—'}'),
                _meta(Icons.place_outlined, '${m['venue'] ?? 'TBD'}'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openEvent(m),
            child: const Text('View', style: TextStyle(color: viewerCyan, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> m) {
    final name = m['event_name'] ?? m['match_title'] ?? m['title'] ?? 'Result';
    return _card(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: viewerOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => _openEvent(m),
            child: const Text(
              'View Result',
              style: TextStyle(color: viewerCyan, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardPreview() {
    if (_top.isEmpty) return _empty('Leaderboard not available yet.');
    return Container(
      decoration: BoxDecoration(
        color: viewerCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: viewerBorder),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('Rank', style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(child: Text('Department', style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700))),
                SizedBox(width: 56, child: Text('Points', textAlign: TextAlign.end, style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const Divider(height: 1, color: viewerBorder),
          ..._top.take(3).map((r) {
            final rank = r['rank'] ?? 0;
            final name = r['name'] ?? 'Department';
            final pts = r['points'] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1 ? viewerOrange : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$name',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '$pts',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: viewerCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: viewerBorder),
      ),
      child: child,
    );
  }

  Widget _meta(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: viewerMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(color: viewerMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
