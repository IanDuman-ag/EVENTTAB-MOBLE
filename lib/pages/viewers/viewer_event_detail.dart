import 'package:flutter/material.dart';

import 'viewer_criteria_detail.dart';
import 'viewer_match_detail.dart';

/// Open match-based or criteria-based event detail from a list/dashboard card.
void openViewerEvent(BuildContext context, Map<String, dynamic> item) {
  final source = '${item['source'] ?? ''}';
  final eventType = '${item['event_type'] ?? ''}';
  final isCriteria = eventType == 'criteria' ||
      source == 'judging' ||
      item['judging_event_id'] != null ||
      '${item['id']}'.startsWith('judging_');

  if (isCriteria) {
    final rawId = item['judging_event_id'] ?? item['id'];
    final idStr = '$rawId'.replaceFirst('judging_', '');
    final id = int.tryParse(idStr);
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViewerCriteriaDetailPage(eventId: id)),
    );
    return;
  }

  final id = item['id'];
  final matchId = id is int ? id : int.tryParse('$id');
  if (matchId == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ViewerMatchDetailPage(matchId: matchId)),
  );
}
