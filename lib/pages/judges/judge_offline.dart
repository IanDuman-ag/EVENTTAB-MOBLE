import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';

/// Local draft + offline submit queue for the Judge module.
class JudgeOfflineStore {
  JudgeOfflineStore._();
  static final JudgeOfflineStore instance = JudgeOfflineStore._();

  static const _draftKey = 'judge_drafts_v1';
  static const _queueKey = 'judge_submit_queue_v1';

  bool isOffline = false;
  String syncStatus = 'Synced';
  final _statusCtrl = StreamController<String>.broadcast();
  StreamSubscription? _connSub;

  Stream<String> get syncStatusStream => _statusCtrl.stream;

  Future<void> init() async {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen((result) async {
      final offline = result.every((r) => r == ConnectivityResult.none);
      isOffline = offline;
      if (!offline) {
        await flushQueue();
      } else {
        _setStatus('Saved Locally');
      }
    });
    final current = await Connectivity().checkConnectivity();
    isOffline = current.every((r) => r == ConnectivityResult.none);
    if (!isOffline) {
      await flushQueue();
    }
  }

  void dispose() {
    _connSub?.cancel();
    _statusCtrl.close();
  }

  void _setStatus(String s) {
    syncStatus = s;
    _statusCtrl.add(s);
  }

  String _draftId(int eventId, int candidateId) => '$eventId:$candidateId';

  Future<void> saveDraftLocal({
    required int eventId,
    required int candidateId,
    required Map<int, double> scores,
    required Map<int, String> comments,
    required int draftStep,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    final map = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    map[_draftId(eventId, candidateId)] = {
      'event_id': eventId,
      'candidate_id': candidateId,
      'scores': scores.map((k, v) => MapEntry('$k', v)),
      'comments': comments.map((k, v) => MapEntry('$k', v)),
      'draft_step': draftStep,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_draftKey, jsonEncode(map));
    _setStatus(isOffline ? 'Saved Locally' : 'Synced');
  }

  Future<Map<String, dynamic>?> loadDraft(int eventId, int candidateId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map[_draftId(eventId, candidateId)] as Map<String, dynamic>?;
  }

  Future<void> clearDraft(int eventId, int candidateId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map.remove(_draftId(eventId, candidateId));
    await prefs.setString(_draftKey, jsonEncode(map));
  }

  Future<void> enqueueSubmit({
    required int eventId,
    required int candidateId,
    required List<Map<String, dynamic>> scores,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final list = raw == null
        ? <dynamic>[]
        : (jsonDecode(raw) as List<dynamic>);
    list.add({
      'event_id': eventId,
      'candidate_id': candidateId,
      'scores': scores,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_queueKey, jsonEncode(list));
    _setStatus('Waiting to Sync');
  }

  Future<void> flushQueue() async {
    if (isOffline) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) {
      _setStatus('Synced');
      return;
    }
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      _setStatus('Synced');
      return;
    }

    _setStatus('Syncing');
    final remaining = <Map<String, dynamic>>[];
    final token = JudgeAuthSession.current?.token ?? '';

    for (final item in list) {
      try {
        final res = await http.post(
          apiUri('/api/events/judging-events/${item['event_id']}/submit_scores/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'candidate_id': item['candidate_id'],
            'scores': item['scores'],
          }),
        );
        if (res.statusCode != 200) {
          remaining.add(item);
        } else {
          await clearDraft(
            item['event_id'] as int,
            item['candidate_id'] as int,
          );
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    await prefs.setString(_queueKey, jsonEncode(remaining));
    _setStatus(remaining.isEmpty ? 'Synced' : 'Sync Failed');
  }
}
