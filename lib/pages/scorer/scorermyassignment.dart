import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import 'scorer_widgets.dart';
import 'scorerscores.dart';

class ScorerMyAssignmentsPage extends StatelessWidget {
  const ScorerMyAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) => const ScorerMyAssignmentsBody();
}

class ScorerMyAssignmentsBody extends StatefulWidget {
  const ScorerMyAssignmentsBody({super.key, this.onEditMatch});

  final ValueChanged<Map<String, dynamic>>? onEditMatch;

  @override
  State<ScorerMyAssignmentsBody> createState() =>
      ScorerMyAssignmentsBodyState();
}

class ScorerMyAssignmentsBodyState extends State<ScorerMyAssignmentsBody> {
  List<Map<String, dynamic>> _assignments = [];
  Map<String, int> _counts = {};
  String _tab = 'all';
  String _todayDisplay = '';
  String _search = '';
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> reload({String? status}) => _load(status: status);

  Future<void> _load({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tab = status ?? _tab;
    try {
      final res =
          await ScorerApi.get('/api/events/scorer/assignments/?status=$tab');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _assignments = (data['assignments'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          _counts = (data['counts'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as int));
          _todayDisplay = data['today_display'] as String? ?? '';
          _tab = tab;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load assignments.';
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

  List<Map<String, dynamic>> get _filteredAssignments {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _assignments;

    return _assignments.where((m) {
      final haystack = [
        m['match_title'],
        m['title'],
        m['event_name'],
        m['teams_label'],
        m['venue'],
        m['sport'],
        m['round_label_display'],
        m['date_display'],
        m['time_display'],
      ].whereType<String>().join(' ').toLowerCase();
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

  void _editMatch(Map<String, dynamic> match) {
    if (widget.onEditMatch != null) {
      widget.onEditMatch!(match);
      return;
    }
    openScorerLiveScoring(context, match: match, onSaved: () => _load());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAssignments;

    return ColoredBox(
      color: scorerBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Assignments',
                        style: TextStyle(
                          color: scorerNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Matches assigned to you.',
                        style: TextStyle(color: scorerMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scorerWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: scorerNavy.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: scorerGold),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(color: scorerMuted, fontSize: 10),
                          ),
                          Text(
                            _todayDisplay.isEmpty ? '—' : _todayDisplay,
                            style: const TextStyle(
                              color: scorerNavy,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: scorerNavy),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search match, team or venue...',
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
                            const BorderSide(color: scorerNavy, width: 1.2),
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
          const SizedBox(height: 14),
          _AssignmentTabs(
            current: _tab,
            counts: _counts,
            onChanged: (tab) => _load(status: tab),
          ),
          const SizedBox(height: 8),
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
                                  ? 'No matches in this category.'
                                  : 'No matches match your search.',
                              style: const TextStyle(color: scorerMuted),
                            ),
                          )
                        : RefreshIndicator(
                            color: scorerGold,
                            onRefresh: () => _load(),
                            child: ListView(
                              children: [
                                ...filtered.asMap().entries.map(
                                      (e) => ScorerAssignmentCard(
                                        match: e.value,
                                        accentNavy: e.key.isOdd,
                                        onTap: () => _editMatch(e.value),
                                      ),
                                    ),
                                const ScorerReminderBox(),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTabs extends StatelessWidget {
  const _AssignmentTabs({
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
      ('live', 'Live'),
      ('upcoming', 'Upcoming'),
      ('completed', 'Completed'),
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
                  color: isActive ? scorerNavy : const Color(0xFFEEEDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '${tab.$2} ($count)',
                      style: TextStyle(
                        color: isActive ? scorerWhite : scorerNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: scorerGold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
