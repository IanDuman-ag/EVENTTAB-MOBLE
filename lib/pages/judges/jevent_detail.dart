import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'judge_auth_service.dart';
import 'judge_nav.dart';
import 'jscore.dart';
import 'jevent.dart';

const _kBg = Color(0xFF0B0B12);
const _kCard = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kMuted = Color(0xFF7F7890);
const _kTeal = Color(0xFF0D7A62);

class JEventDetailPage extends StatefulWidget {
  const JEventDetailPage({super.key, required this.eventId});
  final int eventId;

  @override
  State<JEventDetailPage> createState() => _JEventDetailPageState();
}

class _JEventDetailPageState extends State<JEventDetailPage> {
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = JudgeAuthSession.current?.token ?? '';
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/events/judging-events/${widget.eventId}/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() { _event = jsonDecode(res.body); _isLoading = false; });
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(child: _body(context)),
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

  Widget _body(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)));
    }
    if (_event == null) return const SizedBox();

    final ev = _event!;
    final criteria = (ev['criteria'] as List?) ?? [];
    final candidates = (ev['candidates'] as List?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D5C4A), Color(0xFF1A8C6E)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFFB2EFE0), size: 22),
                ),
                const SizedBox(height: 6),
                const Text('CATEGORY',
                    style: TextStyle(color: Color(0xFFB2EFE0), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(ev['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 10),
                Text(ev['date'] ?? '',
                    style: const TextStyle(color: Color(0xFFB2EFE0),
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(ev['venue'] ?? '',
                    style: const TextStyle(color: Color(0xFFB2EFE0),
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Criteria section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _kTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('COMPETITION CRITERIA',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                ...criteria.map((c) => _CriterionRow(criterion: c)),
                const SizedBox(height: 20),
                // Candidates section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D5C4A), Color(0xFF1A8C6E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Candidates',
                          style: TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('There are ${candidates.length} total of candidates',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12)),
                      const SizedBox(height: 14),
                      ...candidates.map((c) => _CandidateRow(
                        candidate: c,
                        onProceed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JScoringPage(
                              event: ev,
                              candidate: c,
                              criteria: criteria,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
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
              _navItem(Icons.home_rounded, 'Home', false, onTap: () {
                JudgeNav.toHome(context);
              }),
              _navItem(Icons.event_rounded, 'Events', true),
              _navItem(Icons.star_rounded, 'Scoring', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, {VoidCallback? onTap}) {
    final color = active ? _kPurple : const Color(0xFF5A5266);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion});
  final Map<String, dynamic> criterion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded, color: _kTeal, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(criterion['name'] ?? '',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(criterion['description'] ?? '',
                    style: const TextStyle(color: _kMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${criterion['weight_percent']}%',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const Text('Weight',
                  style: TextStyle(color: _kMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate, required this.onProceed});
  final Map<String, dynamic> candidate;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate['name'] ?? '',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Candidate #${candidate['number']}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A8C6E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            child: const Text('Proceed To Score'),
          ),
        ],
      ),
    );
  }
}
