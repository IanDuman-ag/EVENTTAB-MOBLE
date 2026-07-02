import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

class JudgeScoreHistoryPage extends StatefulWidget {
  const JudgeScoreHistoryPage({super.key});

  @override
  State<JudgeScoreHistoryPage> createState() => _JudgeScoreHistoryPageState();
}

class _JudgeScoreHistoryPageState extends State<JudgeScoreHistoryPage> {
  List<Map<String, dynamic>> _entries = [];
  Map<String, int> _counts = {};
  String _tab = 'all';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final tab = status ?? _tab;
    final data =
        await JudgeApi.getJson('/api/events/judge/score-history/?status=$tab');
    if (!mounted) return;

    if (data != null) {
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
        _error = 'Could not load score history.';
        _isLoading = false;
      });
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
              SizedBox(height: 6),
              Text(
                'View all the scores you have submitted.',
                style: TextStyle(color: judgeMuted, fontSize: 13),
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
                  child: CircularProgressIndicator(color: judgeCyan),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!,
                              style: const TextStyle(color: judgeMuted)),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _entries.isEmpty
                      ? const Center(
                          child: Text(
                            'No scores submitted yet.',
                            style: TextStyle(color: judgeMuted),
                          ),
                        )
                      : RefreshIndicator(
                          color: judgeCyan,
                          onRefresh: () => _load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: _entries.length,
                            itemBuilder: (_, i) =>
                                _ScoreHistoryCard(entry: _entries[i]),
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
      ('all', 'ALL'),
      ('pending', 'PENDING'),
      ('approved', 'APPROVED'),
      ('rejected', 'REJECTED'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isActive = current == tab.$1;
          final count = counts[tab.$1] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: Column(
                children: [
                  Text(
                    '${tab.$2} ($count)',
                    style: TextStyle(
                      color: isActive ? judgeCyan : judgeMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 70,
                    color: isActive ? judgeCyan : Colors.transparent,
                  ),
                ],
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
    final status = entry['status'] as String? ?? 'pending';
    final icon = judgeCategoryIcon(entry['category_icon'] as String?);
    final score = entry['score'];
    final maxScore = entry['max_score'] ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: judgeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: judgeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: judgePurple.withValues(alpha: 0.2),
                child: Icon(icon, color: judgePurple, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                entry['category_label'] as String? ?? '',
                style: const TextStyle(
                  color: judgeMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry['date_display']} | ${entry['time_display']} | ${entry['venue']}',
                  style: const TextStyle(color: judgeMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                        text: '${entry['subject_type']}: ',
                        style: const TextStyle(color: judgeMuted),
                      ),
                      TextSpan(
                        text: entry['subject_name'] as String? ?? '',
                        style: const TextStyle(
                          color: judgeCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: judgeBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Criteria: ${entry['criteria_count'] ?? 0}',
                    style: const TextStyle(color: judgeMuted, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry['submitted_at_display'] as String? ?? '',
                  style: const TextStyle(color: judgeMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score / $maxScore',
                style: const TextStyle(
                  color: judgePurple,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _ReviewBadge(status: status, label: entry['status_label']),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, color: judgeCyan),
        ],
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
        color = judgeYellow;
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
