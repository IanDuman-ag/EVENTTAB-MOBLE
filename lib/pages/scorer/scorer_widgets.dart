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
    final words = title.split(' ');
    final first = words.isNotEmpty ? words.first : title;
    final rest = words.length > 1 ? ' ${words.sublist(1).join(' ')}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: first,
                      style: const TextStyle(
                        color: scorerNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: rest,
                      style: const TextStyle(
                        color: scorerNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 42,
                height: 3,
                decoration: BoxDecoration(
                  color: scorerGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
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
    this.onNotifications,
  });

  final int notificationCount;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scorerWhite,
        boxShadow: [
          BoxShadow(
            color: scorerNavy.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/Finallogo.png', width: 34, height: 34),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVENTTAB',
                  style: TextStyle(
                    color: scorerNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'SCORER PORTAL',
                  style: TextStyle(
                    color: scorerMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNotifications,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: scorerNavy, size: 26),
                if (notificationCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: scorerGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: scorerWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onProfile,
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: scorerNavy,
              child: Icon(Icons.person, color: scorerWhite, size: 18),
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
      decoration: BoxDecoration(
        color: scorerWhite,
        boxShadow: [
          BoxShadow(
            color: scorerNavy.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
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
    final color = isActive ? scorerGold : scorerNavy;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? scorerGold.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
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
        decoration: BoxDecoration(
          color: scorerWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: scorerNavy.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Stack(
                children: [
                  Positioned(
                    right: -6,
                    bottom: -8,
                    child: Icon(
                      icon,
                      size: 46,
                      color: color.withValues(alpha: 0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(height: 10),
                      Text(
                        value,
                        style: const TextStyle(
                          color: scorerNavy,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          color: scorerMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const ColoredBox(
              color: scorerGold,
              child: SizedBox(height: 3),
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
    this.accentNavy = false,
  });

  final Map<String, dynamic> match;
  final VoidCallback onTap;
  final bool compact;
  final bool accentNavy;

  @override
  Widget build(BuildContext context) {
    final status = match['status'] as String? ?? 'upcoming';
    final icon = scorerSportIcon(match['sport_icon'] as String?);
    final scoreA = match['score_a'];
    final scoreB = match['score_b'];
    final hasScores = scoreA != null || scoreB != null;
    final teams = match['teams_label'] as String? ?? '';
    final stripe = accentNavy ? scorerNavy : scorerGold;

    Color statusColor;
    switch (status) {
      case 'live':
        statusColor = scorerRed;
      case 'completed':
        statusColor = scorerGreen;
      default:
        statusColor = scorerGold;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, compact ? 10 : 12),
      child: Material(
        color: scorerWhite,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
                            bottom: -8,
                            child: Icon(
                              icon,
                              size: 64,
                              color: scorerNavy.withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: scorerNavy,
                                    child: Icon(icon, color: scorerGold, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      match['match_title'] as String? ??
                                          match['title'] as String? ??
                                          'Match',
                                      style: const TextStyle(
                                        color: scorerNavy,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
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
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: scorerMuted, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                                        match['date_display'],
                                        match['time_display'],
                                      ]
                                          .where((v) =>
                                              (v as String?)?.isNotEmpty == true)
                                          .join(' • '),
                                      style: const TextStyle(
                                        color: scorerMuted,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: scorerMuted),
                                  const SizedBox(width: 2),
                                  Text(
                                    match['venue'] as String? ?? '—',
                                    style: const TextStyle(
                                      color: scorerMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (hasScores) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '$scoreA - $scoreB',
                                  style: const TextStyle(
                                    color: scorerGold,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ] else if (status == 'upcoming') ...[
                                const SizedBox(height: 10),
                                const Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 14, color: scorerGold),
                                    SizedBox(width: 6),
                                    Text(
                                      'Upcoming match',
                                      style: TextStyle(
                                        color: scorerGold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
          color: scorerCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scorerGold.withValues(alpha: 0.45)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: scorerGold, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please ensure scores are accurate before submitting.',
                    style: TextStyle(
                      color: scorerNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You can only submit once per match.',
                    style: TextStyle(
                      color: scorerGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
