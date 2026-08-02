import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';
import 'judge_offline.dart';
import 'judge_theme.dart';
import 'judge_widgets.dart';

/// Step-by-step criterion scoring → Review → Submit confirmation.
class JudgeScoringWizardPage extends StatefulWidget {
  const JudgeScoringWizardPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.candidate,
    required this.criteria,
    this.initialStep = 0,
    this.readOnly = false,
  });

  final int eventId;
  final String eventTitle;
  final Map<String, dynamic> candidate;
  final List<Map<String, dynamic>> criteria;
  final int initialStep;
  final bool readOnly;

  @override
  State<JudgeScoringWizardPage> createState() => _JudgeScoringWizardPageState();
}

class _JudgeScoringWizardPageState extends State<JudgeScoringWizardPage> {
  late int _step; // criterion index, or criteria.length for review
  final Map<int, double> _scores = {};
  final Map<int, String> _comments = {};
  final Map<int, TextEditingController> _scoreCtrls = {};
  final Map<int, TextEditingController> _commentCtrls = {};
  bool _busy = false;
  String? _error;
  bool _submitted = false;
  Map<String, dynamic>? _submitResult;

  List<Map<String, dynamic>> get _criteria => widget.criteria;
  bool get _onReview => _step >= _criteria.length;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _criteria.length);
    for (final c in _criteria) {
      final id = c['id'] as int;
      _scores[id] = 0;
      _comments[id] = '';
      _scoreCtrls[id] = TextEditingController(text: '0');
      _commentCtrls[id] = TextEditingController();
    }
    _hydrate();
  }

  @override
  void dispose() {
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hydrate() async {
    // Local draft first
    final local = await JudgeOfflineStore.instance.loadDraft(
      widget.eventId,
      widget.candidate['id'] as int,
    );
    if (local != null) {
      final scores = (local['scores'] as Map<String, dynamic>? ?? {});
      final comments = (local['comments'] as Map<String, dynamic>? ?? {});
      for (final e in scores.entries) {
        final id = int.tryParse(e.key);
        if (id != null) {
          _scores[id] = (e.value as num).toDouble();
          _scoreCtrls[id]?.text = _scores[id]!.toString();
        }
      }
      for (final e in comments.entries) {
        final id = int.tryParse(e.key);
        if (id != null) {
          _comments[id] = '${e.value}';
          _commentCtrls[id]?.text = _comments[id]!;
        }
      }
      _step = (local['draft_step'] as num?)?.toInt() ?? _step;
      if (mounted) setState(() {});
    }

    // Server scores
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.get(
        apiUri(
          '/api/events/judging-events/${widget.eventId}/my_scores/'
          '?candidate_id=${widget.candidate['id']}',
        ),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        for (final s in data) {
          final id = s['criterion'] as int;
          _scores[id] = double.tryParse('${s['score']}') ?? 0;
          _comments[id] = s['comment'] as String? ?? '';
          _scoreCtrls[id]?.text = _scores[id]!.toString();
          _commentCtrls[id]?.text = _comments[id]!;
        }
        if (data.isNotEmpty &&
            data.every((s) => s['is_locked'] == true && s['is_draft'] != true)) {
          _submitted = true;
          _step = _criteria.length;
        } else if (data.any((s) => s['is_draft'] == true)) {
          final step = data
              .map((s) => (s['draft_step'] as num?)?.toInt() ?? 0)
              .fold<int>(0, (a, b) => a > b ? a : b);
          _step = step.clamp(0, _criteria.length);
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Map<String, dynamic> get _currentCriterion => _criteria[_step];

  bool _validateCurrent() {
    if (_onReview) return true;
    final c = _currentCriterion;
    final id = c['id'] as int;
    final minS = (c['min_score'] as num?)?.toDouble() ?? 0;
    final maxS = (c['max_score'] as num?)?.toDouble() ?? 100;
    final decimals = (c['decimal_places'] as num?)?.toInt() ?? 1;
    final text = _scoreCtrls[id]?.text.trim() ?? '';
    final value = double.tryParse(text);
    if (value == null) {
      _error = 'Enter a valid numeric score.';
      return false;
    }
    if (value < minS || value > maxS) {
      _error = 'Score must be between $minS and $maxS.';
      return false;
    }
    final parts = text.split('.');
    if (parts.length > 1 && parts[1].length > decimals) {
      _error = 'Use at most $decimals decimal place(s).';
      return false;
    }
    final comment = _commentCtrls[id]?.text.trim() ?? '';
    var needComment = c['comment_required'] == true;
    final thr = c['low_score_comment_threshold'];
    if (thr != null && value <= (thr as num).toDouble()) {
      needComment = true;
    }
    if (needComment && comment.isEmpty) {
      _error = 'A comment is required for this criterion.';
      return false;
    }
    _scores[id] = value;
    _comments[id] = comment;
    _error = null;
    return true;
  }

  Future<void> _saveDraft({bool showSnack = true}) async {
    // Capture current field
    if (!_onReview) {
      final id = _currentCriterion['id'] as int;
      final v = double.tryParse(_scoreCtrls[id]?.text.trim() ?? '');
      if (v != null) _scores[id] = v;
      _comments[id] = _commentCtrls[id]?.text.trim() ?? '';
    }

    final scoresPayload = _criteria.map((c) {
      final id = c['id'] as int;
      return {
        'criterion_id': id,
        'score': _scores[id] ?? 0,
        'comment': _comments[id] ?? '',
      };
    }).toList();

    await JudgeOfflineStore.instance.saveDraftLocal(
      eventId: widget.eventId,
      candidateId: widget.candidate['id'] as int,
      scores: _scores,
      comments: _comments,
      draftStep: _step.clamp(0, _criteria.length - 1),
    );

    if (JudgeOfflineStore.instance.isOffline) {
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved locally.')),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.post(
        apiUri('/api/events/judging-events/${widget.eventId}/save_draft/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': widget.candidate['id'],
          'scores': scoresPayload,
          'draft_step': _step.clamp(0, _criteria.length - 1),
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        if (showSnack) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft saved successfully.')),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${body['detail'] ?? 'Could not save draft'}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved locally (offline).')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSubmit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Score?'),
        content: const Text(
          'Once submitted, the score will be locked and cannot be edited '
          'unless reopened by the Faculty In-Charge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: judgeGold),
            child: const Text('Confirm Submission'),
          ),
        ],
      ),
    );
    if (ok == true) await _submit();
  }

  Future<void> _submit() async {
    final scoresPayload = _criteria.map((c) {
      final id = c['id'] as int;
      return {
        'criterion_id': id,
        'score': _scores[id] ?? 0,
        'comment': _comments[id] ?? '',
      };
    }).toList();

    if (JudgeOfflineStore.instance.isOffline) {
      await JudgeOfflineStore.instance.enqueueSubmit(
        eventId: widget.eventId,
        candidateId: widget.candidate['id'] as int,
        scores: scoresPayload,
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitResult = {
          'status_label': 'Waiting to Sync',
          'total_score': _weightedTotal(),
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queued for sync. Not official until server confirms.'),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.post(
        apiUri('/api/events/judging-events/${widget.eventId}/submit_scores/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': widget.candidate['id'],
          'scores': scoresPayload,
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await JudgeOfflineStore.instance.clearDraft(
          widget.eventId,
          widget.candidate['id'] as int,
        );
        if (!mounted) return;
        setState(() {
          _submitted = true;
          _submitResult = body as Map<String, dynamic>;
          _busy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score submitted successfully.')),
        );
      } else {
        setState(() {
          _error = '${body['detail'] ?? 'Submit failed'}';
          _busy = false;
        });
      }
    } catch (e) {
      await JudgeOfflineStore.instance.enqueueSubmit(
        eventId: widget.eventId,
        candidateId: widget.candidate['id'] as int,
        scores: scoresPayload,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitted = true;
        _submitResult = {'status_label': 'Waiting to Sync'};
      });
    }
  }

  double _weightedTotal() {
    double total = 0;
    for (final c in _criteria) {
      final id = c['id'] as int;
      final maxS = (c['max_score'] as num?)?.toDouble() ?? 1;
      final weight = (c['weight_percent'] as num?)?.toDouble() ?? 0;
      final score = _scores[id] ?? 0;
      if (maxS > 0) total += score * weight / maxS;
    }
    return double.parse(total.toStringAsFixed(1));
  }

  double _rawTotal() =>
      _criteria.fold<double>(0, (sum, c) => sum + (_scores[c['id'] as int] ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = JudgeThemeScope.paletteOf(context);
    final name = widget.candidate['name'] as String? ?? '';
    final dept = widget.candidate['department'] as String? ?? '';
    final number = widget.candidate['number'];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            JudgePortalHeader(
              showBack: true,
              onBack: () => Navigator.pop(context),
              onNotifications: null,
              onToggleTheme: null,
            ),
            Expanded(
              child: _submitted
                  ? _successView(c)
                  : (_onReview ? _reviewView(c, name, dept, number) : _criterionView(c, name, dept)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criterionView(JudgePalette c, String name, String dept) {
    final crit = _currentCriterion;
    final id = crit['id'] as int;
    final maxS = (crit['max_score'] as num?)?.toDouble() ?? 100;
    final minS = (crit['min_score'] as num?)?.toDouble() ?? 0;
    final weight = crit['weight_percent'];
    final commentEnabled = crit['comment_enabled'] != false;
    final currentScore = double.tryParse(_scoreCtrls[id]?.text ?? '') ?? minS;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Criterion ${_step + 1} of ${_criteria.length}',
                style: const TextStyle(
                  color: judgeGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (_step + 1) / _criteria.length,
                color: judgeGold,
                backgroundColor: c.chip,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 14),
              Text(name,
                  style: TextStyle(
                      color: c.text, fontSize: 20, fontWeight: FontWeight.w900)),
              if (dept.isNotEmpty)
                Text(dept, style: TextStyle(color: c.muted, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('${crit['name']}',
                  style: TextStyle(
                      color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                '${crit['description'] ?? ''}',
                style: TextStyle(color: c.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _chip(c, 'Weight', '$weight%'),
                  _chip(c, 'Min', '$minS'),
                  _chip(c, 'Max', '$maxS'),
                ],
              ),
              const SizedBox(height: 20),
              Text('Score',
                  style: TextStyle(
                      color: c.text, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _scoreCtrls[id],
                enabled: !widget.readOnly,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    color: c.text, fontSize: 28, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: c.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Slider(
                value: currentScore.clamp(minS, maxS),
                min: minS,
                max: maxS,
                activeColor: judgeGold,
                onChanged: widget.readOnly
                    ? null
                    : (v) {
                        setState(() {
                          _scoreCtrls[id]?.text =
                              v.toStringAsFixed((crit['decimal_places'] as num?)?.toInt() ?? 1);
                        });
                      },
              ),
              if (commentEnabled) ...[
                const SizedBox(height: 8),
                Text('Comment',
                    style: TextStyle(
                        color: c.text, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentCtrls[id],
                  enabled: !widget.readOnly,
                  maxLines: 3,
                  style: TextStyle(color: c.text),
                  decoration: InputDecoration(
                    hintText: 'Optional',
                    hintStyle: TextStyle(color: c.muted),
                    filled: true,
                    fillColor: c.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: judgeRed)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _step -= 1;
                              _error = null;
                            }),
                    child: const Text('Previous'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || widget.readOnly ? null : () => _saveDraft(),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (!_validateCurrent()) {
                            setState(() {});
                            return;
                          }
                          setState(() => _step += 1);
                        },
                  style: FilledButton.styleFrom(backgroundColor: judgeGold),
                  child: Text(_step == _criteria.length - 1 ? 'Review' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewView(JudgePalette c, String name, String dept, dynamic number) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Review Scores',
                style: TextStyle(
                    color: c.text, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text('#$number  $name',
                  style: TextStyle(
                      color: c.text, fontSize: 18, fontWeight: FontWeight.w800)),
              if (dept.isNotEmpty)
                Text(dept, style: TextStyle(color: c.muted)),
              const SizedBox(height: 16),
              ..._criteria.map((crit) {
                final id = crit['id'] as int;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${crit['name']}',
                          style: TextStyle(
                              color: c.text, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Weight ${crit['weight_percent']}%  ·  '
                        'Score ${_scores[id] ?? 0} / ${crit['max_score']}',
                        style: TextStyle(color: c.muted, fontSize: 12),
                      ),
                      if ((_comments[id] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_comments[id]!,
                            style: TextStyle(color: c.text, fontSize: 13)),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text('Raw Total: ${_rawTotal().toStringAsFixed(1)}',
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
              Text('Weighted Total: ${_weightedTotal()}',
                  style: const TextStyle(
                      color: judgeGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
              Text('Final Judge Score: ${_weightedTotal()}',
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: judgeRed)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _criteria.length - 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || widget.readOnly ? null : () => _saveDraft(),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busy || widget.readOnly ? null : _confirmSubmit,
                  style: FilledButton.styleFrom(backgroundColor: judgeGold),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Score'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _successView(JudgePalette c) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: judgeGreen, size: 72),
          const SizedBox(height: 16),
          Text('Score submitted successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.text, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            _submitResult?['status_label']?.toString() ?? 'PENDING VERIFICATION',
            style: const TextStyle(color: judgeGold, fontWeight: FontWeight.w800),
          ),
          if (_submitResult?['total_score'] != null) ...[
            const SizedBox(height: 8),
            Text('Final Score: ${_submitResult!['total_score']}',
                style: TextStyle(color: c.text, fontSize: 16)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'next'),
            style: FilledButton.styleFrom(backgroundColor: judgeGold),
            child: const Text('Score Next Contestant'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'list'),
            child: const Text('Back to Contestants'),
          ),
        ],
      ),
    );
  }

  Widget _chip(JudgePalette c, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              color: c.text, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
