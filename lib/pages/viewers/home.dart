import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import '../auth/server_url_dialog.dart';
import 'bracket.dart';
import 'profile.dart';
import 'rankings.dart';
import 'schedule.dart';
import 'teams.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _featuredMatch;
  List<dynamic> _upcomingMatches = [];
  List<dynamic> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = AuthSession.current?.token;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };

    final results = await Future.wait<_LoadResult<dynamic>>([
      _fetchJson('/api/events/matches/featured/', headers),
      _fetchJson('/api/events/matches/upcoming/', headers),
      _fetchJson('/api/events/activities/', headers),
    ]);

    if (!mounted) {
      return;
    }

    final featuredResult = results[0];
    final upcomingResult = results[1];
    final activitiesResult = results[2];

    final unavailableSections = <String>[
      if (!featuredResult.isSuccess) 'featured match',
      if (!upcomingResult.isSuccess) 'upcoming matches',
      if (!activitiesResult.isSuccess) 'activity feed',
    ];
    final errors = results
        .map((result) => result.error)
        .whereType<String>()
        .toList();

    setState(() {
      _featuredMatch = featuredResult.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              featuredResult.data as Map<String, dynamic>,
            )
          : null;
      _upcomingMatches = upcomingResult.data is List
          ? List<dynamic>.from(upcomingResult.data as List)
          : [];
      _activities = activitiesResult.data is List
          ? List<dynamic>.from(activitiesResult.data as List)
          : [];
      _errorMessage = unavailableSections.isEmpty
          ? null
          : _buildPartialLoadMessage(unavailableSections, errors);
      _isLoading = false;
    });
  }

  Future<_LoadResult<dynamic>> _fetchJson(
    String path,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http.get(apiUri(path), headers: headers);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} for $path');
      }

      final body = response.body.trim();
      if (body.isEmpty || body == 'null') {
        return const _LoadResult.success(null);
      }

      return _LoadResult.success(jsonDecode(body));
    } catch (error) {
      return _LoadResult.failure(_buildLoadErrorMessage(error));
    }
  }

  String _buildPartialLoadMessage(
    List<String> unavailableSections,
    List<String> errors,
  ) {
    final sectionSummary = unavailableSections.join(', ');
    final details = errors.isEmpty ? '' : '\n${errors.first}';
    return 'Some home sections are unavailable right now: $sectionSummary.'
        '\nYou can still use the rest of the viewer.$details';
  }

  String _buildLoadErrorMessage(Object error) {
    if (error is SocketException) {
      return 'Could not reach the server at $defaultApiBaseUrl.\n'
          'On a phone, use your computer IP and make sure Django is running on '
          '0.0.0.0:8000.';
    }

    if (error is http.ClientException) {
      return 'The app could not fetch data from $defaultApiBaseUrl.\n'
          'If you are running the viewer in a browser, make sure the backend '
          'is running on the same machine or pass `API_BASE_URL`.';
    }

    return 'Failed to load data: $error';
  }

  Widget _buildInlineErrorBanner() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A18).withValues(alpha: 0.12),
        border: Border.all(color: const Color(0xFFFF7A18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_off_outlined, color: Color(0xFFFF7A18)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Viewer home is partially unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: _loadData,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF7A18)),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final didSave = await showServerUrlDialog(context);
                  if (didSave && mounted) {
                    _loadData();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00C5D9)),
                  foregroundColor: const Color(0xFF00C5D9),
                ),
                child: const Text('Server URL'),
              ),
            ],
          ),
        ],
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0D),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00C5D9), width: 2),
                color: const Color(0xFF0A0B0D),
              ),
              child: Row(
                children: [
                  // Profile Avatar
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInlineErrorBanner(),
                    // Featured Match Card
                    _buildFeaturedMatch(),
                    const SizedBox(height: 24),
                    // Upcoming Matches
                    _buildUpcomingMatches(),
                    const SizedBox(height: 24),
                    // Activity Feed
                    _buildActivityFeed(),
                    const SizedBox(height: 80), // Space for bottom nav
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

  Widget _buildFeaturedMatch() {
    if (_featuredMatch == null) {
      return const SizedBox.shrink();
    }

    final match = _featuredMatch!;
    final teamA = match['team_a'];
    final teamB = match['team_b'];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: const Color(0xFFFF7A18), width: 4),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12141A),
          border: Border.all(color: const Color(0xFF1E2128)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arena Image
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00C5D9).withValues(alpha: 0.3),
                    const Color(0xFF12141A),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.sports_basketball,
                  size: 80,
                  color: const Color(0xFF00C5D9).withValues(alpha: 0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match['title'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFF7A18),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match['title'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teamA['abbreviation'].toString(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match['score_a'].toString(),
                              style: const TextStyle(
                                color: Color(0xFF00C5D9),
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        color: const Color(0xFF2B2D31),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              teamB['abbreviation'].toString(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match['score_b'].toString(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(width: 4, height: 20, color: const Color(0xFF00C5D9)),
              const SizedBox(width: 12),
              const Text(
                'UPCOMING MATCHES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'SEE ALL',
                  style: TextStyle(
                    color: Color(0xFF00C5D9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _upcomingMatches.isEmpty
              ? const Center(
                  child: Text(
                    'No upcoming matches',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _upcomingMatches.length,
                  itemBuilder: (context, index) {
                    final match = _upcomingMatches[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _upcomingMatches.length - 1 ? 12 : 0,
                      ),
                      child: _buildMatchCard(match),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final teamA = match['team_a'];
    final teamB = match['team_b'];
    final scheduledTime = DateTime.parse(match['scheduled_time']);
    final dateStr =
        '${_getMonthAbbr(scheduledTime.month)} ${scheduledTime.day} - ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF12141A),
        border: Border.all(color: const Color(0xFF1E2128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        teamA['color'].toString().replaceFirst('#', '0xFF'),
                      ),
                    ).withValues(alpha: 0.2),
                    border: Border.all(
                      color: Color(
                        int.parse(
                          teamA['color'].toString().replaceFirst('#', '0xFF'),
                        ),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      teamA['logo_icon'].toString(),
                      style: TextStyle(
                        color: Color(
                          int.parse(
                            teamA['color'].toString().replaceFirst('#', '0xFF'),
                          ),
                        ),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        teamB['color'].toString().replaceFirst('#', '0xFF'),
                      ),
                    ).withValues(alpha: 0.2),
                    border: Border.all(
                      color: Color(
                        int.parse(
                          teamB['color'].toString().replaceFirst('#', '0xFF'),
                        ),
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      teamB['logo_icon'].toString(),
                      style: TextStyle(
                        color: Color(
                          int.parse(
                            teamB['color'].toString().replaceFirst('#', '0xFF'),
                          ),
                        ),
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamA['abbreviation'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'vs ${teamB['abbreviation']}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00C5D9)),
            ),
            child: const Text(
              'REMIND ME',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00C5D9),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(width: 4, height: 20, color: const Color(0xFFFF7A18)),
              const SizedBox(width: 12),
              const Text(
                'ACTIVITY FEED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_activities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No recent activities',
              style: TextStyle(color: Colors.white54),
            ),
          )
        else
          ..._activities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    switch (activity['icon']) {
      case 'emoji_events':
        icon = Icons.emoji_events;
        break;
      case 'calendar_today':
        icon = Icons.calendar_today;
        break;
      case 'announcement':
        icon = Icons.announcement;
        break;
      default:
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12141A),
        border: Border.all(color: const Color(0xFF1E2128)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF7A18), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time_ago'],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              _buildNavItem(Icons.home, 'HOME', true),
              _buildNavItem(
                Icons.emoji_events_outlined,
                'RANKINGS',
                false,
                onTap: () {
                  _navigateToPage(const RankingsPage());
                },
              ),
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

  String _getMonthAbbr(int month) {
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

class _LoadResult<T> {
  const _LoadResult._({this.data, this.error});

  const _LoadResult.success(T? data) : this._(data: data);
  const _LoadResult.failure(String error) : this._(error: error);

  final T? data;
  final String? error;

  bool get isSuccess => error == null;
}
