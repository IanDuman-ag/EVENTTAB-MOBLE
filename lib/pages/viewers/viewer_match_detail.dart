import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_theme.dart';

/// Match-based event detail: Overview / Schedule / Bracket / Results.
class ViewerMatchDetailPage extends StatefulWidget {
  const ViewerMatchDetailPage({super.key, required this.matchId});

  final int matchId;

  @override
  State<ViewerMatchDetailPage> createState() => _ViewerMatchDetailPageState();
}

class _ViewerMatchDetailPageState extends State<ViewerMatchDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _bracket;

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
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        apiUri('/api/events/viewer/match-events/${widget.matchId}/'),
        headers: _headers,
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _error = 'Event not found or unavailable.';
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _overview = Map<String, dynamic>.from(data['overview'] as Map? ?? {});
        _schedule = (data['schedule'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _results = (data['results'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _bracket = data['bracket'] is Map
            ? Map<String, dynamic>.from(data['bracket'] as Map)
            : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _overview?['title'] ?? 'Match Event';
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: '$title',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: viewerCyan)),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: viewerMuted)),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              TabBar(
                controller: _tabs,
                isScrollable: true,
                indicatorColor: viewerCyan,
                labelColor: viewerCyan,
                unselectedLabelColor: viewerMuted,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Bracket'),
                  Tab(text: 'Results'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(),
                    _scheduleTab(),
                    _bracketTab(),
                    _resultsTab(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overviewTab() {
    final o = _overview ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${o['title'] ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        if (o['status'] != null) ViewerStatusChip('${o['status']}'),
        const SizedBox(height: 16),
        _info('Category', '${o['category'] ?? '—'}'),
        _info('Division', '${o['division'] ?? '—'}'),
        _info('Classification', '${o['event_classification'] ?? 'Match-Based'}'),
        _info('Venue', '${o['venue'] ?? 'TBD'}'),
        _info('Event Date', '${o['date_display'] ?? 'TBD'}'),
        _info('Tournament Format', '${o['tournament_format'] ?? '—'}'),
        _info('Number of Teams', '${o['team_count'] ?? 0}'),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(color: viewerCyan, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          '${o['description'] ?? 'No description.'}',
          style: const TextStyle(color: viewerMuted, height: 1.4),
        ),
      ],
    );
  }

  Widget _scheduleTab() {
    if (_schedule.isEmpty) {
      return const Center(
        child: Text('No published matches yet.', style: TextStyle(color: viewerMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedule.length,
      itemBuilder: (_, i) {
        final m = _schedule[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: viewerCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: viewerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Game ${m['game_number'] ?? i + 1}',
                    style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  ViewerStatusChip('${m['status'] ?? 'scheduled'}'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${m['round'] ?? ''}',
                style: const TextStyle(color: viewerMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                '${m['team_a_name'] ?? 'TBD'}  vs  ${m['team_b_name'] ?? 'TBD'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('${m['date_display'] ?? ''}  ${m['time_display'] ?? ''}',
                  style: const TextStyle(color: viewerMuted, fontSize: 12)),
              Text('${m['venue'] ?? 'TBD'}',
                  style: const TextStyle(color: viewerMuted, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _bracketTab() {
    final events = (_bracket?['events'] as List?) ?? [];
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Bracket not available yet.\nOfficial results update the bracket when published.',
          textAlign: TextAlign.center,
          style: TextStyle(color: viewerMuted),
        ),
      );
    }
    final children = <Widget>[];
    for (final ev in events) {
      final event = Map<String, dynamic>.from(ev as Map);
      children.add(
        Text(
          '${event['event_name'] ?? event['name'] ?? 'Tournament'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      );
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          '${event['tournament_type'] ?? 'Single Elimination'}',
          style: const TextStyle(color: viewerMuted, fontSize: 12),
        ),
      );
      children.add(const SizedBox(height: 12));
      for (final rndRaw in (event['rounds'] as List? ?? [])) {
        final rnd = Map<String, dynamic>.from(rndRaw as Map);
        children.add(
          Text(
            '${rnd['label'] ?? rnd['name'] ?? 'Round'}',
            style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w800),
          ),
        );
        children.add(const SizedBox(height: 8));
        for (final match in (rnd['matches'] as List? ?? [])) {
          children.add(_bracketMatch(Map<String, dynamic>.from(match as Map)));
        }
        children.add(const SizedBox(height: 12));
      }
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _bracketMatch(Map<String, dynamic> m) {
    final status = '${m['status'] ?? ''}';
    final isCurrent = m['is_current'] == true || status == 'live';
    final official = m['is_official'] == true;
    final teamA = m['team_a'] is Map ? m['team_a']['name'] : m['team_a_name'];
    final teamB = m['team_b'] is Map ? m['team_b']['name'] : m['team_b_name'];
    final scoreA = m['score_a'];
    final scoreB = m['score_b'];
    final winnerSide = m['winner_side'];

    Color border = viewerBorder;
    if (isCurrent) border = viewerRed;
    if (status == 'completed' && official) border = viewerGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: viewerCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: isCurrent ? 1.5 : 1),
      ),
      child: Column(
        children: [
          _bracketSide('$teamA', scoreA, winnerSide == 'a' || winnerSide == 'A'),
          const Divider(color: viewerBorder, height: 16),
          _bracketSide('$teamB', scoreB, winnerSide == 'b' || winnerSide == 'B'),
          if (m['status_display'] != null) ...[
            const SizedBox(height: 6),
            Text(
              '${m['status_display']}',
              style: const TextStyle(color: viewerOrange, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bracketSide(String name, dynamic score, bool winner) {
    return Row(
      children: [
        if (winner)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.emoji_events, color: viewerOrange, size: 16),
          ),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              color: winner ? viewerCyanLt : Colors.white,
              fontWeight: winner ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          score == null ? '—' : '$score',
          style: TextStyle(
            color: winner ? viewerCyan : viewerMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _resultsTab() {
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No official published results yet.',
          style: TextStyle(color: viewerMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final r = _results[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: viewerCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: viewerBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game ${r['game_number'] ?? i + 1}',
                style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                '${r['team_a_name']} vs ${r['team_b_name']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('Final Score: ${r['final_score'] ?? '—'}',
                  style: const TextStyle(color: viewerMuted)),
              Text('Winner: ${r['winner'] ?? '—'}',
                  style: const TextStyle(color: viewerOrange, fontWeight: FontWeight.w700)),
              if (r['date_display'] != null)
                Text(
                  'Published: ${r['date_display']}',
                  style: const TextStyle(color: viewerMuted, fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: viewerMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
