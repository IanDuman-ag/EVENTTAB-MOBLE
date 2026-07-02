import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import '../auth/scorer_auth_service.dart';

/// Live scoring screen — opened from Start/Continue Scoring on assignments.
class ScorerScoresPage extends StatefulWidget {
  const ScorerScoresPage({
    super.key,
    required this.matchId,
    this.onSaved,
  });

  final int matchId;
  final VoidCallback? onSaved;

  @override
  State<ScorerScoresPage> createState() => _ScorerScoresPageState();
}

class _ScoreSnapshot {
  const _ScoreSnapshot(this.a, this.b, this.foulsA, this.foulsB);
  final int a;
  final int b;
  final int foulsA;
  final int foulsB;
}

class _ScorerScoresPageState extends State<ScorerScoresPage> {
  Map<String, dynamic>? _match;
  int _scoreA = 0;
  int _scoreB = 0;
  int _foulsA = 0;
  int _foulsB = 0;
  final _undoStack = <_ScoreSnapshot>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res =
          await ScorerApi.get('/api/events/scorer/bracket/matches/${widget.matchId}/');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _match = data;
          _scoreA = _asInt(data['score_a']);
          _scoreB = _asInt(data['score_b']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load match.';
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

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  bool get _isLocked {
    final status = _match?['status'] as String? ?? '';
    return status == 'completed' || _match?['is_score_locked'] == true;
  }

  void _pushUndo() {
    _undoStack.add(_ScoreSnapshot(_scoreA, _scoreB, _foulsA, _foulsB));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _addPoints(bool teamA, int points) {
    if (_isLocked) return;
    _pushUndo();
    setState(() {
      if (teamA) {
        _scoreA += points;
      } else {
        _scoreB += points;
      }
    });
  }

  void _adjustScore(bool teamA, int delta) {
    if (_isLocked) return;
    _pushUndo();
    setState(() {
      if (teamA) {
        _scoreA = (_scoreA + delta).clamp(0, 999);
      } else {
        _scoreB = (_scoreB + delta).clamp(0, 999);
      }
    });
  }

  void _undo() {
    if (_isLocked || _undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    setState(() {
      _scoreA = prev.a;
      _scoreB = prev.b;
      _foulsA = prev.foulsA;
      _foulsB = prev.foulsB;
    });
  }

  Future<void> _save({required String status, bool popOnSuccess = false}) async {
    if (_isSaving || _isLocked) return;
    setState(() => _isSaving = true);

    try {
      final res = await ScorerApi.patch(
        '/api/events/scorer/bracket/matches/${widget.matchId}/score/',
        {
          'score_a': _scoreA,
          'score_b': _scoreB,
          'status': status,
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          final locked = status == 'completed' ||
              data['status'] == 'completed' ||
              data['is_score_locked'] == true;
          _match = {
            ...?_match,
            ...data,
            if (locked) 'is_score_locked': true,
          };
          _scoreA = _asInt(data['score_a']);
          _scoreB = _asInt(data['score_b']);
          _isSaving = false;
        });
        widget.onSaved?.call();
        if (popOnSuccess) {
          final summary = _buildSubmissionSummary();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ScorerSubmissionSuccessPage(summary: summary),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'completed'
                    ? 'Final score submitted.'
                    : 'Score updated.',
              ),
              backgroundColor: scorerGreen,
            ),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        setState(() {
          _error = body['detail']?.toString() ?? 'Save failed.';
          _isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not reach the server.';
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildSubmissionSummary() {
    final match = _match ?? {};
    final teamA = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = match['team_b'] as Map<String, dynamic>? ?? {};
    final user = ScorerAuthSession.current;
    final displayName = user?.label?.isNotEmpty == true
        ? user!.label!
        : (user?.username ?? 'Scorer')
            .replaceAll('_', ' ')
            .split(' ')
            .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
            .join(' ');
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');

    return {
      'event': match['event_name'] as String? ??
          match['match_title'] as String? ??
          'Event',
      'match': match['teams_label'] as String? ?? 'Match',
      'score_a': _scoreA,
      'score_b': _scoreB,
      'team_a_name': teamA['name'] as String? ?? 'Team A',
      'team_b_name': teamB['name'] as String? ?? 'Team B',
      'team_a_color': teamA['color'] as String? ?? '#2196F3',
      'team_b_color': teamB['color'] as String? ?? '#FF5252',
      'submitted_at_display':
          '${months[now.month - 1]} ${now.day}, ${now.year} • $hour:$minute $amPm',
      'submitted_by': '$displayName (Scorer)',
      'status': 'PENDING VERIFICATION',
    };
  }

  String _formatSchedule(Map<String, dynamic> match) {
    final date = match['date_display'] as String? ?? '';
    final time = match['time_display'] as String? ?? '';
    if (date.isEmpty) return time;
    if (time.isEmpty) return date;
    return '$date • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isLocked ? 'Final Score' : 'Live Scoring',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadMatch,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: scorerPurple))
          : _error != null && _match == null
              ? Center(child: Text(_error!, style: const TextStyle(color: scorerMuted)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final match = _match!;
    final teamA = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = match['team_b'] as Map<String, dynamic>? ?? {};
    final teamAName = teamA['name'] as String? ?? 'Team A';
    final teamBName = teamB['name'] as String? ?? 'Team B';
    final teamAColor = scorerParseColor(teamA['color'] as String?);
    final teamBColor = scorerParseColor(teamB['color'] as String?);
    final status = match['status'] as String? ?? 'upcoming';
    final isLive = status == 'live';
    final isLocked = _isLocked;
    final roundLabel =
        (match['round_label_display'] as String? ?? 'Match').toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MatchInfoCard(
            title: match['match_title'] as String? ?? match['title'] as String? ?? 'Match',
            teamsLabel: match['teams_label'] as String? ?? '$teamAName vs $teamBName',
            schedule: _formatSchedule(match),
            venue: match['venue'] as String? ?? '—',
            isLive: isLive && !isLocked,
            isLocked: isLocked,
          ),
          if (isLocked) ...[
            const SizedBox(height: 16),
            const _LockedScoreBanner(),
          ],
          const SizedBox(height: 20),
          _Scoreboard(
            teamAName: teamAName,
            teamBName: teamBName,
            teamAColor: teamAColor,
            teamBColor: teamBColor,
            scoreA: _scoreA,
            scoreB: _scoreB,
            foulsA: _foulsA,
            foulsB: _foulsB,
            periodLabel: roundLabel,
            timerLabel: isLocked
                ? 'Final'
                : (isLive
                    ? 'In Progress'
                    : (match['time_display'] as String? ?? 'Scheduled')),
            onFoulA: isLocked
                ? null
                : () => setState(() => _foulsA = (_foulsA + 1).clamp(0, 5)),
            onFoulB: isLocked
                ? null
                : () => setState(() => _foulsB = (_foulsB + 1).clamp(0, 5)),
          ),
          if (!isLocked) ...[
            const SizedBox(height: 24),
            _QuickScoreSection(
              teamAName: teamAName,
              teamBName: teamBName,
              teamAColor: teamAColor,
              teamBColor: teamBColor,
              onAddA: (pts) => _addPoints(true, pts),
              onAddB: (pts) => _addPoints(false, pts),
            ),
            const SizedBox(height: 24),
            _ManualScoreSection(
              scoreA: _scoreA,
              scoreB: _scoreB,
              onDecA: () => _adjustScore(true, -1),
              onIncA: () => _adjustScore(true, 1),
              onDecB: () => _adjustScore(false, -1),
              onIncB: () => _adjustScore(false, 1),
              onUndo: _undoStack.isEmpty ? null : _undo,
              onUpdate: _isSaving ? null : () => _save(status: 'live'),
              isSaving: _isSaving,
            ),
            if (_error != null && _match != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: scorerRed, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _isSaving ? null : () => _save(status: 'completed', popOnSuccess: true),
                style: FilledButton.styleFrom(
                  backgroundColor: scorerGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'SUBMIT FINAL SCORE',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedScoreBanner extends StatelessWidget {
  const _LockedScoreBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scorerGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scorerGreen.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: scorerGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Final score submitted. Scores are locked and cannot be edited.',
              style: TextStyle(color: scorerMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  const _MatchInfoCard({
    required this.title,
    required this.teamsLabel,
    required this.schedule,
    required this.venue,
    required this.isLive,
    this.isLocked = false,
  });

  final String title;
  final String teamsLabel;
  final String schedule;
  final String venue;
  final bool isLive;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scorerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scorerGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 12, color: scorerGreen),
                      SizedBox(width: 6),
                      Text(
                        'LOCKED',
                        style: TextStyle(
                          color: scorerGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scorerRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: scorerRed),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: scorerRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(teamsLabel, style: const TextStyle(color: scorerMuted, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: scorerMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(schedule, style: const TextStyle(color: scorerMuted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: scorerMuted),
              const SizedBox(width: 6),
              Text(venue, style: const TextStyle(color: scorerMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.teamAName,
    required this.teamBName,
    required this.teamAColor,
    required this.teamBColor,
    required this.scoreA,
    required this.scoreB,
    required this.foulsA,
    required this.foulsB,
    required this.periodLabel,
    required this.timerLabel,
    this.onFoulA,
    this.onFoulB,
  });

  final String teamAName;
  final String teamBName;
  final Color teamAColor;
  final Color teamBColor;
  final int scoreA;
  final int scoreB;
  final int foulsA;
  final int foulsB;
  final String periodLabel;
  final String timerLabel;
  final VoidCallback? onFoulA;
  final VoidCallback? onFoulB;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scorerCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scorerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamScoreColumn(
              name: teamAName,
              color: teamAColor,
              score: scoreA,
              fouls: foulsA,
              onFoulTap: onFoulA,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  periodLabel,
                  style: const TextStyle(
                    color: scorerPurple,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$scoreA - $scoreB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timerLabel,
                  style: const TextStyle(color: scorerMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: _TeamScoreColumn(
              name: teamBName,
              color: teamBColor,
              score: scoreB,
              fouls: foulsB,
              onFoulTap: onFoulB,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreColumn extends StatelessWidget {
  const _TeamScoreColumn({
    required this.name,
    required this.color,
    required this.score,
    required this.fouls,
    this.onFoulTap,
    this.alignEnd = false,
  });

  final String name;
  final Color color;
  final int score;
  final int fouls;
  final VoidCallback? onFoulTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onFoulTap,
          behavior: onFoulTap == null ? HitTestBehavior.deferToChild : null,
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              const Text(
                'FOULS',
                style: TextStyle(color: scorerMuted, fontSize: 9, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final active = i < fouls;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? scorerOrange : scorerBorder,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickScoreSection extends StatelessWidget {
  const _QuickScoreSection({
    required this.teamAName,
    required this.teamBName,
    required this.teamAColor,
    required this.teamBColor,
    required this.onAddA,
    required this.onAddB,
  });

  final String teamAName;
  final String teamBName;
  final Color teamAColor;
  final Color teamBColor;
  final ValueChanged<int> onAddA;
  final ValueChanged<int> onAddB;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK SCORE',
          style: TextStyle(
            color: scorerPurple,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(teamAName, style: TextStyle(color: teamAColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3]
              .map((pts) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickButton(
                        label: '+$pts',
                        color: teamAColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onAddA(pts);
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(teamBName, style: TextStyle(color: teamBColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3]
              .map((pts) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuickButton(
                        label: '+$pts',
                        color: teamBColor,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onAddB(pts);
                        },
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualScoreSection extends StatelessWidget {
  const _ManualScoreSection({
    required this.scoreA,
    required this.scoreB,
    required this.onDecA,
    required this.onIncA,
    required this.onDecB,
    required this.onIncB,
    required this.onUndo,
    required this.onUpdate,
    required this.isSaving,
  });

  final int scoreA;
  final int scoreB;
  final VoidCallback onDecA;
  final VoidCallback onIncA;
  final VoidCallback onDecB;
  final VoidCallback onIncB;
  final VoidCallback? onUndo;
  final VoidCallback? onUpdate;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MANUAL SCORE INPUT',
          style: TextStyle(
            color: scorerPurple,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _ScoreStepper(value: scoreA, onDec: onDecA, onInc: onIncA),
        const SizedBox(height: 12),
        _ScoreStepper(value: scoreB, onDec: onDecB, onInc: onIncB),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUndo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scorerMuted,
                  side: const BorderSide(color: scorerBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('UNDO'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onUpdate,
                style: FilledButton.styleFrom(
                  backgroundColor: scorerPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: const Text('UPDATE SCORE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  const _ScoreStepper({
    required this.value,
    required this.onDec,
    required this.onInc,
  });

  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.remove, onTap: onDec),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1520),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scorerBorder),
            ),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        _RoundIconButton(icon: Icons.add, onTap: onInc),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scorerCard,
      shape: const CircleBorder(side: BorderSide(color: scorerBorder)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Submission success screen shown after final score is submitted.
class ScorerSubmissionSuccessPage extends StatelessWidget {
  const ScorerSubmissionSuccessPage({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final scoreA = summary['score_a'];
    final scoreB = summary['score_b'];
    final teamAColor = scorerParseColor(summary['team_a_color'] as String?);
    final teamBColor = scorerParseColor(summary['team_b_color'] as String?);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scorerGreen.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: scorerGreen.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: scorerGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Submission Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your scores have been submitted successfully and are now pending verification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scorerMuted, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scorerCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scorerBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in_rounded,
                            color: scorerGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Submission Summary',
                          style: TextStyle(
                            color: scorerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      icon: Icons.event_rounded,
                      iconColor: scorerPurple,
                      label: 'Event',
                      value: summary['event'] as String? ?? '',
                    ),
                    _SummaryRow(
                      icon: Icons.groups_rounded,
                      iconColor: scorerBlue,
                      label: 'Match',
                      value: summary['match'] as String? ?? '',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: scorerOrange, size: 18),
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 72,
                            child: Text('Final Score',
                                style: TextStyle(color: scorerMuted, fontSize: 13)),
                          ),
                          Text(
                            '$scoreA',
                            style: TextStyle(
                              color: teamAColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('–',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                          ),
                          Text(
                            '$scoreB',
                            style: TextStyle(
                              color: teamBColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SummaryRow(
                      icon: Icons.schedule_rounded,
                      iconColor: scorerGreen,
                      label: 'Submitted On',
                      value: summary['submitted_at_display'] as String? ?? '',
                    ),
                    _SummaryRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: scorerPurple,
                      label: 'Submitted By',
                      value: summary['submitted_by'] as String? ?? '',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              color: scorerGreen, size: 18),
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 72,
                            child: Text('Status',
                                style: TextStyle(color: scorerMuted, fontSize: 13)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scorerGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: scorerGreen.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: scorerGreen, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  summary['status'] as String? ??
                                      'PENDING VERIFICATION',
                                  style: const TextStyle(
                                    color: scorerGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scorerPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scorerPurple.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: scorerPurple, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your submission will be reviewed by the tabulator. You will be notified once it is approved.',
                            style: TextStyle(
                              color: scorerMuted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: scorerPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text(
                    'View Submission',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scorerPurple,
                    side: const BorderSide(color: scorerPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: scorerMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigate to live scoring for a bracket match.
/// Returns shell tab index to switch to (0 = Home, 2 = History) when done.
Future<int?> openScorerLiveScoring(
  BuildContext context, {
  required Map<String, dynamic> match,
  VoidCallback? onSaved,
}) {
  final matchId = match['id'] as int?;
  if (matchId == null) return Future.value(null);

  return Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) => ScorerScoresPage(
        matchId: matchId,
        onSaved: onSaved,
      ),
    ),
  );
}
