import 'package:flutter/material.dart';

/// Scorer portal light theme — navy / gold / white (mockup-accurate).
const scorerNavy = Color(0xFF211D5A);
const scorerGold = Color(0xFFF5A900);
const scorerWhite = Color(0xFFFFFFFF);
const scorerBg = Color(0xFFF5F4FA);
const scorerCard = Color(0xFFFFFFFF);
const scorerBorder = Color(0xFFE4E2F0);
const scorerMuted = Color(0xFF8A87A5);
const scorerText = Color(0xFF211D5A);
const scorerCyan = Color(0xFFF5A900);
const scorerPurple = Color(0xFFF5A900); // primary accent alias
const scorerGreen = Color(0xFF2E9B4F);
const scorerOrange = Color(0xFFF5A900);
const scorerRed = Color(0xFFE53935);
const scorerBlue = Color(0xFF3D6BFF);
const scorerCream = Color(0xFFFFF6E5);

String scorerGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

Color scorerParseColor(String? hex) {
  if (hex == null || hex.isEmpty) return scorerGold;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return scorerGold;
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

/// Split "A vs B" so "vs" can be styled in gold.
List<InlineSpan> scorerTeamsSpans(String label, {double fontSize = 13}) {
  final parts = label.split(RegExp(r'\s+vs\s+', caseSensitive: false));
  if (parts.length < 2) {
    return [
      TextSpan(
        text: label,
        style: TextStyle(
          color: scorerNavy,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }
  return [
    TextSpan(
      text: parts.first.trim(),
      style: TextStyle(
        color: scorerNavy,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
    TextSpan(
      text: ' vs ',
      style: TextStyle(
        color: scorerGold,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    ),
    TextSpan(
      text: parts.sublist(1).join(' vs ').trim(),
      style: TextStyle(
        color: scorerNavy,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    ),
  ];
}
