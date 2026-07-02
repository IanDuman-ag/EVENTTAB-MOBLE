import 'package:flutter/material.dart';

const scorerBg = Color(0xFF0B0B12);
const scorerCard = Color(0xFF17131F);
const scorerBorder = Color(0xFF2A2433);
const scorerCyan = Color(0xFF00C5D9);
const scorerPurple = Color(0xFF9F66FF);
const scorerMuted = Color(0xFF8B8D91);
const scorerGreen = Color(0xFF4CAF50);
const scorerOrange = Color(0xFFFF9800);
const scorerRed = Color(0xFFFF5252);
const scorerBlue = Color(0xFF2196F3);

String scorerGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

Color scorerParseColor(String? hex) {
  if (hex == null || hex.isEmpty) return scorerCyan;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return scorerCyan;
  }
}

IconData scorerSportIcon(String? sport) {
  switch (sport) {
    case 'basketball':
    case 'sports_basketball':
      return Icons.sports_basketball_rounded;
    case 'volleyball':
    case 'sports_volleyball':
      return Icons.sports_volleyball_rounded;
    case 'football':
    case 'sports_soccer':
      return Icons.sports_soccer_rounded;
    case 'table_tennis':
    case 'sports_tennis':
    case 'tennis':
      return Icons.sports_tennis_rounded;
    case 'sports_esports':
      return Icons.sports_esports_rounded;
    default:
      return Icons.sports_rounded;
  }
}
