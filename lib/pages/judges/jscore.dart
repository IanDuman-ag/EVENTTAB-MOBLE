import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';
import 'judge_nav.dart';
import 'jevent.dart';

const _kBg = Color(0xFF0B0B12);
const _kCard = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kTeal = Color(0xFF0D7A62);
const _kMuted = Color(0xFF7F7890);

// ─── JScoringPage ─────────────────────────────────────────────────────────────
class JScoringPage extends StatefulWidget {
  const JScoringPage({
    super.key,
    required this.event,
    required this.candidate,
    required this.criteria,
  });

  final Map<String, dynamic> event;
  final Map<String, dynamic> candidate;
  final List<dynamic> criteria;

  @override
  State<JScoringPage> createState() => _JScoringPageState();
}

class _JScoringPageState extends State<JScoringPage> {
  late Map<int, double> _scores;
  bool _isSubmitting = false;
  bool _isLocked = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialise each criterion score to 0
    _scores = {
      for (final c in widget.criteria)
        (c['id'] as int): 0.0,
    };
    _checkExistingScores();
  }

  Future<void> _checkExistingScores() async {
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final eventId = widget.event['id'];
      final candidateId = widget.candidate['id'];
      final res = await http.get(
        apiUri('/api/events/judging-events/$eventId/my_scores/?candidate_id=$candidateId'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty && data.first['is_locked'] == true) {
          // Already submitted — rebuild as locked result view
          final breakdown = data.map((s) => {
            'criterion': s['criterion_name'],
            'score': double.tryParse(s['score'].toString()) ?? 0,
            'max_score': double.tryParse(s['criterion_max'].toString()) ?? 0,
            'weight': 0.0,
          }).toList();
          double total = 0;
          for (final s in data) {
            total += double.tryParse(s['score'].toString()) ?? 0;
          }
          setState(() {
            _isLocked = true;
            _result = {
              'verification_id': data.first['verification_id'],
              'submitted_at': data.first['submitted_at'],
              'total_score': total,
              'breakdown': breakdown,
            };
          });
        } else {
          // Pre-fill existing scores
          for (final s in data) {
            final cid = s['criterion'] as int;
            _scores[cid] = double.tryParse(s['score'].toString()) ?? 0;
          }
          setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final eventId = widget.event['id'];
      final candidateId = widget.candidate['id'];

      final scoresList = _scores.entries.map((e) => {
        'criterion_id': e.key,
        'score': e.value,
      }).toList();

      final res = await http.post(
        apiUri('/api/events/judging-events/$eventId/submit_scores/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'candidate_id': candidateId,
          'scores': scoresList,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _isLocked = true;
          _result = data;
          _isSubmitting = false;
        });
      } else {
        final body = jsonDecode(res.body);
        setState(() {
          _error = body['detail'] ?? 'Submission failed.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  void _adjustScore(int criterionId, double delta, double maxScore) {
    if (_isLocked) return;
    setState(() {
      final current = _scores[criterionId] ?? 0;
      _scores[criterionId] = (current + delta).clamp(0, maxScore);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: _isLocked && _result != null
                  ? _lockedView()
                  : _scoringView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A102D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: _kPurple, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('EVENTTAB',
              style: TextStyle(color: _kPurple, fontSize: 17,
                  fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search_rounded, color: _kPurple), onPressed: () {}),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A102D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPurple, width: 2),
            ),
            child: const Icon(Icons.person, color: _kPurple, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Scoring input view ────────────────────────────────────────────────────
  Widget _scoringView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D5C4A), Color(0xFF1A8C6E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kTeal.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.event['title'] ?? '',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFFB2EFE0), size: 14),
                    const SizedBox(width: 4),
                    Text(widget.event['venue'] ?? '',
                        style: const TextStyle(color: Color(0xFFB2EFE0),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Category chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Category',
                    style: TextStyle(color: _kMuted, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(widget.event['category_name'] ?? '',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                const Text('Select Candidate',
                    style: TextStyle(color: _kMuted, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _kTeal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: _kTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.candidate['name'] ?? '',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          Text('Candidate #${widget.candidate['number']}',
                              style: const TextStyle(color: _kTeal,
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Scoring header
                Row(
                  children: [
                    const Text('Scoring',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Submit'),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent,
                            fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 16),
                // Criteria score rows
                ...widget.criteria.map((c) {
                  final cid = c['id'] as int;
                  final maxScore = double.tryParse(c['max_score'].toString()) ?? 0;
                  final current = _scores[cid] ?? 0;
                  // Guard: name might be a raw JSON string if admin entered it wrong.
                  // Try to parse it and extract the real name.
                  final rawName = c['name']?.toString() ?? '';
                  String displayName = rawName;
                  if (rawName.trimLeft().startsWith('{') ||
                      rawName.trimLeft().startsWith('[')) {
                    try {
                      final parsed = jsonDecode(rawName);
                      if (parsed is Map) {
                        displayName = parsed['name']?.toString() ??
                            parsed['title']?.toString() ??
                            'Criterion ${cid}';
                      } else if (parsed is List && parsed.isNotEmpty) {
                        displayName = parsed.first['name']?.toString() ??
                            'Criterion ${cid}';
                      }
                    } catch (_) {
                      displayName = 'Criterion $cid';
                    }
                  }
                  return _ScoreRow(
                    name: displayName,
                    maxScore: maxScore,
                    current: current,
                    onDecrement: () => _adjustScore(cid, -1, maxScore),
                    onIncrement: () => _adjustScore(cid, 1, maxScore),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Locked / submitted view ───────────────────────────────────────────────
  Widget _lockedView() {
    final r = _result!;
    final breakdown = (r['breakdown'] as List?) ?? [];
    final totalScore = double.tryParse(r['total_score'].toString()) ?? 0;
    final submittedAt = r['submitted_at'] ?? '';
    final verificationId = r['verification_id'] ?? '';

    // Format timestamp
    String formattedTime = submittedAt;
    try {
      final dt = DateTime.parse(submittedAt).toLocal();
      formattedTime =
          '${_monthName(dt.month)} ${dt.day}, ${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {}

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded,
                color: _kTeal, size: 22),
          ),
          const SizedBox(height: 16),
          // Locked card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: Colors.red.shade400, width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOCKED & SUBMITTED',
                          style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('Submission Timestamp: $formattedTime',
                          style: const TextStyle(color: _kMuted, fontSize: 11)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Verification ID',
                                style: TextStyle(color: _kMuted, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(verificationId,
                                style: const TextStyle(color: _kTeal,
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Event title
          Text(widget.event['title'] ?? '',
              style: const TextStyle(color: _kTeal, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Total score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalScore.toStringAsFixed(1),
                  style: const TextStyle(color: _kTeal, fontSize: 64,
                      fontWeight: FontWeight.w900, height: 1)),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 6),
                child: Text('/ 100',
                    style: TextStyle(color: _kMuted, fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Judging Breakdown',
              style: TextStyle(color: _kMuted, fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...breakdown.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value as Map<String, dynamic>;
            final score = double.tryParse(b['score'].toString()) ?? 0;
            final maxScore = double.tryParse(b['max_score'].toString()) ?? 1;
            final ratio = (score / maxScore).clamp(0.0, 1.0);
            final barColors = [
              const Color(0xFF0D7A62),
              const Color(0xFF6B22D8),
              const Color(0xFF2196F3),
              const Color(0xFFFF7A18),
            ];
            final barColor = barColors[i % barColors.length];

            return _BreakdownRow(
              name: b['criterion'] ?? '',
              score: score,
              maxScore: maxScore,
              ratio: ratio,
              barColor: barColor,
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home_rounded, 'Home', false, onTap: () {
                JudgeNav.toHome(context);
              }),
              _navItem(context, Icons.event_rounded, 'Events', false, onTap: () {
                JudgeNav.toEvents(context);
              }),
              _navItem(context, Icons.star_rounded, 'Scoring', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, {VoidCallback? onTap}) {
    final color = active ? _kPurple : const Color(0xFF5A5266);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

// ─── Score Row ────────────────────────────────────────────────────────────────
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.name,
    required this.maxScore,
    required this.current,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String name;
  final double maxScore;
  final double current;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w800)),
                Text('Max ${maxScore.toInt()} points',
                    style: const TextStyle(color: _kMuted, fontSize: 11)),
              ],
            ),
          ),
          // Decrement
          _CircleBtn(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          const SizedBox(width: 16),
          // Score value
          SizedBox(
            width: 36,
            child: Text(current.toInt().toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 16),
          // Increment
          _CircleBtn(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: _kTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kTeal.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: _kTeal, size: 18),
      ),
    );
  }
}

// ─── Breakdown Row ────────────────────────────────────────────────────────────
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.ratio,
    required this.barColor,
  });

  final String name;
  final double score;
  final double maxScore;
  final double ratio;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text('${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

