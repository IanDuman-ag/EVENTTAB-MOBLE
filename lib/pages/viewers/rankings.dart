import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../auth/config.dart';
import 'bracket.dart';
import 'home.dart';
import 'schedule.dart';
import 'teams.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg       = Color(0xFF0A0B0D);
const _kBorder   = Color(0xFF1E2128);
const _kCyan     = Color(0xFF00C5D9);
const _kCyanLt   = Color(0xFF7CE1EF);
const _kOrange   = Color(0xFFFF7A18);
const _kMuted    = Color(0xFF76787F);
const _kDimBg    = Color(0xFF12141A);

// ─── models ──────────────────────────────────────────────

class _EventCategory {
  final int id;
  final String name;
  final String categoryType;
  final String icon;
  final String color;
  final int eventCount;
  const _EventCategory({required this.id, required this.name,
      required this.categoryType, required this.icon,
      required this.color, required this.eventCount});
  factory _EventCategory.fromJson(Map<String, dynamic> j) => _EventCategory(
      id: j['id'], name: j['name'],
      categoryType: j['category_type'] ?? '',
      icon: j['icon'] ?? 'category',
      color: j['color'] ?? '#00C5D9',
      eventCount: j['event_count'] ?? 0);
  Color get flutterColor {
    try { return Color(int.parse(color.replaceFirst('#', '0xFF'))); }
    catch (_) { return _kCyan; }
  }
}

class _JudgingEvent {
  final int id;
  final String title;
  final String categoryName;
  final String date;
  final String venue;
  final String status;
  final int candidateCount;
  const _JudgingEvent({required this.id, required this.title,
      required this.categoryName, required this.date,
      required this.venue, required this.status, required this.candidateCount});
  factory _JudgingEvent.fromJson(Map<String, dynamic> j) => _JudgingEvent(
      id: j['id'], title: j['title'],
      categoryName: j['category_name'] ?? '',
      date: j['date'] ?? '', venue: j['venue'] ?? '',
      status: j['status'] ?? 'upcoming',
      candidateCount: j['candidate_count'] ?? 0);
}

class _CandidateStanding {
  final int rank;
  final int candidateId;
  final String name;
  final int number;
  final double totalScore;
  final bool isLive;
  const _CandidateStanding({required this.rank, required this.candidateId,
      required this.name, required this.number,
      required this.totalScore, required this.isLive});
  factory _CandidateStanding.fromJson(Map<String, dynamic> j) =>
      _CandidateStanding(
          rank: j['rank'], candidateId: j['candidate_id'],
          name: j['name'], number: j['number'],
          totalScore: double.tryParse(j['total_score'].toString()) ?? 0.0,
          isLive: j['is_live'] ?? false);
}

// ─── Page ────────────────────────────────────────────────

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, this.onNavigate});
  final Function(String)? onNavigate;
  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with TickerProviderStateMixin {
  // step: 0=categories, 1=events, 2=leaderboard
  int _step = 0;
  _EventCategory? _selectedCategory;
  _JudgingEvent?  _selectedEvent;

  List<_EventCategory>     _categories = [];
  List<_JudgingEvent>      _events     = [];
  List<_CandidateStanding> _standings  = [];

  bool    _isLoading     = false;
  String? _error;
  String  _selectedPeriod = 'OVERALL';
  final   _periods = ['OVERALL', 'DAY 1', 'DAY 2', 'DAY 3'];

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _baseUrl = defaultApiBaseUrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadCategories();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Map<String, String> get _headers {
    final token = AuthSession.current?.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> _loadCategories() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.get(
          Uri.parse('$_baseUrl/api/events/categories/'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _categories = list.map((e) => _EventCategory.fromJson(e)).toList();
          _isLoading = false;
        });
        _fadeCtrl..reset()..forward();
      } else { throw Exception('HTTP ${res.statusCode}'); }
    } catch (e) {
      setState(() { _error = 'Could not load categories: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadEvents(_EventCategory cat) async {
    setState(() { _isLoading = true; _error = null; _selectedCategory = cat; });
    try {
      final res = await http.get(
          Uri.parse('$_baseUrl/api/events/categories/${cat.id}/events/'),
          headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _events = list.map((e) => _JudgingEvent.fromJson(e)).toList();
          _step = 1; _isLoading = false;
        });
        _fadeCtrl..reset()..forward();
      } else { throw Exception('HTTP ${res.statusCode}'); }
    } catch (e) {
      setState(() { _error = 'Could not load events: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadStandings(_JudgingEvent event) async {
    setState(() {
      _isLoading = true; _error = null;
      _selectedEvent = event; _selectedPeriod = 'OVERALL';
    });
    try {
      final res = await http.get(
          Uri.parse('$_baseUrl/api/events/rankings-events/${event.id}/standings/'),
          headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _standings = list.map((e) => _CandidateStanding.fromJson(e)).toList();
          _step = 2; _isLoading = false;
        });
        _fadeCtrl..reset()..forward();
      } else { throw Exception('HTTP ${res.statusCode}'); }
    } catch (e) {
      setState(() { _error = 'Could not load standings: $e'; _isLoading = false; });
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      if (_step == 2) {
        _step = 1;
      } else if (_step == 1) {
        _step = 0;
      }
    });
    _fadeCtrl..reset()..forward();
  }

  void _nav(Widget page) => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => page));

  VoidCallback _retryCurrentStep() {
    if (_step == 2 && _selectedEvent != null) {
      return () => _loadStandings(_selectedEvent!);
    }
    if (_step == 1 && _selectedCategory != null) {
      return () => _loadEvents(_selectedCategory!);
    }
    return _loadCategories;
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _kCyan))
                  : _error != null
                      ? _buildError()
                      : FadeTransition(opacity: _fadeAnim, child: _buildStep()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _step > 0 ? _goBack : null,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: _kCyan, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _step > 0
                  ? const Icon(Icons.arrow_back_ios_new, color: _kCyan, size: 16)
                  : const Icon(Icons.person, color: _kCyan, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Text('EVENT TAB',
              style: TextStyle(color: _kCyan, fontSize: 20,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: _kCyan),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kOrange, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _retryCurrentStep(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: _kCyan)),
                child: const Text('RETRY',
                    style: TextStyle(color: _kCyan,
                        fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildCategoryStep();
      case 1: return _buildEventsStep();
      case 2: return _buildLeaderboard();
      default: return const SizedBox.shrink();
    }
  }

  // ─── STEP 0 — Category grid ──────────────────────────────

  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RANKINGS',
              style: TextStyle(color: _kOrange, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text('SELECT CATEGORY',
              style: TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Choose a category to view standings',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 24),
          if (_categories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No categories found.',
                    style: TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12,
                  mainAxisSpacing: 12, childAspectRatio: 1.15),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) => _buildCategoryCard(_categories[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_EventCategory cat) {
    final color = cat.flutterColor;
    return GestureDetector(
      onTap: () => _loadEvents(cat),
      child: Container(
        decoration: BoxDecoration(
          color: _kDimBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, height: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(_iconFromName(cat.icon), color: color, size: 26),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('${cat.eventCount} EVENT${cat.eventCount != 1 ? 'S' : ''}',
                          style: TextStyle(color: color, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(right: 12, top: 12,
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.2), size: 12)),
          ],
        ),
      ),
    );
  }

  // ─── STEP 1 — Event list ─────────────────────────────────

  Widget _buildEventsStep() {
    final color = _selectedCategory?.flutterColor ?? _kCyan;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_selectedCategory?.name.toUpperCase() ?? '',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: _kMuted, size: 10),
              const SizedBox(width: 8),
              Text('SELECT EVENT',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('SELECT EVENT',
              style: TextStyle(color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('Choose an event to see its leaderboard',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 24),
          if (_events.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No events in this category.',
                  style: TextStyle(color: Colors.white38)),
            ))
          else
            ...(_events.map((e) => _buildEventTile(e, color))),
        ],
      ),
    );
  }

  Widget _buildEventTile(_JudgingEvent event, Color accent) {
    final isActive = event.status == 'active';
    return GestureDetector(
      onTap: () => _loadStandings(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kDimBg,
          border: Border(
            left: BorderSide(color: isActive ? _kOrange : accent, width: 3),
            top: const BorderSide(color: _kBorder),
            right: const BorderSide(color: _kBorder),
            bottom: const BorderSide(color: _kBorder),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _kOrange, borderRadius: BorderRadius.circular(3)),
                      child: const Text('LIVE',
                          style: TextStyle(color: Color(0xFF061014),
                              fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  Text(event.title,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.white.withValues(alpha: 0.35), size: 12),
                      const SizedBox(width: 4),
                      Text(event.venue,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11)),
                      const SizedBox(width: 12),
                      Icon(Icons.people_outline,
                          color: Colors.white.withValues(alpha: 0.35), size: 12),
                      const SizedBox(width: 4),
                      Text('${event.candidateCount} participants',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _kMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2 — Leaderboard (matches image) ────────────────

  Widget _buildLeaderboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title block ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('CURRENT RANKINGS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _kOrange, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 2)),
                const SizedBox(height: 6),
                const Text('LEADERBOARD',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 36,
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // ── Podium ──
          if (_standings.length >= 3) _buildPodium()
          else if (_standings.isNotEmpty) _buildSimpleTop(),
          const SizedBox(height: 24),
          // ── Divider ──
          Container(height: 1, color: _kBorder),
          const SizedBox(height: 20),
          // ── Period selector ──
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          // ── Column headers ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 32),
                const Expanded(
                  child: Text('RANK  ATHLETE',
                      style: TextStyle(color: _kMuted, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                const Text('TREND',
                    style: TextStyle(color: _kMuted, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(width: 16),
                const Text('POINTS',
                    style: TextStyle(color: _kMuted, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Rank rows (4th place onward) ──
          ..._standings.skip(_standings.length >= 3 ? 3 : 0).map(_buildRankRow),
          const SizedBox(height: 20),
          // ── View full standings button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kCyanLt, _kCyan]),
                ),
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF061014),
                      shape: const RoundedRectangleBorder()),
                  child: const Text('VIEW FULL STANDINGS',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Podium (top 3) ───────────────────────────────────────

  Widget _buildPodium() {
    final top = _standings.take(3).toList();
    // Layout: 2nd | 1st | 3rd  (matching image)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumCard(top[1], 2, const Color(0xFF4A4C50), 76)),
          const SizedBox(width: 10),
          Expanded(child: _buildPodiumCard(top[0], 1, _kOrange, 96)),
          const SizedBox(width: 10),
          Expanded(child: _buildPodiumCard(top[2], 3, const Color(0xFFBDBDBD), 76)),
        ],
      ),
    );
  }

  Widget _buildSimpleTop() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: _standings.map(_buildRankRow).toList()),
    );
  }

  Widget _buildPodiumCard(
      _CandidateStanding s, int position, Color accent, double boxSize) {
    final isFirst = position == 1;
    // Format score like image: "5.2K PTS"
    final pts = s.totalScore >= 1000
        ? '${(s.totalScore / 1000).toStringAsFixed(1)}K PTS'
        : '${s.totalScore.toStringAsFixed(1)} PTS';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown / trophy for 1st
        if (isFirst)
          const Icon(Icons.emoji_events, color: _kOrange, size: 22)
        else
          const SizedBox(height: 22),
        const SizedBox(height: 6),
        // Avatar box — styled like image (dark bg, accent border)
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: boxSize, height: boxSize,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C22),
                border: Border.all(color: accent, width: isFirst ? 3 : 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: accent,
                    fontSize: isFirst ? 38 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            // Rank badge bottom-right
            Positioned(
              bottom: -8, right: -8,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isFirst ? _kOrange : const Color(0xFF1E2128),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent, width: 1.5),
                ),
                child: Center(
                  child: Text('$position',
                      style: TextStyle(
                        color: isFirst ? const Color(0xFF061014) : _kMuted,
                        fontSize: 11, fontWeight: FontWeight.w900,
                      )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          s.name.length > 8 ? s.name.substring(0, 8).toUpperCase() : s.name.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: isFirst ? 13 : 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Score
        Text(pts,
            style: TextStyle(
              color: isFirst ? _kOrange : _kMuted,
              fontSize: 11, fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 8),
        // Podium platform bar
        Container(
          height: isFirst ? 48 : 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            border: Border(top: BorderSide(color: accent, width: 2)),
          ),
          child: Center(
            child: Icon(
              isFirst ? Icons.workspace_premium : Icons.military_tech,
              color: accent.withValues(alpha: 0.5),
              size: isFirst ? 22 : 16,
            ),
          ),
        ),
      ],
    );
  }

  // ── Period selector ──────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _periods.map((p) {
          final sel = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _kCyan : const Color(0xFF1E2128),
                  border: Border.all(
                      color: sel ? _kCyan : const Color(0xFF2B2D31)),
                  borderRadius: BorderRadius.circular(sel ? 20 : 4),
                ),
                child: Text(p,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sel ? const Color(0xFF061014) : _kMuted,
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Rank row (4th place onward) ──────────────────────────

  Widget _buildRankRow(_CandidateStanding s) {
    // Trend: top 3 show up arrow, rest show dash
    final trendUp = s.rank <= 3;
    final pts = s.totalScore >= 1000
        ? '${(s.totalScore / 1000).toStringAsFixed(1)}K'
        : s.totalScore.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: s.isLive ? _kOrange : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _kDimBg,
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                s.rank.toString().padLeft(2, '0'),
                style: const TextStyle(color: _kMuted, fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2128),
                border: Border.all(color: const Color(0xFF2B2D31)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _kCyan, fontSize: 15,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name
            Expanded(
              child: Text(s.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ),
            // Trend
            SizedBox(
              width: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    trendUp ? Icons.trending_up : Icons.remove,
                    color: trendUp ? _kCyan : const Color(0xFF4A4C50),
                    size: 14,
                  ),
                  if (trendUp) ...[
                    const SizedBox(width: 2),
                    Text('+${4 - s.rank}',
                        style: const TextStyle(color: _kCyan,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
            // Score + live badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (s.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(3)),
                    child: const Text('LIVE PLAY',
                        style: TextStyle(color: Colors.white, fontSize: 8,
                            fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                Text(pts,
                    style: const TextStyle(color: _kOrange, fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav ──────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'HOME', false,
                  onTap: () => _nav(const HomePage())),
              _buildNavItem(Icons.emoji_events, 'RANKINGS', true),
              _buildNavItem(Icons.calendar_today, 'SCHEDULE', false,
                  onTap: () => _nav(const SchedulePage())),
              _buildNavItem(Icons.people_outline, 'TEAMS', false,
                  onTap: () => _nav(const TeamsPage())),
              _buildNavItem(Icons.account_tree_outlined, 'BRACKET', false,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BracketPage()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isActive ? _kCyan : const Color(0xFF4A4C50), size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: isActive ? _kCyan : const Color(0xFF4A4C50),
                fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }

  // ─── Icon lookup ─────────────────────────────────────────

  IconData _iconFromName(String name) {
    switch (name) {
      case 'school':             return Icons.school;
      case 'sports_basketball':  return Icons.sports_basketball;
      case 'theater_comedy':     return Icons.theater_comedy;
      case 'sports_esports':     return Icons.sports_esports;
      case 'emoji_events':       return Icons.emoji_events;
      case 'music_note':         return Icons.music_note;
      case 'sports_soccer':      return Icons.sports_soccer;
      case 'sports_volleyball':  return Icons.sports_volleyball;
      default:                   return Icons.category;
    }
  }
}
