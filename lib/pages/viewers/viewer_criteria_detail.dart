import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_theme.dart';

/// Criteria-based event detail: Overview / Schedule / Contestants / Results / Awards.
class ViewerCriteriaDetailPage extends StatefulWidget {
  const ViewerCriteriaDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  State<ViewerCriteriaDetailPage> createState() => _ViewerCriteriaDetailPageState();
}

class _ViewerCriteriaDetailPageState extends State<ViewerCriteriaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _schedule;
  List<Map<String, dynamic>> _contestants = [];
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _awards = [];
  bool _showScores = false;

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
    _tabs = TabController(length: 5, vsync: this);
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
        apiUri('/api/events/viewer/criteria-events/${widget.eventId}/'),
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
        _schedule = data['schedule'] is Map
            ? Map<String, dynamic>.from(data['schedule'] as Map)
            : {};
        _contestants = (data['contestants'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _results = (data['results'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _awards = (data['awards'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _showScores = data['show_scores'] == true;
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
    final title = _overview?['title'] ?? 'Criteria Event';
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
                  Tab(text: 'Contestants'),
                  Tab(text: 'Results'),
                  Tab(text: 'Awards'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(),
                    _scheduleTab(),
                    _contestantsTab(),
                    _resultsTab(),
                    _awardsTab(),
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
        _info('Venue', '${o['venue'] ?? 'TBD'}'),
        _info('Date', '${o['date_display'] ?? 'TBD'}'),
        _info('Competition Structure', '${o['competition_structure'] ?? '—'}'),
        _info('Contestants', '${o['contestant_count'] ?? 0}'),
        _info('Current Stage', '${o['current_stage'] ?? '—'}'),
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
    final s = _schedule ?? {};
    final stages = (s['stages'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _info('Competition Date', '${s['date_display'] ?? 'TBD'}'),
        _info('Time', '${s['time_display'] ?? '—'}'),
        _info('Venue', '${s['venue'] ?? 'TBD'}'),
        _info('Current Stage', '${s['current_stage'] ?? '—'}'),
        const SizedBox(height: 16),
        const Text('Stages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (stages.isEmpty)
          const Text('No stages published.', style: TextStyle(color: viewerMuted))
        else
          ...stages.map((st) {
            final active = st['is_active'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: viewerCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? viewerCyan : viewerBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${st['name'] ?? 'Stage'}',
                          style: TextStyle(
                            color: active ? viewerCyan : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if ('${st['description'] ?? ''}'.isNotEmpty)
                          Text(
                            '${st['description']}',
                            style: const TextStyle(color: viewerMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (active) const ViewerStatusChip('Current'),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _contestantsTab() {
    if (_contestants.isEmpty) {
      return const Center(
        child: Text('No contestants published yet.', style: TextStyle(color: viewerMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contestants.length,
      itemBuilder: (_, i) {
        final c = _contestants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: viewerCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: viewerBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: viewerCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${c['number'] ?? i + 1}',
                  style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c['name'] ?? 'Contestant'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${c['department'] ?? '—'}',
                      style: const TextStyle(color: viewerMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ViewerStatusChip('${c['status'] ?? 'Competing'}'),
            ],
          ),
        );
      },
    );
  }

  Widget _resultsTab() {
    if (_results.isEmpty) {
      return const Center(
        child: Text('No published results yet.', style: TextStyle(color: viewerMuted)),
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
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${r['rank'] ?? i + 1}',
                  style: TextStyle(
                    color: (r['rank'] == 1) ? viewerOrange : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r['award'] ?? ''}',
                      style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    Text(
                      '${r['contestant_name'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${r['department'] ?? ''}',
                      style: const TextStyle(color: viewerMuted, fontSize: 12),
                    ),
                    if (_showScores && r['score'] != null)
                      Text(
                        'Score: ${r['score']}',
                        style: const TextStyle(color: viewerMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _awardsTab() {
    if (_awards.isEmpty) {
      return const Center(
        child: Text('No published awards yet.', style: TextStyle(color: viewerMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _awards.length,
      itemBuilder: (_, i) {
        final a = _awards[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: viewerCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: viewerBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.military_tech_outlined, color: viewerOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['title'] ?? 'Award'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${a['recipient'] ?? ''}',
                      style: const TextStyle(color: viewerCyanLt, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${a['department'] ?? ''}',
                      style: const TextStyle(color: viewerMuted, fontSize: 12),
                    ),
                  ],
                ),
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
            width: 150,
            child: Text(label, style: const TextStyle(color: viewerMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
