import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import 'scorer_widgets.dart';

class ScorerHistoryPage extends StatelessWidget {
  const ScorerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => const ScorerHistoryBody();
}

class ScorerHistoryBody extends StatefulWidget {
  const ScorerHistoryBody({super.key});

  @override
  State<ScorerHistoryBody> createState() => _ScorerHistoryBodyState();
}

class _ScorerHistoryBodyState extends State<ScorerHistoryBody> {
  List<Map<String, dynamic>> _entries = [];
  Map<String, int> _counts = {};
  String _tab = 'all';
  String _search = '';
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tab = status ?? _tab;
    final q = _search.trim();
    final query = q.isEmpty
        ? '/api/events/scorer/history/?status=$tab'
        : '/api/events/scorer/history/?status=$tab&q=${Uri.encodeComponent(q)}';

    try {
      final res = await ScorerApi.get(query);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _entries =
              (data['entries'] as List? ?? []).cast<Map<String, dynamic>>();
          _counts = (data['counts'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as int));
          _tab = tab;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load history.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View all your submitted match results.',
                style: TextStyle(color: scorerMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _HistoryTabs(
          current: _tab,
          counts: _counts,
          onChanged: (tab) => _load(status: tab),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search match, team or venue...',
              hintStyle: const TextStyle(color: scorerMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: scorerMuted),
              filled: true,
              fillColor: scorerCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: scorerBorder),
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: scorerPurple),
                )
              : _error != null
                  ? Center(child: Text(_error!))
                  : _entries.isEmpty
                      ? const Center(
                          child: Text(
                            'No submitted results yet.',
                            style: TextStyle(color: scorerMuted),
                          ),
                        )
                      : RefreshIndicator(
                          color: scorerPurple,
                          onRefresh: () => _load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _entries.length,
                            itemBuilder: (_, i) =>
                                _HistoryCard(entry: _entries[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  final String current;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('all', 'All'),
      ('approved', 'Approved'),
      ('pending', 'Pending'),
      ('returned', 'Returned'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isActive = current == tab.$1;
          final count = counts[tab.$1] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? scorerPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? scorerPurple : scorerBorder,
                  ),
                ),
                child: Text(
                  '${tab.$2} ($count)',
                  style: TextStyle(
                    color: isActive ? Colors.white : scorerMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final status = entry['status'] as String? ?? 'pending';
    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = scorerGreen;
      case 'returned':
        statusColor = scorerRed;
      default:
        statusColor = scorerOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scorerCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scorerBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scorerPurple.withValues(alpha: 0.15),
            child: Icon(
              scorerSportIcon(entry['sport_icon'] as String?),
              color: scorerPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry['match_title'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (entry['status_label'] as String? ?? status)
                            .toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry['teams_label'] as String? ?? '',
                  style: const TextStyle(color: scorerMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry['date_display']} • ${entry['time_display']} • ${entry['venue']}',
                  style: const TextStyle(color: scorerMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry['score_a']} - ${entry['score_b']}',
                style: const TextStyle(
                  color: scorerPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('Final', style: TextStyle(color: scorerMuted, fontSize: 10)),
              const Icon(Icons.chevron_right_rounded, color: scorerMuted),
            ],
          ),
        ],
      ),
    );
  }
}
