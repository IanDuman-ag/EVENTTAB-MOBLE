import 'package:flutter/material.dart';

import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

class JudgeAssignmentsPage extends StatelessWidget {
  const JudgeAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: judgeBg,
      body: SafeArea(child: JudgeAssignmentsBody()),
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
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get allAssignments => _assignments;

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
    final data = await JudgeApi.getJson(
      '/api/events/judge/assignments/?status=$tab',
    );
    if (!mounted) return;

    if (data != null) {
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
  }

  void _openAssignment(Map<String, dynamic> assignment) {
    if (widget.onOpenAssignment != null) {
      widget.onOpenAssignment!(assignment);
      return;
    }
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
                child: Text(
                  'My Assignments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: judgeCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: judgeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Today',
                      style: TextStyle(
                        color: judgeMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _todayDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatusTabs(
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
                  : _assignments.isEmpty
                      ? const Center(
                          child: Text(
                            'No assignments in this category.',
                            style: TextStyle(color: judgeMuted),
                          ),
                        )
                      : RefreshIndicator(
                          color: judgeCyan,
                          onRefresh: () => _load(),
                          child: ListView(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            children: _assignments
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
    final tabs = [
      ('upcoming', 'UPCOMING'),
      ('ongoing', 'ONGOING'),
      ('completed', 'COMPLETED'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isActive = current == tab.$1;
          final count = counts[tab.$1] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: Column(
                children: [
                  Text(
                    '${tab.$2} ($count)',
                    style: TextStyle(
                      color: isActive ? judgeCyan : judgeMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 80,
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
