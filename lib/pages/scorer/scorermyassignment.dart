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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
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

  void _editMatch(Map<String, dynamic> match) {
    if (widget.onEditMatch != null) {
      widget.onEditMatch!(match);
      return;
    }
    openScorerLiveScoring(context, match: match, onSaved: () => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                        color: Colors.white,
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
                  color: scorerCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scorerBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(color: scorerMuted, fontSize: 10),
                    ),
                    Text(
                      _todayDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AssignmentTabs(
          current: _tab,
          counts: _counts,
          onChanged: (tab) => _load(status: tab),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: scorerPurple),
                )
              : _error != null
                  ? Center(child: Text(_error!))
                  : _assignments.isEmpty
                      ? const Center(
                          child: Text(
                            'No matches in this category.',
                            style: TextStyle(color: scorerMuted),
                          ),
                        )
                      : RefreshIndicator(
                          color: scorerPurple,
                          onRefresh: () => _load(),
                          child: ListView(
                            children: [
                              ..._assignments.map(
                                (m) => ScorerAssignmentCard(
                                  match: m,
                                  onTap: () => _editMatch(m),
                                ),
                              ),
                              const ScorerReminderBox(),
                            ],
                          ),
                        ),
        ),
      ],
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? scorerPurple : scorerCard,
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
