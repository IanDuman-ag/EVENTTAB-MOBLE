import 'package:flutter/material.dart';

import 'jevent_detail.dart';
import 'judge_api.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';
import 'jscoring_wizard.dart';

class JudgeViewAssignmentPage extends StatefulWidget {
  const JudgeViewAssignmentPage({
    super.key,
    required this.judgingEventId,
  });

  final int judgingEventId;

  @override
  State<JudgeViewAssignmentPage> createState() =>
      _JudgeViewAssignmentPageState();
}

class _JudgeViewAssignmentPageState extends State<JudgeViewAssignmentPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final data = await JudgeApi.getJson(
      '/api/events/judge/assignments/${widget.judgingEventId}/',
    );
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Assignment not found.';
        _isLoading = false;
      });
    }
  }

  void _viewContestants() {
    final participants = (_data!['participants'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (participants.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JEventDetailPage(eventId: widget.judgingEventId),
        ),
      );
      return;
    }

    final criteria = (_data!['criteria'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ContestantListPage(
          eventId: widget.judgingEventId,
          eventTitle: _data!['title'] as String? ?? '',
          criteria: criteria,
          participants: participants,
          currentStage: _data!['current_stage'] as Map<String, dynamic>?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: judgeBg,
      body: SafeArea(
        child: Column(
          children: [
            JudgePortalHeader(
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(child: _body()),
            if (_data != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _viewContestants,
                    style: FilledButton.styleFrom(
                      backgroundColor: judgeGold,
                      foregroundColor: judgeNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Contestants',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: judgeCyan),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: judgeMuted)),
      );
    }

    final data = _data!;
    final assignment = data['assignment'] as Map<String, dynamic>? ?? {};
    final criteria =
        (data['criteria'] as List? ?? []).cast<Map<String, dynamic>>();
    final participants =
        (data['participants'] as List? ?? []).cast<Map<String, dynamic>>();
    final icon = judgeCategoryIcon(data['category_icon'] as String?);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Assignment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review the event details and your judging assignment.',
                      style: TextStyle(color: judgeMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              JudgeStatusBadge(
                status: data['status'] as String? ?? 'upcoming',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: judgeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: judgeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: judgePurple.withValues(alpha: 0.2),
                          child: Icon(icon, color: judgePurple),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['category_label'] as String? ?? '',
                          style: const TextStyle(
                            color: judgeMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: judgePurple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (data['assignment_type'] as String? ?? 'EVENT')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: judgePurple,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['title'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data['date_display']} | ${data['time_display']} | ${data['venue']}',
                            style: const TextStyle(
                              color: judgeMuted,
                              fontSize: 12,
                            ),
                          ),
                          if ((data['description'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 10),
                            Text(
                              data['description'] as String,
                              style: const TextStyle(
                                color: judgeMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _SideStat(
                          value: '${data['participant_count'] ?? 0}',
                          label: 'Participants',
                        ),
                        const SizedBox(height: 10),
                        _SideStat(
                          value: '${data['criteria_count'] ?? 0}',
                          label: 'Criteria',
                        ),
                        const SizedBox(height: 10),
                        _SideStat(
                          value: '${data['total_points'] ?? 100}',
                          label: 'Total Pts',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: judgeCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: judgeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR ASSIGNMENT',
                  style: TextStyle(
                    color: judgeCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Assigned Role',
                  value: assignment['role_detail'] as String? ?? 'Judge',
                ),
                _InfoLine(
                  label: 'Judge ID',
                  value: assignment['judge_id'] as String? ?? '—',
                ),
                _InfoLine(
                  label: 'Date Assigned',
                  value: assignment['assigned_at_display'] as String? ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CriteriaList(criteria: criteria),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ParticipantsList(participants: participants),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: judgeMuted, fontSize: 9),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: judgeMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaList extends StatelessWidget {
  const _CriteriaList({required this.criteria});

  final List<Map<String, dynamic>> criteria;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: judgeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: judgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCORING CRITERIA',
            style: TextStyle(
              color: judgeCyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...criteria.asMap().entries.map((e) {
            final c = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ${c['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if ((c['description'] as String?)?.isNotEmpty == true)
                    Text(
                      c['description'] as String,
                      style: const TextStyle(color: judgeMuted, fontSize: 10),
                    ),
                  Text(
                    '${c['max_score']} pts',
                    style: const TextStyle(
                      color: judgePurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          Text(
            'TOTAL POINTS: ${criteria.fold<int>(0, (s, c) => s + ((c['max_score'] as num?)?.toInt() ?? 0))} pts',
            style: const TextStyle(
              color: judgeMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsList extends StatelessWidget {
  const _ParticipantsList({required this.participants});

  final List<Map<String, dynamic>> participants;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: judgeCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: judgeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARTICIPANTS (${participants.length})',
            style: const TextStyle(
              color: judgeCyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...participants.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: judgeBorder,
                    child: Text(
                      '${p['number']}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p['name'] as String? ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: judgeMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContestantListPage extends StatelessWidget {
  const _ContestantListPage({
    required this.eventId,
    required this.eventTitle,
    required this.criteria,
    required this.participants,
    this.currentStage,
  });

  final int eventId;
  final String eventTitle;
  final List<Map<String, dynamic>> criteria;
  final List<Map<String, dynamic>> participants;
  final Map<String, dynamic>? currentStage;

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    final active = participants
        .where((p) => p['is_qualified'] != false && p['scoring_status'] != 'not_qualified')
        .toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            JudgePortalHeader(
              showBack: true,
              onBack: () => Navigator.pop(context),
              onNotifications: null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contestants',
                        style: TextStyle(
                            color: c.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    if (currentStage != null)
                      Text(
                        'Stage: ${currentStage!['name'] ?? 'Main Scoring'}',
                        style: const TextStyle(
                            color: judgeGold, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? Center(
                      child: Text('No qualified contestants for this stage.',
                          style: TextStyle(color: c.muted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: active.length,
                      itemBuilder: (_, i) {
                        final p = active[i];
                        final status = p['scoring_status'] as String? ?? 'pending';
                        final action = p['action_label'] as String? ?? 'Score';
                        final note = p['review_note'] as String? ?? '';
                        final color = switch (status) {
                          'submitted' => judgeGreen,
                          'draft' => judgeGold,
                          'returned' => judgeRed,
                          _ => c.muted,
                        };
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: judgeGold.withValues(alpha: 0.15),
                                    backgroundImage: (p['photo'] as String?) != null
                                        ? NetworkImage(p['photo'] as String)
                                        : null,
                                    child: (p['photo'] as String?) == null
                                        ? Text('#${p['number']}',
                                            style: const TextStyle(
                                                color: judgeGold,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '#${p['number']}  ${p['name']}',
                                          style: TextStyle(
                                              color: c.text,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        if ((p['department'] as String?)?.isNotEmpty == true)
                                          Text('${p['department']}',
                                              style: TextStyle(
                                                  color: c.muted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p['scoring_status_label'] as String? ?? status,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              if (status == 'returned' && note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Correction reason: $note',
                                    style: const TextStyle(
                                        color: judgeRed, fontSize: 12)),
                              ],
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: status == 'not_qualified'
                                      ? null
                                      : () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => JudgeScoringWizardPage(
                                                eventId: eventId,
                                                eventTitle: eventTitle,
                                                candidate: p,
                                                criteria: criteria,
                                                initialStep:
                                                    (p['draft_step'] as num?)?.toInt() ?? 0,
                                                readOnly: status == 'submitted',
                                              ),
                                            ),
                                          );
                                          if (result != null && context.mounted) {
                                            // Stay on list; parent can refresh on pop.
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: judgeGold,
                                    foregroundColor: judgeNavy,
                                  ),
                                  child: Text(action),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
