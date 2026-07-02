import 'package:flutter/material.dart';

const judgeBg = Color(0xFF0B0B12);
const judgeCard = Color(0xFF17131F);
const judgeBorder = Color(0xFF2A2433);
const judgeCyan = Color(0xFF00C5D9);
const judgePurple = Color(0xFF9F66FF);
const judgeMuted = Color(0xFF8B8D91);
const judgeGreen = Color(0xFF4CAF50);
const judgeRed = Color(0xFFFF5252);
const judgeYellow = Color(0xFFFFC107);

IconData judgeCategoryIcon(String? iconName) {
  switch (iconName) {
    case 'sports_soccer':
      return Icons.sports_soccer_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'sports_esports':
      return Icons.sports_esports_rounded;
    case 'theater_comedy':
      return Icons.theater_comedy_rounded;
    case 'mic':
      return Icons.mic_rounded;
    case 'directions_run':
      return Icons.directions_run_rounded;
    default:
      return Icons.emoji_events_rounded;
  }
}

Color judgeStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'ongoing':
    case 'live':
      return judgeRed;
    case 'completed':
    case 'approved':
      return judgeGreen;
    case 'pending':
    case 'upcoming':
      return judgeCyan;
    case 'rejected':
      return judgeRed;
    default:
      return judgeMuted;
  }
}

String judgeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
