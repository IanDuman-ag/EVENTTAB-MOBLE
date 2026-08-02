import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';
import 'viewer_leaderboard.dart';
import 'viewer_theme.dart';

/// More tab — Announcements, Departments, Calendar, About.
class ViewerMoreBody extends StatelessWidget {
  const ViewerMoreBody({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.campaign_outlined,
        'Announcements',
        'Official ceremony & schedule notices',
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ViewerAnnouncementsPage()),
            )
      ),
      (
        Icons.apartment_outlined,
        'Departments',
        'Participating colleges & standings',
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ViewerDepartmentsPage()),
            )
      ),
      (
        Icons.calendar_month_outlined,
        'Event Calendar',
        'Published events by date',
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ViewerCalendarPage()),
            )
      ),
      (
        Icons.info_outline_rounded,
        'About EventTab',
        'System info & contact',
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ViewerAboutPage()),
            )
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'More',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Announcements, departments, calendar, and about.',
          style: TextStyle(color: viewerMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: viewerCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: viewerBorder),
            ),
            child: ListTile(
              leading: Icon(item.$1, color: viewerCyan),
              title: Text(
                item.$2,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              subtitle: Text(item.$3, style: const TextStyle(color: viewerMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: viewerMuted),
              onTap: item.$4,
            ),
          );
        }),
      ],
    );
  }
}

class ViewerAnnouncementsPage extends StatefulWidget {
  const ViewerAnnouncementsPage({super.key});

  @override
  State<ViewerAnnouncementsPage> createState() => _ViewerAnnouncementsPageState();
}

class _ViewerAnnouncementsPageState extends State<ViewerAnnouncementsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(
        apiUri('/api/events/viewer/announcements/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['announcements'] as List? ?? []);
        setState(() {
          _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: 'Announcements',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: viewerCyan))
                  : _items.isEmpty
                      ? const Center(
                          child: Text('No announcements yet.',
                              style: TextStyle(color: viewerMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final a = _items[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: viewerCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: viewerBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a['title'] ?? 'Announcement'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${a['body'] ?? a['description'] ?? ''}',
                                    style: const TextStyle(color: viewerMuted, height: 1.35),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${a['time_display'] ?? ''}',
                                    style: const TextStyle(color: viewerCyan, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewerDepartmentsPage extends StatefulWidget {
  const ViewerDepartmentsPage({super.key});

  @override
  State<ViewerDepartmentsPage> createState() => _ViewerDepartmentsPageState();
}

class _ViewerDepartmentsPageState extends State<ViewerDepartmentsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(
        apiUri('/api/events/viewer/rankings/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['rankings'] as List?) ?? [];
        setState(() {
          _rows = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: 'Departments',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: viewerCyan))
                  : _rows.isEmpty
                      ? const Center(
                          child: Text('No departments listed yet.',
                              style: TextStyle(color: viewerMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rows.length,
                          itemBuilder: (_, i) {
                            final d = _rows[i];
                            Color accent = viewerCyan;
                            try {
                              accent = Color(
                                int.parse('${d['color']}'.replaceFirst('#', '0xFF')),
                              );
                            } catch (_) {}
                            return InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewerDepartmentDetailPage(department: d),
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: viewerCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: viewerBorder),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: accent.withValues(alpha: 0.2),
                                      child: Text(
                                        '${d['abbreviation'] ?? '?'}'.substring(
                                          0,
                                          ('${d['abbreviation'] ?? '?'}'.length)
                                              .clamp(0, 3),
                                        ),
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${d['name'] ?? 'Department'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            'Rank #${d['rank'] ?? '—'} · ${d['points'] ?? 0} pts',
                                            style: const TextStyle(
                                              color: viewerMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: viewerMuted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewerCalendarPage extends StatefulWidget {
  const ViewerCalendarPage({super.key});

  @override
  State<ViewerCalendarPage> createState() => _ViewerCalendarPageState();
}

class _ViewerCalendarPageState extends State<ViewerCalendarPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(
        apiUri('/api/events/viewer/events/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['events'] as List? ?? []);
        final events = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        events.sort((a, b) => '${a['scheduled_time'] ?? a['date_display']}'
            .compareTo('${b['scheduled_time'] ?? b['date_display']}'));
        setState(() {
          _events = events;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: 'Event Calendar',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: viewerCyan))
                  : _events.isEmpty
                      ? const Center(
                          child: Text('No published events.',
                              style: TextStyle(color: viewerMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (_, i) {
                            final e = _events[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: viewerCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: viewerBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e['event_name'] ?? e['title'] ?? 'Event'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${e['date_display'] ?? 'TBD'} · ${e['time_display'] ?? '—'}',
                                    style: const TextStyle(color: viewerCyan, fontSize: 12),
                                  ),
                                  Text(
                                    '${e['venue'] ?? 'TBD'}',
                                    style: const TextStyle(color: viewerMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewerAboutPage extends StatefulWidget {
  const ViewerAboutPage({super.key});

  @override
  State<ViewerAboutPage> createState() => _ViewerAboutPageState();
}

class _ViewerAboutPageState extends State<ViewerAboutPage> {
  Map<String, dynamic> _about = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = AuthSession.current?.token;
      final res = await http.get(
        apiUri('/api/events/viewer/about/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _about = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: viewerBg,
      body: SafeArea(
        child: Column(
          children: [
            ViewerHeader(
              title: 'About EventTab',
              showBack: true,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Icon(Icons.emoji_events_outlined, color: viewerCyan, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'EventTab',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_about['system_description'] ?? 'EventTab Intramurals Management System.'}',
                    style: const TextStyle(color: viewerMuted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  _row('School', '${_about['school_name'] ?? '—'}'),
                  _row('Current Intramurals', '${_about['current_intramurals'] ?? '—'}'),
                  _row('Version', '${_about['version'] ?? '1.0.0'}'),
                  _row('Contact', '${_about['contact'] ?? '—'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: viewerMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
