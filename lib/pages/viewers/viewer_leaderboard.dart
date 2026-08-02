import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_theme.dart';

/// Overall championship leaderboard (departments / teams).
class ViewerLeaderboardBody extends StatefulWidget {
  const ViewerLeaderboardBody({super.key});

  @override
  State<ViewerLeaderboardBody> createState() => _ViewerLeaderboardBodyState();
}

class _ViewerLeaderboardBodyState extends State<ViewerLeaderboardBody> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  Map<String, String> get _headers {
    final token = AuthSession.current?.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        apiUri('/api/events/viewer/rankings/'),
        headers: _headers,
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _error = 'Failed to load leaderboard (${res.statusCode})';
          _loading = false;
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['rankings'] as List?) ?? (data['teams'] as List?) ?? [];
      setState(() {
        _rows = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Championship Leaderboard',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Overall standings from officially published results.',
            style: TextStyle(color: viewerMuted, fontSize: 12),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: viewerCyan));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: viewerMuted)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text('No standings published yet.', style: TextStyle(color: viewerMuted)),
      );
    }
    return RefreshIndicator(
      color: viewerCyan,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: viewerCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: viewerBorder),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text('Rank',
                            style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        child: Text('Department',
                            style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text('Points',
                            textAlign: TextAlign.end,
                            style: TextStyle(color: viewerMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: viewerBorder),
                ..._rows.map((r) => InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ViewerDepartmentDetailPage(department: r),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${r['rank'] ?? ''}',
                                style: TextStyle(
                                  color: r['rank'] == 1 ? viewerOrange : Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${r['name'] ?? 'Department'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Text(
                                '${r['points'] ?? 0}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: viewerCyan,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ViewerDepartmentDetailPage extends StatelessWidget {
  const ViewerDepartmentDetailPage({super.key, required this.department});

  final Map<String, dynamic> department;

  @override
  Widget build(BuildContext context) {
    final name = department['name'] ?? 'Department';
    final points = department['points'] ?? 0;
    final wins = department['wins'] ?? 0;
    final events = department['events'] ?? department['played'] ?? 0;
    final rank = department['rank'] ?? '—';
    final losses = department['losses'] ?? 0;

    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: '$name',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '$name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Rank #$rank',
                    style: const TextStyle(color: viewerCyan, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  _stat('Total Championship Points', '$points'),
                  _stat('Major Event Wins', '$wins'),
                  _stat('Minor Event Wins', '${department['minor_wins'] ?? 0}'),
                  _stat('Events Won / Played', '$events'),
                  _stat('Losses', '$losses'),
                  const SizedBox(height: 16),
                  const Text(
                    'Participating Events',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    department['category'] != null && '${department['category']}'.isNotEmpty
                        ? 'Category focus: ${department['category']}'
                        : 'Based on officially published match results.',
                    style: const TextStyle(color: viewerMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: viewerCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: viewerBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: viewerMuted, fontSize: 13)),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
