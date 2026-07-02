import 'dart:convert';

import 'package:flutter/material.dart';

import 'scorer_api.dart';
import 'scorer_theme.dart';
import 'scorer_widgets.dart';

class ScorerBracketPage extends StatefulWidget {
  const ScorerBracketPage({super.key});

  @override
  State<ScorerBracketPage> createState() => _ScorerBracketPageState();
}

class _ScorerBracketPageState extends State<ScorerBracketPage> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ScorerApi.get('/api/events/scorer/bracket/');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _events = (data['events'] as List? ?? []).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load brackets.';
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
    showScorerScoreEditor(context, match: match, onSaved: _loadBracket);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: scorerCyan));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: scorerMuted)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadBracket,
              style: FilledButton.styleFrom(
                backgroundColor: scorerCyan,
                foregroundColor: scorerBg,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Text(
          'No tournament brackets generated yet.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return RefreshIndicator(
      color: scorerCyan,
      onRefresh: _loadBracket,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text(
            'TOURNAMENT BRACKETS',
            style: TextStyle(
              color: scorerCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Generated bracket progression from admin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ..._events.map((event) => _EventBracketSection(
                event: event,
                onEditMatch: _editMatch,
              )),
        ],
      ),
    );
  }
}

class _EventBracketSection extends StatelessWidget {
  const _EventBracketSection({
    required this.event,
    required this.onEditMatch,
  });

  final Map<String, dynamic> event;
  final void Function(Map<String, dynamic> match) onEditMatch;

  @override
  Widget build(BuildContext context) {
    final rounds = (event['rounds'] as List? ?? []).cast<Map<String, dynamic>>();
    final tournamentType = event['tournament_type'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, color: scorerCyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (event['event_name'] as String? ?? 'Event').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (tournamentType.isNotEmpty)
                      Text(
                        tournamentType,
                        style: const TextStyle(color: scorerMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rounds.map(
            (round) => _RoundSection(round: round, onEditMatch: onEditMatch),
          ),
        ],
      ),
    );
  }
}

class _RoundSection extends StatelessWidget {
  const _RoundSection({
    required this.round,
    required this.onEditMatch,
  });

  final Map<String, dynamic> round;
  final void Function(Map<String, dynamic> match) onEditMatch;

  @override
  Widget build(BuildContext context) {
    final matches = (round['matches'] as List? ?? []).cast<Map<String, dynamic>>();
    final roundLabel = round['round_label_display'] as String? ?? 'Round';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scorerCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scorerCyan.withValues(alpha: 0.35)),
            ),
            child: Text(
              roundLabel.toUpperCase(),
              style: const TextStyle(
                color: scorerCyan,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 16,
                      color: scorerMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ScorerMatchCard(
                  match: match,
                  compact: true,
                  onTap: () => onEditMatch(match),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
