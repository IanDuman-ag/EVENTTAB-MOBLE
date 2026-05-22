import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'home.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

  String get _displayName {
    final username = AuthSession.current?.username.trim();
    if (username == null || username.isEmpty) {
      return 'MARCUS VANCE';
    }

    return username
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get _emailAddress {
    final email = AuthSession.current?.email.trim();
    if (email == null || email.isEmpty) {
      return 'm.vance@elitearena.com';
    }
    return email;
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    final navigator = Navigator.of(context);

    setState(() {
      _isLoggingOut = true;
    });

    await authService.logout();

    if (!mounted) {
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onLogin: () {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          },
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                      return;
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12141A),
                      border: Border.all(color: const Color(0xFF00C5D9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFFFB083),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileHeroCard(
                  displayName: _displayName.toUpperCase(),
                  initials: _initialsFromName(_displayName),
                ),
                const SizedBox(height: 42),
                const _SectionLabel('ACCOUNT INTEGRITY'),
                const SizedBox(height: 14),
                _SettingRow(
                  icon: Icons.mail_outline,
                  accentColor: const Color(0xFF7CE1EF),
                  title: 'Email Address',
                  subtitle: _emailAddress,
                ),
                const SizedBox(height: 2),
                const _SettingRow(
                  icon: Icons.lock_outline,
                  accentColor: Color(0xFF7CE1EF),
                  title: 'Password',
                  subtitle: 'Updated 3 months ago',
                ),
                const SizedBox(height: 42),
                const _SectionLabel('NOTIFICATIONS & THEME'),
                const SizedBox(height: 14),
                _NotificationRow(
                  enabled: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                const _ThemeRow(),
                const SizedBox(height: 20),
                _LogoutButton(isBusy: _isLoggingOut, onPressed: _handleLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initialsFromName(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'MV';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.displayName, required this.initials});

  final String displayName;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141415),
        border: Border.all(color: const Color(0xFF18191B)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF102B31), Color(0xFF0C1114)],
                  ),
                  border: Border.all(color: const Color(0xFF7CE1EF)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF7CE1EF),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF161311),
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF5D6168),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.7,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151516),
        border: Border.all(color: const Color(0xFF111214)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6A6D73),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF5D6168), size: 18),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151516),
        border: Border.all(color: const Color(0xFF111214)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFFFF7A18),
            size: 18,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Match starts, results, and rank movements.',
                  style: TextStyle(
                    color: Color(0xFF6A6D73),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFB35A08),
            inactiveThumbColor: const Color(0xFF7B7F85),
            inactiveTrackColor: const Color(0xFF2A2D34),
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151516),
        border: Border.all(color: const Color(0xFF111214)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.dark_mode_outlined,
            color: Color(0xFFFF7A18),
            size: 18,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Theme',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1511),
              border: Border.all(color: const Color(0xFF7C3300)),
            ),
            child: const Text(
              'DARK',
              style: TextStyle(
                color: Color(0xFFFF7A18),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Color(0xFF5A241A)),
          shape: const RoundedRectangleBorder(),
          foregroundColor: const Color(0xFFF16A52),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF16A52),
                ),
              )
            : const Icon(Icons.logout, size: 16),
        label: Text(
          isBusy ? 'LOGGING OUT' : 'LOG OUT',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
