import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

class JudgeAssignmentsPage extends StatelessWidget {
  const JudgeAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: const SafeArea(child: JudgeAssignmentsBody()),
    );
  }
}

class JudgeAssignmentsBody extends StatefulWidget {
  const JudgeAssignmentsBody({
    super.key,
    this.onOpenAssignment,
  });

  final ValueChanged<Map<String, dynamic>>? onOpenAssignment;

  @override
  State<JudgeAssignmentsBody> createState() => JudgeAssignmentsBodyState();
}

class JudgeAssignmentsBodyState extends State<JudgeAssignmentsBody> {
  List<Map<String, dynamic>> _assignments = [];
  Map<String, int> _counts = {};
  String _tab = 'upcoming';
  String _todayDisplay = '';
  String _search = '';
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> get allAssignments => _assignments;

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
    // Load all assigned events then filter locally for richer sort/filter.
    final data = await JudgeApi.getJson('/api/events/judge/assignments/');
    if (!mounted) return;

    if (data != null) {
      final raw = (data['assignments'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      var list = raw
          .where((a) =>
              (a['assignment_type'] as String?) == 'CRITERIA BASED' &&
              ((a['criteria_count'] as num?)?.toInt() ?? 0) > 0)
          .toList();
      if (tab != 'all' && tab.isNotEmpty) {
        list = list.where((a) => a['status'] == tab).toList();
      }
      // Nearest schedule first
      list.sort((a, b) {
        final ad = '${a['date'] ?? ''} ${a['time_display'] ?? ''}';
        final bd = '${b['date'] ?? ''} ${b['time_display'] ?? ''}';
        return ad.compareTo(bd);
      });
      setState(() {
        _assignments = list;
        _counts = (data['counts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int));
        _todayDisplay = data['today_display'] as String? ?? '';
        _tab = tab;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Could not load events.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAssignments {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _assignments;

    return _assignments.where((a) {
      final haystack = [
        a['title'],
        a['subtitle'],
        a['venue'],
        a['category_label'],
        a['assignment_type'],
        a['date_display'],
        a['time_display'],
        a['status'],
        ...(a['criteria_names'] as List? ?? []),
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

  void _openAssignment(Map<String, dynamic> assignment) {
    widget.onOpenAssignment?.call(assignment);
  }

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    final filtered = _filteredAssignments;

    return ColoredBox(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My Events',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: judgeGold),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(color: c.muted, fontSize: 10),
                          ),
                          Text(
                            _todayDisplay.isEmpty ? '—' : _todayDisplay,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
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
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: c.text),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search event, venue or criteria...',
                hintStyle: TextStyle(color: c.muted),
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.clear_rounded, color: c.muted),
                        onPressed: _clearSearch,
                      ),
                filled: true,
                fillColor: c.chip,
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
                  borderSide: BorderSide(color: c.text, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _StatusTabs(
            current: _tab,
            counts: _counts,
            onChanged: (tab) => _load(status: tab),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: judgeGold),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: TextStyle(color: c.muted)),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _load(),
                              style: FilledButton.styleFrom(
                                backgroundColor: c.text,
                                foregroundColor: c.surface,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? _EmptyAssignments(
                            isSearch: _search.trim().isNotEmpty,
                          )
                        : RefreshIndicator(
                            color: judgeGold,
                            onRefresh: () => _load(),
                            child: ListView(
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 24),
                              children: filtered
                                  .map(
                                    (a) => JudgeAssignmentCard(
                                      assignment: a,
                                      showCriteria: true,
                                      actionLabel: 'VIEW ASSIGNMENT →',
                                      onTap: () => _openAssignment(a),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments({this.isSearch = false});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.assignment_rounded,
                    size: 88, color: judgeGold.withValues(alpha: 0.25)),
                const Icon(Icons.check_circle_rounded,
                    size: 36, color: judgeGold),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isSearch
                  ? 'No assignments match your search.'
                  : 'No assignments in this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different keyword or clear the search.'
                  : "You're all caught up! New assignments will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  final String current;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    final tabs = [
      ('upcoming', 'Upcoming', Icons.assignment_rounded),
      ('ongoing', 'Ongoing', Icons.hourglass_top_rounded),
      ('completed', 'Completed', Icons.check_circle_outline_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isActive = current == tab.$1;
          final count = counts[tab.$1] ?? 0;
          final color = isActive ? judgeGold : c.text;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? judgeGold.withValues(alpha: 0.12)
                      : c.chip,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(tab.$3, size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          '${tab.$2} ($count)',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                          color: judgeGold,
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
