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

    try {
      final res = await ScorerApi.get(
        '/api/events/scorer/history/?status=$tab',
      );
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

  List<Map<String, dynamic>> get _filteredEntries {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _entries;

    return _entries.where((e) {
      final haystack = [
        e['match_title'],
        e['event_name'],
        e['teams_label'],
        e['venue'],
        e['status_label'],
        e['status'],
        '${e['score_a']}',
        '${e['score_b']}',
        e['date_display'],
        e['time_display'],
      ].whereType<Object>().map((v) => '$v'.toLowerCase()).join(' ');
      return haystack.contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _search = value);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return ColoredBox(
      color: scorerWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 3,
            color: scorerGold,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score History',
                  style: TextStyle(
                    color: scorerNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Submitted scores, including tabulator-approved results.',
                  style: TextStyle(color: scorerMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _HistoryTabs(
            current: _tab,
            counts: _counts,
            onChanged: (tab) => _load(status: tab),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: scorerNavy),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search match, team, venue or score...',
                      hintStyle: const TextStyle(color: scorerMuted),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: scorerMuted),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: scorerMuted),
                              onPressed: _clearSearch,
                            ),
                      filled: true,
                      fillColor: const Color(0xFFEEEDF5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: scorerGold, width: 1.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scorerWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scorerBorder),
                  ),
                  child: const Icon(Icons.tune_rounded, color: scorerNavy),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: scorerGold),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: scorerMuted),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              _search.trim().isEmpty
                                  ? (_tab == 'approved'
                                      ? 'No approved scores yet.'
                                      : 'No submitted results yet.')
                                  : 'No results match your search.',
                              style: const TextStyle(color: scorerMuted),
                            ),
                          )
                        : RefreshIndicator(
                            color: scorerGold,
                            onRefresh: () => _load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _HistoryCard(
                                entry: filtered[i],
                                accentNavy: i.isOdd,
                              ),
                            ),
                          ),
          ),
        ],
      ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? scorerGold : scorerWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? scorerGold : scorerBorder,
                  ),
                ),
                child: Text(
                  '${tab.$2} ($count)',
                  style: TextStyle(
                    color: isActive ? scorerWhite : scorerNavy,
                    fontWeight: FontWeight.w800,
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
  const _HistoryCard({
    required this.entry,
    this.accentNavy = false,
  });

  final Map<String, dynamic> entry;
  final bool accentNavy;

  @override
  Widget build(BuildContext context) {
    final status = entry['status'] as String? ?? 'pending';
    final scoreA = entry['score_a'];
    final scoreB = entry['score_b'];
    final icon = scorerSportIcon(entry['sport_icon'] as String?);
    final teams = entry['teams_label'] as String? ?? '';
    final stripe = accentNavy ? scorerNavy : scorerGold;

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = scorerGreen;
      case 'returned':
        statusColor = scorerRed;
      default:
        statusColor = scorerGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scorerWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scorerNavy.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: stripe),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Stack(
                  children: [
                    Positioned(
                      right: -4,
                      bottom: -10,
                      child: Icon(
                        icon,
                        size: 68,
                        color: scorerNavy.withValues(alpha: 0.05),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: scorerNavy,
                          child: Icon(icon, color: scorerGold, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry['match_title'] as String? ?? '',
                                style: const TextStyle(
                                  color: scorerNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(children: scorerTeamsSpans(teams)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 12, color: scorerMuted),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      [
                                        entry['date_display'],
                                        entry['time_display'],
                                      ]
                                          .where((v) =>
                                              (v as String?)?.isNotEmpty ==
                                              true)
                                          .join(' • '),
                                      style: const TextStyle(
                                        color: scorerMuted,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: scorerMuted),
                                  const SizedBox(width: 2),
                                  Text(
                                    entry['venue'] as String? ?? '—',
                                    style: const TextStyle(
                                      color: scorerMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (entry['status_label'] as String? ?? status)
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${scoreA ?? '—'} - ${scoreB ?? '—'}',
                              style: TextStyle(
                                color: status == 'approved'
                                    ? scorerGreen
                                    : scorerGold,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              status == 'approved'
                                  ? 'Approved'
                                  : 'Submitted',
                              style: const TextStyle(
                                color: scorerMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
