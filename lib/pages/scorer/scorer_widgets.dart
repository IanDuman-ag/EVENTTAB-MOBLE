import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import 'scorerscores.dart';

class ScorerMatchCard extends StatelessWidget {
  const ScorerMatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> match;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final teamA = match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = match['team_b'] as Map<String, dynamic>? ?? {};
    final status = match['status'] as String? ?? 'upcoming';
    final isLive = status == 'live';
    final scoreA = match['score_a'];
    final scoreB = match['score_b'];

    return Material(
      color: scorerCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? scorerGreen : scorerBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isLive)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: scorerGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      (match['title'] as String? ?? '').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isLive ? scorerGreen : scorerMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              Row(
                children: [
                  Expanded(
                    child: _TeamScoreLine(
                      name: teamA['abbreviation'] as String? ?? 'A',
                      color: scorerParseColor(teamA['color'] as String?),
                      score: scoreA?.toString() ?? '–',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: scorerMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamScoreLine(
                      name: teamB['abbreviation'] as String? ?? 'B',
                      color: scorerParseColor(teamB['color'] as String?),
                      score: scoreB?.toString() ?? '–',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 14, color: scorerCyan),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to update score',
                      style: TextStyle(
                        color: scorerCyan.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreLine extends StatelessWidget {
  const _TeamScoreLine({
    required this.name,
    required this.color,
    required this.score,
    this.alignEnd = false,
  });

  final String name;
  final Color color;
  final String score;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: TextStyle(
            color: Colors.white,
            fontSize: alignEnd ? 22 : 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ScorerSectionHeader extends StatelessWidget {
  const ScorerSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: scorerPurple,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ScorerPortalHeader extends StatelessWidget {
  const ScorerPortalHeader({
    super.key,
    this.notificationCount = 0,
    this.onProfile,
  });

  final int notificationCount;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: scorerCard,
        border: Border(bottom: BorderSide(color: scorerBorder)),
      ),
      child: Row(
        children: [
          Image.asset('assets/Finallogo.png', width: 32, height: 32),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVENTTAB',
                  style: TextStyle(
                    color: scorerPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'SCORER PORTAL',
                  style: TextStyle(
                    color: scorerMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white),
              if (notificationCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: scorerRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: scorerPurple.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: scorerPurple, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ScorerBottomNav extends StatelessWidget {
  const ScorerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: scorerCard,
        border: Border(top: BorderSide(color: scorerBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScorerNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _ScorerNavItem(
                icon: Icons.assignment_rounded,
                label: 'Assignments',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _ScorerNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'History',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _ScorerNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorerNavItem extends StatelessWidget {
  const _ScorerNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? scorerPurple : scorerMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ScorerStatCard extends StatelessWidget {
  const ScorerStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scorerCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scorerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: scorerMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class ScorerAssignmentCard extends StatelessWidget {
  const ScorerAssignmentCard({
    super.key,
    required this.match,
    required this.onTap,
    this.compact = false,
  });

  final Map<String, dynamic> match;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = match['status'] as String? ?? 'upcoming';
    final isLive = status == 'live';
    final icon = scorerSportIcon(match['sport_icon'] as String?);
    final scoreA = match['score_a'];
    final scoreB = match['score_b'];
    final hasScores = scoreA != null || scoreB != null;

    Color statusColor;
    switch (status) {
      case 'live':
        statusColor = scorerRed;
      case 'completed':
        statusColor = scorerGreen;
      default:
        statusColor = scorerOrange;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, compact ? 10 : 14),
      child: Material(
        color: scorerCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLive ? scorerRed : scorerBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scorerPurple.withValues(alpha: 0.15),
                      child: Icon(icon, color: scorerPurple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match['match_title'] as String? ??
                                match['title'] as String? ??
                                'Match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            match['teams_label'] as String? ?? '',
                            style: const TextStyle(
                              color: scorerMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: scorerMuted),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: scorerMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${match['date_display'] ?? ''} • ${match['time_display'] ?? ''}',
                        style: const TextStyle(color: scorerMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: scorerMuted),
                      const SizedBox(width: 6),
                      Text(
                        match['venue'] as String? ?? '—',
                        style: const TextStyle(color: scorerMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
                if (hasScores && !compact) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$scoreA - $scoreB',
                    style: const TextStyle(
                      color: scorerPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                if (!compact && status != 'completed') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: match['has_started_scoring'] == true
                        ? FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: scorerPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              match['action_label'] as String? ??
                                  'CONTINUE SCORING',
                            ),
                          )
                        : OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scorerPurple,
                              side: const BorderSide(color: scorerPurple),
                            ),
                            child: Text(
                              match['action_label'] as String? ??
                                  'START SCORING',
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScorerReminderBox extends StatelessWidget {
  const ScorerReminderBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scorerBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scorerBlue.withValues(alpha: 0.35)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: scorerBlue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Please ensure scores are accurate before submitting. '
                'You can only submit once per match.',
                style: TextStyle(color: scorerMuted, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showScorerScoreEditor(
  BuildContext context, {
  required Map<String, dynamic> match,
  required VoidCallback onSaved,
}) {
  openScorerLiveScoring(context, match: match, onSaved: onSaved);
}

class ScorerScoreEditorSheet extends StatefulWidget {
  const ScorerScoreEditorSheet({
    super.key,
    required this.match,
    required this.onSaved,
  });

  final Map<String, dynamic> match;
  final VoidCallback onSaved;

  @override
  State<ScorerScoreEditorSheet> createState() => _ScorerScoreEditorSheetState();
}

class _ScorerScoreEditorSheetState extends State<ScorerScoreEditorSheet> {
  late final TextEditingController _scoreACtrl;
  late final TextEditingController _scoreBCtrl;
  late String _status;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scoreACtrl = TextEditingController(
      text: widget.match['score_a']?.toString() ?? '0',
    );
    _scoreBCtrl = TextEditingController(
      text: widget.match['score_b']?.toString() ?? '0',
    );
    _status = widget.match['status'] as String? ?? 'upcoming';
  }

  @override
  void dispose() {
    _scoreACtrl.dispose();
    _scoreBCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final scoreA = int.tryParse(_scoreACtrl.text.trim());
    final scoreB = int.tryParse(_scoreBCtrl.text.trim());
    if (scoreA == null || scoreB == null) {
      setState(() => _error = 'Enter valid scores.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final matchId = widget.match['id'];
      final isBracket = widget.match['source'] == 'bracket';
      final path = isBracket
          ? '/api/events/scorer/bracket/matches/$matchId/score/'
          : '/api/events/scorer/matches/$matchId/score/';
      final res = await ScorerApi.patch(
        path,
        {'score_a': scoreA, 'score_b': scoreB, 'status': _status},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        widget.onSaved();
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

  @override
  Widget build(BuildContext context) {
    final teamA = widget.match['team_a'] as Map<String, dynamic>? ?? {};
    final teamB = widget.match['team_b'] as Map<String, dynamic>? ?? {};
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scorerBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.match['match_title'] as String? ??
                widget.match['title'] as String? ??
                'Update Score',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ScoreField(
                  label: teamA['abbreviation'] as String? ?? 'Team A',
                  controller: _scoreACtrl,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '–',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Expanded(
                child: _ScoreField(
                  label: teamB['abbreviation'] as String? ?? 'Team B',
                  controller: _scoreBCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'STATUS',
            style: TextStyle(
              color: scorerCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _status,
            dropdownColor: scorerCard,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0E1520),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: scorerBorder),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
              DropdownMenuItem(value: 'live', child: Text('Live')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: _isSaving ? null : (v) => setState(() => _status = v!),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: scorerCyan,
                foregroundColor: scorerBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'SAVE SCORE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: scorerMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0E1520),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: scorerBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: scorerCyan, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
