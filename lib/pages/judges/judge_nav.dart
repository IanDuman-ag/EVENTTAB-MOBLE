import 'package:flutter/material.dart';

import 'jevent.dart';
import 'judge_shell.dart';

/// Shared judge bottom-nav navigation (avoids jhome <-> jevent circular imports).
class JudgeNav {
  JudgeNav._();

  static void toHome(BuildContext context) {
    // Check if we're already on the home page
    if (ModalRoute.of(context)?.settings.name == '/judge/home') return;
    
    // Try to find the home page in the stack
    var foundHome = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/judge/home') {
        foundHome = true;
        return true;
      }
      // Stop at the first route that's not a judge page to avoid going back to role selection
      if (route.isFirst || route.settings.name == null || !route.settings.name!.startsWith('/judge/')) {
        return true;
      }
      return false;
    });
    
    // If we didn't find home in the stack, push it
    if (!foundHome) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/judge/home'),
          builder: (_) => const JudgeHomePage(),
        ),
      );
    }
  }

  static void toEvents(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == '/judge/events') return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/judge/events'),
        builder: (_) => const JEventPage(),
      ),
      (route) => route.settings.name == '/judge/home',
    );
  }
}
