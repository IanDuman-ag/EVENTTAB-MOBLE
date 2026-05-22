import 'package:flutter/material.dart';

import 'jevent.dart';
import 'jhome.dart';

/// Shared judge bottom-nav navigation (avoids jhome <-> jevent circular imports).
class JudgeNav {
  JudgeNav._();

  static void toHome(BuildContext context) {
    var atHome = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/judge/home') {
        atHome = true;
        return true;
      }
      return route.isFirst;
    });
    if (!atHome) {
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
