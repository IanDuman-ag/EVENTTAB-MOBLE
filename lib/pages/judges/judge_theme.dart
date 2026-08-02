import 'package:flutter/material.dart';

/// Accent colors shared by light and dark.
const judgeGold = Color(0xFFF5A900);
const judgeGreen = Color(0xFF2E9B4F);
const judgeRed = Color(0xFFE53935);
const judgeBlue = Color(0xFF3D6BFF);
const judgePurple = Color(0xFF7B5CFF);
const judgeYellow = judgeGold;
const judgeCyan = judgeGold;

/// Light defaults (kept for older screens that still use consts).
const judgeNavy = Color(0xFF211D5A);
const judgeWhite = Color(0xFFFFFFFF);
const judgeBg = Color(0xFFF5F4FA);
const judgeCard = Color(0xFFFFFFFF);
const judgeBorder = Color(0xFFE4E2F0);
const judgeMuted = Color(0xFF8A87A5);
const judgeCream = Color(0xFFFFF6E5);

class JudgePalette {
  const JudgePalette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.cream,
    required this.surface,
    required this.chip,
    required this.headerBg,
  });

  final bool isDark;
  final Color bg;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color cream;
  final Color surface;
  final Color chip;
  final Color headerBg;

  static const light = JudgePalette(
    isDark: false,
    bg: Color(0xFFF5F4FA),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE4E2F0),
    text: Color(0xFF211D5A),
    muted: Color(0xFF8A87A5),
    cream: Color(0xFFFFF6E5),
    surface: Color(0xFFFFFFFF),
    chip: Color(0xFFEEEDF5),
    headerBg: Color(0xFFFFFFFF),
  );

  static const dark = JudgePalette(
    isDark: true,
    bg: Color(0xFF0B0B12),
    card: Color(0xFF17131F),
    border: Color(0xFF2A2433),
    text: Color(0xFFF5F4FA),
    muted: Color(0xFF9A96B0),
    cream: Color(0xFF2A2418),
    surface: Color(0xFF121018),
    chip: Color(0xFF221E2C),
    headerBg: Color(0xFF17131F),
  );
}

class JudgeThemeScope extends InheritedWidget {
  const JudgeThemeScope({
    super.key,
    required this.isDark,
    required this.onToggle,
    required super.child,
  });

  final bool isDark;
  final VoidCallback onToggle;

  JudgePalette get colors => isDark ? JudgePalette.dark : JudgePalette.light;

  static JudgeThemeScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<JudgeThemeScope>();
  }

  static JudgeThemeScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'JudgeThemeScope not found in context');
    return scope!;
  }

  static JudgePalette paletteOf(BuildContext context) {
    return maybeOf(context)?.colors ?? JudgePalette.light;
  }

  @override
  bool updateShouldNotify(JudgeThemeScope oldWidget) =>
      isDark != oldWidget.isDark;
}

IconData judgeCategoryIcon(String? iconName) {
  switch (iconName) {
    case 'sports_soccer':
      return Icons.sports_soccer_rounded;
    case 'sports_basketball':
      return Icons.sports_basketball_rounded;
    case 'sports_volleyball':
      return Icons.sports_volleyball_rounded;
    case 'sports_tennis':
    case 'table_tennis':
      return Icons.sports_tennis_rounded;
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
      return judgeGold;
    case 'completed':
    case 'approved':
      return judgeGreen;
    case 'pending':
    case 'upcoming':
      return judgeGold;
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

List<InlineSpan> judgeSubjectSpans(
  String label, {
  double fontSize = 12,
  Color? muted,
  Color? highlight,
}) {
  final mutedColor = muted ?? judgeMuted;
  final gold = highlight ?? judgeGold;
  final parts = label.split(RegExp(r'\s*[–-]\s*'));
  if (parts.length < 2) {
    return [
      TextSpan(
        text: label,
        style: TextStyle(
          color: mutedColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }
  return [
    TextSpan(
      text: '${parts.first.trim()} - ',
      style: TextStyle(
        color: mutedColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    TextSpan(
      text: parts.sublist(1).join(' - ').trim(),
      style: TextStyle(
        color: gold,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
      ),
    ),
  ];
}
