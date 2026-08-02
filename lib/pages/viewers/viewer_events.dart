import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_event_detail.dart';
import 'viewer_theme.dart';

/// Events tab — published match/criteria events with search, filter, sort.
class ViewerEventsBody extends StatefulWidget {
  const ViewerEventsBody({super.key});

  @override
  State<ViewerEventsBody> createState() => _ViewerEventsBodyState();
}

class _ViewerEventsBodyState extends State<ViewerEventsBody> {
  bool _loading = true;
  String? _error;
  String _type = 'all'; // all | match | criteria
  String _status = 'all';
  String _sort = 'date'; // date | name | status
  String _search = '';
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic> _counts = {};

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
      final params = <String, String>{};
      if (_type != 'all') params['type'] = _type;
      if (_status != 'all') params['status'] = _status;
      if (_search.trim().isNotEmpty) params['q'] = _search.trim();
      final uri = apiUri('/api/events/viewer/events/').replace(queryParameters: params);
      final res = await http.get(uri, headers: _headers);
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _error = 'Failed to load events (${res.statusCode})';
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      var events = (data['events'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      events = _sortEvents(events);
      setState(() {
        _events = events;
        _counts = Map<String, dynamic>.from(data['counts'] as Map? ?? {});
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

  List<Map<String, dynamic>> _sortEvents(List<Map<String, dynamic>> items) {
    final copy = [...items];
    switch (_sort) {
      case 'name':
        copy.sort((a, b) => '${a['event_name'] ?? a['title']}'
            .compareTo('${b['event_name'] ?? b['title']}'));
        break;
      case 'status':
        copy.sort((a, b) => '${a['status']}'.compareTo('${b['status']}'));
        break;
      default:
        copy.sort((a, b) => '${a['scheduled_time'] ?? a['date_display']}'
            .compareTo('${b['scheduled_time'] ?? b['date_display']}'));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Events',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${_counts['all'] ?? _events.length} published events',
                style: const TextStyle(color: viewerMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => _search = v,
                onSubmitted: (_) => _load(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search events…',
                  hintStyle: const TextStyle(color: viewerMuted),
                  prefixIcon: const Icon(Icons.search, color: viewerMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: viewerCyan),
                    onPressed: _showSortSheet,
                  ),
                  filled: true,
                  fillColor: viewerCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: viewerBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: viewerBorder),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', 'all', _type, (v) {
                      setState(() => _type = v);
                      _load();
                    }),
                    _chip('Match-Based', 'match', _type, (v) {
                      setState(() => _type = v);
                      _load();
                    }),
                    _chip('Criteria-Based', 'criteria', _type, (v) {
                      setState(() => _type = v);
                      _load();
                    }),
                    const SizedBox(width: 8),
                    _chip('Live', 'live', _status, (v) {
                      setState(() => _status = _status == v ? 'all' : v);
                      _load();
                    }),
                    _chip('Upcoming', 'upcoming', _status, (v) {
                      setState(() => _status = _status == v ? 'all' : v);
                      _load();
                    }),
                    _chip('Completed', 'completed', _status, (v) {
                      setState(() => _status = _status == v ? 'all' : v);
                      _load();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: viewerCyan));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: viewerMuted)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_events.isEmpty) {
      return const Center(
        child: Text('No published events found.', style: TextStyle(color: viewerMuted)),
      );
    }
    return RefreshIndicator(
      color: viewerCyan,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _events.length,
        itemBuilder: (_, i) => _eventCard(_events[i]),
      ),
    );
  }

  Widget _chip(String label, String value, String selected, ValueChanged<String> onTap) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? viewerCyan.withValues(alpha: 0.18) : viewerCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? viewerCyan : viewerBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? viewerCyan : viewerMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: viewerCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sort by', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            for (final opt in [
              ('date', 'Date'),
              ('name', 'Event Name'),
              ('status', 'Status'),
            ])
              ListTile(
                title: Text(opt.$2, style: const TextStyle(color: Colors.white)),
                trailing: _sort == opt.$1
                    ? const Icon(Icons.check, color: viewerCyan)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _sort = opt.$1);
                  setState(() => _events = _sortEvents(_events));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> e) {
    final name = e['event_name'] ?? e['match_title'] ?? e['title'] ?? 'Event';
    final category = e['sport'] ?? e['category_group'] ?? '—';
    final classification = e['event_classification'] ??
        (e['event_type'] == 'criteria' ? 'Criteria-Based' : 'Match-Based');
    final division = e['division'] ?? e['round_label_display'] ?? '—';
    final venue = e['venue'] ?? 'TBD';
    final date = e['date_display'] ?? 'TBD';
    final status = '${e['status'] ?? 'scheduled'}';

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
          _row('Category', '$category'),
          _row('Classification', '$classification'),
          _row('Division', '$division'),
          _row('Venue', '$venue'),
          _row('Date', '$date'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => openViewerEvent(context, e),
              child: const Text('View', style: TextStyle(color: viewerCyan, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: viewerMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
