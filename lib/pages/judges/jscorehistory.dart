import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';

class JudgeScoreHistoryPage extends StatefulWidget {
  const JudgeScoreHistoryPage({super.key});

  @override
  State<JudgeScoreHistoryPage> createState() => _JudgeScoreHistoryPageState();
}

class _JudgeScoreHistoryPageState extends State<JudgeScoreHistoryPage> {
  List<Map<String, dynamic>> _entries = [];
  Map<String, int> _counts = {};
  String _tab = 'all';
  DateTime? _filterDate;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _dateLabel {
    final d = _filterDate ?? DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: judgeNavy,
              secondary: judgeGold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _filterDate = picked);
    _load();
  }

  Future<void> _load({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tab = status ?? _tab;
    var path = '/api/events/judge/score-history/?status=$tab';
    if (_filterDate != null) {
      final d = _filterDate!;
      final iso =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      path += '&date_from=$iso&date_to=$iso';
    }

    final data = await JudgeApi.getJson(path);
    if (!mounted) return;

    if (data != null) {
      final raw =
          (data['entries'] as List? ?? []).cast<Map<String, dynamic>>();
      // Only criteria-based submissions.
      final filtered = raw
          .where((e) => ((e['criteria_count'] as num?)?.toInt() ?? 0) > 0)
          .toList();
      setState(() {
        _entries = filtered;
        _counts = (data['counts'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int));
        _tab = tab;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Could not load score history.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);

    return ColoredBox(
      color: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score History',
                        style: TextStyle(
                          color: c.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'View all the scores you have submitted.',
                        style: TextStyle(color: c.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                              'Filter by Date',
                              style: TextStyle(color: c.muted, fontSize: 10),
                            ),
                            Text(
                              _dateLabel,
                              style: TextStyle(
                                color: c.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: c.text, size: 18),
                      ],
                    ),
                  ),
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
                    : _entries.isEmpty
                        ? Center(
                            child: Text(
                              'No scores submitted yet.',
                              style: TextStyle(color: c.muted),
                            ),
                          )
                        : RefreshIndicator(
                            color: judgeGold,
                            onRefresh: () => _load(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 24),
                              itemCount: _entries.length,
                              itemBuilder: (_, i) =>
                                  _ScoreHistoryCard(entry: _entries[i]),
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
    final c = JudgeThemeScope.paletteOf(context);
    final tabs = [
      ('all', 'All', Icons.grid_view_rounded, judgeGold),
      ('pending', 'Pending', Icons.schedule_rounded, c.text),
      ('approved', 'Approved', Icons.check_circle_rounded, judgeGreen),
      ('rejected', 'Disapproved', Icons.cancel_rounded, judgeRed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isActive = current == tab.$1;
          final count = counts[tab.$1] ?? 0;
          final accent = isActive ? judgeGold : tab.$4;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? judgeGold.withValues(alpha: 0.12)
                      : c.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(tab.$3, size: 15, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          '${tab.$2} ($count)',
                          style: TextStyle(
                            color: isActive ? judgeGold : c.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: 26,
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

class _ScoreHistoryCard extends StatelessWidget {
  const _ScoreHistoryCard({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    final status = entry['status'] as String? ?? 'pending';
    final icon = judgeCategoryIcon(entry['category_icon'] as String?);
    final score = entry['score'];
    final maxScore = entry['max_score'] ?? 100;
    final subject = entry['subject_name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.07),
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
            Container(width: 5, color: judgeGold),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: judgeGold.withValues(alpha: 0.14),
                          child: Icon(icon, color: judgeGold, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: judgeGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (entry['category_label'] as String? ?? '')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: judgeGold,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['title'] as String? ?? '',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              entry['date_display'],
                              entry['time_display'],
                              entry['venue'],
                            ]
                                .where((v) =>
                                    (v as String?)?.isNotEmpty == true)
                                .join(' | '),
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${entry['subject_type'] ?? 'Participant'}: ',
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                ...judgeSubjectSpans(
                                  subject,
                                  muted: c.muted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.chip,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Criteria: ${entry['criteria_count'] ?? 0}',
                              style: TextStyle(
                                color: c.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry['submitted_at_display'] as String? ?? '',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score / $maxScore',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: judgeGold, size: 20),
                        const SizedBox(height: 8),
                        _ReviewBadge(
                          status: status,
                          label: entry['status_label'],
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

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge({required this.status, required this.label});

  final String status;
  final dynamic label;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (status) {
      case 'approved':
        icon = Icons.check_circle_rounded;
        color = judgeGreen;
      case 'rejected':
        icon = Icons.cancel_rounded;
        color = judgeRed;
      default:
        icon = Icons.schedule_rounded;
        color = judgeGold;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
