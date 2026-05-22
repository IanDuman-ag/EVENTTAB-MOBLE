import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'bracket.dart';
import 'home.dart';
import 'profile.dart';
import 'schedule.dart';
import 'teams.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key, this.onNavigate});

  final Function(String)? onNavigate;

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  static const String _allCategoriesLabel = 'ALL CATEGORIES';
  static const String _allEventNamesLabel = 'ALL EVENT NAMES';
  static const String _overallDayLabel = 'OVERALL';

  String _selectedCategory = _allCategoriesLabel;
  String _selectedDay = _overallDayLabel;
  String _selectedEventName = _allEventNamesLabel;

  List<dynamic> _teams = [];
  List<dynamic> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = AuthSession.current?.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      final responses = await Future.wait<http.Response>([
        http.get(
          Uri.parse('http://127.0.0.1:8000/api/events/teams/'),
          headers: headers,
        ),
        http.get(
          Uri.parse('http://127.0.0.1:8000/api/events/matches/'),
          headers: headers,
        ),
      ]);

      final teamResponse = responses[0];
      final matchResponse = responses[1];

      if (teamResponse.statusCode == 200 && matchResponse.statusCode == 200) {
        setState(() {
          _teams = jsonDecode(teamResponse.body) as List<dynamic>;
          _matches = jsonDecode(matchResponse.body) as List<dynamic>;
          _syncSelections();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load rankings');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load rankings: $e';
        _isLoading = false;
      });
    }
  }

  List<String> get _categoryOptions {
    final categories = <String>{};
    for (final rawMatch in _matches) {
      categories.add(_extractCategory(rawMatch as Map<String, dynamic>));
    }

    final sortedCategories = categories.toList()..sort();
    return [_allCategoriesLabel, ...sortedCategories];
  }

  List<String> get _eventNameOptions {
    final eventNames = <String>{};
    for (final rawMatch in _applyMatchFilters(
      ignoreEventName: true,
      ignoreDay: true,
    )) {
      final match = rawMatch as Map<String, dynamic>;
      eventNames.add(_eventName(match));
    }

    final sortedEventNames = eventNames.toList()..sort();
    return [_allEventNamesLabel, ...sortedEventNames];
  }

  List<_DayFilterOption> get _dayOptions {
    final orderedDates = <DateTime>[];
    final seen = <String>{};

    for (final rawMatch in _applyMatchFilters(ignoreDay: true)) {
      final match = rawMatch as Map<String, dynamic>;
      final scheduledDate = _parseMatchDate(match);
      if (scheduledDate == null) {
        continue;
      }

      final normalizedDate = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );
      final key = normalizedDate.toIso8601String();
      if (seen.add(key)) {
        orderedDates.add(normalizedDate);
      }
    }

    orderedDates.sort();

    final options = <_DayFilterOption>[
      const _DayFilterOption(
        label: _overallDayLabel,
        description: 'All event days',
      ),
    ];

    for (var index = 0; index < orderedDates.length; index++) {
      final date = orderedDates[index];
      options.add(
        _DayFilterOption(
          label: 'DAY ${index + 1}',
          date: date,
          description: '${_monthLabel(date.month)} ${date.day}, ${date.year}',
        ),
      );
    }

    return options;
  }

  List<_RankedTeam> get _visibleRankings {
    final filteredMatches = _applyMatchFilters();
    final participatingTeamIds = <int>{};

    for (final rawMatch in filteredMatches) {
      final match = rawMatch as Map<String, dynamic>;
      participatingTeamIds.addAll(_extractTeamIds(match));
    }

    final sourceTeams = participatingTeamIds.isEmpty
        ? _teams.cast<Map<String, dynamic>>()
        : _teams
              .cast<Map<String, dynamic>>()
              .where((team) => participatingTeamIds.contains(team['id']))
              .toList();

    final rankings = sourceTeams
        .map((team) => _buildRankedTeam(team, filteredMatches))
        .toList();

    rankings.sort((a, b) {
      final pointsComparison = b.points.compareTo(a.points);
      if (pointsComparison != 0) {
        return pointsComparison;
      }
      return a.name.compareTo(b.name);
    });

    for (var index = 0; index < rankings.length; index++) {
      rankings[index] = rankings[index].copyWith(rank: index + 1);
    }

    return rankings;
  }

  void _syncSelections() {
    final categories = _categoryOptions;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    final eventNames = _eventNameOptions;
    if (!eventNames.contains(_selectedEventName)) {
      _selectedEventName = eventNames.first;
    }

    final dayLabels = _dayOptions.map((option) => option.label).toList();
    if (!dayLabels.contains(_selectedDay)) {
      _selectedDay = dayLabels.first;
    }
  }

  List<dynamic> _applyMatchFilters({
    bool ignoreCategory = false,
    bool ignoreEventName = false,
    bool ignoreDay = false,
  }) {
    final selectedDayOption = ignoreDay ? null : _selectedDayOption;

    return _matches.where((rawMatch) {
      final match = rawMatch as Map<String, dynamic>;

      if (!ignoreCategory && _selectedCategory != _allCategoriesLabel) {
        if (_extractCategory(match) != _selectedCategory) {
          return false;
        }
      }

      if (!ignoreEventName && _selectedEventName != _allEventNamesLabel) {
        if (_eventName(match) != _selectedEventName) {
          return false;
        }
      }

      if (!ignoreDay &&
          selectedDayOption?.date != null &&
          !_isSameDay(_parseMatchDate(match), selectedDayOption!.date)) {
        return false;
      }

      return true;
    }).toList();
  }

  _RankedTeam _buildRankedTeam(
    Map<String, dynamic> team,
    List<dynamic> filteredMatches,
  ) {
    final teamId = team['id'] as int?;
    final abbreviation = team['abbreviation']?.toString() ?? 'TEAM';
    final relevantMatches = filteredMatches
        .cast<Map<String, dynamic>>()
        .where((match) => _extractTeamIds(match).contains(teamId))
        .toList();

    var wins = 0;
    var losses = 0;
    var liveMatches = 0;
    var upcomingMatches = 0;

    for (final match in relevantMatches) {
      final status = match['status']?.toString().toLowerCase() ?? '';
      final isTeamA =
          match['team_a'] is Map<String, dynamic> &&
          (match['team_a'] as Map<String, dynamic>)['id'] == teamId;
      final scoreA = _asInt(match['score_a']);
      final scoreB = _asInt(match['score_b']);

      if (status == 'completed' && scoreA != null && scoreB != null) {
        if ((isTeamA && scoreA > scoreB) || (!isTeamA && scoreB > scoreA)) {
          wins++;
        } else if (scoreA != scoreB) {
          losses++;
        }
      } else if (status == 'live') {
        liveMatches++;
      } else if (status == 'upcoming') {
        upcomingMatches++;
      }
    }

    final matchesPlayed = wins + losses;
    final fallbackSeed = ((teamId ?? abbreviation.length) * 73) % 420;
    final points = relevantMatches.isEmpty
        ? 2200 + fallbackSeed
        : 2600 +
              (wins * 780) +
              (matchesPlayed * 180) +
              (liveMatches * 140) +
              (upcomingMatches * 70) +
              fallbackSeed;

    var trend = wins - losses;
    if (trend == 0 && liveMatches > 0) {
      trend = 1;
    }

    return _RankedTeam(
      rank: 0,
      name: team['name']?.toString() ?? abbreviation,
      abbreviation: abbreviation,
      logoIcon: team['logo_icon']?.toString() ?? '',
      color: _parseColor(team['color']?.toString()),
      points: points,
      trend: trend,
      isLive: liveMatches > 0,
    );
  }

  Set<int> _extractTeamIds(Map<String, dynamic> match) {
    final teamIds = <int>{};
    final teamA = match['team_a'];
    final teamB = match['team_b'];

    if (teamA is Map<String, dynamic> && teamA['id'] is int) {
      teamIds.add(teamA['id'] as int);
    }
    if (teamB is Map<String, dynamic> && teamB['id'] is int) {
      teamIds.add(teamB['id'] as int);
    }

    return teamIds;
  }

  String _extractCategory(Map<String, dynamic> match) {
    final title = match['title']?.toString().toUpperCase() ?? '';

    if (title.contains('WOMEN') ||
        title.contains('WOMENS') ||
        title.contains('GIRLS')) {
      return 'WOMEN';
    }
    if (title.contains('MEN') ||
        title.contains('MENS') ||
        title.contains('BOYS')) {
      return 'MEN';
    }
    if (title.contains('MIXED') ||
        title.contains('COED') ||
        title.contains('CO-ED')) {
      return 'MIXED';
    }

    return 'OPEN';
  }

  String _formatSport(String? sport) {
    if (sport == null || sport.trim().isEmpty) {
      return 'OTHER';
    }

    final normalized = sport.trim().toLowerCase();
    if (normalized == 'basketball') {
      return 'BASKETBALL';
    }
    if (normalized == 'volleyball') {
      return 'VOLLEYBALL';
    }
    if (normalized == 'football') {
      return 'FOOTBALL';
    }

    return normalized.toUpperCase();
  }

  String _eventName(Map<String, dynamic> match) {
    final title = match['title']?.toString().trim();
    if (title != null && title.isNotEmpty) {
      return title.toUpperCase();
    }
    return _formatSport(match['sport']?.toString());
  }

  _DayFilterOption? get _selectedDayOption {
    for (final option in _dayOptions) {
      if (option.label == _selectedDay) {
        return option;
      }
    }
    return null;
  }

  DateTime? _parseMatchDate(Map<String, dynamic> match) {
    final rawDate = match['scheduled_time']?.toString();
    if (rawDate == null || rawDate.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(rawDate).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false;
    }

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return const Color(0xFF00C5D9);
    }

    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF00C5D9);
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0B0D),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C5D9)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0B0D),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRankings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final rankings = _visibleRankings;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00C5D9), width: 2),
                color: const Color(0xFF0A0B0D),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00C5D9),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF00C5D9),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'EVENT TAB',
                    style: TextStyle(
                      color: Color(0xFF00C5D9),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: const Color(0xFF00C5D9),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT RANKINGS',
                            style: TextStyle(
                              color: Color(0xFFFF7A18),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'LEADERBOARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Choose the event category, event day, and event name before viewing the standings.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSelectionPanel(),
                    const SizedBox(height: 20),
                    _buildSelectionSummary(),
                    const SizedBox(height: 24),
                    _buildTop3Section(rankings),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          const Expanded(
                            child: Text(
                              'TEAM',
                              style: TextStyle(
                                color: Color(0xFF76787F),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 60),
                          const Text(
                            'TREND',
                            style: TextStyle(
                              color: Color(0xFF76787F),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Text(
                            'POINTS',
                            style: TextStyle(
                              color: Color(0xFF76787F),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRankingsList(rankings),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF7CE1EF), Color(0xFF00C5D9)],
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF061014),
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text(
                              'VIEW FULL STANDINGS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSelectionPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF101218),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF242834)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C5D9).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF00C5D9), size: 18),
                SizedBox(width: 10),
                Text(
                  'FILTER RANKINGS',
                  style: TextStyle(
                    color: Color(0xFF00C5D9),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModernFilterDropdown(
              title: 'CATEGORY',
              icon: Icons.category_outlined,
              options: _categoryOptions,
              selectedValue: _selectedCategory,
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                  _syncSelections();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildModernFilterDropdown(
              title: 'EVENT DAY',
              icon: Icons.calendar_today_outlined,
              options: _dayOptions.map((option) => option.label).toList(),
              selectedValue: _selectedDay,
              onSelected: (value) {
                setState(() {
                  _selectedDay = value;
                  _syncSelections();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildModernFilterDropdown(
              title: 'EVENT NAME',
              icon: Icons.emoji_events_outlined,
              options: _eventNameOptions,
              selectedValue: _selectedEventName,
              onSelected: (value) {
                setState(() {
                  _selectedEventName = value;
                  _syncSelections();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterDropdown({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    final safeValue = options.contains(selectedValue)
        ? selectedValue
        : options.isNotEmpty
        ? options.first
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF171A22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B303B)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF00C5D9).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00C5D9), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFF7A18),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: const Color(0xFF171A22),
                    menuMaxHeight: 280,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF7DEEFF),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    selectedItemBuilder: (context) {
                      return options.map((option) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            option,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList();
                    },
                    items: options.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onSelected(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    final selectedDayDescription =
        _selectedDayOption?.description ?? 'All event days';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00C5D9).withValues(alpha: 0.12),
              const Color(0xFFFF7A18).withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: const Color(0xFF1E2128)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, color: Color(0xFF00C5D9), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$selectedDayDescription / $_selectedEventName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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

  Widget _buildTop3Section(List<_RankedTeam> rankings) {
    if (rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No rankings available for the selected filters.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final topThree = List<_RankedTeam?>.generate(
      3,
      (index) => index < rankings.length ? rankings[index] : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildPodiumCard(
                  team: topThree[1],
                  place: 2,
                  isFeatured: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPodiumCard(
                  team: topThree[0],
                  place: 1,
                  isFeatured: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPodiumCard(
                  team: topThree[2],
                  place: 3,
                  isFeatured: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF1E2128)),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required _RankedTeam? team,
    required int place,
    required bool isFeatured,
  }) {
    final accentColor = isFeatured
        ? const Color(0xFFFF7A18)
        : place == 2
        ? const Color(0xFF7DEEFF)
        : const Color(0xFFE8E8E8);

    final avatarSize = isFeatured ? 102.0 : 82.0;

    if (team == null) {
      return Column(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: accentColor.withValues(alpha: 0.5),
              size: isFeatured ? 46 : 38,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'TBD',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: isFeatured ? 16 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (isFeatured)
          const Icon(
            Icons.workspace_premium,
            color: Color(0xFFFF7A18),
            size: 20,
          ),
        if (isFeatured) const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: team.color.withValues(alpha: 0.12),
                border: Border.all(
                  color: accentColor,
                  width: isFeatured ? 2.5 : 2,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isFeatured
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  team.logoIcon.isEmpty ? team.abbreviation : team.logoIcon,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: isFeatured ? 28 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$place',
                  style: const TextStyle(
                    color: Color(0xFF061014),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          team.abbreviation,
          style: TextStyle(
            color: Colors.white,
            fontSize: isFeatured ? 16 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCompactPoints(team.points),
          style: TextStyle(
            color: isFeatured
                ? const Color(0xFFFF7A18)
                : const Color(0xFF76787F),
            fontSize: isFeatured ? 12 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(List<_RankedTeam> rankings) {
    final remainingRankings = rankings.skip(3).toList();

    if (remainingRankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'More standings will appear here as soon as more teams are ranked for this filter.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: remainingRankings.map((team) {
        final isTrendingUp = team.trend > 0;
        final isTrendingDown = team.trend < 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: team.isLive
                      ? const Color(0xFFFF7A18)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12141A),
                border: Border.all(color: const Color(0xFF1E2128)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      team.rank.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: team.isLive
                            ? const Color(0xFFFF7A18)
                            : const Color(0xFF76787F),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: team.color.withValues(alpha: 0.16),
                      border: Border.all(
                        color: team.color.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        team.logoIcon.isEmpty
                            ? _firstLabelCharacter(team.abbreviation)
                            : team.logoIcon,
                        style: TextStyle(
                          color: team.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          team.abbreviation,
                          style: const TextStyle(
                            color: Color(0xFF76787F),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isTrendingUp)
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFF00C5D9),
                            size: 14,
                          ),
                        if (isTrendingDown)
                          const Icon(
                            Icons.trending_down,
                            color: Color(0xFFE57373),
                            size: 14,
                          ),
                        if (team.trend == 0)
                          const Icon(
                            Icons.remove,
                            color: Color(0xFF76787F),
                            size: 14,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          team.trend == 0
                              ? '-'
                              : '${team.trend > 0 ? '+' : ''}${team.trend}',
                          style: TextStyle(
                            color: isTrendingDown
                                ? const Color(0xFFE57373)
                                : team.trend == 0
                                ? const Color(0xFF76787F)
                                : const Color(0xFF00C5D9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (team.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        if (team.isLive) const SizedBox(width: 8),
                        Text(
                          _formatFullPoints(team.points),
                          style: const TextStyle(
                            color: Color(0xFFFF7A18),
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0B0D),
        border: Border(top: BorderSide(color: Color(0xFF1E2128), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.home,
                'HOME',
                false,
                onTap: () {
                  _navigateToPage(const HomePage());
                },
              ),
              _buildNavItem(Icons.emoji_events_outlined, 'RANKINGS', true),
              _buildNavItem(
                Icons.calendar_today,
                'SCHEDULE',
                false,
                onTap: () {
                  _navigateToPage(const SchedulePage());
                },
              ),
              _buildNavItem(
                Icons.people_outline,
                'TEAMS',
                false,
                onTap: () {
                  _navigateToPage(const TeamsPage());
                },
              ),
              _buildNavItem(
                Icons.account_tree_outlined,
                'BRACKET',
                false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BracketPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF00C5D9) : const Color(0xFF4A4C50),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF00C5D9)
                  : const Color(0xFF4A4C50),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K PTS';
    }
    return '$points PTS';
  }

  String _firstLabelCharacter(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1);
  }

  String _formatFullPoints(int points) {
    final digits = points.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final reverseIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  static String _monthLabel(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return months[month - 1];
  }
}

class _RankedTeam {
  const _RankedTeam({
    required this.rank,
    required this.name,
    required this.abbreviation,
    required this.logoIcon,
    required this.color,
    required this.points,
    required this.trend,
    required this.isLive,
  });

  final int rank;
  final String name;
  final String abbreviation;
  final String logoIcon;
  final Color color;
  final int points;
  final int trend;
  final bool isLive;

  _RankedTeam copyWith({int? rank}) {
    return _RankedTeam(
      rank: rank ?? this.rank,
      name: name,
      abbreviation: abbreviation,
      logoIcon: logoIcon,
      color: color,
      points: points,
      trend: trend,
      isLive: isLive,
    );
  }
}

class _DayFilterOption {
  const _DayFilterOption({
    required this.label,
    required this.description,
    this.date,
  });

  final String label;
  final String description;
  final DateTime? date;
}
